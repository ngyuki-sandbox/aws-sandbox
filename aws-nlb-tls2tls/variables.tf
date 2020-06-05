################################################################################
# variables


variable profile {}
variable region {}
variable key_name {}
variable tag {}
variable zone_domain {}
variable service_domain {}
variable server_domain {}
variable trusted_cidr {}

locals {
  profile        = var.profile
  region         = var.region
  key_name       = var.key_name
  tag            = var.tag
  zone_domain    = var.zone_domain
  service_domain = var.service_domain
  server_domain  = var.server_domain
  trusted_cidr   = var.trusted_cidr
}
