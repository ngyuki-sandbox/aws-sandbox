
resource "aws_sqs_queue" "input" {
  name                       = "${var.name}-input"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  delay_seconds              = 10
}

resource "aws_sqs_queue" "output" {
  name                       = "${var.name}-output"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 60
}

resource "aws_sqs_queue_policy" "output" {
  queue_url = aws_sqs_queue.output.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.output.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.main.arn
          }
        }
      }
    ]
  })
}

output "input_queue_url" {
  value = aws_sqs_queue.input.id
}

output "output_queue_url" {
  value = aws_sqs_queue.output.id
}
