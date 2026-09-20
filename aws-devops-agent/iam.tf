
####################################################################################################
# DevOpsAgentRole-AgentSpace

resource "aws_iam_role" "devops_agentspace" {
  name = "DevOpsAgentRole-AgentSpace"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "aidevops.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:aidevops:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "devops_agentspace_access" {
  role       = aws_iam_role.devops_agentspace.name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsAgentAccessPolicy"
}

####################################################################################################
# DevOpsAgentRole-WebappAdmin

resource "aws_iam_role" "devops_operator" {
  name = "DevOpsAgentRole-WebappAdmin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "aidevops.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:aidevops:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "devops_operator_access" {
  role       = aws_iam_role.devops_operator.name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsOperatorAppAccessPolicy"
}

####################################################################################################
# DevOpsAgentActionsRole-AgentSpace

resource "aws_iam_role" "devops_action" {
  name = "DevOpsAgentActionsRole-AgentSpace"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "aidevops.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:SetSourceIdentity",
        "sts:TagSession",
      ]
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:aidevops:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "devops_action" {
  name = "RebootInstances"
  role = aws_iam_role.devops_action.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:RebootInstances"
      Resource = aws_instance.main.arn
    }]
  })
}

####################################################################################################
# DevOpsAgentChannel

resource "aws_iam_role" "devops_slack" {
  name = "DevOpsAgentChannel"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "aidevops.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnEquals = {
          "aws:SourceArn" = awscc_devopsagent_agent_space.main.arn
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "devops_slack" {
  role       = aws_iam_role.devops_slack.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AIDevOpsChannelAccessPolicy"
}
