data "aws_route53_zone" "lifein19x19" {
  name         = "lifein19x19.com."
  private_zone = false
}

resource "aws_route53_record" "root_record" {
  zone_id = data.aws_route53_zone.lifein19x19.id
  name    = "${var.environment}.lifein19x19.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.static_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.static_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.lifein19x19.id
  name    = "www.${var.environment}.lifein19x19.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.static_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.static_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "root_cert" {
  provider    = aws.us-east-1
  domain_name = "${var.environment}.lifein19x19.com"
  subject_alternative_names = [
    "www.${var.environment}.lifein19x19.com"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "root_cert_validation_record" {
  provider = aws.us-east-1
  name     = aws_acm_certificate.root_cert.domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.root_cert.domain_validation_options.0.resource_record_type
  zone_id  = data.aws_route53_zone.lifein19x19.id
  records  = [aws_acm_certificate.root_cert.domain_validation_options.0.resource_record_value]
  ttl      = 60
}

resource "aws_route53_record" "www_cert_validation_record" {
  provider = aws.us-east-1
  name     = aws_acm_certificate.root_cert.domain_validation_options.1.resource_record_name
  type     = aws_acm_certificate.root_cert.domain_validation_options.1.resource_record_type
  zone_id  = data.aws_route53_zone.lifein19x19.id
  records  = [aws_acm_certificate.root_cert.domain_validation_options.1.resource_record_value]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "root_cert_validation" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.root_cert.arn
  validation_record_fqdns = [aws_route53_record.root_cert_validation_record.fqdn,
  aws_route53_record.www_cert_validation_record.fqdn]
}

