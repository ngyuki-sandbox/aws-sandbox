
resource "aws_lambda_function" "lambda" {
  function_name = var.name
  role          = aws_iam_role.lambda.arn
  timeout       = 10
  memory_size   = 128
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.main.repository_url}:latest"
  publish       = true

  image_config {
    command           = ["handlers/index.php"]
    entry_point       = ["/home/app/bin/bootstrap"]
    working_directory = "/home/app/"
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.lambda.name
    log_format = "Text"
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  depends_on = [terraform_data.dummy_image_push]
}

resource "aws_lambda_alias" "lambda" {
  function_name    = aws_lambda_function.lambda.function_name
  function_version = aws_lambda_function.lambda.version
  name             = "latest" # @todo

  lifecycle {
    ignore_changes = [function_version]
  }
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
          "logs:PutLogEvents",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"

        ],
        "Resource" : "*"
      }
    ]
  })
}
