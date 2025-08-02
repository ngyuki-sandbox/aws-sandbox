
resource "aws_cloudwatch_log_group" "main" {
  name              = "${var.name}-ecs"
  retention_in_days = 1
}
