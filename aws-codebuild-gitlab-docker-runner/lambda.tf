
data "archive_file" "main" {
  type        = "zip"
  source_file = "${path.module}/index.mjs"
  output_path = "${path.module}/tmp/lambda.zip"
}

resource "aws_lambda_function" "main" {
  function_name    = var.name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs24.x"
  timeout          = 60
  filename         = data.archive_file.main.output_path
  source_code_hash = data.archive_file.main.output_base64sha256

  environment {
    variables = {
      CODEBUILD_PROJECT = aws_codebuild_project.main.name
      GITLAB_URL        = var.gitlab_url
      RUNNER_TAGS       = jsonencode(var.runner_tags)
      GITLAB_TOKEN_SSM  = aws_ssm_parameter.gitlab_token.name
      SECRET_TOKEN_SSN  = aws_ssm_parameter.secret_token.name
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

resource "aws_ssm_parameter" "gitlab_token" {
  name  = "/${var.name}/gitlab-token"
  type  = "SecureString"
  value = gitlab_project_access_token.main.token
}

resource "aws_ssm_parameter" "secret_token" {
  name  = "/${var.name}/secret-token"
  type  = "SecureString"
  value = random_password.token.result
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
      {
        Action = "ssm:GetParameter"
        Effect = "Allow"
        Resource = [
          aws_ssm_parameter.gitlab_token.arn,
          aws_ssm_parameter.secret_token.arn,
        ]
      },
    ]
  })
}
