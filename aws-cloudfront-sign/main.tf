
data "aws_route53_zone" "main" {
  provider     = aws.cloudfront
  name         = "${var.zone_name}."
  private_zone = false
}

module "cloudfront" {
  source    = "./cloudfront"
  providers = { aws = aws.cloudfront }

  name            = var.name
  zone_id         = data.aws_route53_zone.main.zone_id
  acm_domain_name = var.acm_domain_name
  cf_domain_name  = var.cf_domain_name
  alb_dns_name    = module.alb.dns_name
  s3_domain_name  = module.s3.domain
}

module "alb" {
  source = "./alb"

  name            = var.name
  zone_id         = data.aws_route53_zone.main.zone_id
  acm_domain_name = var.acm_domain_name
  alb_domain_name = var.alb_domain_name
  authorized_keys = var.authorized_keys
  allow_ssh_ips   = var.allow_ssh_ips
  key_pair_ids    = module.cloudfront.key_pair_ids
  private_keys    = module.cloudfront.private_keys
}

module "s3" {
  source = "./s3"

  name           = "${var.name}-private"
  cloudfront_arn = module.cloudfront.arn
}
