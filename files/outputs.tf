# Public URL of the website.
output "website_url" {
  description = "HTTPS URL of the static website"
  value       = "https://${var.domain_name}"
}
