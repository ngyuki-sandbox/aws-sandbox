
resource "aws_pipes_pipe" "main" {
  name     = var.project
  role_arn = aws_iam_role.pipe.arn
  source   = aws_sqs_queue.dlq.arn
  target   = aws_sns_topic.main.arn

  target_parameters {
    input_template = <<-EOT
      {
        "version": "1.0",
        "source": "custom",
        "content": {
          "textType": "client-markdown",
          "title": ":warning: SQS デッドレータ―通知",
          "description": <$.body>,
          "nextSteps": [
            "メッセージがデッドレターキューに送られました"
          ]
        }
      }
    EOT
  }

  depends_on = [aws_iam_role_policy.pipe]
}

data "aws_caller_identity" "main" {}

resource "aws_iam_role" "pipe" {
  name = "${var.project}-pipe"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "pipes.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.main.account_id
        }
      }
    }
  })
}

resource "aws_iam_role_policy" "pipe" {
  role = aws_iam_role.pipe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
        ],
        Resource = [
          aws_sqs_queue.dlq.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ],
        Resource = [
          aws_sns_topic.main.arn,
        ]
      },
    ]
  })
}
