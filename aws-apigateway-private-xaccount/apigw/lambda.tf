
resource "aws_lambda_function" "main" {
  function_name    = var.name
  role             = aws_iam_role.lambda.arn
  handler          = "lambda.handler"
  runtime          = "nodejs22.x"
  memory_size      = 128
  timeout          = 60
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  timeouts {
    delete = "1m"
  }
}

data "archive_file" "lambda" {
  type             = "zip"
  source_file      = "${path.module}/lambda.mjs"
  output_path      = "${path.module}/lambda.zip"
  output_file_mode = "0644"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
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
          "Service" : [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com",
          ]
        },
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "lambda" {
  role_name   = aws_iam_role.lambda.name
  policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}
