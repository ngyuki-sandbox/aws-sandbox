
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
    image           = "aws/codebuild/standard:8.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true

    environment_variable {
      name  = "GITLAB_URL"
      value = var.gitlab_url
    }

    environment_variable {
      name  = "RUNNER_VERSION"
      value = data.gitlab_metadata.main.version
    }

    environment_variable {
      name  = "RUNNER_TOKEN_DOCKER"
      value = aws_ssm_parameter.runner_token_docker.name
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "RUNNER_TOKEN_SHELL"
      value = aws_ssm_parameter.runner_token_shell.name
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "EXECUTOR"
      value = "docker"
    }

    environment_variable {
      name  = "CACHE_BUCKET"
      value = aws_s3_bucket.main.bucket
    }
  }
}

moved {
  from = aws_ssm_parameter.runner_token
  to   = aws_ssm_parameter.runner_token_docker
}

resource "aws_ssm_parameter" "runner_token_docker" {
  name  = "/${var.name}/runner-token-docker"
  type  = "SecureString"
  value = gitlab_user_runner.docker.token
}

resource "aws_ssm_parameter" "runner_token_shell" {
  name  = "/${var.name}/runner-token-shell"
  type  = "SecureString"
  value = gitlab_user_runner.shell.token
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

resource "aws_iam_role_policy_attachment" "build" {
  role       = aws_iam_role.build.id
  policy_arn = aws_iam_policy.build.arn
}

resource "aws_iam_policy" "build" {
  name = aws_iam_role.build.id

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
        Action = "ssm:GetParameters"
        Effect = "Allow"
        Resource = [
          aws_ssm_parameter.runner_token_docker.arn,
          aws_ssm_parameter.runner_token_shell.arn,
        ]
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
