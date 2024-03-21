
variable "default_tags" {
  type = map(string)
}

variable "name" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "database_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "ec2_authorized_keys" {
  type = list(string)
}
