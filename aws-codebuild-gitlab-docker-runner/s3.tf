
resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-"
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "/"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = 30
    }
  }
}
