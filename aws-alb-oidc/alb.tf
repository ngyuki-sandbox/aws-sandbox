
resource "aws_lb" "main" {
  name               = var.name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "main" {
  name        = var.name
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_lambda_function.main.arn
  depends_on       = [aws_lambda_permission.main]
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type = "authenticate-oidc"

    authenticate_oidc {
      client_id              = var.oidc_client_id
      client_secret          = var.oidc_client_secret
      issuer                 = var.oidc_issuer
      authorization_endpoint = var.oidc_authorization_endpoint
      token_endpoint         = var.oidc_token_endpoint
      user_info_endpoint     = var.oidc_user_info_endpoint
      scope                  = var.oidc_scope

      # 認証後のセッション設定
      session_cookie_name = "AWSELBAuthSessionCookie"
      session_timeout     = 3600

      # 認証失敗時の動作
      on_unauthenticated_request = "authenticate"
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
