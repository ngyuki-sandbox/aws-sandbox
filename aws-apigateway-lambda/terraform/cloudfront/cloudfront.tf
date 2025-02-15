
resource "aws_cloudfront_distribution" "main" {
  enabled = true
  comment = var.cf_domain_name

  aliases         = [var.cf_domain_name]
  is_ipv6_enabled = false
  http_version    = "http2and3"
  price_class     = "PriceClass_200"
  web_acl_id      = aws_wafv2_web_acl.main.arn

  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_domain_name

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_cache_behavior {
    target_origin_id         = var.origin_domain_name
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    viewer_protocol_policy   = "https-only"
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.main.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.main.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_cloudfront_cache_policy" "main" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "main" {
  name = "Managed-AllViewer"
  # name = "Managed-AllViewerExceptHostHeader"
}
