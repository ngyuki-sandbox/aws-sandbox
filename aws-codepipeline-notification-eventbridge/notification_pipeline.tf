
locals {
  pipeline_status = {
    STARTED   = ":information_source:"
    SUCCEEDED = ":white_check_mark:"
    FAILED    = ":x:"
    STOPPED   = ":no_entry_sign:"
  }
}

resource "aws_cloudwatch_event_rule" "pipeline" {
  for_each = local.pipeline_status
  name     = "${var.name}-pipeline-${lower(each.key)}"

  event_pattern = jsonencode({
    "source" : ["aws.codepipeline"],
    "detail-type" : ["CodePipeline Pipeline Execution State Change"]
    "detail" : {
      "pipeline" : [aws_codepipeline.main.name],
      "state" : ["${each.key}"],
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline" {
  for_each = local.pipeline_status
  rule     = aws_cloudwatch_event_rule.pipeline[each.key].name
  arn      = aws_sns_topic.chatbot.arn

  input_transformer {
    input_paths = {
      "execution-id" = "$.detail.execution-id"
      "pipeline"     = "$.detail.pipeline"
      "region"       = "$.region"
      "state"        = "$.detail.state"
      "title"        = "$.detail-type"
    }
    input_template = <<-EOT
      {
        "version": "1.0",
        "source": "custom",
        "content": {
          "title": "${each.value} <title>",
          "description": "<pipeline> -> *<state>*",
          "nextSteps": [
            "https://<region>.console.aws.amazon.com/codesuite/codepipeline/pipelines/<pipeline>/executions/<execution-id>/visualization"
          ]
        }
      }
    EOT
  }
}
