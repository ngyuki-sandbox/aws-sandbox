
resource "aws_codebuild_project" "main" {
  name           = var.name
  service_role   = aws_iam_role.main.arn
  build_timeout  = 15
  queued_timeout = 15

  source {
    type     = "GITLAB_SELF_MANAGED"
    location = var.gitlab_repo

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codeconnections_connection.main.arn
    }
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
      group_name = aws_cloudwatch_log_group.main.name
    }
  }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
  }
}

resource "aws_codebuild_webhook" "main" {
  project_name = aws_codebuild_project.main.name

  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "WORKFLOW_JOB_QUEUED"
      type                    = "EVENT"
    }
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/codebuild/${var.name}"
  retention_in_days = 1
}
