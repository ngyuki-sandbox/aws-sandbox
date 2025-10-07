
# resource "aws_elasticache_serverless_cache" "main" {
#   name                 = var.name
#   engine               = "valkey"
#   major_engine_version = "8"
#   security_group_ids   = var.security_group_ids
#   subnet_ids           = var.subnet_ids

#   cache_usage_limits {
#     data_storage {
#       minimum = 1
#       unit = "GB"
#     }
#     ecpu_per_second {
#       minimum = 1000
#       maximum = 100000
#     }
#   }
# }

# locals {
#   elasticache_host = aws_elasticache_serverless_cache.main.endpoint[0].address
#   elasticache_port = aws_elasticache_serverless_cache.main.endpoint[0].port
#   elasticache_tls  = true
# }

###

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.name}-cl"
  description                = "${var.name}-cl"
  engine                     = "valkey"
  engine_version             = "8.0"
  node_type                  = "cache.r7g.large"
  parameter_group_name       = "default.valkey8.cluster.on"
  cluster_mode               = "enabled"
  num_node_groups            = 3
  replicas_per_node_group    = 1
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = var.security_group_ids
  maintenance_window         = "sun:19:00-sun:21:00" # JST (mon:04:00-mon:06:00)
  automatic_failover_enabled = true
  multi_az_enabled           = true
  auto_minor_version_upgrade = true
  at_rest_encryption_enabled = true
  apply_immediately          = true
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name}-cl"
  subnet_ids = var.subnet_ids
}

locals {
  elasticache_host = aws_elasticache_replication_group.main.configuration_endpoint_address
  elasticache_port = 6379
  elasticache_tls  = false
}
