
resource "aws_lb" "main" {
  name               = var.name
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "main" {
  name                 = var.name
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = "10"
  vpc_id               = var.vpc_id

  health_check {
    protocol            = "HTTP"
    port                = 80
    path                = "/"
    matcher             = "200-399"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}
