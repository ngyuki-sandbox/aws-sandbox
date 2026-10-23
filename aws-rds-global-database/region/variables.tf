
variable "name" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "package_name" {
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
  type = number
}

variable "global_cluster_identifier" {
  type    = string
  default = null
}
