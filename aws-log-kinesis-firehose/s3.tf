
resource "aws_s3_bucket" "s3" {
  bucket        = var.name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "s3" {
  bucket = aws_s3_bucket.s3.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "s3" {
  bucket                  = aws_s3_bucket.s3.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3" {
  bucket = aws_s3_bucket.s3.id

  rule {
    id     = "purge object"
    status = "Enabled"
    expiration {
      days = 3
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}
