
resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = "${var.cf_domain_name}."
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.cloudfront.domain_name]
}

resource "aws_route53_record" "domain_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}
