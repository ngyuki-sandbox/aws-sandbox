
resource "aws_s3_bucket" "source" {
  bucket_prefix = "${var.name}-source-"
  force_destroy = true
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/../deploy"
  output_path = "source.zip"
}

resource "aws_s3_object" "source" {
  bucket = aws_s3_bucket.source.id
  key    = "source.zip"
  source = data.archive_file.source.output_path
  etag   = filemd5(data.archive_file.source.output_path)
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}
