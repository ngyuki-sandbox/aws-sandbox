################################################################################
# Route53
################################################################################

resource "aws_route53_zone" "private" {
  name = local.env.private_domain

  vpc {
    vpc_id = aws_vpc.vpc.id
  }

  lifecycle {
    ignore_changes = [
      vpc,
    ]
  }
}

resource "aws_route53_vpc_association_authorization" "peer" {
  zone_id = aws_route53_zone.private.zone_id
  vpc_id  = local.peer.vpc_id
}

resource "aws_route53_record" "rds" {
  zone_id = aws_route53_zone.private.id
  name    = "rds.${local.env.private_domain}"
  type    = "CNAME"
  ttl     = 60

  records = [aws_rds_cluster.rds.endpoint]
}

output "zone_id" {
  value = aws_route53_vpc_association_authorization.peer.zone_id
}
