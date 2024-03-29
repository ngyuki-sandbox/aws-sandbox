
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

output "codepipeline_name" {
  value = aws_codepipeline.main.name
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.default_tags
  }
}

resource "aws_codestarconnections_connection" "main" {
  name          = var.name
  provider_type = "GitHub"
}

resource "aws_codepipeline" "main" {
  name          = var.name
  role_arn      = aws_iam_role.pipeline.arn
  pipeline_type = "V2"

  variable {
    name          = "PR_NUMBER"
    default_value = ""
  }

  variable {
    name          = "PR_ACTION"
    default_value = ""
  }

  artifact_store {
    location = aws_s3_bucket.main.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      output_artifacts = ["source"]

      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.main.arn
        DetectChanges        = "true"
        FullRepositoryId     = var.github_repo
        OutputArtifactFormat = "CODE_ZIP"
        BranchName           = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      input_artifacts = ["source"]

      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main.name
        EnvironmentVariables = jsonencode([
          {
            name  = "PR_NUMBER"
            value = "#{variables.PR_NUMBER}"
          },
          {
            name  = "PR_ACTION"
            value = "#{variables.PR_ACTION}"
          },
        ])
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      input_artifacts = ["source"]

      category = "Deploy"
      owner    = "AWS"
      provider = "S3"
      version  = "1"

      configuration = {
        BucketName = aws_s3_bucket.main.bucket
        ObjectKey  = "deploy"
        Extract    = "true"
      }
    }
  }
}

resource "aws_codebuild_project" "main" {
  name         = var.name
  service_role = aws_iam_role.build.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        build:
          commands:
            - printf  "PR_NUMBER=%s PR_ACTION=%s" "$PR_NUMBER" "$PR_ACTION"
    EOT
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
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
  }
}

resource "aws_iam_role" "pipeline" {
  name = "${var.name}-pipeline"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : {
      Action : "sts:AssumeRole",
      Effect : "Allow",
      Principal : {
        Service : "codepipeline.amazonaws.com",
      }
    }
  })
}

resource "aws_iam_role_policy" "pipeline" {
  name = aws_iam_role.pipeline.id
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "codestar-connections:UseConnection"
        ],
        Effect : "Allow"
        Resource : aws_codestarconnections_connection.main.arn
      },
      {
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:UploadPart",
        ]
        Effect : "Allow"
        Resource : "${aws_s3_bucket.main.arn}/*"
      },
      {
        Action : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ],
        Effect : "Allow"
        Resource : aws_codebuild_project.main.arn
      },
    ],
  })
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
      Principal : { Service : "codebuild.amazonaws.com" }
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
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect : "Allow"
        Resource : "${aws_s3_bucket.main.arn}/*"
      },
      {
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect : "Allow"
        Resource : "*"
      },
    ]
  })
}

resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-"
  force_destroy = true
}
