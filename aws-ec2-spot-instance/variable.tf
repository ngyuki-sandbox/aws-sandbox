
variable "project" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "allowed_account_ids" {
  type = list(string)
}
