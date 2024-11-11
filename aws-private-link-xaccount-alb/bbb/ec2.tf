
data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "main" {
  ami                         = data.aws_ssm_parameter.ami_amazon_linux.value
  instance_type               = "t3.micro"
  subnet_id                   = values(data.aws_subnet.main)[0].id
  vpc_security_group_ids      = [aws_security_group.main.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  user_data_replace_on_change = true
  user_data                   = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    hostname: "${var.name}-server"
    ssh_authorized_keys: ${jsonencode(var.authorized_keys)}
    runcmd:
      - yum install -y httpd
      - systemctl enable httpd --now
    ssh_authorized_keys: ${jsonencode(var.authorized_keys)}
    EOS

  tags = {
    Name = "${var.name}-server"
  }
}

output "instance_id" {
  value = aws_instance.main.id
}
