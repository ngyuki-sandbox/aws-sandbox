###############################################################################
# variable

variable "tag" {
  default = "throughput"
}

################################################################################
# IAM

resource "aws_iam_role" "lambda" {
  name = "${var.tag}-lambda"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda" {
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"

        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

################################################################################
# SQS

resource "aws_sqs_queue" "queue" {
  name                       = "${var.tag}-queue"
  message_retention_seconds  = 3600
  visibility_timeout_seconds = 15
}

################################################################################
# Lambda

resource "aws_lambda_function" "func" {
  function_name = "${var.tag}-func"
  role          = aws_iam_role.lambda.arn
  handler       = "dist/index.handler"
  runtime       = "nodejs12.x"
  timeout       = 60
  memory_size   = 3008

  filename         = "${path.module}/package.zip"
  source_code_hash = filebase64sha256("${path.module}/package.zip")

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.queue.id
    }
  }
}

################################################################################
# Log

resource "aws_cloudwatch_log_group" "func" {
  name              = "/aws/lambda/${aws_lambda_function.func.function_name}"
  retention_in_days = 1
}
