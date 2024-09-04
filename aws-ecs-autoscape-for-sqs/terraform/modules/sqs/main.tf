
variable "name" {
  type = string
}

resource "aws_sqs_queue" "main" {
  name = var.name
}

output "arn" {
  value = aws_sqs_queue.main.arn
}

output "url" {
  value = aws_sqs_queue.main.url
}

output "name" {
  value = aws_sqs_queue.main.name
}
