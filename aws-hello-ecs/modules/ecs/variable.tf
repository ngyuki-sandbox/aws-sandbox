
variable "name" {}
variable "subnet_ids" {}
variable "security_group_ids" {}
variable "assign_public_ip" { default = true }
variable "target_group_arn" {}

variable "chatbot_topic_arn" {
  type    = string
  default = null
}
