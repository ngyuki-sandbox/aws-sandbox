
resource "aws_rds_cluster" "main" {
  cluster_identifier              = var.name
  engine                          = var.engine
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  global_cluster_identifier       = var.global_cluster_identifier
  db_subnet_group_name            = aws_db_subnet_group.main.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.id
  vpc_security_group_ids          = [aws_security_group.main.id]
  backup_retention_period         = 7
  preferred_backup_window         = "20:00-21:00" # 5:00-6:00 JST
  skip_final_snapshot             = true

  lifecycle {
    ignore_changes = [
      replication_source_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "main" {
  count                        = var.instance_count
  engine                       = var.engine
  engine_version               = var.engine_version
  identifier_prefix            = "${var.name}-"
  cluster_identifier           = aws_rds_cluster.main.id
  instance_class               = var.instance_class
  db_subnet_group_name         = aws_db_subnet_group.main.id
  db_parameter_group_name      = aws_db_parameter_group.main.id
  auto_minor_version_upgrade   = false
  publicly_accessible          = false
  preferred_maintenance_window = "sat:14:00-sat:16:00" # 23:00- JST
}

resource "aws_db_subnet_group" "main" {
  name       = var.name
  subnet_ids = sort(data.aws_subnets.main.ids)
}

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.name}-aurora-postgresql14"
  description = "${var.name}-aurora-postgresql14"
  family      = "aurora-postgresql14"
  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "immediate"
  }
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.name}-aurora-postgresql14"
  description = "${var.name}-aurora-postgresql14"
  family      = "aurora-postgresql14"
  parameter {
    name         = "track_activity_query_size"
    value        = "1048576"
    apply_method = "pending-reboot"
  }
  lifecycle {
    create_before_destroy = true
  }
}
