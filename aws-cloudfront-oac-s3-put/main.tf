
provider "aws" {}

provider "aws" {
  alias  = "cloudfront"
  region = "us-east-1"
}

###

variable "name" {
  type = string
}

variable "zone_name" {
  type = string
}

variable "cf_domain_name" {
  type = string
}

###

output "cloudfront_url" {
  value = "https://${var.cf_domain_name}"
}

###

data "aws_route53_zone" "main" {
  provider     = aws.cloudfront
  name         = var.zone_name
  private_zone = false
}

module "cloudfront" {
  source    = "./cloudfront"
  providers = { aws = aws.cloudfront }

  name           = var.name
  zone_id        = data.aws_route53_zone.main.zone_id
  cf_domain_name = var.cf_domain_name
  s3_domain_name = module.s3.domain
}

module "s3" {
  source = "./s3"

  name           = "${var.name}-private"
  cloudfront_arn = module.cloudfront.arn
}
