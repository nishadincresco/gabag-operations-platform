variable "name_suffix" {
  description = "Suffix to append to resource names"
  type        = string
}

variable "github_actions_username" {
  description = "The IAM username for GitHub Actions"
  type        = string
}

variable "enable_ecr" {
  description = "Attach ECR/ECS deploy permissions (prod legacy worker path)"
  type        = bool
  default     = false
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs when enable_ecr is true"
  type        = list(string)
  default     = []
}

variable "enable_shared_infra" {
  description = "Include EC2/RDS permissions for terraform/envs/shared (GitHub Actions shared job)"
  type        = bool
  default     = true
}
