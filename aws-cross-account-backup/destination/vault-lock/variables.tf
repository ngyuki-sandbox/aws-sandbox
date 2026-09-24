
variable "name" {
  type = string
}

variable "source_account_id" {
  type = string
}

variable "changeable_for_days" {
  type = number
}

variable "min_retention_days" {
  type = number
}

variable "max_retention_days" {
  type = number
}
