
resource "aws_lb" "main" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for s in data.aws_subnet.main : s.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name                 = var.name
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = data.aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    protocol = "HTTP"
    port     = 80
    path     = "/"
    matcher  = "307,405"
  }
}


resource "aws_security_group" "alb" {
  name   = "${var.name}-alb"
  vpc_id = data.aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb"
  }
}

data "aws_network_interface" "main" {
  count = length(aws_vpc_endpoint.main.subnet_ids)
  id    = sort(aws_vpc_endpoint.main.network_interface_ids)[count.index]
}

resource "aws_lb_target_group_attachment" "main" {
  count            = length(aws_vpc_endpoint.main.subnet_ids)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = data.aws_network_interface.main[count.index].private_ip
}
