
data "aws_route53_zone" "main" {
  name         = var.zone_name
  private_zone = true
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "aaa"
  type    = "A"
  alias {
    name                   = aws_vpc_endpoint.main.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.main.dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }
}
