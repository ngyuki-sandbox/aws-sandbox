
resource "aws_lb" "main" {
  name                       = var.name
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.main[*].id
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "main" {
  for_each = toset(["blue", "green"])

  name                 = "${var.name}-${each.key}"
  port                 = local.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 10

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "prod" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main["blue"].arn
  }

  # CodeDeploy が blue/green を切り替える
  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "${var.name}-alb"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
