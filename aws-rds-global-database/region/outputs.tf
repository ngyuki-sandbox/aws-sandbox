
output "instance_id" {
  value = aws_instance.main.id
}

output "rds_cluster" {
  value = aws_rds_cluster.main.id
}

output "rds_cluster_arn" {
  value = aws_rds_cluster.main.arn
}
