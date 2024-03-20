
resource "aws_s3_bucket" "artifact" {
  bucket_prefix = "${var.name}-artifact-"
  force_destroy = true
}
