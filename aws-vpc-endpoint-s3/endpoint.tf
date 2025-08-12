
data "aws_region" "main" {}

resource "aws_vpc_endpoint" "main" {
  vpc_id             = data.aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.main.name}.s3"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [for s in data.aws_subnet.main : s.id]
  security_group_ids = [aws_security_group.vpc_endpoint.id]
}

resource "aws_security_group" "vpc_endpoint" {
  name   = "${var.name}-vpc-endpoint"
  vpc_id = data.aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
