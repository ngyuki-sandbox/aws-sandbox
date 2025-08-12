
resource "aws_s3_bucket" "main" {
  bucket        = var.domain
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerEnforced"
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
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.main.arn}/*",
        "Principal" : {
          "AWS" : "*",
        },
        "Condition" : {
          "StringEquals" : {
            "aws:SourceVpce" : [aws_vpc_endpoint.main.id],
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket  = aws_s3_bucket.main.id
  key     = "index.html"
  content = "index.html"
}

resource "aws_s3_object" "a" {
  bucket  = aws_s3_bucket.main.id
  key     = "a.txt"
  content = "this is a.txt"
}

resource "aws_s3_object" "b" {
  bucket  = aws_s3_bucket.main.id
  key     = "b.txt"
  content = "this is b.txt"
}
