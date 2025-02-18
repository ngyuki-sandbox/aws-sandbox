
data "aws_region" "current" {}

data "aws_sns_topic" "chatbot" {
  name = var.chatbot_topic_name
}
