
output "instance_id" {
  value = aws_instance.main.id
}

output "s3_bucket" {
  value = aws_s3_bucket.main.id
}

output "s3_bucket_regional_domain_name" {
  value = aws_s3_bucket.main.bucket_regional_domain_name
}
