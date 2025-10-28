
output "arn" {
  value = aws_cloudfront_distribution.cloudfront.arn
}

output "key_pair_ids" {
  value = {
    rsa   = aws_cloudfront_public_key.rsa.id
    ecdsa = aws_cloudfront_public_key.ecdsa.id
  }
}

output "private_keys" {
  value = {
    rsa   = tls_private_key.rsa.private_key_pem
    ecdsa = tls_private_key.ecdsa.private_key_pem
  }
}
