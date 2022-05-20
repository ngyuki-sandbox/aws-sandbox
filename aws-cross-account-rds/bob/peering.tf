################################################################################
# VPC peering connection
################################################################################

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = local.peer.peering_connection_id
  auto_accept               = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

output "owner_id" {
  value = aws_vpc.vpc.owner_id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}
