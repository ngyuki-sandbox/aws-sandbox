
locals {
  source_key   = "source/ecspresso.zip"
  cache_prefix = "codebuild-cache"
}

################################################################################
# ソース（ecspresso の設定一式を zip にして S3 に置く）

resource "aws_s3_bucket" "main" {
  bucket_prefix = "${var.name}-"
  force_destroy = true
}

# S3 ソースアクションはバージョニングが必須
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# CodeBuild のキャッシュは 30 日で削除する（削除されたら次のビルドで作り直される）
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "codebuild-cache"
    status = "Enabled"

    filter {
      prefix = "${local.cache_prefix}/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# オブジェクト作成イベントを EventBridge に送る
resource "aws_s3_bucket_notification" "main" {
  bucket      = aws_s3_bucket.main.id
  eventbridge = true
}

# ecspresso の設定から参照する環境ごとの値
locals {
  ecspresso_vars = {
    region                = data.aws_region.current.region
    cluster               = aws_ecs_cluster.main.name
    service               = aws_ecs_service.main.name
    codedeployApplication = aws_codedeploy_app.main.name
    codedeployGroup       = aws_codedeploy_deployment_group.main.deployment_group_name
    family                = aws_ecs_task_definition.main.family
    executionRoleArn      = aws_iam_role.execution.arn
    taskRoleArn           = aws_iam_role.task.arn
    logGroup              = aws_cloudwatch_log_group.ecs.name
  }
}

# ecspresso の設定ファイルと Terraform で生成した vars.json をまとめる
# ecspresso/vars.json はローカル確認用のサンプルなので zip には含めない
data "archive_file" "ecspresso" {
  type        = "zip"
  output_path = "${path.module}/tmp/ecspresso.zip"

  source {
    filename = "vars.json"
    content  = jsonencode(local.ecspresso_vars)
  }

  dynamic "source" {
    for_each = ["ecspresso.jsonnet", "ecs-task-def.jsonnet"]

    content {
      filename = source.value
      content  = file("${path.module}/ecspresso/${source.value}")
    }
  }
}

resource "aws_s3_object" "ecspresso" {
  bucket = aws_s3_bucket.main.id
  key    = local.source_key
  source = data.archive_file.ecspresso.output_path
  etag   = data.archive_file.ecspresso.output_md5

  depends_on = [aws_s3_bucket_versioning.main]
}

################################################################################
# CodeBuild（ecspresso deploy を実行する）

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/${var.name}/codebuild"
  retention_in_days = 1
}

resource "aws_codebuild_project" "main" {
  name         = var.name
  service_role = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  # ダウンロードした ecspresso をキャッシュする
  cache {
    type     = "S3"
    location = "${aws_s3_bucket.main.bucket}/${local.cache_prefix}"
  }

  environment {
    type         = "LINUX_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${var.name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.codebuild.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
        ]
        Resource = aws_s3_bucket.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      # ecspresso deploy で必要な ECS の権限
      {
        Effect = "Allow"
        Action = [
          "ecs:Describe*",
          "ecs:List*",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
          "ecs:UpdateService",
          "application-autoscaling:Describe*",
        ]
        Resource = "*"
      },
      # ecspresso deploy で必要な CodeDeploy の権限
      {
        Effect = "Allow"
        Action = [
          "codedeploy:BatchGet*",
          "codedeploy:CreateDeployment",
          "codedeploy:Get*",
          "codedeploy:List*",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:StopDeployment",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.execution.arn,
          aws_iam_role.task.arn,
        ]
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      },
    ]
  })
}

################################################################################
# CodePipeline

resource "aws_codepipeline" "main" {
  name          = var.name
  pipeline_type = "V2"
  role_arn      = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.main.bucket
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
        S3Bucket             = aws_s3_bucket.main.bucket
        S3ObjectKey          = local.source_key
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["Source"]

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  # パイプライン作成時の初回実行でソースと権限がそろっているように
  depends_on = [
    aws_s3_object.ecspresso,
    aws_iam_role_policy.codepipeline,
  ]
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.name}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "codepipeline"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
        ]
        Resource = aws_codebuild_project.main.arn
      },
    ]
  })
}

################################################################################
# トリガー（ソースの zip がアップロードされたらパイプラインを開始する）

resource "aws_cloudwatch_event_rule" "trigger" {
  name = "${var.name}-trigger"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [aws_s3_bucket.main.bucket] }
      object = { key = [local.source_key] }
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger" {
  rule     = aws_cloudwatch_event_rule.trigger.name
  arn      = aws_codepipeline.main.arn
  role_arn = aws_iam_role.trigger.arn
}

resource "aws_iam_role" "trigger" {
  name = "${var.name}-trigger"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "trigger" {
  name = "trigger"
  role = aws_iam_role.trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "codepipeline:StartPipelineExecution"
      Resource = aws_codepipeline.main.arn
    }]
  })
}
