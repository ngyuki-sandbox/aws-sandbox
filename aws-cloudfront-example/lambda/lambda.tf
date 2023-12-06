

data "archive_file" "main" {
  type             = "zip"
  source_file      = "${path.module}/index.mjs"
  output_file_mode = "0644"
  output_path      = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "main" {
  function_name    = var.name
  role             = aws_iam_role.main.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 60
  filename         = data.archive_file.main.output_path
  source_code_hash = data.archive_file.main.output_base64sha256
  environment {
    variables = {
      "KEY_PAIR_ID" = var.key_pair_id
      "PRIVATE_KEY" = var.private_key
      "CF_DOMAIN"   = var.cf_domain_name
    }
  }
}

resource "aws_lambda_function_url" "main" {
  function_name      = aws_lambda_function.main.function_name
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "main" {
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

resource "aws_iam_role_policy" "main" {
  role = aws_iam_role.main.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:FilterLogEvents",
          "logs:PutLogEvents",
        ],
        "Resource" : "*",
      },
    ]
  })
}
