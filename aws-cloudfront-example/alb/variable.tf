
variable "name" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

variable "allow_ssh_ips" {
  type = list(string)
}
