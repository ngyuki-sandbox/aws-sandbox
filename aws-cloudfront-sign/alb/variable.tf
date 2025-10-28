
variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "acm_domain_name" {
  type = string
}

variable "alb_domain_name" {
  type = string
}

variable "authorized_keys" {
  type = list(string)
}

variable "allow_ssh_ips" {
  type = list(string)
}

variable "key_pair_ids" {
  type = object({
    rsa   = string
    ecdsa = string
  })
}

variable "private_keys" {
  type = object({
    rsa   = string
    ecdsa = string
  })
}
