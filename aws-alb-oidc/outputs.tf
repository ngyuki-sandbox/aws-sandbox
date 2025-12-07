
output "alb_url" {
  value = "https://${var.alb_domain_name}"
}

output "oidc_redirect_uri" {
  value = "https://${var.alb_domain_name}/oauth2/idpresponse"
}
