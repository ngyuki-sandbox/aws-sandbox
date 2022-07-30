################################################################################
# variable
################################################################################

variable "name" {}
variable "ami_id" {}
variable "wait" {}
variable "subnet_id" {}
variable "vpc_security_group_ids" {}
variable "target_group_arn" {}
variable "authorized_keys" {}

locals {
  name = var.name
}
