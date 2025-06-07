
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "aurora_cluster_id" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_services" {
  type = list(string)
}
