################################################################################
# VPC peering connection
################################################################################

resource "aws_vpc_peering_connection" "peer" {
  peer_owner_id = local.peer.owner_id
  peer_vpc_id   = local.peer.vpc_id
  vpc_id        = aws_vpc.vpc.id
}

resource "aws_vpc_peering_connection_options" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

output "peering_connection_id" {
  value = aws_vpc_peering_connection.peer.id
}

output "cidr_block" {
  value = aws_vpc.vpc.cidr_block
}
