
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
        Action : "s3:*"
        Effect : "Allow"
        Resource : "*"
      },
    ]
  })
}
