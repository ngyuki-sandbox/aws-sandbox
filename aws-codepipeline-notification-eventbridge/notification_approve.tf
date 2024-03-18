
locals {
  approve_status = {
    STARTED   = { emoji = ":question:", description = "APPROVAL NEEDED" },
    SUCCEEDED = { emoji = ":ok:", description = "APPROVAL OK" },
    FAILED    = { emoji = ":ng:", description = "APPROVAL NG" },
  }
}

resource "aws_cloudwatch_event_rule" "approve" {
  for_each = local.approve_status
  name     = "${var.name}-approve-${lower(each.key)}"

  event_pattern = jsonencode({
    "source" : ["aws.codepipeline"],
    "detail-type" : ["CodePipeline Action Execution State Change"]
    "detail" : {
      "pipeline" : [aws_codepipeline.main.name],
      "state" : ["${each.key}"],
      "type" : {
        "owner" : ["AWS"],
        "provider" : ["Manual"],
        "category" : ["Approval"],
      },
    },
  })
}

resource "aws_cloudwatch_event_target" "approve" {
  for_each = local.approve_status
  rule     = aws_cloudwatch_event_rule.approve[each.key].name
  arn      = aws_sns_topic.chatbot.arn

  input_transformer {
    input_paths = {
      "region"       = "$.region"
      "title"        = "$.detail-type"
      "pipeline"     = "$.detail.pipeline"
      "state"        = "$.detail.state"
      "execution-id" = "$.detail.execution-id"
      "category"     = "$.detail.type.category"
    }
    input_template = <<-EOT
      {
        "version": "1.0",
        "source": "custom",
        "content": {
          "title": "${each.value.emoji} <title>",
          "description": "<pipeline> -> *${each.value.description}*",
          "nextSteps": [
            "https://<region>.console.aws.amazon.com/codesuite/codepipeline/pipelines/<pipeline>/executions/<execution-id>/visualization"
          ]
        }
      }
    EOT
  }
}
