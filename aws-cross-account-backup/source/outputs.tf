
output "account_id" {
  value = data.aws_caller_identity.main.account_id
}

output "instance_id" {
  value = aws_instance.main.id
}

output "vault_arn" {
  value = aws_backup_vault.main.arn
}
