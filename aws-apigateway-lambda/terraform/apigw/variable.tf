
variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "org_domain_name" {
  type = string
}

variable "cf_domain_name" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "allow_ips" {
  type = list(string)
}
