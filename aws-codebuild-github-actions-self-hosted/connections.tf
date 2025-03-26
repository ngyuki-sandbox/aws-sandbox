
resource "aws_codeconnections_connection" "main" {
  name          = var.name
  provider_type = "GitHub"
}
