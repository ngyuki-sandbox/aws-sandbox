################################################################################
# Requestor

resource "aws_ec2_transit_gateway" "requestor" {
  provider                        = aws.requestor
  description                     = "${var.tag}-tgw"
  amazon_side_asn                 = 64513
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = {
    Name = "${var.tag}-tgw"
  }
}

output "requestor_transit_gateway_id" {
  value = aws_ec2_transit_gateway.requestor.id
}

resource "aws_ec2_transit_gateway_peering_attachment" "requestor" {
  provider                = aws.requestor
  transit_gateway_id      = aws_ec2_transit_gateway.requestor.id
  peer_region             = var.accepter_region
  peer_transit_gateway_id = aws_ec2_transit_gateway.accepter.id

  tags = {
    Name = "${var.tag}-peering"
  }
}

resource "aws_ec2_transit_gateway_route" "requestor" {
  provider                       = aws.requestor
  count                          = length(var.accepter_cidrs)
  transit_gateway_route_table_id = aws_ec2_transit_gateway.requestor.association_default_route_table_id
  destination_cidr_block         = var.accepter_cidrs[count.index]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.accepter.id
}

################################################################################
# Accepter

resource "aws_ec2_transit_gateway" "accepter" {
  provider                        = aws.accepter
  description                     = "${var.tag}-tgw"
  amazon_side_asn                 = 64514
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"

  tags = {
    Name = "${var.tag}-tgw"
  }
}

output "accepter_transit_gateway_id" {
  value = aws_ec2_transit_gateway.accepter.id
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accepter" {
  provider                      = aws.accepter
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.requestor.id

  tags = {
    Name = "${var.tag}-peering"
  }
}

resource "aws_ec2_transit_gateway_route" "accepter" {
  provider                       = aws.accepter
  count                          = length(var.requestor_cidrs)
  transit_gateway_route_table_id = aws_ec2_transit_gateway.accepter.association_default_route_table_id
  destination_cidr_block         = var.requestor_cidrs[count.index]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.accepter.id
}
