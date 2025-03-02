
data "aws_caller_identity" "self" {}

data "archive_file" "main" {
  type        = "zip"
  source_file = "${path.module}/index.mjs"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "main" {
  function_name    = var.name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  timeout          = 60
  filename         = data.archive_file.main.output_path
  source_code_hash = data.archive_file.main.output_base64sha256

  environment {
    variables = {
      CODEBUILD_PROJECT = aws_codebuild_project.main.name
      GITLAB_URL        = var.gitlab_url
      GITLAB_TOKEN      = gitlab_project_access_token.main.token
      SECRET_TOKEN      = random_password.token.result
      RUNNER_TAGS       = jsonencode(var.runner_tags)
    }
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.lambda.name
    log_format = "Text"
  }
}

resource "aws_lambda_function_url" "main" {
  function_name      = aws_lambda_function.main.function_name
  authorization_type = "NONE"
}

resource "random_password" "token" {
  length = 32
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
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
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
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codebuild:StartBuild",
        ],
        "Resource" : aws_codebuild_project.main.arn
      },
    ]
  })
}
