################################################################################
# EC2

resource "aws_instance" "server" {
  ami                         = "ami-0f310fced6141e627" # Amazon Linux 2 AMI 2.0.20200406.0 x86_64 HVM gp2
  instance_type               = "t3.nano"
  key_name                    = local.key_name
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.server.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "${local.tag}-sv"
  }
}
