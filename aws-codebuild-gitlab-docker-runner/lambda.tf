
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
      CODEBUILD_PROJECT  = aws_codebuild_project.main.name
      GITLAB_URL         = var.gitlab_url
      RUNNER_DOCKER_TAGS = jsonencode(var.runner_docker_tags)
      RUNNER_SHELL_TAGS  = jsonencode(var.runner_shell_tags)
      GITLAB_TOKEN_SSM   = aws_ssm_parameter.gitlab_token.name
      SIGNING_TOKEN_SSM  = aws_ssm_parameter.signing_token.name
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

resource "aws_lambda_permission" "FunctionURLAllowPublicAccess" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.main.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "FunctionURLInvokeAllowPublicAccess" {
  statement_id             = "FunctionURLInvokeAllowPublicAccess"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.main.function_name
  principal                = "*"
  invoked_via_function_url = true
}

resource "random_bytes" "signing_token" {
  length = 32
}

resource "aws_ssm_parameter" "gitlab_token" {
  name  = "/${var.name}/gitlab-token"
  type  = "SecureString"
  value = gitlab_project_access_token.main.token
}

resource "aws_ssm_parameter" "signing_token" {
  name  = "/${var.name}/signing-token"
  type  = "SecureString"
  value = "whsec_${random_bytes.signing_token.base64}"
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

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_policy" "lambda" {
  name = aws_iam_role.lambda.name
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
          aws_ssm_parameter.signing_token.arn,
        ]
      },
    ]
  })
}
