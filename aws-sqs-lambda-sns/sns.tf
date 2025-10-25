
resource "aws_sns_topic" "main" {
  name = var.name
}

# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.main.arn
#   protocol  = "email"
#   endpoint  = var.email
# }

resource "aws_sns_topic_subscription" "output" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.output.arn
  raw_message_delivery = true
}
