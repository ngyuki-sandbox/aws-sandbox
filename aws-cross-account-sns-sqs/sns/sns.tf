resource "aws_sns_topic" "this" {
  name = var.name
}


resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = jsonencode({
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : var.sqs_assume_role_arn,
      },
      "Action" : "sns:Subscribe",
      "Resource" : aws_sns_topic.this.arn
    }]
    }
  )
}

