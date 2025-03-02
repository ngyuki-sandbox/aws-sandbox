
resource "aws_s3_bucket" "main" {
  bucket = var.name
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

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*",
        ],
        "Principal" : "*"
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        },
      },
    ]
  })
}
