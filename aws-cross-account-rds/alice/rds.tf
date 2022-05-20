################################################################################
# RDS
################################################################################

locals {
  rds_cluster_identifier = "${local.env.tag}-rds"
}

resource "aws_rds_cluster" "rds" {
  cluster_identifier                  = local.rds_cluster_identifier
  engine                              = "aurora-postgresql"
  engine_version                      = "13.6"
  database_name                       = local.env.rds_database
  master_username                     = local.env.rds_username
  master_password                     = local.env.rds_password
  db_subnet_group_name                = aws_db_subnet_group.rds.id
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.rds.id
  vpc_security_group_ids              = [aws_security_group.rds.id]
  backup_retention_period             = local.env.rds_retention_period
  preferred_backup_window             = local.env.rds_backup_window
  preferred_maintenance_window        = local.env.rds_maintenance_window
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  skip_final_snapshot                 = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
}

resource "aws_rds_cluster_instance" "rds" {
  identifier                 = "${local.env.tag}-rds-01"
  cluster_identifier         = aws_rds_cluster.rds.id
  engine                     = "aurora-postgresql"
  engine_version             = "13.6"
  instance_class             = local.env.rds_instance_type
  db_parameter_group_name    = aws_db_parameter_group.rds.id
  auto_minor_version_upgrade = false
  publicly_accessible        = false
}

resource "aws_db_subnet_group" "rds" {
  name       = "${local.env.tag}-rds"
  subnet_ids = [for x in aws_subnet.subnets : x.id]
}

resource "aws_rds_cluster_parameter_group" "rds" {
  name        = "${local.env.tag}-rds-cluster"
  description = "${local.env.tag}-rds-cluster"
  family      = "aurora-postgresql13"
}

resource "aws_db_parameter_group" "rds" {
  name        = "${local.env.tag}-rds-instance"
  description = "${local.env.tag}-rds-instance"
  family      = "aurora-postgresql13"
}

output "rds" {
  value = {
    rw = aws_rds_cluster.rds.endpoint
    ro = aws_rds_cluster.rds.reader_endpoint
  }
}
