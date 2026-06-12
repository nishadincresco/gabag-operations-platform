output "app_id" {
  description = "Amplify application ID"
  value       = aws_amplify_app.main.id
}

# Alias for env output consistency
output "amplify_app_id" {
  value = aws_amplify_app.main.id
}

output "default_domain" {
  value = aws_amplify_app.main.default_domain
}

output "role_arn" {
  value = aws_iam_role.amplify_role.arn
}

output "branch_name" {
  value = var.git_branch
}

output "default_domain_url" {
  description = "Default Amplify URL for the tracked branch"
  value       = "https://${var.git_branch}.${aws_amplify_app.main.default_domain}"
}

output "custom_domain_url" {
  description = "Custom domain URL when domain association is enabled"
  value       = var.custom_domain != null ? "https://${var.custom_domain}" : null
}

output "certificate_verification_dns_record" {
  description = "Add this record in Route53 if custom domain SSL stays pending"
  value       = try(aws_amplify_domain_association.main[0].certificate_verification_dns_record, null)
}

# Hostname only (e.g. d111111abcdef8.cloudfront.net) for third-party DNS CNAME at domain apex.
output "custom_domain_branch_dns_target" {
  description = "CNAME target for the mapped branch (CloudFront); use when DNS is outside Route 53 (e.g. Hostpoint)"
  value       = local.amplify_cloudfront_target
}

output "synced_branches" {
  description = "Amplify branches that receive app env vars via update-branch on each apply"
  value       = local.effective_sync_branches
}

output "cloudwatch_log_group" {
  description = "SSR hosting compute log group (streams: <branch>/<date>/<id>)"
  value       = aws_cloudwatch_log_group.amplify_app.name
}
