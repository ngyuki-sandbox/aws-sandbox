///////////////////////////////////////////////////////////////////////////////
/// IAM
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
/// ECS

resource "aws_iam_role" "execution" {
  name = "${var.tag}-execution"

  assume_role_policy = jsonencode({
    Version : "2008-10-17",
    Statement : [{
      Action : "sts:AssumeRole"
      Effect : "Allow"
      Principal : { Service : "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

///////////////////////////////////////////////////////////////////////////////
/// Gitlab

resource "aws_iam_user" "gitlab" {
  name = "${var.tag}-gitlab"
}

resource "aws_iam_access_key" "gitlab" {
  user = aws_iam_user.gitlab.name
}

resource "aws_iam_user_policy_attachment" "gitlab_PowerUserAccess" {
  user       = aws_iam_user.gitlab.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_user_policy_attachment" "gitlab_IAMReadOnlyAccess" {
  user       = aws_iam_user.gitlab.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}
