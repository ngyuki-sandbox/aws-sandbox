################################################################################
# Route Table

resource aws_route_table front {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.tag}-front"
  }
}

resource aws_route_table_association subnets {
  count          = length(aws_subnet.subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.front.id
}

resource aws_route igw {
  route_table_id         = aws_route_table.front.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource aws_route tgw {
  count                  = length(var.transit_gateway_routes)
  route_table_id         = aws_route_table.front.id
  destination_cidr_block = var.transit_gateway_routes[count.index]
  transit_gateway_id     = var.transit_gateway_id
}
