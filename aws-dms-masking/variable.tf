
variable "db_cluster_identifier" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "db_cluster_parameter_group_name" {
  type = string
}

variable "db_parameter_group_name" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}
