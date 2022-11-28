
resource "aws_db_instance" "rds" {
  identifier                          = "${var.prefix}-rds"
  engine                              = "postgres"
  engine_version                      = "14"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  db_subnet_group_name                = aws_db_subnet_group.rds.id
  parameter_group_name                = aws_db_parameter_group.rds.id
  vpc_security_group_ids              = [aws_security_group.rds.id]
  db_name                             = "test"
  username                            = "postgres"
  password                            = "password"
  multi_az                            = false
  auto_minor_version_upgrade          = false
  publicly_accessible                 = false
  iam_database_authentication_enabled = true
  skip_final_snapshot                 = true
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.prefix}-rds"
  subnet_ids = values(data.aws_subnet.subnets).*.id
}

resource "aws_db_parameter_group" "rds" {
  name        = "${var.prefix}-rds"
  description = "${var.prefix}-rds"
  family      = "postgres14"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pglogical"
    apply_method = "pending-reboot"
  }
}
