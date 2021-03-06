data "http" "myip" {
    url = "http://ipv4.icanhazip.com"
}

locals {
  root_ip_address = chomp(data.http.myip.body)
}


data "aws_route53_zone" "lifein19x19" {
  name         = "lifein19x19.com."
  private_zone = false
}

resource "aws_route53_record" "environment_record" {
  zone_id = data.aws_route53_zone.lifein19x19.id
  name    = "${var.environment}.lifein19x19.com"
  type    = "A"

  records = var.maintenance_mode ? null : [
    local.root_ip_address
  ]
  ttl = var.maintenance_mode ? null : 60

  dynamic alias {
    for_each = var.maintenance_mode ? [var.maintenance_mode] : []
    content {
      name                   = aws_cloudfront_distribution.static_distribution.domain_name
      zone_id                = aws_cloudfront_distribution.static_distribution.hosted_zone_id
      evaluate_target_health = false
    }
  }
}

resource "aws_route53_record" "www_environment_record" {
  zone_id = data.aws_route53_zone.lifein19x19.id
  name    = "www.${var.environment}.lifein19x19.com"
  type    = "A"

  records = var.maintenance_mode ? null : [
    local.root_ip_address
  ]
  ttl = var.maintenance_mode ? null : 60

  dynamic alias {
    for_each = var.maintenance_mode ? [var.maintenance_mode] : []
    content {
      name                   = aws_cloudfront_distribution.static_distribution.domain_name
      zone_id                = aws_cloudfront_distribution.static_distribution.hosted_zone_id
      evaluate_target_health = false
    }
  }
}

resource "aws_route53_record" "root_record" {
  count   = var.environment == "prod" ? 1 : 0
  zone_id = data.aws_route53_zone.lifein19x19.id
  name    = "lifein19x19.com"
  type    = "A"

  records = var.maintenance_mode ? null : [
    local.root_ip_address
  ]
  ttl = var.maintenance_mode ? null : 60

  dynamic alias {
    for_each = var.maintenance_mode ? [var.maintenance_mode] : []
    content {
      name                   = aws_cloudfront_distribution.static_distribution.domain_name
      zone_id                = aws_cloudfront_distribution.static_distribution.hosted_zone_id
      evaluate_target_health = false
    }
  }
}

resource "aws_route53_record" "www_record" {
  count   = var.environment == "prod" ? 1 : 0
  zone_id = data.aws_route53_zone.lifein19x19.id
  name    = "www.lifein19x19.com"
  type    = "CNAME"

  records = [
    aws_route53_record.root_record.0.name
  ]
  ttl = 60
}


resource "aws_acm_certificate" "root_cert" {
  provider    = aws.us-east-1
  domain_name = "${var.environment}.lifein19x19.com"
  subject_alternative_names = compact([
    "www.${var.environment}.lifein19x19.com",
    var.environment == "prod" ? "lifein19x19.com" : "",
    var.environment == "prod" ? "www.lifein19x19.com" : "",
  ])
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "environment_cert_validation_record" {
  provider = aws.us-east-1
  name     = aws_acm_certificate.root_cert.domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.root_cert.domain_validation_options.0.resource_record_type
  zone_id  = data.aws_route53_zone.lifein19x19.id
  records  = [aws_acm_certificate.root_cert.domain_validation_options.0.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "www_environment_cert_validation_record" {
  provider = aws.us-east-1
  name     = aws_acm_certificate.root_cert.domain_validation_options.1.resource_record_name
  type     = aws_acm_certificate.root_cert.domain_validation_options.1.resource_record_type
  zone_id  = data.aws_route53_zone.lifein19x19.id
  records  = [aws_acm_certificate.root_cert.domain_validation_options.1.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "root_cert_validation_record" {
  provider = aws.us-east-1
  count    = var.environment == "prod" ? 1 : 0
  name     = aws_acm_certificate.root_cert.domain_validation_options.2.resource_record_name
  type     = aws_acm_certificate.root_cert.domain_validation_options.2.resource_record_type
  zone_id  = data.aws_route53_zone.lifein19x19.id
  records  = [aws_acm_certificate.root_cert.domain_validation_options.2.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "www_root_cert_validation_record" {
  provider = aws.us-east-1
  count    = var.environment == "prod" ? 1 : 0
  name     = aws_acm_certificate.root_cert.domain_validation_options.3.resource_record_name
  type     = aws_acm_certificate.root_cert.domain_validation_options.3.resource_record_type
  zone_id  = data.aws_route53_zone.lifein19x19.id
  records  = [aws_acm_certificate.root_cert.domain_validation_options.3.resource_record_value]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "root_cert_validation" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.root_cert.arn
  validation_record_fqdns = compact([
    aws_route53_record.environment_cert_validation_record.fqdn,
    aws_route53_record.www_environment_cert_validation_record.fqdn,
    var.environment == "prod" ? aws_route53_record.root_cert_validation_record.0.fqdn : "",
    var.environment == "prod" ? aws_route53_record.www_root_cert_validation_record.0.fqdn : ""
  ])
}

