
resource "aws_dms_replication_instance" "main" {
  replication_instance_id     = "dms"
  replication_instance_class  = "dms.t3.medium"
  engine_version              = "3.4.7"
  multi_az                    = false
  allocated_storage           = 50
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  publicly_accessible         = false
  vpc_security_group_ids      = var.vpc_security_group_ids
  auto_minor_version_upgrade  = true
  apply_immediately           = true
}

resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_id          = "dms"
  replication_subnet_group_description = "dms"
  subnet_ids                           = data.aws_db_subnet_group.main.subnet_ids
}

resource "aws_dms_endpoint" "source" {
  endpoint_id   = "dms-source"
  endpoint_type = "source"
  engine_name   = "aurora"
  server_name   = data.aws_rds_cluster.source.endpoint
  port          = data.aws_rds_cluster.source.port
  username      = var.db_username
  password      = var.db_password
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = "dms-target"
  endpoint_type = "target"
  engine_name   = "aurora"
  server_name   = aws_rds_cluster.target.endpoint
  port          = aws_rds_cluster.target.port
  username      = var.db_username
  password      = var.db_password
}

resource "aws_dms_replication_task" "main" {
  replication_task_id      = "dms"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  migration_type           = "full-load"
  start_replication_task   = false

  replication_task_settings = jsonencode({
    FullLoadSettings = {
      TargetTablePrepMode = "TRUNCATE_BEFORE_LOAD"
    }
    Logging = {
      EnableLogging = true
    }
  })

  table_mappings = jsonencode(
    {
      rules = [
        {
          rule-type   = "selection"
          rule-id     = "1"
          rule-name   = "1"
          rule-action = "include"
          object-locator = {
            schema-name = "test"
            table-name  = "t_user"
          }
        },
        {
          rule-type   = "transformation"
          rule-id     = "100"
          rule-name   = "100"
          rule-target = "column"
          rule-action = "remove-column"
          object-locator = {
            schema-name = "test"
            table-name  = "t_user"
            column-name = "password_hash"
          }
        },
        {
          "rule-type" : "transformation",
          "rule-id" : "200",
          "rule-name" : "200",
          "rule-target" : "column",
          "rule-action" : "add-column",
          "object-locator" : {
            "schema-name" : "test"
            "table-name" : "t_user"
          },
          "value" : "email",
          "data-type" : {
            "type" : "string",
            "length" : "255"
          },
          "expression" : "hash_sha256($user_id)"
          //"expression" : "hash_sha256($email)" // Failed to init column calculation expression 'hash_sha256($email)' [20014]  (manipulator.c:1215)
        },
      ]
    }
  )
}
