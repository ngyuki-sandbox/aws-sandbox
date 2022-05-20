################################################################################
# Security Group
################################################################################

#-------------------------------------------------------------------------------
# rds
#-------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${local.env.tag}-rds"
  description = "${local.env.tag}-rds"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env.tag}-rds"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.env.allow_rds_ingress
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-------------------------------------------------------------------------------
# resolver_inbound
#-------------------------------------------------------------------------------

resource "aws_security_group" "resolver_inbound" {
  name        = "${local.env.tag}-resolver-inbound"
  description = "${local.env.tag}-resolver-inbound"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env.tag}-resolver-inbound"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = local.env.allow_rds_ingress
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
