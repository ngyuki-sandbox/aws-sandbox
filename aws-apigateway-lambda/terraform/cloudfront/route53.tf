
resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  type    = "CNAME"
  name    = var.cf_domain_name
  records = [aws_cloudfront_distribution.main.domain_name]
  ttl     = 60
}
