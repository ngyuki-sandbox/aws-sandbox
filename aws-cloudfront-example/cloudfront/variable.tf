
variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "acm_domain_name" {
  type = string
}

variable "cf_domain_name" {
  type = string
}

variable "allow_cf_ips" {
  type = list(string)
}

variable "alb_dns_name" {
  type = string
}

variable "s3_domain_name" {
  type = string
}

variable "lambda_domain_name" {
  type = string
}
