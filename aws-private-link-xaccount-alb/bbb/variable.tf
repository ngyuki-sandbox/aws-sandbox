
variable "name" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

variable "allowed_principals" {
  type = list(string)
}
