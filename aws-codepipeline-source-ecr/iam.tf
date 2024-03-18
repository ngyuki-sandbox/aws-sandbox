
resource "aws_iam_role" "build" {
  name = "${var.name}-build"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "build" {
  name = "${var.name}-build"
  role = aws_iam_role.build.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "ecr:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "s3:*"
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow",
        Resource = "*"
      },
    ],
  })
}

resource "aws_iam_role" "pipeline" {
  name = "${var.name}-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = {
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com",
      }
    }
  })
}

resource "aws_iam_role_policy" "pipeline" {
  name = "${var.name}-pipeline"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ecr:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ]
        Effect   = "Allow"
        Resource = aws_codebuild_project.build.arn
      }
    ],
  })
}


resource "aws_iam_role" "trigger" {
  name = "${var.name}-trigger"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = {
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal : { Service : "events.amazonaws.com" }
    }
  })
}

resource "aws_iam_role_policy" "trigger" {
  name = aws_iam_role.trigger.id
  role = aws_iam_role.trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Action : "codepipeline:StartPipelineExecution"
        Resource : aws_codepipeline.pipeline.arn
      }
    ]
  })
}
