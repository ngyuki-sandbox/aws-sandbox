
resource "aws_iam_role" "sfn" {
  name = "${var.name}-sfn"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Action : "sts:AssumeRole",
      Principal : { Service : "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn" {
  role = aws_iam_role.sfn.id
  name = aws_iam_role.sfn.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:StopDBCluster",
          "rds:StartDBCluster",
          "rds:DescribeDBClusters",
        ]
        Resource = "*"
      }
    ]
  })
}
