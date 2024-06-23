
resource "aws_codebuild_project" "main" {
  name         = var.name
  service_role = aws_iam_role.build.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yaml")
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type         = "LINUX_LAMBDA_CONTAINER"
    image        = "aws/codebuild/amazonlinux-x86_64-lambda-standard:nodejs20"
    compute_type = "BUILD_LAMBDA_1GB"

    environment_variable {
      name  = "TZ"
      value = "Asia/Tokyo"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
    }
  }
}

resource "aws_iam_role" "build" {
  name = "${var.name}-build"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Action : "sts:AssumeRole"
      Effect : "Allow"
      Principal : {
        Service : "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "build" {
  name = aws_iam_role.build.id
  role = aws_iam_role.build.id

  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect : "Allow"
        Resource : "*"
      },
      {
        Action : [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect : "Allow"
        Resource : "${aws_s3_bucket.pipeline.arn}/*"
      },
      {
        Action : [
          "lambda:GetAlias",
          "lambda:UpdateAlias",
          "lambda:UpdateFunctionCode",
        ]
        Effect : "Allow"
        Resource : aws_lambda_function.lambda.arn
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/build/${var.name}"
  retention_in_days = 1
}
