
resource "aws_service_discovery_private_dns_namespace" "main" {
  name = var.dns_name
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "main" {
  name = var.name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
