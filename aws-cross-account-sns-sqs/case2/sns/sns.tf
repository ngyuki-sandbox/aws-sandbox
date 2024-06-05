
variable "name" {}
variable "region" {}
variable "assume_role_arn" {}
variable "sqs_queue_arn" {}

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

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}
