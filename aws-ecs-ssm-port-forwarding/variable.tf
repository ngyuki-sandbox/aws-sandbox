
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "allowed_account_ids" {
  type = list(string)
}

variable "default_tags" {
  type = map(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "rds_host" {
  type = string
}
