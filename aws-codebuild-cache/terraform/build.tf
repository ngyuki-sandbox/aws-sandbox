
locals {
  builds = {
    "build"        = "buildspec-build.yml",
    "buildx"       = "buildspec-buildx.yml",
    "buildx-use"   = "buildspec-buildx-use.yml",
    "buildx-cache" = "buildspec-buildx-cache.yml",
  }
}


resource "aws_codebuild_project" "main" {
  for_each = local.builds

  name         = "${var.name}-${each.key}"
  service_role = aws_iam_role.build.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value
  }

  artifacts {
    type = "CODEPIPELINE"
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
    compute_type    = "BUILD_GENERAL1_LARGE"
    privileged_mode = true

    environment_variable {
      name  = "TZ"
      value = "Asia/Tokyo"
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = aws_ecr_repository.main.repository_url
    }
  }
}
