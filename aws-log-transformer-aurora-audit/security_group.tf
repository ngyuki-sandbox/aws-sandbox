
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "${var.name}-rds"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "${var.name}-rds"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allow_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
