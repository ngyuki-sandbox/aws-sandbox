
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    aws_iam_role.devops_agentspace,
    aws_iam_role_policy_attachment.devops_agentspace_access,
    aws_iam_role.devops_operator,
    aws_iam_role_policy_attachment.devops_operator_access,
    aws_iam_role.devops_action,
    aws_iam_role_policy.devops_action,
  ]
  create_duration = "30s"
}

resource "awscc_devopsagent_agent_space" "main" {
  name   = "default-space"
  locale = "ja-JP"
  operator_app = {
    iam = {
      operator_app_role_arn = aws_iam_role.devops_operator.arn
    }
  }
  depends_on = [
    time_sleep.wait_for_iam_propagation
  ]
}

resource "terraform_data" "devops_agent_elevated_actions_enabled" {
  input = {
    agent_space_id = awscc_devopsagent_agent_space.main.agent_space_id
  }
  provisioner "local-exec" {
    command     = <<-EOT
      aws devops-agent update-agent-space \
        --agent-space-id "$agent_space_id" \
        --preferences elevatedActionsEnabled=true
    EOT
    environment = self.input
  }
}

resource "awscc_devopsagent_association" "main" {
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"
  configuration = {
    aws = {
      account_type       = "monitor"
      account_id         = data.aws_caller_identity.current.account_id
      assumable_role_arn = aws_iam_role.devops_agentspace.arn
    }
  }
  depends_on = [
    awscc_devopsagent_agent_space.main
  ]
}

resource "terraform_data" "devops_agent_elevated_role_arn" {
  input = {
    agent_space_id = awscc_devopsagent_agent_space.main.agent_space_id
    association_id = awscc_devopsagent_association.main.association_id
    configuration = jsonencode({
      aws = {
        accountId            = data.aws_caller_identity.current.account_id
        accountType          = "monitor"
        assumableRoleArn     = aws_iam_role.devops_agentspace.arn
        agentElevatedRoleArn = aws_iam_role.devops_action.arn
      }
      }
    )
  }
  provisioner "local-exec" {
    command     = <<-EOT
      aws devops-agent update-association \
        --agent-space-id "$agent_space_id" \
        --association-id "$association_id" \
        --configuration "$configuration"
    EOT
    environment = self.input
  }
}
