
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "public_security_group_id" {
  value = aws_security_group.public.id
}

output "private_security_group_id" {
  value = aws_security_group.private.id
}
