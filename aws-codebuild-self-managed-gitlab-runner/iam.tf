
resource "aws_iam_role" "main" {
  name = var.name

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Action : "sts:AssumeRole"
      Effect : "Allow"
      Principal : {
        Service : "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "main" {
  name = aws_iam_role.main.id
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Action : [
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection",
        ]
        Effect : "Allow"
        Resource : aws_codeconnections_connection.main.arn
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
