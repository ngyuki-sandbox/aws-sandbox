
resource "aws_scheduler_schedule" "main" {
  name                = "${var.name}-scheduler"
  schedule_expression = "rate(1 minute)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.ecs_cluster_arn
    role_arn = aws_iam_role.main.arn

    ecs_parameters {
      launch_type         = "FARGATE"
      platform_version    = "LATEST"
      task_definition_arn = var.task_definition_arn
      task_count          = 1

      network_configuration {
        subnets          = var.subnet_ids
        security_groups  = var.security_group_ids
        assign_public_ip = var.assign_public_ip
      }
    }

    input = jsonencode({
      "containerOverrides" : [
        {
          "name" : "app",
          "command" : ["php", "-r", "var_dump('ok');"]
        }
      ]
    })
  }
}
