
provider "aws" {
  region              = var.region
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.defailt_tags
  }
}

provider "aws" {
  alias               = "us-east-1"
  region              = "us-east-1"
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.defailt_tags
  }
}

data "aws_route53_zone" "main" {
  name         = var.zone_name
  private_zone = false
}

module "acm_apigw" {
  source = "./acm"

  zone_id     = data.aws_route53_zone.main.zone_id
  domain_name = var.acm_domain_name
}

module "acm_cloudfront" {
  source    = "./acm"
  providers = { aws = aws.us-east-1 }

  zone_id     = data.aws_route53_zone.main.zone_id
  domain_name = var.acm_domain_name
}


module "apigw" {
  source = "./apigw"

  name            = var.name
  zone_id         = data.aws_route53_zone.main.zone_id
  certificate_arn = module.acm_apigw.certificate_arn
  org_domain_name = var.org_domain_name
  cf_domain_name  = var.cf_domain_name
  stage_name      = "dev"
  allow_ips       = var.allow_ips
}

module "cloudfront" {
  source    = "./cloudfront"
  providers = { aws = aws.us-east-1 }

  name               = "${var.name}-cf"
  zone_id            = data.aws_route53_zone.main.zone_id
  certificate_arn    = module.acm_cloudfront.certificate_arn
  cf_domain_name     = var.cf_domain_name
  origin_domain_name = var.org_domain_name # module.apigw.invoke_domain
  allow_ips          = var.allow_ips
}

output "urls" {
  value = concat(
    module.apigw.urls,
    module.cloudfront.urls,
  )
}
