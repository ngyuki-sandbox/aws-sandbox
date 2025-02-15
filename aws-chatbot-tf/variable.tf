
variable "name" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "allowed_account_ids" {
  type = list(string)
}

variable "region" {
  type = string
}

variable "workspace_id" {
  type = string
}

variable "channel_id" {
  type = string
}

variable "channel_name" {
  type = string
}
