
variable "name" {
  type = string
}

variable "allowed_account_ids" {
  type = list(string)
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

variable "org_domain_name" {
  type = string
}

variable "cf_domain_name" {
  type = string
}

variable "allow_ips" {
  type = list(string)
}
