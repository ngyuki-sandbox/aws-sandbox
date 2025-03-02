
resource "aws_codebuild_project" "main" {
  name           = var.name
  service_role   = aws_iam_role.build.arn
  build_timeout  = 15
  queued_timeout = 15

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
    }
  }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true

    environment_variable {
      name  = "GITLAB_URL"
      value = var.gitlab_url
    }

    environment_variable {
      name  = "RUNNER_TOKEN"
      value = gitlab_user_runner.main.token
    }

    environment_variable {
      name  = "CACHE_BUCKET"
      value = aws_s3_bucket.main.bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/${var.name}"
  retention_in_days = 1
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
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect : "Allow"
        Resource : "${aws_cloudwatch_log_group.build.arn}:*"
      },
      {
        Action : "s3:*",
        Effect : "Allow",
        Resource : [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*",
        ],
      },
    ]
  })
}
