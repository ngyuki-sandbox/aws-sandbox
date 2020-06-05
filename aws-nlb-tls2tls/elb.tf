################################################################################
# ELB

resource "aws_lb" "public" {
  name               = "${local.tag}-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_a.id]
  ip_address_type    = "ipv4"
}

resource "aws_lb_target_group" "public" {
  name        = "${local.tag}-tg"
  port        = 443
  protocol    = "TLS"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    interval            = 30
    port                = 80
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

resource "aws_lb_target_group_attachment" "public" {
  target_group_arn = aws_lb_target_group.public.arn
  target_id        = aws_instance.server.id
}
