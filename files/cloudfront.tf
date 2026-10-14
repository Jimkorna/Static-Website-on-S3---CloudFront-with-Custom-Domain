# ---------------------------------------------------------------------------
# Origin Access Control (OAC): lets CloudFront securely sign requests to S3,
# so the bucket can stay private.
# ---------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_prefix}-oac"
  description                       = "OAC for static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------------------------------------------------------------------
# CloudFront distribution: serves the S3 content over HTTPS on our domain.
# ---------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100" # cheapest: North America and Europe edge locations only

  # Origin: the private S3 bucket, accessed through OAC
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https" # force HTTPS
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Static site: do not forward query strings or cookies to the origin
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Cache lifetime: default 1 day, max 1 year
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # HTTPS certificate (validated ACM certificate from us-east-1)
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
