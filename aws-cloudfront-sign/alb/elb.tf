
resource "aws_lb" "main" {
  name               = var.name
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.main.id]
  subnets            = data.aws_subnets.main.ids
}

resource "aws_lb_target_group" "main" {
  name                 = var.name
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = "10"
  vpc_id               = data.aws_vpc.main.id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTPS"
  port              = 443
  certificate_arn   = aws_acm_certificate.main.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}
