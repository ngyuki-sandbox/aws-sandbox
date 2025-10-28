
resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-"
  force_destroy = true

  timeouts {
    create = "1m"
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    Version : "2008-10-17",
    Statement : [
      {
        Action : "s3:GetObject",
        Effect : "Allow",
        Resource : "${aws_s3_bucket.main.arn}/*",
        Principal : {
          Service : "cloudfront.amazonaws.com",
        },
        Condition : {
          StringEquals : {
            "aws:SourceArn" : var.cloudfront_arn,
          },
        },
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.main.bucket
  key          = "private/image.png"
  source       = "${path.module}/files/image.png"
  content_type = "image/png"
}
