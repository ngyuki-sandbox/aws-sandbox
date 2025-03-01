
resource "aws_codebuild_project" "main" {
  name           = var.name
  service_role   = aws_iam_role.main.arn
  build_timeout  = 15
  queued_timeout = 15

  source {
    type     = "GITLAB_SELF_MANAGED"
    location = var.gitlab_repo
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

resource "terraform_data" "main" {
  input = {
    project_name = aws_codebuild_project.main.name
    source = jsonencode({
      "type" : "GITLAB_SELF_MANAGED",
      "location" : var.gitlab_repo,
      "auth" : {
        "type" : "CODECONNECTIONS",
        "resource" : aws_codeconnections_connection.main.arn
      },
    })
  }

  provisioner "local-exec" {
    command     = <<EOT
      aws codebuild update-project --name "$${project_name}" --source "$${source}"
    EOT
    environment = self.input
  }

  depends_on = [aws_codebuild_project.main]
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

  depends_on = [terraform_data.main]
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/codebuild/${var.name}"
  retention_in_days = 1
}
