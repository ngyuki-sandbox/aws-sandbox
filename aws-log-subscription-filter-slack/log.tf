
resource "aws_cloudwatch_log_group" "log" {
  name              = "${var.name}-log"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_subscription_filter" "log" {
  name            = "${var.name}-log"
  log_group_name  = aws_cloudwatch_log_group.log.name
  filter_pattern  = "{ $.level = \"ERROR\" }"
  destination_arn = aws_lambda_function.lambda.arn
}
