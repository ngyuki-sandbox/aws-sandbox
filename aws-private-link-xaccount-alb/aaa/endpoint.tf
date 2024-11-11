
data "aws_caller_identity" "current" {}

resource "aws_vpc_endpoint" "main" {
  service_name       = var.vpc_service_name
  vpc_endpoint_type  = var.vpc_endpoint_type
  vpc_id             = data.aws_vpc.main.id
  subnet_ids         = values(data.aws_subnet.main)[*].id
  security_group_ids = [aws_security_group.main.id]
}
