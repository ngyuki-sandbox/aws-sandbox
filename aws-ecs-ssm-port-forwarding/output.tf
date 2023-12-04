
output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "container_name" {
  value = jsondecode(aws_ecs_task_definition.main.container_definitions)[0].name
}

output "rds_host" {
  value = var.rds_host
}
