
output "cloudfronturl_" {
  value = "https://${var.cf_domain_name}/"
}

output "ec2_instance_id" {
  value = module.alb.instance_id
}
