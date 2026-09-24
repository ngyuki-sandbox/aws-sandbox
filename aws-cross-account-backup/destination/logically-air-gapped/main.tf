
resource "aws_backup_logically_air_gapped_vault" "main" {
  name               = var.name
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days
}

resource "aws_backup_vault_policy" "main" {
  backup_vault_name = aws_backup_logically_air_gapped_vault.main.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "backup:CopyIntoBackupVault"
      Principal = {
        AWS = "arn:aws:iam::${var.source_account_id}:root"
      }
      Resource = aws_backup_logically_air_gapped_vault.main.arn
    }]
  })
}

resource "aws_ram_resource_share" "main" {
  name                      = var.name
  allow_external_principals = false
}

resource "aws_ram_resource_association" "main" {
  resource_arn       = aws_backup_logically_air_gapped_vault.main.arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

resource "aws_ram_principal_association" "main" {
  principal          = var.source_account_id
  resource_share_arn = aws_ram_resource_share.main.arn
}
