
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
