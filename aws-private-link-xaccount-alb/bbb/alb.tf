
resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = values(data.aws_subnet.main)[*].id
  security_groups    = [aws_security_group.main.id]
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

resource "aws_lb_target_group" "alb" {
  name     = "${var.name}-alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 5
    timeout             = 4
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.main.id
  port             = 80
}
