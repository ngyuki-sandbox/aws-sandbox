
resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-s3-"
  force_destroy = true

  tags = {
    Name                 = "${var.name}-s3"
    (var.backup_tag_key) = "enabled"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 10
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_object" "main" {
  bucket  = aws_s3_bucket.main.id
  key     = "test.txt"
  content = "this is test"
}
