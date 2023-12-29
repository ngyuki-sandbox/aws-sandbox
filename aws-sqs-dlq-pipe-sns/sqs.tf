
resource "aws_sqs_queue" "main" {
  name = var.project

  visibility_timeout_seconds = 1

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 2
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.project}-dlq"
}
