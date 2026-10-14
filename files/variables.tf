variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "ap-south-1" # Mumbai
}

variable "project_prefix" {
  description = "Prefix used in the names of the resources (bucket, OAC)"
  type        = string
  default     = "hello-world-site"
}

variable "hosted_zone_name" {
  description = "Existing public Route 53 hosted zone that owns the domain"
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain name (subdomain) under which the website is served"
  type        = string
}
