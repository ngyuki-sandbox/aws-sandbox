
output "vpc_service_name" {
  value = aws_vpc_endpoint_service.main.service_name
}

output "vpc_endpoint_type" {
  value = aws_vpc_endpoint_service.main.service_type
}
