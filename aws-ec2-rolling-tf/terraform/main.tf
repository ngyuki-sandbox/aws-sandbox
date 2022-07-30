################################################################################
# main
################################################################################

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
  }
}

locals {
  name   = "amir"
  region = data.aws_region.current.name
}

data "aws_region" "current" {}

################################################################################
# vpc
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a", "${local.region}c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_ipv6        = false
  enable_nat_gateway = false
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "lb" {
  name        = "${local.name}-lb"
  description = "${local.name}-lb"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "Name" = "${local.name}-lb"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web"
  description = "${local.name}-web"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "Name" = "${local.name}-web"
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = var.allow_ssh_ingress
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
# ELB
################################################################################

resource "aws_lb" "this" {
  name                             = "${local.name}-lb"
  load_balancer_type               = "application"
  ip_address_type                  = "ipv4"

  security_groups = [aws_security_group.lb.id]
  subnets         = module.vpc.public_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    target_group_arn = null_resource.web.triggers.target_group_arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "dummy" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTP"
  port              = 8080

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group" "web" {
  name     = substr(format("%s-%s", local.name, sha256(local.ami_id)), 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/index.html"
    matcher             = "200-399"
    interval            = 10
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "web" {
  triggers = {
    target_group_arn = aws_lb_target_group.web.arn
  }
  provisioner "local-exec" {
    command = <<-EOF
      set -ex -o pipefail
      if [ "$wait" -ne 0 ]; then
        timeout "$wait" aws elbv2 wait target-in-service --target-group-arn "$target_group_arn"
      fi
    EOF
    environment = {
      wait = var.wait
      target_group_arn = aws_lb_target_group.web.arn
    }
  }
}

################################################################################
# ami
################################################################################

data "aws_ami" "base" {
  count = var.ami == null ? 1 : 0

  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["base-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  ami_id = coalesce(var.ami, one(data.aws_ami.base.*.id))
}

################################################################################
# instance
################################################################################

module "instance" {
  source = "./instance"
  for_each = { for i, v in module.vpc.public_subnets : module.vpc.public_subnets_cidr_blocks[i] => v }

  name                   = "${local.name}-${each.key}"
  ami_id                 = local.ami_id
  wait                   = var.wait
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.web.id]
  target_group_arn       = aws_lb_target_group.web.arn
  authorized_keys        = var.authorized_keys
}
