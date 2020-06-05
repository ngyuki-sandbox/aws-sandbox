################################################################################
# route53

data "aws_route53_zone" "cert" {
  name         = local.zone_domain
  private_zone = false
}

resource "aws_route53_record" "server" {
  zone_id = data.aws_route53_zone.cert.zone_id
  name    = local.server_domain
  type    = "A"
  records = [aws_instance.server.public_ip]
  ttl     = "60"
}

resource "aws_route53_record" "cert" {
  zone_id = data.aws_route53_zone.cert.zone_id
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
  ttl     = "60"
}

resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.cert.zone_id
  name    = local.service_domain
  type    = "CNAME"
  records = [aws_lb.public.dns_name]
  ttl     = "60"
}
