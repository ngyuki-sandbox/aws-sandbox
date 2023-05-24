
data "aws_rds_cluster" "source" {
  cluster_identifier = var.db_cluster_identifier
}

data "aws_db_cluster_snapshot" "snapshot" {
  db_cluster_identifier = var.db_cluster_identifier
  snapshot_type         = "automated"
  most_recent           = true
}

resource "aws_rds_cluster" "target" {
  cluster_identifier              = "dms"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.mysql_aurora.2.11.1"
  db_subnet_group_name            = var.db_subnet_group_name
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name
  vpc_security_group_ids          = var.vpc_security_group_ids
  snapshot_identifier             = data.aws_db_cluster_snapshot.snapshot.id
}

resource "aws_rds_cluster_instance" "target" {
  identifier              = "dms-01"
  cluster_identifier      = aws_rds_cluster.target.id
  engine                  = "aurora-mysql"
  instance_class          = "db.t3.small"
  db_parameter_group_name = var.db_parameter_group_name
}

data "aws_db_subnet_group" "main" {
  name = var.db_subnet_group_name
}
