
provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "x"
  region = "ap-northeast-1"
  assume_role {
    role_arn     = var.assume_role_arn
    session_name = var.assume_role_name
  }
}

variable "assume_role_arn" {
  type = string
}

variable "assume_role_name" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

variable "zone_name" {
  type = string
}

module "aaa" {
  source            = "./aaa"
  name              = "example-aaa"
  authorized_keys   = var.authorized_keys
  zone_name         = var.zone_name
  vpc_service_name  = module.bbb.vpc_service_name
  vpc_endpoint_type = module.bbb.vpc_endpoint_type
}

data "aws_caller_identity" "current" {}

module "bbb" {
  providers       = { aws = aws.x }
  source          = "./bbb"
  name            = "example-bbb"
  authorized_keys = var.authorized_keys
  allowed_principals = [
    data.aws_caller_identity.current.arn
  ]
}

output "instance_ids" {
  value = {
    aaa = module.aaa.instance_id
  }
}
