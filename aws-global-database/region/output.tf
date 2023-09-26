
data "aws_region" "current" {}

output "output" {
  value = {
    region      = data.aws_region.current.name
    instance_id = aws_instance.server.id
  }
}

output "rds_cluster" {
  value = aws_rds_cluster.main.id
}
