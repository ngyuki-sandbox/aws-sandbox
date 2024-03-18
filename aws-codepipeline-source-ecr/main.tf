
variable "name" {
  default = "sandbox"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

provider "aws" {
  region = "ap-northeast-1"
}

data "archive_file" "source" {
  type        = "zip"
  source_file = "buildspec.yml"
  output_path = "source.zip"
}

resource "aws_s3_bucket" "source" {
  bucket_prefix = "${var.name}-source-"
}

resource "aws_s3_object" "source" {
  bucket = aws_s3_bucket.source.id
  key    = "source.zip"
  source = data.archive_file.source.output_path
  etag   = filemd5(data.archive_file.source.output_path)
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "artifact" {
  bucket_prefix = "${var.name}-artifact-"
  force_destroy = true
}

resource "aws_ecr_repository" "main" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_codebuild_project" "build" {
  name         = var.name
  service_role = aws_iam_role.build.arn

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
    }
  }
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/${var.name}"
  retention_in_days = 1
}

resource "aws_codepipeline" "pipeline" {
  name     = var.name
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      namespace        = "SourceVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["Source"]

      configuration = {
        S3Bucket             = aws_s3_object.source.bucket
        S3ObjectKey          = aws_s3_object.source.key
        PollForSourceChanges = "true"
      }
    }

    action {
      name             = "Image"
      namespace        = "ImageVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["Image"]

      configuration = {
        RepositoryName = aws_ecr_repository.main.name
        ImageTag       = "latest"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.build.name
        PrimarySource = "Source"
        EnvironmentVariables = jsonencode([
          { name = "ECR_REGISTRY_ID", value = "#{ImageVariables.RegistryId}" },
          { name = "ECR_REPOSITORY_NAME", value = "#{ImageVariables.RepositoryName}" },
          { name = "ECR_IMAGE_TAG", value = "#{ImageVariables.ImageTag}" },
          { name = "ECR_IMAGE_DIGEST", value = "#{ImageVariables.ImageDigest}" },
          { name = "ECR_IMAGE_URI", value = "#{ImageVariables.ImageURI}" },
        ])
      }

      input_artifacts  = ["Source", "Image"]
      output_artifacts = ["Build"]
    }
  }
}


resource "aws_cloudwatch_event_rule" "main" {
  name = "${var.name}-pipeline-ecr"

  event_pattern = jsonencode({
    "detail-type" : ["ECR Image Action"],
    "source" : ["aws.ecr"],
    "detail" : {
      "action-type" : ["PUSH"],
      "repository-name" : [aws_ecr_repository.main.name],
      "image-tag" : ["latest"],
      "result" : ["SUCCESS"],
    }
  })
}

resource "aws_cloudwatch_event_target" "main" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = aws_codepipeline.pipeline.arn
  role_arn = aws_iam_role.trigger.arn
}
