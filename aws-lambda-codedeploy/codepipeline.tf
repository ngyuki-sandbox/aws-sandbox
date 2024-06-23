
resource "aws_codepipeline" "main" {
  name     = var.name
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline.bucket
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "ECR"
      version  = "1"

      namespace        = "SourceExport"
      output_artifacts = ["Source"]

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

      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.main.name
        EnvironmentVariables = jsonencode([
          { name = "LAMBDA_FUNCTION_NAME", value = aws_lambda_function.lambda.function_name },
          { name = "LAMBDA_FUNCTION_ALIAS", value = aws_lambda_alias.lambda.name },
          { name = "ECR_IMAGE_DIGEST", value = "#{SourceExport.ImageDigest}" },
          { name = "ECR_IMAGE_TAG", value = "#{SourceExport.ImageTag}" },
          { name = "ECR_IMAGE_URI", value = "#{SourceExport.ImageURI}" },
          { name = "ECR_REGISTRY_ID", value = "#{SourceExport.RegistryId}" },
          { name = "ECR_REPOSITORY_NAME", value = "#{SourceExport.RepositoryName}" },
        ])
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "CodeDeploy"
      version  = "1"

      input_artifacts = ["Build"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.main.name
        DeploymentGroupName = aws_codedeploy_deployment_group.main.deployment_group_name
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "pipeline" {
  name = "${var.name}-pipeline-from-ecr"

  event_pattern = jsonencode({
    "source" : ["aws.ecr"],
    "detail-type" : ["ECR Image Action"],
    "resources" : [aws_ecr_repository.main.arn],
    "detail" : {
      "action-type" : ["PUSH"],
      "image-tag" : ["latest"],
      "repository-name" : [aws_ecr_repository.main.name],
      "result" : ["SUCCESS"]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule     = aws_cloudwatch_event_rule.pipeline.name
  arn      = aws_codepipeline.main.arn
  role_arn = aws_iam_role.pipeline_trigger.arn
}

resource "aws_iam_role" "pipeline" {
  name = "${var.name}-pipeline"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : {
      Action : "sts:AssumeRole",
      Effect : "Allow",
      Principal : { Service : "codepipeline.amazonaws.com" }
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
          "s3:GetObject",
          "s3:PutObject",
          "s3:UploadPart",
        ]
        Effect : "Allow"
        Resource : "${aws_s3_bucket.pipeline.arn}/*"
      },
      {
        Action : [
          "ecr:DescribeImages",
        ]
        Effect : "Allow"
        Resource : aws_ecr_repository.main.arn
      },
      {
        Action : [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ]
        Effect : "Allow"
        Resource : aws_codebuild_project.main.arn
      },
      {
        Action : [
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
        ]
        Effect : "Allow"
        Resource : "*"
      },
      {
        Action : [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
        ]
        Effect : "Allow"
        Resource : aws_codedeploy_deployment_group.main.arn
      },
    ]
  })
}

resource "aws_s3_bucket" "pipeline" {
  bucket_prefix = "${var.name}-pipeline-"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "pipeline" {
  bucket = aws_s3_bucket.pipeline.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "pipeline_trigger" {
  name = "${var.name}-pipeline-trigger"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Action : "sts:AssumeRole",
      Effect : "Allow",
      Principal : {
        Service : "events.amazonaws.com",
      }
    }]
  })
}

resource "aws_iam_role_policy" "pipeline_trigger" {
  name = aws_iam_role.pipeline_trigger.id
  role = aws_iam_role.pipeline_trigger.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Action : "codepipeline:StartPipelineExecution"
      Effect : "Allow"
      Resource : aws_codepipeline.main.arn
    }]
  })
}
