################################################################################
# variable
################################################################################

variable "name" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

variable "allow_ssh_ingress" {
  type = list(string)
}
