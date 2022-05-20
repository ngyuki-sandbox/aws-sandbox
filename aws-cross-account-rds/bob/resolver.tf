################################################################################
# Route53 Resolver
################################################################################

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "foo"
  direction = "OUTBOUND"


  dynamic "ip_address" {
    for_each = aws_subnet.subnets
    content {
      subnet_id = ip_address.value.id
    }
  }

  security_group_ids = [
    aws_security_group.resolver_outbound.id,
  ]

  tags = {
    Name = "${local.env.tag}-resolver-outbound"
  }
}

resource "aws_route53_resolver_rule" "fwd" {
  domain_name          = local.env.forward_domain
  name                 = "${local.env.tag}-resolver-outbound-fwd"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = aws_instance.sv.private_ip
  }

  tags = {
    Name = "${local.env.tag}-resolver-outbound-fwd"
  }
}

resource "aws_route53_resolver_rule_association" "fwd" {
  resolver_rule_id = aws_route53_resolver_rule.fwd.id
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route53_resolver_rule" "peer" {
  domain_name          = local.env.peer_domain
  name                 = "${local.env.tag}-resolver-outbound-peer"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  dynamic "target_ip" {
    for_each = local.peer.resolver_inbound_ips
    content {
      ip = target_ip.value
    }
  }

  tags = {
    Name = "${local.env.tag}-resolver-outbound-peer"
  }
}

resource "aws_route53_resolver_rule_association" "peer" {
  resolver_rule_id = aws_route53_resolver_rule.peer.id
  vpc_id           = aws_vpc.vpc.id
}
