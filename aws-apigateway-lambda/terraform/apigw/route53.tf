
resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  type    = "A"
  name    = var.org_domain_name

  alias {
    name                   = aws_api_gateway_domain_name.main.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main.regional_zone_id
    evaluate_target_health = true
  }
}
