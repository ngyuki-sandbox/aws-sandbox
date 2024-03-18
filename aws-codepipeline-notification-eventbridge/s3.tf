
resource "aws_s3_bucket" "artifact" {
  bucket_prefix = "${var.name}-artifact-"
  force_destroy = true
}

resource "aws_s3_bucket" "source" {
  bucket_prefix = "${var.name}-source-"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "source" {
  bucket = aws_s3_bucket.source.id
  key    = "source.zip"
  source = data.archive_file.source.output_path
  etag   = filemd5(data.archive_file.source.output_path)
}

data "archive_file" "source" {
  type        = "zip"
  source_file = "README.md"
  output_path = "source.zip"
}
