
output "cluster" {
  value = aws_ecs_cluster.main.name
}

output "service" {
  value = aws_ecs_service.main.name
}
