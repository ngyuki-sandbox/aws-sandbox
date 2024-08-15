
variable "name" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "database_name" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "instance_count" {
  type = string
}

variable "global_cluster_identifier" {
  type    = string
  default = null
}

variable "ec2_authorized_keys" {
  type = list(string)
}
