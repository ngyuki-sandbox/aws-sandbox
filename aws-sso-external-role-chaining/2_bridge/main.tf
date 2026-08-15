
provider "aws" {
  region = "ap-northeast-1"
}

variable "bridge_account_id" {
  type = string
}

variable "email" {
  type = string
}

output "role_arn" {
  value = aws_iam_role.main.arn
}

resource "aws_iam_role" "main" {
  name = "external"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          AWS = "arn:aws:iam::${var.bridge_account_id}:root"
        }
        Condition = {
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${var.bridge_account_id}:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_ExternalAccountAccess_*"
          }
          StringEquals = {
            "aws:PrincipalTag/email" : var.email
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "main" {
  name = "external"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}
