
variable "name" {}
variable "region" {}
variable "assume_role_arn" {}
variable "sns_topic_arn" {}

provider "aws" {
  region = var.region

  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform"
  }
}

resource "aws_sqs_queue" "this" {
  name = var.name
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn
}

resource "aws_sqs_queue_policy" "sns_topic" {
  queue_url = aws_sqs_queue.this.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "sns-topic",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "sqs:SendMessage",
        "Resource" : aws_sqs_queue.this.arn,
        "Condition" : {
          "ArnEquals" : {
            "aws:SourceArn" : var.sns_topic_arn,
          }
        }
      }
    ]
  })
}
