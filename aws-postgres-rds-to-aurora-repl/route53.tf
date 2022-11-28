
resource "aws_route53_zone" "private" {
  name = "local.test."
  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }
}

resource "aws_route53_record" "rds" {
  zone_id = aws_route53_zone.private.id
  name    = "rds.local.test."
  type    = "CNAME"
  ttl     = 60

  records = [aws_db_instance.rds.address]
}

resource "aws_route53_record" "aurora" {
  zone_id = aws_route53_zone.private.id
  name    = "aurora.local.test."
  type    = "CNAME"
  ttl     = 60

  records = [aws_rds_cluster.aurora.endpoint]
}
