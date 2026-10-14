# Terraform / OpenTofu and provider version constraints.
# The lock file of the original project pinned aws 5.100.0, so we stay on the 5.x line.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Used only for the CloudFront cache invalidation (null_resource in s3.tf)
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
