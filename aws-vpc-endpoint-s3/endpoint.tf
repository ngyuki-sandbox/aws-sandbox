
resource "aws_vpc_endpoint" "main" {
  vpc_id            = data.aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.aws_vpc.main.main_route_table_id]

  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Resource" : "*",
        "Principal" : "*"
      }
    ]
  })
}
