
resource "aws_vpc_endpoint_service" "main" {
  acceptance_required        = false
  allowed_principals         = var.allowed_principals
  network_load_balancer_arns = [aws_lb.nlb.arn]
}
