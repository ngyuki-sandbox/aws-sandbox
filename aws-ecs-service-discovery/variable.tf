
variable "name" {
  type    = string
  default = "ecs-service-connect"
}

variable "authorized_keys" {
  type = list(string)
}
