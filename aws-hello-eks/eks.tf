
# SSM Parameter Store から最新の Amazon Linux 2023 最適化 AMI を取得
data "aws_ssm_parameter" "eks_node_ami" {
  name = "/aws/service/eks/optimized-ami/${var.k8s_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# EKS クラスター本体
resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
  ]
}

# ノード用 Launch Template
resource "aws_launch_template" "node" {
  name_prefix   = "${var.name}-node-"
  image_id      = data.aws_ssm_parameter.eks_node_ami.value
  instance_type = "t3.small"

  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${aws_eks_cluster.cluster.name}
    apiServerEndpoint: ${aws_eks_cluster.cluster.endpoint}
    certificateAuthority: ${aws_eks_cluster.cluster.certificate_authority[0].data}
    cidr: ${aws_eks_cluster.cluster.kubernetes_network_config[0].service_ipv4_cidr}
--//--
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS マネージドノードグループ
resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.name}-node"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.node,
  ]
}

# 作業用 EC2 からのアクセスエントリ（Kubernetes グループ hello:operators に紐付け）
resource "aws_eks_access_entry" "operator" {
  cluster_name      = aws_eks_cluster.cluster.name
  principal_arn     = aws_iam_role.operator.arn
  kubernetes_groups = ["hello:operators"]
  type              = "STANDARD"
}
