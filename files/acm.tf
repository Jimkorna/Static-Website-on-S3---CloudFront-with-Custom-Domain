# ---------------------------------------------------------------------------
# TLS certificate for the website domain.
# Must be created in us-east-1 because CloudFront requires it.
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Create the replacement first so the distribution never loses its certificate
  lifecycle {
    create_before_destroy = true
  }
}

# Waits until ACM has validated the certificate through the DNS records below.
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# DNS records (CNAME) that prove to ACM that we own the domain.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}
