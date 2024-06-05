
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
  name_prefix = var.name
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.this.arn
}

output "sqs_queue_endpoint" {
  value = aws_sqs_queue.this.url
}
