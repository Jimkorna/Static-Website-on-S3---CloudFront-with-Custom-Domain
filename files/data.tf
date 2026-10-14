# Existing public Route 53 hosted zone that contains our domain.
# Used for the website ALIAS record and the ACM DNS validation records.
data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}
