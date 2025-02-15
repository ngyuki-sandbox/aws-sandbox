
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.name}-waf"
  scope = "REGIONAL"

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
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = concat(
    # data.aws_ec2_managed_prefix_list.cloudfront.entries[*].cidr,
    var.allow_ips,
  )
}

resource "aws_wafv2_web_acl_association" "apigw" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
