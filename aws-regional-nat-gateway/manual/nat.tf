
resource "aws_eip" "main" {
  domain = "vpc"
  tags = {
    Name = "${var.name}-ngw"
  }
}

resource "aws_nat_gateway" "main" {
  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"

  availability_zone_address {
    availability_zone = data.aws_availability_zones.main.names[0]
    allocation_ids    = [aws_eip.main.id]
  }

  tags = {
    Name = "${var.name}-ngw"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "main" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}
