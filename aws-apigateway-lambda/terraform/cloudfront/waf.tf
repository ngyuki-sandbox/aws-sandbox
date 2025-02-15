
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.name}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
    metric_name                = "${var.name}-waf"
  }

  rule {
    name     = "ipset"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ipset.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      sampled_requests_enabled   = false
      metric_name                = "${var.name}-ipset"
    }
  }
}

resource "aws_wafv2_ip_set" "ipset" {
  name               = "${var.name}-ipset"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allow_ips
}
