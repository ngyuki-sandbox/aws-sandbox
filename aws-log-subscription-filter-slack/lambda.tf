
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/index.mjs"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = var.name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 60
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      SLACK_INCOMING_WEBHOOK_URL = var.slack_incoming_webhook_url
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        "Resource" : "*",
      },
    ]
  })
}


resource "aws_lambda_permission" "lambda" {
  function_name  = aws_lambda_function.lambda.function_name
  action         = "lambda:InvokeFunction"
  principal      = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = "${aws_cloudwatch_log_group.log.arn}:*"
}
