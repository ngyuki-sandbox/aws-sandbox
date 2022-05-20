variable "assume_role_arn" {}

variable "env" {}
variable "peer" {}

locals {
  env  = var.env
  peer = var.peer
}
