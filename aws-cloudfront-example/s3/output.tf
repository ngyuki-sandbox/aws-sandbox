
output "domain" {
  value = aws_s3_bucket.main.bucket_regional_domain_name
}

output "path" {
  value = aws_s3_object.index.key
}
