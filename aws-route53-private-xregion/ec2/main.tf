
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "name" {
  type = string
}

################################################################################
# EC2

data "aws_ssm_parameter" "ami_amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "main" {
  ami = data.aws_ssm_parameter.ami_amazon_linux.value

  instance_type               = "t3.nano"
  subnet_id                   = values(data.aws_subnet.subnets)[0].id
  vpc_security_group_ids      = [data.aws_security_group.default.id]
  iam_instance_profile        = aws_iam_instance_profile.main.name
  ebs_optimized               = false
  monitoring                  = false
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
}

################################################################################
# IAM Role

resource "aws_iam_role" "main" {
  name = "${var.name}-ec2"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "main" {
  role_name = aws_iam_role.main.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_instance_profile" "main" {
  name = aws_iam_role.main.name
  role = aws_iam_role.main.name
}

################################################################################
# VPC

data "aws_vpc" "vpc" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "subnets" {
  for_each = { for x in data.aws_availability_zones.available.names : x => x }

  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = each.value
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.vpc.id
  name   = "default"
}

################################################################################
# route53

resource "aws_route53_zone" "main" {
  name = "test.local"
  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "region"
  type    = "TXT"
  ttl     = 60
  records = [var.name]
}

################################################################################
# output

output "ec2" {
  value = {
    instance_id = aws_instance.main.id
    public_ip   = aws_instance.main.public_ip
  }
}
