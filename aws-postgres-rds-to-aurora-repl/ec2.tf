
data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "server" {
  ami                         = data.aws_ssm_parameter.ami_amazon_linux.value
  instance_type               = "t2.nano"
  subnet_id                   = values(data.aws_subnet.subnets)[0].id
  vpc_security_group_ids      = [aws_security_group.server.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.server.name

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    hostname: "${var.prefix}-server"
    ssh_authorized_keys: ${jsonencode(var.ssh_authorized_keys)}
    runcmd:
      - amazon-linux-extras install -y postgresql14
  EOS

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "${var.prefix}-server"
  }
}

output "instance" {
  value = aws_instance.server.id
}

resource "aws_iam_role" "server" {
  name = "${var.prefix}-server"
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
