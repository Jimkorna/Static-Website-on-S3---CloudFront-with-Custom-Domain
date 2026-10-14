# Default provider: used for S3, CloudFront, Route 53.
provider "aws" {
  region = var.aws_region
}

# Aliased provider for us-east-1.
# CloudFront only accepts ACM certificates that live in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
