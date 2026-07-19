
variable "name" {
  type = string
}

variable "allow_ips" {
  type = list(string)
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}
