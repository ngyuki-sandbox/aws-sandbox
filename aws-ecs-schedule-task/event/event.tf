
resource "aws_cloudwatch_event_rule" "main" {
  name                = "${var.name}-event"
  schedule_expression = "cron(* * * * ? *)"
}

resource "aws_cloudwatch_event_target" "main" {
  target_id = "${var.name}-event"
  rule      = aws_cloudwatch_event_rule.main.name
  arn       = var.ecs_cluster_arn
  role_arn  = aws_iam_role.main.arn

  ecs_target {
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
        "command" : ["php", "-v"]
      }
    ]
  })
}
