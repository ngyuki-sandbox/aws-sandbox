
resource "aws_cloudwatch_log_group" "main" {
  name              = "${var.name}/ecs/app"
  retention_in_days = 1
}
