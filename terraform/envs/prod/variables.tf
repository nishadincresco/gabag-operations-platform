variable "aws_region" {
  type        = string
  description = "AWS region for S3 and Amplify"
  default     = "eu-west-1"
}

variable "amplify_web_url" {
  type        = string
  description = "Public HTTPS base URL (Amplify default hostname or custom domain); must match NEXTAUTH and any OAuth callbacks"
  default     = "https://gabag-operations-platform.example.com"
}

variable "domain_name" {
  type        = string
  description = "Logical hostname for docs/tfvars; Amplify custom domain apex only when enable_amplify_custom_domain is true"
  default     = "gabag-operations-platform.example.com"
}

variable "create_dns_zone" {
  type        = bool
  description = "Create a Route53 hosted zone for domain_name"
  default     = false
}

variable "route53_zone_id" {
  type        = string
  description = "Existing public hosted zone ID for domain_name when create_dns_zone is false"
  default     = null
}

variable "db_name" {
  type        = string
  description = "PostgreSQL database name on the shared RDS instance"
  default     = "gabag_operations_platform_prod"
}

variable "db_password" {
  type        = string
  description = "Shared RDS master password (same value as terraform/envs/shared)"
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8 && !can(regex("[/@\" ]", var.db_password))
    error_message = "db_password must be at least 8 characters and must not contain '/', '@', '\"', or spaces (RDS restriction)."
  }
}

variable "s3_public_url" {
  type        = string
  description = "Optional public S3 base URL (root .env S3_PUBLIC_URL)"
  default     = ""
}

variable "auth_secret" {
  type      = string
  sensitive = true
}

variable "cron_secret" {
  type      = string
  sensitive = true
}

variable "s3_access_key_id" {
  type      = string
  sensitive = true
}

variable "s3_secret_access_key" {
  type      = string
  sensitive = true
}

variable "github_actions_username" {
  type        = string
  description = "Existing IAM user for GitHub Actions"
  default     = "github-actions-user"
}

variable "github_repository" {
  type        = string
  description = "GitHub repo URL for Amplify CI"
  default     = "https://github.com/nishadincresco/gabag-operations-platform"
}

variable "github_access_token" {
  type        = string
  description = "GitHub classic PAT — only used when manage_amplify_git = true"
  sensitive   = true
  default     = null
}

variable "manage_amplify_git" {
  type        = bool
  description = "If false, connect GitHub manually in Amplify Console"
  default     = false
}

variable "enable_amplify_custom_domain" {
  type        = bool
  description = "Manage aws_amplify_domain_association in Terraform"
  default     = false
}

variable "amplify_sync_branches" {
  type        = list(string)
  description = "Branch names to sync app env vars to via aws amplify update-branch (null = [git_branch])"
  default     = ["main"]
}
