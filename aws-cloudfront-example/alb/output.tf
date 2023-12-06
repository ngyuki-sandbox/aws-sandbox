
output "dns_name" {
  value = aws_lb.main.dns_name
}

output "instance_id" {
  value = aws_instance.main.id
}
