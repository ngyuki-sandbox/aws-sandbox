################################################################################
# VPC

resource aws_vpc main {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.tag}-vpc"
  }
}

output vpc_id {
  value = aws_vpc.main.id
}

################################################################################
# internet_gateway

resource aws_internet_gateway igw {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.tag}-igw"
  }
}

################################################################################
# Subnet

data aws_availability_zones available {
  state            = "available"
  exclude_zone_ids = ["apne1-az3"]
}

resource aws_subnet subnets {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 100 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.tag}-front"
  }
}

################################################################################
# Security Group

resource aws_security_group sg {
  vpc_id      = aws_vpc.main.id
  name        = "${var.tag}-sg"
  description = "${var.tag}-sg"

  tags = {
    Name = "${var.tag}-sg"
  }

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
