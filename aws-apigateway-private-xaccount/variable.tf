
variable "name" {
  type = string
}

variable "assume_role_arn" {
  type = string
}

variable "region" {
  type = string
}

variable "defailt_tags" {
  type = map(string)
}

variable "zone_name" {
  type = string
}

variable "acm_domain_name" {
  type = string
}

variable "api_domain_name" {
  type = string
}
