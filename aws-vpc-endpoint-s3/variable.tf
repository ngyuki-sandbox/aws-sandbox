
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "default_tags" {
  type = map(string)
}


variable "ssh_authorized_keys" {
  type = list(string)
}
