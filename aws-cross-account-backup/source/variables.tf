
variable "name" {
  type = string
}

variable "backup_tag_key" {
  type = string
}

variable "schedule" {
  type = string
}

variable "retention_days" {
  type = number
}

variable "destination_account_id" {
  type = string
}

variable "destination_vault_arns" {
  type = set(string)
}
