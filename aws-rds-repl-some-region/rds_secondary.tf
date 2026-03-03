
resource "aws_rds_cluster" "secondary" {
  count = var.skip_secondary ? 0 : 1

  cluster_identifier              = "${var.name}-secondary"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.10.3"
  master_username                 = null # レプリカ側は username,password を指定できない
  master_password                 = null
  db_subnet_group_name            = aws_db_subnet_group.main.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.id
  vpc_security_group_ids          = [aws_security_group.rds.id]
  apply_immediately               = true
  skip_final_snapshot             = true
  replication_source_identifier   = aws_rds_cluster.primary.arn
}

resource "aws_rds_cluster_instance" "secondary" {
  count = length(aws_rds_cluster.secondary)

  identifier_prefix          = "${var.name}-secondary-"
  cluster_identifier         = aws_rds_cluster.secondary[count.index].id
  engine                     = "aurora-mysql"
  instance_class             = "db.t3.medium"
  db_parameter_group_name    = aws_db_parameter_group.main.id
  auto_minor_version_upgrade = false
  publicly_accessible        = true
}
