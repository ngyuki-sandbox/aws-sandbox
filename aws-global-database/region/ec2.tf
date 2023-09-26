
data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "server" {
  ami                         = data.aws_ssm_parameter.ami_amazon_linux.value
  instance_type               = "t3.nano"
  subnet_id                   = sort(data.aws_subnets.main.ids)[0]
  vpc_security_group_ids      = [aws_security_group.main.id]
  iam_instance_profile        = aws_iam_instance_profile.server.name
  ebs_optimized               = false
  monitoring                  = false
  associate_public_ip_address = true

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    hostname: "${var.name}-server"
    ssh_authorized_keys: ${jsonencode(var.ec2_authorized_keys)}
  EOS

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "${var.name}-server"
  }
}

resource "aws_iam_role" "server" {
  name = "${var.name}-server"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_instance_profile" "server" {
  name = aws_iam_role.server.name
  role = aws_iam_role.server.name
}
