
provider "aws" {
  region              = var.region
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.default_tags
  }
}

resource "aws_chatbot_slack_channel_configuration" "test" {
  configuration_name    = var.channel_name
  iam_role_arn          = aws_iam_role.main.arn
  guardrail_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  logging_level         = "ERROR"
  slack_channel_id      = var.channel_id
  slack_team_id         = var.workspace_id

  sns_topic_arns = [
    aws_sns_topic.main.arn,
  ]
}

resource "aws_iam_role" "main" {
  name = var.name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "chatbot.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "main" {
  role_name = aws_iam_role.main.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AWSIncidentManagerResolverAccess",
    "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSSupportAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]
}

resource "aws_sns_topic" "main" {
  name = var.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.main.arn
}
