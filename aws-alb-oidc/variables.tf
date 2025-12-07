
variable "name" {
  type = string
}

variable "zone_name" {
  type = string
}

variable "alb_domain_name" {
  type = string
}

variable "oidc_client_id" {
  type = string
}

variable "oidc_client_secret" {
  type      = string
  sensitive = true
}

variable "oidc_issuer" {
  type = string
}

variable "oidc_authorization_endpoint" {
  type = string
}

variable "oidc_token_endpoint" {
  type = string
}

variable "oidc_user_info_endpoint" {
  type = string
}

variable "oidc_scope" {
  type = string
}
