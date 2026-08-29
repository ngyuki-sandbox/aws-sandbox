
output "microvm_image_arn" {
  value       = awscc_lambda_microvm_image.main.image_arn
}

output "iam_role_arn" {
  value       = aws_iam_role.main.arn
}
