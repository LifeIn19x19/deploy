resource "aws_s3_bucket" "static_error_bucket" {
  bucket = "${var.environment}.lifein19x19.com"
  acl    = "public-read"
}

data "aws_s3_bucket" "logs_bucket" {
  bucket = "l19-logs"
}

locals {
  s3_origin_id = "staticErrorOrigin"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin access identity for staticErrorOrigin"
}

resource "aws_cloudfront_distribution" "static_distribution" {
  origin {
    domain_name = aws_s3_bucket.static_error_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  comment             = "Distribution for static files for L19"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  logging_config {
    include_cookies = true
    bucket          = data.aws_s3_bucket.logs_bucket.bucket_domain_name
    prefix          = "${var.environment}/"
  }

  aliases = [
    "${var.environment}.lifein19x19.com",
    "www.${var.environment}.lifein19x19.com",
    var.environment == "prod" ? "lifein19x19.com" : null,
    var.environment == "prod" ? "www.lifein19x19.com" : null,
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 400
    response_page_path = "/error.html"
    response_code      = 200
  }
  custom_error_response {
    error_code         = 404
    response_page_path = "/error.html"
    response_code      = 200
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.root_cert_validation.certificate_arn
    ssl_support_method  = "sni-only"
  }
}
