variable "name_suffix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "repository" {
  type        = string
  description = "GitHub repository URL"
  default     = null
}

variable "access_token" {
  type        = string
  description = "GitHub personal access token"
  sensitive   = true
  default     = null
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "git_branch" {
  type        = string
  description = "The git branch to track"
  default     = "main"
}

variable "custom_domain" {
  type        = string
  description = "Custom domain for this branch (e.g. dev.hhf.apexai.ch)"
  default     = null
}

variable "public_base_url" {
  type        = string
  description = "Canonical HTTPS base URL for branch env (NEXTAUTH_URL, AUTH_URL, NEXT_PUBLIC_APP_URL) when DNS is managed outside Terraform and custom_domain is null"
  default     = null
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 zone ID for custom domain DNS records"
  default     = null
}

variable "amplify_domain_route53_zone_id" {
  type        = string
  description = "Hosted zone ID for IAM role AWSAmplifyDomainRole-<zoneId> (Amplify Console + Route53 DNS automation). Pass module.route53.zone_id so the role exists before using Hosting → Custom domains."
  default     = null
}

variable "manage_git_repository" {
  type        = bool
  description = "If false, connect GitHub in Amplify Console; Terraform will not change repository/access_token"
  default     = false
}

# Branch env vars override app env vars at SSR runtime, so we must push the same map
# onto each deployed branch. Defaults to the primary git_branch; add feature/preview
# branch names when they exist (e.g. ["main"] on both dev and prod Amplify apps).
variable "sync_branches" {
  type        = list(string)
  description = "Branch names to sync app environment variables to via aws amplify update-branch"
  default     = null
}

variable "error_alarm_threshold" {
  type        = number
  description = "Number of application errors in 5 minutes before the alarm fires"
  default     = 10
}

variable "http_5xx_alarm_threshold" {
  type        = number
  description = "Number of HTTP 5xx responses in 5 minutes before the alarm fires"
  default     = 20
}
