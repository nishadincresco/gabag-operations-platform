output "amplify_app_id" {
  description = "Amplify App ID"
  value       = module.amplify.app_id
}

output "amplify_default_domain" {
  description = "Default Amplify domain"
  value       = module.amplify.default_domain
}

output "app_url" {
  description = "Deployed app URL"
  value       = module.amplify.default_domain_url
}

output "s3_bucket_name" {
  description = "Documents S3 bucket name"
  value       = module.s3.bucket_name
}
