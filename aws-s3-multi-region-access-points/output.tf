
output "main_arn" {
  value = aws_s3control_multi_region_access_point.main.arn
}

output "main_domain" {
  value = aws_s3control_multi_region_access_point.main.domain_name
}

output "bucket_tky" {
  value = module.tky.bucket
}

output "bucket_osk" {
  value = module.osk.bucket
}
