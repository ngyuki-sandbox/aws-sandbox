
resource "aws_cloudfront_distribution" "cloudfront" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  retain_on_delete    = false
  wait_for_deployment = false

  aliases = [var.cf_domain_name]

  origin {
    domain_name = var.alb_dns_name
    origin_id   = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-test"
      value = "123"
    }

    custom_header {
      name  = "x-forwarded-host"
      value = var.cf_domain_name
    }
  }

  origin {
    domain_name              = var.s3_domain_name
    origin_id                = var.s3_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.private.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "https-only"
    target_origin_id       = var.alb_dns_name

    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.nocache.id
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "https-only"
    target_origin_id       = var.alb_dns_name

    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.nocache.id
    trusted_key_groups         = [aws_cloudfront_key_group.main.id]
  }

  ordered_cache_behavior {
    path_pattern           = "/private/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "https-only"
    target_origin_id       = var.s3_domain_name

    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.nocache.id
    trusted_key_groups         = [aws_cloudfront_key_group.main.id]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_origin_access_control" "private" {
  name                              = var.name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "ecdsa" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "aws_cloudfront_public_key" "rsa" {
  name        = "${var.name}-rsa"
  encoded_key = tls_private_key.rsa.public_key_pem
}

resource "aws_cloudfront_public_key" "ecdsa" {
  name        = "${var.name}-ecdsa"
  encoded_key = tls_private_key.ecdsa.public_key_pem
}

resource "aws_cloudfront_key_group" "main" {
  name = var.name
  items = [
    aws_cloudfront_public_key.rsa.id,
    aws_cloudfront_public_key.ecdsa.id,
  ]
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "all" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_response_headers_policy" "nocache" {
  name = "${var.name}-nostore"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "no-cache,must-revalidate,max-age=0"
      override = true
    }
  }
}
