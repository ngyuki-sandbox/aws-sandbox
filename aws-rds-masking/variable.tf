
variable "rds_source_cluster_identifier" {
  type = string
}

variable "rds_zone_name" {
  type = string
}

variable "rds_dns_name" {
  type = string
}

variable "rds_ro_dns_name" {
  type = string
}

variable "rds_engine" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_cluster_parameter_group_name" {
  type = string
}

variable "rds_instance_parameter_group_name" {
  type = string
}

variable "rds_subnet_group_name" {
  type = string
}

variable "rds_security_group_ids" {
  type = list(string)
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type = string
}

variable "rds_database" {
  type = string
}

variable "lambda_security_group_ids" {
  type = list(string)
}

variable "sqls" {
  type = list(string)
}
