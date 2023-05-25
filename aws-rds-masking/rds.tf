
data "aws_db_cluster_snapshot" "source" {
  db_cluster_identifier = var.rds_source_cluster_identifier
  snapshot_type         = "automated"
  most_recent           = true
}

resource "aws_rds_cluster" "main" {
  cluster_identifier_prefix       = format("%s-", var.rds_source_cluster_identifier)
  engine                          = var.rds_engine
  engine_version                  = var.rds_engine_version
  db_subnet_group_name            = var.rds_subnet_group_name
  db_cluster_parameter_group_name = var.rds_cluster_parameter_group_name
  vpc_security_group_ids          = var.rds_security_group_ids
  snapshot_identifier             = data.aws_db_cluster_snapshot.source.id
  skip_final_snapshot             = true
}

resource "aws_rds_cluster_instance" "main" {
  identifier_prefix       = format("%s-", aws_rds_cluster.main.cluster_identifier)
  cluster_identifier      = aws_rds_cluster.main.cluster_identifier
  engine                  = var.rds_engine
  instance_class          = var.rds_instance_class
  db_parameter_group_name = var.rds_instance_parameter_group_name
}

data "aws_db_subnet_group" "main" {
  name = var.rds_subnet_group_name
}
