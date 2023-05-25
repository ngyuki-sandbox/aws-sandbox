
data "aws_route53_zone" "main" {
  name         = var.rds_zone_name
  private_zone = true
}

resource "aws_route53_record" "db" {
  zone_id    = data.aws_route53_zone.main.zone_id
  name       = var.rds_dns_name
  type       = "CNAME"
  ttl        = 300
  records    = [aws_rds_cluster.main.endpoint]
  depends_on = [aws_lambda_invocation.lambda]
}

resource "aws_route53_record" "db_ro" {
  zone_id    = data.aws_route53_zone.main.zone_id
  name       = var.rds_ro_dns_name
  type       = "CNAME"
  ttl        = 300
  records    = [aws_rds_cluster.main.reader_endpoint]
  depends_on = [aws_lambda_invocation.lambda]
}
