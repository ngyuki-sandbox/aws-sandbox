
variable "github_repo" {
  type = string
}

variable "github_branch" {
  type = string
}

output "github_role_arn" {
  value = aws_iam_role.github.arn
}

locals {
  github_url = "https://token.actions.githubusercontent.com"
}

data "tls_certificate" "github" {
  url = local.github_url
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = local.github_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates.0.sha1_fingerprint]
}

resource "aws_iam_role" "github" {
  name = "${var.name}-github"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.github.arn
        },
        "Condition" : {
          "StringLike" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_repo}:*"
          },
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "github" {
  role = aws_iam_role.github.id
  name = aws_iam_role.github.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "codepipeline:StartPipelineExecution",
        Resource : aws_codepipeline.main.arn,
      },
    ]
  })
}
