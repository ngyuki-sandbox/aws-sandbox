
module "vpc" {
  source = "./vpc"
  name   = var.name
}

module "ecs" {
  source = "./ecs"
  name   = var.name
}

module "event" {
  source              = "./event"
  name                = var.name
  ecs_cluster_arn     = module.ecs.cluster_arn
  task_definition_arn = module.ecs.task_definition_arn
  subnet_ids          = module.vpc.subnet_ids
  security_group_ids  = [module.vpc.security_group_id]
}

module "scheduler" {
  source              = "./scheduler"
  name                = var.name
  ecs_cluster_arn     = module.ecs.cluster_arn
  task_definition_arn = module.ecs.task_definition_arn
  subnet_ids          = module.vpc.subnet_ids
  security_group_ids  = [module.vpc.security_group_id]
}
