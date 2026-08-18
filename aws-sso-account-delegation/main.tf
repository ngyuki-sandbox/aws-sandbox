
provider "aws" {
  region = "ap-northeast-1"
}

variable "delegated_account_id" {
  type = string
}

variable "permission_sets" {
  type = list(object({
    name     = string
    accounts = list(string)
    emails   = list(string)
  }))
}

data "aws_ssoadmin_instances" "main" {}

# ユーザーを email でルックアップ
data "aws_identitystore_user" "main" {
  for_each = toset(flatten(var.permission_sets[*].emails))

  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]
  alternate_identifier {
    unique_attribute {
      attribute_path  = "emails.value"
      attribute_value = each.value
    }
  }
}

# Identity Center 管理用の許可セット（各部門の管理者に付与する）
resource "aws_ssoadmin_permission_set" "main" {
  for_each = { for o in var.permission_sets : o.name => o }

  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.value.name
  relay_state  = "https://ap-northeast-1.console.aws.amazon.com/singlesignon/home"
}

resource "aws_ssoadmin_permission_set_inline_policy" "dev_admin" {
  for_each = { for o in var.permission_sets : o.name => o }

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.main[each.key].arn
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Identity Center で最低限必要な読み込み系のポリシー
        Effect = "Allow"
        Action = [
          "identitystore:Describe*",
          "identitystore:List*",
          "organizations:Describe*",
          "organizations:List*",
          "sso-directory:DescribeDirectory",
          "sso-directory:DescribeGroups",
          "sso-directory:DescribeUsers",
          "sso-directory:ListGroups",
          "sso-directory:ListUsers",
          "sso-directory:SearchGroups",
          "sso-directory:SearchUsers",
          "sso:Describe*",
          "sso:List*",
        ]
        Resource = "*"
      },
      {
        # 許可セットの付与・剥奪のポリシー
        # アカウントナンバーで制限する
        Effect = "Allow"
        Action = [
          "sso:CreateAccountAssignment",
          "sso:DeleteAccountAssignment",
        ]
        Resource = concat(
          [for v in each.value.accounts : "arn:aws:sso:::account/${v}"],
          [
            "arn:aws:sso:::permissionSet/*/*",
            data.aws_ssoadmin_instances.main.arns[0],
        ])
      },
    ]
  })
}

locals {
  permission_set_emails = {
    for o in flatten([
      for p in var.permission_sets : [
        for email in p.emails : {
          name  = p.name
          email = email
        }
      ]
    ]) :
    "${o.name}:${o.email}" => o
  }
}

resource "aws_ssoadmin_account_assignment" "main" {
  for_each = local.permission_set_emails

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.main[each.value.name].arn
  principal_id       = data.aws_identitystore_user.main[each.value.email].id
  principal_type     = "USER"
  target_id          = var.delegated_account_id
  target_type        = "AWS_ACCOUNT"
}
