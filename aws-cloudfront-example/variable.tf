
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

variable "allow_ssh_ips" {
  type = list(string)
}

variable "allow_cf_ips" {
  type = list(string)
}

variable "authorized_keys" {
  type = list(string)
}

variable "zone_name" {
  type = string
}

variable "cf_domain_name" {
  type = string
}
