
output "arn" {
  value = aws_cloudfront_distribution.cloudfront.arn
}

output "key_pair_id" {
  value = aws_cloudfront_public_key.main.id
}

output "private_key" {
  value = tls_private_key.main.private_key_pem
}
