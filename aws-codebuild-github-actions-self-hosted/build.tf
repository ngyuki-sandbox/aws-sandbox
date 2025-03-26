
resource "aws_codebuild_project" "main" {
  name         = var.name
  service_role = aws_iam_role.build.arn

  source {
    type = "GITHUB"
    #location        = var.github_repo
    location        = "CODEBUILD_DEFAULT_WEBHOOK_SOURCE_LOCATION"
    buildspec       = file("buildspec.yaml")
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }

    auth {
      resource = aws_codeconnections_connection.main.arn
      type     = "CODECONNECTIONS"
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
      group_name = aws_cloudwatch_log_group.build.name
    }
  }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true

    environment_variable {
      name  = "TZ"
      value = "Asia/Tokyo"
    }
  }
}

import {
  id = "sandbox"
  to = aws_codebuild_webhook.main
}

resource "aws_codebuild_webhook" "main" {
  project_name = aws_codebuild_project.main.name
  build_type   = "BUILD"

  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "WORKFLOW_JOB_QUEUED"
      type                    = "EVENT"
    }
  }

  scope_configuration {
    name  = var.github_org
    scope = "GITHUB_ORGANIZATION"
  }
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/${var.name}"
  retention_in_days = 1
}
