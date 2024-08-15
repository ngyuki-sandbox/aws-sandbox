
data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "aws_security_group" "main" {
  vpc_id = data.aws_vpc.main.id
  name   = var.name
}

resource "aws_vpc_security_group_ingress_rule" "self" {
  security_group_id            = aws_security_group.main.id
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.main.id
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}
