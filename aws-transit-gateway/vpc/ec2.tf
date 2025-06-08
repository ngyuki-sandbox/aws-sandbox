################################################################################
# EC2

data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_iam_instance_profile" "ec2" {
  name = "AmazonSSMRoleForInstancesQuickSetup"
}

resource "aws_instance" "server" {
  ami                         = data.aws_ssm_parameter.ami_amazon_linux.value
  key_name                    = var.key_name
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.subnets[0].id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  iam_instance_profile        = data.aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    hostname: "${var.tag}-server"
  EOS

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "${var.tag}-server"
  }
}

output "instances" {
  value = {
    server = {
      instance_id = aws_instance.server.id
      private_ip  = aws_instance.server.private_ip
    }
  }
}
