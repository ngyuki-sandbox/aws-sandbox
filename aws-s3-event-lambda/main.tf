
variable "name" {
  type    = string
  default = "s3-event-lambda"
}

data "aws_caller_identity" "self" {}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

data "archive_file" "main" {
  type        = "zip"
  source_file = "index.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "main" {
  function_name = var.name
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60

  filename         = data.archive_file.main.output_path
  source_code_hash = data.archive_file.main.output_base64sha256
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 1
}

resource "aws_s3_bucket" "main" {
  bucket        = var.name
  force_destroy = true
}

resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.main.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.main]
}

resource "aws_lambda_permission" "main" {
  statement_id   = "s3invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.main.arn
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.main.arn
  source_account = data.aws_caller_identity.self.account_id
}
