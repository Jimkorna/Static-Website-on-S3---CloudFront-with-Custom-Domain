# ---------------------------------------------------------------------------
# S3 bucket that stores the static website files.
# Bucket name example: hello-world-site-tost.me.ketchup.scio.systems
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_prefix}-${var.domain_name}"
}

# Security: block ALL public access to the bucket.
# Content is reachable only through CloudFront (see the bucket policy below).
resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy: only this specific CloudFront distribution may read objects.
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    # Restrict access to our distribution only (OAC best practice)
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# ---------------------------------------------------------------------------
# Upload the local index.html to the bucket.
# The etag (MD5 hash) makes Terraform re-upload the file whenever it changes.
# ---------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "index.html" # local file in the project folder
  etag         = filemd5("index.html")
  content_type = "text/html"
}

# ---------------------------------------------------------------------------
# Invalidate the CloudFront cache whenever index.html changes,
# so visitors see the new version immediately.
# Requires the AWS CLI to be installed and configured on the machine running apply.
# ---------------------------------------------------------------------------
resource "null_resource" "clear_cache" {
  triggers = {
    # Re-run only when the HTML content changes
    hash = filemd5("index.html")
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.cdn.id} --paths '/*'"
  }

  # Make sure the new file is uploaded before the cache is invalidated
  depends_on = [aws_s3_object.index]
}
