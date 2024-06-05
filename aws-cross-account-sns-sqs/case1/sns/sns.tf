
variable "name" {}
variable "region" {}
variable "assume_role_arn" {}
variable "sqs_assume_role_arn" {}

provider "aws" {
  region = var.region

  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform"
  }
}

resource "aws_sns_topic" "this" {
  name = var.name
}

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = jsonencode({
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : var.sqs_assume_role_arn,
      },
      "Action" : "sns:Subscribe",
      "Resource" : aws_sns_topic.this.arn
    }]
    }
  )
}

output "sns_topic_arn" {
  value = aws_sns_topic_policy.this.arn
}
