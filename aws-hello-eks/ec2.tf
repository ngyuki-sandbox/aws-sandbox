
# SSM Parameter Store から最新の Amazon Linux 2023 AMI を取得
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# 作業用 EC2 の IAM ロール
resource "aws_iam_role" "operator" {
  name = "${var.name}-operator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Systems Manager Session Manager 接続用ポリシー
resource "aws_iam_role_policy_attachment" "operator_ssm" {
  role       = aws_iam_role.operator.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EKS クラスター情報の参照権限（aws eks update-kubeconfig 用）
resource "aws_iam_role_policy" "operator_eks" {
  name = "eks-describe-cluster"
  role = aws_iam_role.operator.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
        ]
        Resource = aws_eks_cluster.cluster.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "operator" {
  name = "${var.name}-operator"
  role = aws_iam_role.operator.name
}

# 作業用 EC2 のセキュリティグループ（インバウンドなし、アウトバウンド全開放）
resource "aws_security_group" "operator" {
  name        = "${var.name}-operator"
  description = "Security group for operator EC2 instance"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-operator"
  }
}

# 作業用 EC2 インスタンス（プライベートサブネットに配置）
resource "aws_instance" "operator" {
  ami                  = data.aws_ssm_parameter.al2023_ami.value
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.private[0].id
  iam_instance_profile = aws_iam_instance_profile.operator.name

  vpc_security_group_ids = [
    aws_security_group.operator.id,
  ]

  # kubectl の自動インストール
  user_data = <<-EOF
    #!/bin/bash
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
      ARCH_NAME="amd64"
    else
      ARCH_NAME="arm64"
    fi
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH_NAME/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
  EOF

  tags = {
    Name = "${var.name}-operator"
  }
}

# EKS クラスターの API サーバー（443）へのアクセスを許可するルール
resource "aws_security_group_rule" "operator" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.operator.id
  description              = "Allow HTTPS from operator EC2 to EKS API server"
}
