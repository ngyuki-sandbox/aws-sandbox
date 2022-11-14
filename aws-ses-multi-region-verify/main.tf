
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "domain" {}

module "global" {
  source = "./global"
  domain = var.domain
}

module "tokyo" {
  source  = "./regional"
  region  = "ap-northeast-1"
  domain  = var.domain
  zone_id = module.global.zone_id
}

module "osaka" {
  source  = "./regional"
  region  = "ap-northeast-3"
  domain  = var.domain
  zone_id = module.global.zone_id
}
