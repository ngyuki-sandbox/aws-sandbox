
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

module "apigw" {
  source    = "./apigw"
  providers = { aws = aws }

  name       = var.name
  stage_name = "dev"
  vpc_ids    = [module.aaa.vpc_id, module.xxx.vpc_id]
  vpce_ids   = [module.aaa.vpce_id, module.xxx.vpce_id]
}

module "aaa" {
  source    = "./endpoint"
  providers = { aws = aws }

  name = "${var.name}-aaa"
}

module "xxx" {
  source    = "./endpoint"
  providers = { aws = aws.xxx }

  name = "${var.name}-xxx"
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
