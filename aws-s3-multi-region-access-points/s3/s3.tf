
resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "main" {
  role   = var.replication_role_arn
  bucket = aws_s3_bucket.main.id
  rule {
    status = "Enabled"
    destination {
      bucket = var.replication_destination_arn
    }
  }
  depends_on = [aws_s3_bucket_versioning.main]
}
