
output "vpc_id" {
  value = data.aws_vpc.main.id
}

output "vpce_id" {
  value = aws_vpc_endpoint.main.id
}

output "instance_id" {
  value = aws_instance.main.id
}
