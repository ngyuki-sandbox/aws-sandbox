
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type = string
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

  name          = "${var.name}-pr"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.pipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.main.bucket
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      pull_request {
        events = ["OPEN", "UPDATED", "CLOSED"]
        branches {
          includes = ["dev"]
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name      = "Source"
      namespace = "SourceVariables"

      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.main.arn
        DetectChanges        = "false"
        OutputArtifactFormat = "CODE_ZIP"
        FullRepositoryId     = var.github_repo
        BranchName           = var.github_branch
      }

      output_artifacts = [
        "Source"
      ]
    }
  }

  stage {
    name = "Build"
    action {
      name      = "Build"
      namespace = "BuildVariables"

      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main.name
        EnvironmentVariables = jsonencode([
          {
            name  = "AUTHOR_NAME"
            value = "#{SourceVariables.AuthorDisplayName}"
          },
          {
            name  = "AUTHOR_EMAIL"
            value = "#{SourceVariables.AuthorEmail}"
          },
          {
            name  = "COMMIT_HASH"
            value = "#{SourceVariables.CommitId}"
          },
          {
            name  = "COMMIT_MESSAGE"
            value = "#{SourceVariables.CommitMessage}"
          },
          {
            name  = "GITHUB_REPO"
            value = "#{SourceVariables.FullRepositoryName}"
          },
          {
            name  = "PR_NUMBER"
            value = "#{SourceVariables.PullRequestId}"
          },
          {
            name  = "PR_TITLE"
            value = "#{SourceVariables.PullRequestTitle}"
          },
        ])
      }

      input_artifacts = [
        "Source"
      ]
    }
  }
}

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
    privileged_mode = false
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
      {
        Action : [
          "ssm:GetParameters",
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
