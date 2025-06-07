
resource "aws_iam_role" "scheduler" {
  name = "${var.name}-scheduler"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Action : "sts:AssumeRole",
      Principal : { Service : "scheduler.amazonaws.com" },
    }]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  role = aws_iam_role.scheduler.id
  name = aws_iam_role.scheduler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action : "states:StartExecution",
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
