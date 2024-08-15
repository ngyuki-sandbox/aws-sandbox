
resource "aws_route53_zone" "main" {
  name = "local"
  vpc {
    vpc_id = data.aws_vpc.main.id
  }
}

resource "aws_route53_record" "rds" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "rds"
  type    = "CNAME"
  ttl     = "60"
  records = [
    aws_rds_cluster.main.endpoint,
  ]
}
