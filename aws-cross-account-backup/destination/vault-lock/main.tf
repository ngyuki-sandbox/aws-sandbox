
resource "aws_kms_key" "main" {
  description             = var.name
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_backup_vault" "main" {
  name          = var.name
  kms_key_arn   = aws_kms_key.main.arn
  force_destroy = true
}

resource "aws_backup_vault_lock_configuration" "main" {
  backup_vault_name   = aws_backup_vault.main.name
  changeable_for_days = var.changeable_for_days
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
}

resource "aws_backup_vault_policy" "main" {
  backup_vault_name = aws_backup_vault.main.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "backup:CopyIntoBackupVault"
      Principal = {
        AWS = "arn:aws:iam::${var.source_account_id}:root"
      }
      Resource = aws_backup_vault.main.arn
    }]
  })
}
