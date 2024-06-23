
output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda.function_name
}
