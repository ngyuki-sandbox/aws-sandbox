
output "app_url" {
  value = "http://${aws_lb.main.dns_name}/"
}

output "pipeline_name" {
  value = aws_codepipeline.main.name
}

output "source_uri" {
  value = "s3://${aws_s3_bucket.main.bucket}/${local.source_key}"
}
