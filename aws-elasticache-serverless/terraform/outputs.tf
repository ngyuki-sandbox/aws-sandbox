
output "elasticache_host" {
  value = local.elasticache_host
}

output "elasticache_port" {
  value = local.elasticache_port
}

output "ecr_repository_name" {
  value = aws_ecr_repository.main.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.main.family
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

output "subnet_ids" {
  value = join(",", var.subnet_ids)
}

output "security_group_id" {
  value = var.security_group_ids[0]
}
