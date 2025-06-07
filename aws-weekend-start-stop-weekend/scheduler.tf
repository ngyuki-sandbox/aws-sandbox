
locals {
  start_schedule_expression = "cron(30 07 ? * MON-FRI *)"
  stop_schedule_expression  = "cron(30 21 ? * MON-FRI *)"
}

resource "aws_scheduler_schedule_group" "main" {
  name = var.name
}

resource "aws_scheduler_schedule" "start_ecs" {
  for_each = toset(var.ecs_services)

  name                         = "${var.name}-start-ecs-${each.value}"
  group_name                   = aws_scheduler_schedule_group.main.name
  schedule_expression          = local.start_schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"
  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      Cluster      = var.ecs_cluster_name
      Service      = each.value
      DesiredCount = 1
    })
    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_scheduler_schedule" "stop_ecs" {
  for_each = toset(var.ecs_services)

  name                         = "${var.name}-stop-ecs-${each.value}"
  group_name                   = aws_scheduler_schedule_group.main.name
  schedule_expression          = local.stop_schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"
  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      Cluster      = var.ecs_cluster_name
      Service      = each.value
      DesiredCount = 0
    })
    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_scheduler_schedule" "start_rds" {
  for_each = toset([var.aurora_cluster_id])

  name                         = "${var.name}-start-rds-${each.value}"
  group_name                   = aws_scheduler_schedule_group.main.name
  schedule_expression          = local.start_schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"
  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBCluster"
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      DbClusterIdentifier = var.aurora_cluster_id
    })
    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_scheduler_schedule" "stop_rds" {
  for_each = toset([var.aurora_cluster_id])

  name                         = "${var.name}-stop-rds-${each.value}"
  group_name                   = aws_scheduler_schedule_group.main.name
  schedule_expression          = local.stop_schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"
  flexible_time_window { mode = "OFF" }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBCluster"
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      DbClusterIdentifier = var.aurora_cluster_id
    })
    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}
