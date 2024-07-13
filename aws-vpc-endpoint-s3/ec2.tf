
data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "main" {
  ami                         = data.aws_ssm_parameter.ami_amazon_linux.value
  instance_type               = "t3.nano"
  subnet_id                   = values(data.aws_subnet.main)[0].id
  vpc_security_group_ids      = [aws_security_group.main.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    hostname: ${var.name}
    ssh_authorized_keys: ${jsonencode(var.ssh_authorized_keys)}
  EOS

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = var.name
  }
}

resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2"

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

resource "aws_iam_instance_profile" "ec2" {
  name = aws_iam_role.ec2.name
  role = aws_iam_role.ec2.name
}
