
resource "aws_vpc_endpoint" "main" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.main.name}.execute-api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [data.aws_security_group.main.id]
  subnet_ids          = values(data.aws_subnet.main)[*].id
  private_dns_enabled = true
}
