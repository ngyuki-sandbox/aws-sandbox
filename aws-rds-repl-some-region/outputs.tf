
output "rds_primary" {
  value = aws_rds_cluster.primary.endpoint
}

output "rds_secondary" {
  value = length(aws_rds_cluster.secondary) == 0 ? null : one(aws_rds_cluster.secondary[*].endpoint)
}
