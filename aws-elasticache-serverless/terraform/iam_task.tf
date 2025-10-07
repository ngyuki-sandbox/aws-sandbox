
resource "aws_iam_role" "task" {
  name = "${var.name}-ecs-task"

  assume_role_policy = jsonencode({
    Version : "2008-10-17"
    Statement : [
      {
        Action : "sts:AssumeRole"
        Effect : "Allow"
        Principal : {
          Service : "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "task" {
  role = aws_iam_role.task.name
  name = aws_iam_role.task.name

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource : "*",
      },
      {
        Effect : "Allow",
        Action : "s3:GetObject",
        Resource : "*",
      },
      {
        Effect : "Allow",
        Action : "elasticache:*",
        Resource : "*",
      },
    ]
  })
}
