
data "aws_caller_identity" "source" {
  provider = aws.source
}

data "aws_caller_identity" "destination" {
  provider = aws.destination
}

module "mgmt" {
  source    = "./mgmt"
  providers = { aws = aws.mgmt }
}

module "source" {
  source    = "./source"
  providers = { aws = aws.source }

  name                   = var.name
  backup_tag_key         = var.backup_tag_key
  schedule               = "cron(50 22 ? * * *)"
  retention_days         = 10
  destination_account_id = data.aws_caller_identity.destination.account_id
  destination_vault_arns = [
    module.destination_vault_lock.vault_arn,
    module.destination_logically_air_gapped.vault_arn,
  ]
}

module "destination_vault_lock" {
  source    = "./destination/vault-lock"
  providers = { aws = aws.destination }

  name                = "${var.name}-vault-lock"
  source_account_id   = data.aws_caller_identity.source.account_id
  changeable_for_days = 3
  min_retention_days  = 3
  max_retention_days  = 10
}

module "destination_logically_air_gapped" {
  source    = "./destination/logically-air-gapped"
  providers = { aws = aws.destination }

  name               = "${var.name}-logically-air-gapped"
  source_account_id  = data.aws_caller_identity.source.account_id
  min_retention_days = 7
  max_retention_days = 10
}
