
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/ecs/${var.name}"
  retention_in_days = 7
}
