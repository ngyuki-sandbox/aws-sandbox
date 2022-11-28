
resource "aws_rds_cluster" "aurora" {
  cluster_identifier                  = "${var.prefix}-aurora"
  engine                              = "aurora-postgresql"
  engine_version                      = "14"
  database_name                       = "test"
  master_username                     = "postgres"
  master_password                     = "password"
  db_subnet_group_name                = aws_db_subnet_group.aurora.id
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.aurora.id
  vpc_security_group_ids              = [aws_security_group.aurora.id]
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  skip_final_snapshot                 = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier_prefix          = "${var.prefix}-aurora-"
  engine                     = "aurora-postgresql"
  cluster_identifier         = aws_rds_cluster.aurora.id
  instance_class             = "db.t3.medium"
  db_subnet_group_name       = aws_db_subnet_group.aurora.id
  db_parameter_group_name    = aws_db_parameter_group.aurora.id
  auto_minor_version_upgrade = false
  publicly_accessible        = false
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.prefix}-aurora"
  subnet_ids = values(data.aws_subnet.subnets).*.id
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${var.prefix}-aurora-cluster"
  description = "${var.prefix}-aurora-cluster"
  family      = "aurora-postgresql14"

  # parameter {
  #   name         = "rds.logical_replication"
  #   value        = "1"
  #   apply_method = "pending-reboot"
  # }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pglogical"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora" {
  name        = "${var.prefix}-aurora-db"
  description = "${var.prefix}-aurora-db"
  family      = "aurora-postgresql14"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pglogical"
    apply_method = "pending-reboot"
  }
}

resource "aws_cloudwatch_log_group" "aurora" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora.cluster_identifier}/postgresql"
  retention_in_days = 7
}
