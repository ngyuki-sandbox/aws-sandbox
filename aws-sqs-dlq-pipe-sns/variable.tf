
variable "project" {
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

variable "email" {
  type = string
}
