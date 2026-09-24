
resource "aws_organizations_aws_service_access" "backup" {
  service_principal = "backup.amazonaws.com"
}

resource "aws_backup_global_settings" "main" {
  global_settings = {
    isCrossAccountBackupEnabled     = "true"
    isMpaEnabled                    = "false"
    isDelegatedAdministratorEnabled = "false"
  }
  depends_on = [
    aws_organizations_aws_service_access.backup,
  ]
}
