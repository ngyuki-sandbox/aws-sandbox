
output "invoke_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "domain_name_arn" {
  value = aws_api_gateway_domain_name.main.arn
}
