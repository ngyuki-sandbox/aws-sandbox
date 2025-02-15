
variable "name" {
  type = string
}

variable "assume_role_arn" {
  type = string
}

variable "region" {
  type = string
}

variable "defailt_tags" {
  type = map(string)
}
