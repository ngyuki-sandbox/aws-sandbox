
locals {
  rds_cluster_identifier = var.name
  rds_cloudwatch_logs_exports = toset([
    "error",
    "slowquery",
    "audit",
    "general",
  ])
}

resource "aws_rds_cluster" "main" {
  cluster_identifier              = local.rds_cluster_identifier
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.10.3"
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_db_subnet_group.main.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.id
  vpc_security_group_ids          = [aws_security_group.rds.id]
  apply_immediately               = true
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = local.rds_cloudwatch_logs_exports

  depends_on = [
    aws_cloudwatch_log_group.aurora_mysql,
    aws_cloudwatch_log_transformer.aurora_mysql_audit,
  ]
}

resource "aws_rds_cluster_instance" "main" {
  identifier_prefix       = "${var.name}-logs"
  cluster_identifier      = aws_rds_cluster.main.id
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
    name         = "slow_query_log"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "long_query_time"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_slow_admin_statements"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_queries_not_using_indexes"
    value        = "0"
    apply_method = "immediate"
  }

  parameter {
    name         = "server_audit_logging"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "server_audit_events"
    value        = "CONNECT,QUERY_DDL,QUERY_DCL"
    apply_method = "immediate"
  }

  parameter {
    name         = "general_log"
    value        = "0"
    apply_method = "immediate"
  }
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.name}-instance"
  description = "${var.name}-instance"
  family      = "aurora-mysql8.0"
}

resource "aws_cloudwatch_log_group" "aurora_mysql" {
  for_each = local.rds_cloudwatch_logs_exports

  name              = "/aws/rds/cluster/${local.rds_cluster_identifier}/${each.value}"
  log_group_class   = "STANDARD"
  retention_in_days = 3
  skip_destroy      = true

  tags = {
    Name = "${local.rds_cluster_identifier}-${each.value}"
  }
}

resource "aws_cloudwatch_log_transformer" "aurora_mysql_audit" {
  log_group_arn = aws_cloudwatch_log_group.aurora_mysql["audit"].arn

  transformer_config {
    csv {
      source          = "@message"
      delimiter       = ","
      quote_character = "'"

      columns = [
        "timestamp",
        "serverhost",
        "username",
        "host",
        "connectionid",
        "queryid",
        "operation",
        "database",
        "object",
        "retcode",
      ]
    }
  }

  transformer_config {
    type_converter {
      entry {
        key  = "connectionid"
        type = "integer"
      }

      entry {
        key  = "queryid"
        type = "integer"
      }

      entry {
        key  = "retcode"
        type = "integer"
      }
    }
  }

  transformer_config {
    add_keys {
      entry {
        key                 = "log_type"
        value               = "aurora_mysql_audit"
        overwrite_if_exists = false
      }

      entry {
        key                 = "db_cluster"
        value               = local.rds_cluster_identifier
        overwrite_if_exists = false
      }
    }
  }
}
