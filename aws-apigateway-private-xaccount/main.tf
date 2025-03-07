
provider "aws" {
  region = var.region
  default_tags {
    tags = var.defailt_tags
  }
}

provider "aws" {
  alias = "xxx"
  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform"
  }
  default_tags {
    tags = var.defailt_tags
  }
}

module "acm" {
  source    = "./acm"
  providers = { aws = aws }

  zone_name   = var.zone_name
  domain_name = var.acm_domain_name
}

module "apigw" {
  source    = "./apigw"
  providers = { aws = aws }

  name            = var.name
  stage_name      = "dev"
  vpce_ids        = [module.aaa.vpce_id, module.xxx.vpce_id]
  certificate_arn = module.acm.certificate_arn
  domain_name     = var.api_domain_name
}

module "aaa" {
  source    = "./endpoint"
  providers = { aws = aws }

  name                  = "${var.name}-aaa"
  zone_name             = var.zone_name
  domain_name           = var.api_domain_name
  apigw_domain_name_arn = module.apigw.domain_name_arn
}

module "xxx" {
  source    = "./endpoint"
  providers = { aws = aws.xxx }

  name                  = "${var.name}-xxx"
  zone_name             = var.zone_name
  domain_name           = var.api_domain_name
  apigw_domain_name_arn = module.apigw.domain_name_arn
}

output "invoke_url" {
  value = module.apigw.invoke_url
}

output "aaa" {
  value = module.aaa.instance_id
}

output "xxx" {
  value = module.xxx.instance_id
}

###

resource "aws_ram_resource_share" "main" {
  name                      = "test"
  allow_external_principals = true
}

resource "aws_ram_resource_association" "main" {
  resource_arn       = module.apigw.domain_name_arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

resource "aws_ram_principal_association" "main" {
  resource_share_arn = aws_ram_resource_share.main.arn
  principal          = data.aws_caller_identity.xxx.account_id
}

data "aws_caller_identity" "xxx" {
  provider = aws.xxx
}

resource "aws_ram_resource_share_accepter" "main" {
  provider  = aws.xxx
  share_arn = aws_ram_principal_association.main.resource_share_arn
}
