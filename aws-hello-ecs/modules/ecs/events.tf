
resource "aws_cloudwatch_event_rule" "main" {
  name = var.name

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "resources" : [aws_ecs_service.main.id],
    "detail-type" : ["ECS Deployment State Change", ],
  })
}

resource "aws_cloudwatch_event_target" "chatbot" {
  count = var.chatbot_topic_arn != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "chatbot"
  arn       = var.chatbot_topic_arn

  # 素の通知だと Service が無くて判りずらいので部分的に改竄する
  # ECS の他の種類に通知なら Service もあったりするのだけど・・
  #
  # 入力トランスフォーマーで custom 通知に変換することも考えられるが
  # イベント種類ごとに emoji を変えようとするとイベントルール自体分ける必要があるのでやめ
  # 後段は lambda にしても良いかも
  input_transformer {
    input_paths = {
      "version"             = "$.version",
      "id"                  = "$.id",
      "detail-type"         = "$.detail-type"
      "source"              = "$.source",
      "account"             = "$.account",
      "time"                = "$.time",
      "region"              = "$.region",
      "resource"            = "$.resources[0]",
      "detail-eventType"    = "$.detail.eventType"
      "detail-eventName"    = "$.detail.eventName"
      "detail-clusterArn"   = "$.detail.clusterArn"
      "detail-deploymentId" = "$.detail.deploymentId"
      "detail-reason"       = "$.detail.reason"
      "detail-updatedAt"    = "$.detail.updatedAt"
    }
    input_template = <<-EOT
      {
        "version": "<version>",
        "id": "<id>",
        "detail-type": "<detail-type>",
        "source": "<source>",
        "account": "<account>",
        "time": "<time>",
        "region": "<region>",
        "resources": ["<resource>"],
        "detail": {
            "clusterArn": "<detail-clusterArn>",
            "eventType": "<detail-eventType>",
            "eventName": "<detail-eventName>",
            "deploymentId": "<detail-deploymentId>",
            "updatedAt": "<detail-updatedAt>",
            "reason": "<detail-reason>\n*Service*\r${aws_ecs_service.main.name}"
        }
      }
    EOT
  }
}

resource "aws_cloudwatch_event_target" "log" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "log"
  arn       = aws_cloudwatch_log_group.event.arn
}

resource "aws_cloudwatch_log_group" "event" {
  name              = "/aws/events/${var.name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_resource_policy" "event" {
  policy_name = aws_cloudwatch_log_group.event.name
  policy_document = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_cloudwatch_log_group.event.arn}:*",
        "Principal" : {
          "Service" : [
            "events.amazonaws.com",
            "delivery.logs.amazonaws.com"
          ]
        },
      }
    ],
  })
}
