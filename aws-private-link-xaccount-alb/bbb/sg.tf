
resource "aws_security_group" "main" {
  vpc_id      = data.aws_vpc.main.id
  name        = "main"
  description = "main"
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "main" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}
