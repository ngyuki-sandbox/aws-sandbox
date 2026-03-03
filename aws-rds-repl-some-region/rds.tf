
resource "aws_rds_cluster" "primary" {
  cluster_identifier              = var.name
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.10.3"
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_db_subnet_group.main.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.id
  vpc_security_group_ids          = [aws_security_group.rds.id]
  apply_immediately               = true
  skip_final_snapshot             = true
}

resource "aws_rds_cluster_instance" "primary" {
  identifier_prefix       = "${var.name}-"
  cluster_identifier      = aws_rds_cluster.primary.id
  engine                  = "aurora-mysql"
  instance_class          = "db.t3.medium"
  db_parameter_group_name = aws_db_parameter_group.main.id
  publicly_accessible     = true
}

resource "aws_db_subnet_group" "main" {
  name       = var.name
  subnet_ids = data.aws_subnets.main.ids
}

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.name}-cluster"
  description = "${var.name}-cluster"
  family      = "aurora-mysql8.0"

  parameter {
    name         = "binlog_format"
    value        = "row"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "aurora_enhanced_binlog"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "binlog_backup"
    value        = "0"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "binlog_replication_globaldb"
    value        = "0"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "binlog-do-db"
    value        = "test"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "replicate-do-db"
    value        = "test"
    apply_method = "immediate"
  }
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.name}-instance"
  description = "${var.name}-instance"
  family      = "aurora-mysql8.0"
}
