
variable "allow_ssh_ingress" {
  type = list(string)
}

variable "allow_rds_ingress" {
  type = list(string)
}

variable "alice_role_arn" {
  type = string
}

variable "bob_role_arn" {
  type = string
}
