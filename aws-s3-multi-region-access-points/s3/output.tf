
output "bucket" {
  value      = aws_s3_bucket.main.id
  depends_on = [aws_s3_bucket_versioning.main]
}

output "bucket_arn" {
  value      = aws_s3_bucket.main.arn
  depends_on = [aws_s3_bucket_versioning.main]
}
