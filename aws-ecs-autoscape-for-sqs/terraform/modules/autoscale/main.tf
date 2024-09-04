
resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 0
  max_capacity       = 1
}

resource "aws_appautoscaling_policy" "up" {
  name        = "${var.name}-up"
  policy_type = "StepScaling"

  service_namespace  = aws_appautoscaling_target.main.service_namespace
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

  step_scaling_policy_configuration {
    cooldown                = 10
    metric_aggregation_type = "Maximum"
    adjustment_type         = "ExactCapacity"

    step_adjustment {
      metric_interval_upper_bound = 1
      scaling_adjustment          = 0
    }

    step_adjustment {
      metric_interval_lower_bound = 1
      scaling_adjustment          = 1
    }
  }
}

# resource "aws_appautoscaling_policy" "down" {
#   name        = "${var.name}-down"
#   policy_type = "StepScaling"

#   service_namespace  = aws_appautoscaling_target.main.service_namespace
#   resource_id        = aws_appautoscaling_target.main.resource_id
#   scalable_dimension = aws_appautoscaling_target.main.scalable_dimension

#   step_scaling_policy_configuration {
#     cooldown                = 10
#     metric_aggregation_type = "Maximum"
#     adjustment_type         = "ExactCapacity"

#     step_adjustment {
#       metric_interval_upper_bound = 0
#       scaling_adjustment          = 0
#     }
#   }
# }

resource "aws_cloudwatch_metric_alarm" "up" {
  alarm_name          = "${var.name}-up"
  alarm_description   = "${var.name}-up"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  treat_missing_data  = "missing"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  dimensions = {
    QueueName = var.sqs_queue_name
  }
  alarm_actions = [aws_appautoscaling_policy.up.arn]
  ok_actions    = [aws_appautoscaling_policy.up.arn]
}

# resource "aws_cloudwatch_metric_alarm" "down" {
#   alarm_name          = "${var.name}-down"
#   alarm_description   = "${var.name}-down"
#   namespace           = "AWS/SQS"
#   metric_name         = "ApproximateAgeOfOldestMessage"
#   statistic           = "Maximum"
#   treat_missing_data  = "missing"
#   period              = 60
#   evaluation_periods  = 1
#   comparison_operator = "LessThanOrEqualToThreshold"
#   threshold           = 0
#   dimensions = {
#     QueueName = var.sqs_queue_name
#   }
#   alarm_actions = [aws_appautoscaling_policy.down.arn]
# }
