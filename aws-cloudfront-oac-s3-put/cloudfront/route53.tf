
resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = var.cf_domain_name
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.main.domain_name]
}
