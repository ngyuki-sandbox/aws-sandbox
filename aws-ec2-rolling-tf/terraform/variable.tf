################################################################################
# variable
################################################################################

variable "ami" {
  type = string
  default = null
}


variable "wait" {
  type    = number
  default = 300
}

variable "authorized_keys" {
  type = list(string)
}

variable "allow_ssh_ingress" {
  type = list(string)
}
