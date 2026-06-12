output "dkim_tokens" {
  value       = aws_ses_domain_dkim.main.dkim_tokens
  description = "DKIM tokens for DNS verification"
}

output "smtp_username" {
  value = aws_iam_access_key.smtp_user_key.id
}

output "smtp_password" {
  value     = aws_iam_access_key.smtp_user_key.ses_smtp_password_v4
  sensitive = true
}

output "ses_domain_identity_arn" {
  value = aws_ses_domain_identity.main.arn
}
