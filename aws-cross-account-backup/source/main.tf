
data "aws_caller_identity" "main" {}

resource "aws_backup_region_settings" "main" {
  resource_type_opt_in_preference = {
    "EC2" = true
    "S3"  = true
  }

  lifecycle {
    ignore_changes = [resource_type_opt_in_preference]
  }
}

resource "aws_backup_vault" "main" {
  name          = var.name
  force_destroy = true
}

resource "aws_backup_plan" "main" {
  name = var.name

  rule {
    rule_name                    = "cross-account"
    target_vault_name            = aws_backup_vault.main.name
    schedule                     = var.schedule
    schedule_expression_timezone = "Asia/Tokyo"
    start_window                 = 60
    completion_window            = 180

    lifecycle {
      delete_after = var.retention_days
    }

    dynamic "copy_action" {
      for_each = var.destination_vault_arns
      content {
        destination_vault_arn = copy_action.value
        lifecycle {
          delete_after = var.retention_days
        }
      }
    }
  }
}

resource "aws_backup_selection" "main" {
  name         = var.name
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = "enabled"
  }
}

resource "aws_iam_role" "backup" {
  name = "${var.name}-backup"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  for_each = {
    AWSBackupServiceRolePolicyForBackup    = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
    AWSBackupServiceRolePolicyForS3Backup  = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
    AWSBackupServiceRolePolicyForS3Restore = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  }
  role       = aws_iam_role.backup.name
  policy_arn = each.value
}
