
data "aws_route53_zone" "main" {
  provider     = aws.cloudfront
  name         = "${var.zone_name}."
  private_zone = false
}

module "cloudfront" {
  source = "./cloudfront"
  providers = {
    aws = aws.cloudfront
  }

  name               = var.name
  zone_id            = data.aws_route53_zone.main.zone_id
  acm_domain_name    = var.acm_domain_name
  cf_domain_name     = var.cf_domain_name
  allow_cf_ips       = var.allow_cf_ips
  alb_dns_name       = module.alb.dns_name
  s3_domain_name     = module.s3.domain
  lambda_domain_name = module.lambda.domain
}

module "alb" {
  source = "./alb"

  name            = var.name
  zone_id         = data.aws_route53_zone.main.zone_id
  acm_domain_name = var.acm_domain_name
  alb_domain_name = var.alb_domain_name
  authorized_keys = var.authorized_keys
  allow_ssh_ips   = var.allow_ssh_ips
}

module "s3" {
  source = "./s3"

  name           = "${var.name}-private"
  cloudfront_arn = module.cloudfront.arn
}

module "lambda" {
  source         = "./lambda"
  name           = var.name
  key_pair_id    = module.cloudfront.key_pair_id
  private_key    = module.cloudfront.private_key
  cf_domain_name = var.cf_domain_name
}

resource "local_sensitive_file" "private_key" {
  content  = module.cloudfront.private_key
  filename = "private_key.pem"
}
