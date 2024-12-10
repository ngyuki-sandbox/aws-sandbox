
module "vpc" {
  source = "./modules/defaultvpc"
  name   = var.name
}

module "ecs" {
  source             = "./modules/ecs"
  name               = var.name
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.vpc.security_group_id]
}

module "ec2" {
  source             = "./modules/ec2"
  name               = var.name
  subnet_id          = module.vpc.subnet_ids[0]
  security_group_ids = [module.vpc.security_group_id]
  authorized_keys    = var.authorized_keys
}

output "instance_id" {
  value = module.ec2.instance_id
}
