################################################################################
# VPC

resource "aws_vpc" "main" {
  cidr_block           = "10.27.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.tag}-vpc"
  }
}

locals {
  vpc_id = aws_vpc.main.id
}

################################################################################
# Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = local.vpc_id

  tags = {
    Name = "${local.tag}-igw"
  }
}

################################################################################
# Subnet

resource "aws_subnet" "public_a" {
  vpc_id            = local.vpc_id
  cidr_block        = "10.27.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${local.tag}-a"
  }
}

################################################################################
# Route Table

resource "aws_route_table" "route" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.tag}-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.route.id
}
