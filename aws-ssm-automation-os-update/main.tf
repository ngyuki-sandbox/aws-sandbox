
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_ssm_document" "main" {
  name            = var.name
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/runbook.yml", {
    assume_role      = jsonencode(aws_iam_role.main.arn)
    log_group        = jsonencode(aws_cloudwatch_log_group.main.name)
    get_initial_info = jsonencode(file("${path.module}/get_initial_info.py"))
    versionlock      = base64gzip(file("${path.module}/versionlock.list"))
  })

  tags = {
    Name = var.name
  }
}

resource "aws_iam_role" "main" {
  name_prefix = "${var.name}-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = var.name
  }
}

resource "aws_iam_policy" "main" {
  name_prefix = "${var.name}-"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "logs:*",
          "ssm:*",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/ssm/automation/${var.name}"
  retention_in_days = 3
}
