
resource "aws_sns_topic" "main" {
  name         = var.project
  display_name = var.project
}

resource "aws_sns_topic_subscription" "main" {
  topic_arn = aws_sns_topic.main.arn
  endpoint  = var.email
  protocol  = "email"
}
