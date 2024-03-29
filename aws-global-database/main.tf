
resource "aws_rds_global_cluster" "main" {
  global_cluster_identifier = var.name
  engine                    = var.engine
  engine_version            = var.engine_version
  database_name             = var.database_name
  deletion_protection       = false
  force_destroy             = true
}

module "tokyo" {
  providers = { aws = aws.tokyo }
  source    = "./region"

  name                      = "${var.name}-tokyo"
  engine                    = var.engine
  engine_version            = var.engine_version
  master_username           = var.master_username
  master_password           = var.master_password
  database_name             = var.database_name
  instance_class            = var.instance_class
  instance_count            = 1
  ec2_authorized_keys       = var.ec2_authorized_keys
  global_cluster_identifier = aws_rds_global_cluster.main.id
}

module "osaka" {
  providers = { aws = aws.osaka }
  source    = "./region"

  name                      = "${var.name}-osaka"
  engine                    = var.engine
  engine_version            = var.engine_version
  master_username           = null
  master_password           = null
  database_name             = null
  instance_class            = var.instance_class
  instance_count            = 1
  ec2_authorized_keys       = var.ec2_authorized_keys
  global_cluster_identifier = aws_rds_global_cluster.main.id

  depends_on = [
    module.tokyo.rds_cluster,
  ]
}

output "tokyo" {
  value = module.tokyo.output
}

output "osaka" {
  value = module.osaka.output
}
