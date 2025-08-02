
module "vpc" {
  source = "./vpc"
  name   = var.name
}

module "elb" {
  source             = "./elb"
  name               = var.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.vpc.security_group_id]
}

module "ecs" {
  source             = "./ecs"
  name               = var.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.vpc.security_group_id]
  target_group_arns  = module.elb.target_group_arns
  listener_rule_arn  = module.elb.listener_rule_arn
}
