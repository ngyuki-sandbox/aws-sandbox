module "sns" {
  source          = "./sns"
  name            = "${var.name}-sns"
  region          = var.region
  assume_role_arn = var.sns_assume_role_arn

  sqs_queue_arn = module.sqs.sqs_queue_arn
}

module "sqs" {
  source          = "./sqs"
  name            = "${var.name}-sqs"
  region          = var.region
  assume_role_arn = var.sqs_assume_role_arn

  sns_topic_arn = module.sns.sns_topic_arn
}
