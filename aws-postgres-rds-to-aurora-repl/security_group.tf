
resource "aws_security_group" "server" {
  name        = "${var.prefix}-server"
  description = "${var.prefix}-server"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    "Name" = "${var.prefix}-server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.prefix}-rds"
  description = "${var.prefix}-rds"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    "Name" = "${var.prefix}-rds"
  }

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.server.id,
      aws_security_group.aurora.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "aurora" {
  name        = "${var.prefix}-aurora"
  description = "${var.prefix}-aurora"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    "Name" = "${var.prefix}-aurora"
  }

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.server.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
