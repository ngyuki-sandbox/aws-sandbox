
provider "aws" {
  region = var.region
  default_tags {
    tags = var.default_tags
  }
}

module "vpc" {
  source = "./modules/vpc"
  name   = var.name
}

module "sqs" {
  source = "./modules/sqs"
  name   = var.name
}

module "ecs" {
  source             = "./modules/ecs"
  name               = var.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = module.vpc.security_group_ids

  environments = {
    SQS_QUEUE_URL = module.sqs.url
  }
}

module "autoscale" {
  source           = "./modules/autoscale"
  name             = var.name
  sqs_queue_name   = module.sqs.name
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
}

output "sqs_queue_url" {
  value = module.sqs.url
}
