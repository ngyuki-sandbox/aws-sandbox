
provider "aws" {
  region = "ap-northeast-1"
}

variable "email" {
  type = string
}

variable "bridge_account_id" {
  type = string
}

data "aws_ssoadmin_instances" "main" {}

data "aws_identitystore_user" "main" {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]
  alternate_identifier {
    unique_attribute {
      attribute_path  = "emails.value"
      attribute_value = var.email
    }
  }
}

resource "aws_ssoadmin_permission_set" "main" {
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = "ExternalAccountAccess"
}

resource "aws_ssoadmin_permission_set_inline_policy" "main" {
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.main.arn
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "*"
      },
    ]
  })
}

resource "aws_ssoadmin_account_assignment" "main" {
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.main.arn
  principal_type     = "USER"
  principal_id       = data.aws_identitystore_user.main.user_id
  target_type        = "AWS_ACCOUNT"
  target_id          = var.bridge_account_id
}

resource "aws_ssoadmin_instance_access_control_attributes" "main" {
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  attribute {
    key = "userName"
    value {
      source = [
        "$${path:userName}",
      ]
    }
  }
  attribute {
    key = "email"
    value {
      source = [
        "$${path:emails[primary eq true].value}",
      ]
    }
  }
}
