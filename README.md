# Static Website on S3 + CloudFront with Custom Domain (OpenTofu)

Infrastructure-as-code that publishes a static website (a CSS toast with ketchup) on **AWS S3 + CloudFront**,
served over HTTPS on a custom domain managed in Route 53.

## Architecture

```
Browser ──HTTPS──> Route 53 (ALIAS) ──> CloudFront ──(OAC)──> private S3 bucket
                                            │
                                  ACM certificate (us-east-1)
```

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` + public access block | Private bucket that stores the site |
| `aws_s3_bucket_policy` | Only this CloudFront distribution can read the objects |
| `aws_s3_object` | Uploads `index.html` (re-uploaded when the file changes) |
| `aws_cloudfront_origin_access_control` | Lets CloudFront securely access the private bucket |
| `aws_cloudfront_distribution` | CDN with HTTPS redirect, `PriceClass_100` |
| `aws_acm_certificate` + DNS validation | TLS certificate (must be in `us-east-1` for CloudFront) |
| `aws_route53_record` | Certificate validation records and the ALIAS record for the site |
| `null_resource` | Runs a CloudFront cache invalidation when `index.html` changes |

## Project structure

```
.
├── versions.tf             # OpenTofu/Terraform and provider versions
├── providers.tf            # Default provider + us-east-1 alias (for ACM)
├── variables.tf            # Input variables
├── terraform.auto.tfvars   # Values for the variables (loaded automatically)
├── data.tf                 # Existing Route 53 hosted zone
├── s3.tf                   # Bucket, policy, index.html upload, cache invalidation
├── acm.tf                  # Certificate and DNS validation
├── cloudfront.tf           # OAC and distribution
├── route53.tf              # ALIAS record
├── outputs.tf              # Website URL
└── index.html              # The website
```

## Prerequisites

- [OpenTofu](https://opentofu.org/) (or Terraform) installed
- AWS credentials configured
- An existing **public Route 53 hosted zone** for your domain
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed (used by the cache invalidation step)

## Usage

1. Edit `terraform.auto.tfvars` with your hosted zone and the domain you want to use.
2. Deploy:

   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

   The first apply takes a few minutes, since ACM validation and the CloudFront distribution need time.

3. Open the URL from the output:

   ```bash
   tofu output website_url
   ```

4. To update the site, edit `index.html` and run `tofu apply` again. The new file is uploaded and the CloudFront cache is invalidated automatically.

5. Remove everything:

   ```bash
   tofu destroy
   ```

   Note: the bucket must be empty. Because Terraform created the only object, destroy removes it first.

## Variables

| Name | Description | Default |
|---|---|---|
| `aws_region` | Region for the S3 bucket | `ap-south-1` |
| `project_prefix` | Prefix for resource names | `hello-world-site` |
| `hosted_zone_name` | Existing Route 53 hosted zone | n/a |
| `domain_name` | Domain (subdomain) of the website | n/a |

## Outputs

| Name | Description |
|---|---|
| `website_url` | HTTPS URL of the website |

## Notes

- The S3 bucket is fully private. All traffic goes through CloudFront.
- `PriceClass_100` keeps costs low (North America and Europe edge locations only).
- Never commit `terraform.tfstate`.
