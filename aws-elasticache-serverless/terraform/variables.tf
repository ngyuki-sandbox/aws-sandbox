
variable "name" {
  type = string
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
