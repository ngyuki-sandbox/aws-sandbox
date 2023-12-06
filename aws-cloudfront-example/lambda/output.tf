
output "domain" {
  value = split("/", aws_lambda_function_url.main.function_url)[2]
}

output "url" {
  value = aws_lambda_function_url.main.function_url
}
