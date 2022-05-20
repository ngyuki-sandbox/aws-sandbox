################################################################################
# Security Group
################################################################################

#-------------------------------------------------------------------------------
# sv
#-------------------------------------------------------------------------------

resource "aws_security_group" "sv" {
  name        = "${local.env.tag}-sv"
  description = "${local.env.tag}-sv"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env.tag}-sv"
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.env.allow_ssh_ingress
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.env.vpc_cidr_block] # @todo
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-------------------------------------------------------------------------------
# resolver
#-------------------------------------------------------------------------------

resource "aws_security_group" "resolver_outbound" {
  name        = "${local.env.tag}-resolver-outbound"
  description = "${local.env.tag}-resolver-outbound"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env.tag}-resolver-outbound"
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  ingress {
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
    security_groups = [aws_security_group.sv.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
