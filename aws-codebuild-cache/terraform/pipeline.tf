
resource "aws_codepipeline" "main" {
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
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["Source"]

      configuration = {
        S3Bucket             = aws_s3_object.source.bucket
        S3ObjectKey          = aws_s3_object.source.key
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    dynamic "action" {
      for_each = aws_codebuild_project.main
      content {
        name     = action.key
        category = "Build"
        owner    = "AWS"
        provider = "CodeBuild"
        version  = "1"

        input_artifacts  = ["Source"]
        output_artifacts = []

        configuration = {
          ProjectName = action.value.name
        }
      }
    }
  }
}
