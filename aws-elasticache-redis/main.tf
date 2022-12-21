################################################################################
# main
################################################################################

data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name
}

################################################################################
# vpc
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name               = var.name
  cidr               = "10.0.0.0/16"
  azs                = ["${local.region}a", "${local.region}c"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_ipv6        = false
  enable_nat_gateway = false
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis"
  description = "${var.name}-redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2"
  description = "${var.name}-ec2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_ingress
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# EC2
################################################################################

resource "aws_instance" "instance" {
  ami                    = "ami-0abaa5b0faf689830"
  instance_type          = "t3.nano"
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = module.vpc.public_subnets[0]

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    ssh_authorized_keys: ${jsonencode(var.authorized_keys)}
  EOS

  tags = {
    Name = var.name
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    tags = {
      Name = var.name
    }
  }
}

################################################################################
# Redis
################################################################################

module "redis" {
  source = "./redis"

  name               = var.name
  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.redis.id]
}
