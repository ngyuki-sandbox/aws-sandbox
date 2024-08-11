
resource "aws_sqs_queue" "main" {
  name                        = "${var.name}.fifo"
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 3600
  fifo_queue                  = true
  content_based_deduplication = false
  deduplication_scope         = "queue"
}
