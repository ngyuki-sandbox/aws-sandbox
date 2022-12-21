
resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "redis22" {
  description          = "redis22"
  replication_group_id = "redis22"
  node_type            = "cache.t3.micro"
  engine               = "redis"
  engine_version       = "6.2"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = var.security_group_ids
  apply_immediately    = true

  multi_az_enabled           = true
  automatic_failover_enabled = true
  num_node_groups            = 2
  replicas_per_node_group    = 1

}

resource "aws_elasticache_replication_group" "redis11" {
  description          = "redis11"
  replication_group_id = "redis11"
  node_type            = "cache.t3.micro"
  engine               = "redis"
  engine_version       = "6.2"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = var.security_group_ids
  apply_immediately    = true

  multi_az_enabled           = true
  automatic_failover_enabled = true
  replicas_per_node_group    = 1

}


resource "aws_elasticache_replication_group" "redis02" {
  description          = "redis02"
  replication_group_id = "redis02"
  node_type            = "cache.t3.micro"
  engine               = "redis"
  engine_version       = "6.2"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = var.security_group_ids
  apply_immediately    = true

  multi_az_enabled           = true
  automatic_failover_enabled = true
  num_cache_clusters         = 2

}
