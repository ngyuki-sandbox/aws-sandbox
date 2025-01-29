
module "vpc" {
  source = "../../modules/defaultvpc"
  name   = var.name
}

module "elb" {
  source             = "../../modules/elb"
  name               = var.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.vpc.security_group_id]
}

module "ecs" {
  source             = "../../modules/ecs"
  name               = var.name
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.vpc.security_group_id]
  target_group_arn   = module.elb.target_group_arn
  chatbot_topic_arn  = one(data.aws_sns_topic.chatbot[*].arn)

  // TargetGroup が LB にアタッチされたあとでなければならない
  depends_on = [module.elb]
}

data "aws_sns_topic" "chatbot" {
  count = var.chatbot_topic_name != null ? 1 : 0
  name  = var.chatbot_topic_name
}
