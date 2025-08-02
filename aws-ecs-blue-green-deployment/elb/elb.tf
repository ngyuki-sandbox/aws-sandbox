
resource "aws_lb" "main" {
  name               = var.name
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "403"
      content_type = "text/plain"
      message_body = "Forbidden"
    }
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.main[0].arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.main[1].arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_target_group" "main" {
  count = 2

  name                 = "${var.name}-${count.index}"
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
