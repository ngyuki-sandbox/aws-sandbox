
variable "name" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

variable "zone_name" {
  type = string
}

variable "vpc_service_name" {
  type = string
}

variable "vpc_endpoint_type" {
  type = string
}
