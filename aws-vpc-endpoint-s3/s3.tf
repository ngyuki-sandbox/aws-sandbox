
resource "aws_s3_bucket" "main" {
  bucket_prefix = var.name
  force_destroy = true
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
            "aws:sourceVpc" : [data.aws_vpc.main.id],
            "s3:ExistingObjectTag/public" : "true",
          }
        },
      },
    ],
  })
}

resource "aws_s3_object" "a" {
  bucket  = aws_s3_bucket.main.id
  key     = "a.txt"
  content = "this is a.txt"
  tags = {
    public = "true"
  }
}

resource "aws_s3_object" "b" {
  bucket  = aws_s3_bucket.main.id
  key     = "b.txt"
  content = "this is b.txt"
}
