################################################################################
# Route53 Resolver
################################################################################

resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "${local.env.tag}-resolver-inbound"
  direction = "INBOUND"


  dynamic "ip_address" {
    for_each = aws_subnet.subnets
    content {
      subnet_id = ip_address.value.id
    }
  }

  security_group_ids = [
    aws_security_group.resolver_inbound.id,
  ]

  tags = {
    Name = "${local.env.tag}-resolver-inbound"
  }
}

output "resolver_inbound_ips" {
  value = [for x in aws_route53_resolver_endpoint.inbound.ip_address : x.ip]
}
