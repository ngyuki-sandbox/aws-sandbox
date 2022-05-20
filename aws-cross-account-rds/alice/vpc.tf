################################################################################
# VPC
################################################################################

resource "aws_vpc" "vpc" {
  cidr_block           = local.env.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env.tag}-vpc"
  }
}

#-------------------------------------------------------------------------------
# Subnet
#-------------------------------------------------------------------------------

resource "aws_subnet" "subnets" {
  for_each = local.env.subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.env.tag}-public-${each.key}"
  }
}

#-------------------------------------------------------------------------------
# Gateway
#-------------------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.env.tag}-igw"
  }
}

#-------------------------------------------------------------------------------
# Route Table
#-------------------------------------------------------------------------------

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.env.tag}-rt"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block                = local.peer.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }
}

resource "aws_route_table_association" "rt" {
  for_each = aws_subnet.subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.rt.id
}
