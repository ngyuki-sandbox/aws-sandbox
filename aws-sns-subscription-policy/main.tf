
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "email" {
  type = string
}

output "topic_arn" {
  value = aws_sns_topic.main.arn
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.default_tags
  }
}

resource "aws_sns_topic" "main" {
  name = var.name
}

resource "aws_sns_topic_subscription" "main" {
  topic_arn           = aws_sns_topic.main.arn
  protocol            = "email"
  endpoint            = var.email
  filter_policy_scope = "MessageBody"
  filter_policy = jsonencode({
    "source" : ["oreore"],
    }
  )
}
