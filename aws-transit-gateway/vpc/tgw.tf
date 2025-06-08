################################################################################
# Transit Gateway

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
  count              = var.transit_gateway_has ? 1 : 0
  subnet_ids         = aws_subnet.subnets.*.id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.main.id

  tags = {
    Name = "${var.tag}-vpc-attachment"
  }
}
