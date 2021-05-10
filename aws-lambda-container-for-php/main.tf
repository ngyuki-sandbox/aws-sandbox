###############################################################################
# variable

variable "tag" {
  default = "lambda-container-for-php"
}

variable "docker_tag" {
  default = "latest"
}

################################################################################
# AWS

provider "aws" {
  region = "ap-northeast-1"
}

################################################################################
# IAM

resource "aws_iam_role" "lambda" {
  name = "${var.tag}-lambda"
  path = "/service-role/"

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

resource "aws_iam_policy" "lambda" {
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

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

###############################################################################
# ECR

resource "aws_ecr_repository" "php" {
  name                 = "${var.tag}-php"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "${var.tag}-php"
  }
}

output "aws_ecr_repository_url" {
  value = aws_ecr_repository.php.repository_url
}

################################################################################
# Lambda

resource "aws_lambda_function" "func" {
  function_name = "${var.tag}-func"
  role          = aws_iam_role.lambda.arn
  timeout       = 10
  memory_size   = 128
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.php.repository_url}:${var.docker_tag}"
  image_config {
    command           = ["handlers/index.php"]
    entry_point       = ["/home/app/bin/bootstrap"]
    working_directory = "/home/app/"
  }
}

################################################################################
# Log

resource "aws_cloudwatch_log_group" "func" {
  name              = "/aws/lambda/${aws_lambda_function.func.function_name}"
  retention_in_days = 1
}
