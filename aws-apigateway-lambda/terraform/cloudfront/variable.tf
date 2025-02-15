
variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "cf_domain_name" {
  type = string
}

variable "origin_domain_name" {
  type = string
}

variable "allow_ips" {
  type = list(string)
}
