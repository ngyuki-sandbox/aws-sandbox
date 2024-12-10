
resource "aws_lb" "nlb" {
  name               = "${var.name}-nlb"
  load_balancer_type = "network"
  ip_address_type    = "ipv4"
  subnets            = values(data.aws_subnet.main)[*].id
  security_groups    = [aws_security_group.main.id]
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb.arn
  }
}

resource "aws_lb_target_group" "nlb" {
  name        = "${var.name}-nlb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "alb"
  health_check {
    protocol            = "HTTP"
    interval            = 5
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group_attachment" "nlb" {
  target_group_arn = aws_lb_target_group.nlb.arn
  target_id        = aws_lb.alb.arn
  port             = 80
}
