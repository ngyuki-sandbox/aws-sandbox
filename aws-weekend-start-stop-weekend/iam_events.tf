
resource "aws_iam_role" "events" {
  name = "${var.name}-events"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Action : "sts:AssumeRole",
      Principal : { Service : "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "events_permissions" {
  name = aws_iam_role.events.id
  role = aws_iam_role.events.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = "*"
      }
    ]
  })
}
