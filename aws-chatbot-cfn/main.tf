
variable "name" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "allowed_account_ids" {
  type = list(string)
}

variable "region" {
  type = string
}

variable "workspace_id" {
  type = string
}

variable "channel_id" {
  type = string
}

variable "channel_name" {
  type = string
}

provider "aws" {
  region              = var.region
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = var.default_tags
  }
}

resource "aws_cloudformation_stack" "chatbot" {
  name = var.name
  template_body = yamlencode({
    Resources = {
      SlackChannelConfiguration = {
        Type = "AWS::Chatbot::SlackChannelConfiguration"
        Properties = {
          ConfigurationName = var.channel_name
          GuardrailPolicies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
          IamRoleArn        = aws_iam_role.main.arn
          LoggingLevel      = "ERROR"
          SlackWorkspaceId  = var.workspace_id
          SlackChannelId    = var.channel_id
          SnsTopicArns = [
            aws_sns_topic.main.arn,
          ]
        }
      }
    }
  })
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
  managed_policy_arns = [
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
