
# resource "aws_cloudwatch_event_rule" "stop" {
#   name                = "${var.name}-stop"
#   schedule_expression = "cron(0 13 ? * FRI *)" # FRI 13:00 UTC = FRI 22:00 JST
# }

# resource "aws_cloudwatch_event_target" "stop" {
#   for_each = {
#     ecs = aws_sfn_state_machine.stop_ecs.arn
#     rds = aws_sfn_state_machine.stop_rds.arn
#   }
#   rule     = aws_cloudwatch_event_rule.stop.name
#   role_arn = aws_iam_role.events.arn
#   arn      = each.value
# }

# resource "aws_cloudwatch_event_rule" "start" {
#   name                = "${var.name}-start"
#   schedule_expression = "cron(30 22 ? * SUN *)" # SUN 22:30 UTC = 月曜 07:30 JST
# }

# resource "aws_cloudwatch_event_target" "start" {
#   for_each = {
#     ecs = aws_sfn_state_machine.start_ecs.arn
#     rds = aws_sfn_state_machine.start_rds.arn
#   }
#   rule     = aws_cloudwatch_event_rule.start.name
#   role_arn = aws_iam_role.events.arn
#   arn      = each.value
# }
