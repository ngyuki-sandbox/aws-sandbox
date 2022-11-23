
resource "aws_cloudwatch_log_group" "log" {
  name              = "${var.name}-log"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_subscription_filter" "log" {
  name            = "${var.name}-log"
  role_arn        = aws_iam_role.log.arn
  log_group_name  = aws_cloudwatch_log_group.log.name
  filter_pattern  = "ERROR"
  destination_arn = aws_kinesis_firehose_delivery_stream.firehose.arn
  distribution    = "ByLogStream"
}

data "aws_region" "current" {}

resource "aws_iam_role" "log" {
  name = "${var.name}-log"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "logs.${data.aws_region.current.name}.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy" "log" {
  role = aws_iam_role.log.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        "Resource" : "*",
      },
    ]
  })
}
