
variable "domain" {}

data "aws_route53_zone" "this" {
  name = var.domain
}

output "zone_id" {
  value = data.aws_route53_zone.this.id
}
