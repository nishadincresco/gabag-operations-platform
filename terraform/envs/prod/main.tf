## Prod: Amplify + S3 + EventBridge + IAM (optional Route53)
## Database: logical DB on shared RDS (terraform/envs/shared)

data "aws_caller_identity" "current" {}

locals {
  environment  = "prod"
  project_name = "gabag-operations-platform"
  name_suffix  = "${local.project_name}-${local.environment}"
  app_base_url = var.amplify_web_url

  db_endpoint = data.terraform_remote_state.shared.outputs.db_endpoint
  db_username = data.terraform_remote_state.shared.outputs.db_username

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }

  database_url = "postgresql://${local.db_username}:${urlencode(var.db_password)}@${local.db_endpoint}/${var.db_name}?sslmode=no-verify"

  amplify_env = {
    DATABASE_URL         = local.database_url
    DIRECT_URL           = local.database_url
    AUTH_SECRET          = var.auth_secret
    NEXTAUTH_SECRET      = var.auth_secret
    AUTH_TRUST_HOST      = "true"
    NEXTAUTH_URL         = local.app_base_url
    NEXT_PUBLIC_APP_URL  = local.app_base_url
    S3_ACCESS_KEY_ID     = var.s3_access_key_id
    S3_SECRET_ACCESS_KEY = var.s3_secret_access_key
    S3_REGION            = var.aws_region
    S3_BUCKET_NAME       = module.s3.bucket_name
    S3_PUBLIC_URL        = var.s3_public_url
    CRON_SECRET          = var.cron_secret
    NODE_ENV             = "production"
  }
}

module "s3" {
  source = "../../modules/s3"

  name_suffix  = local.name_suffix
  common_tags  = local.common_tags
  account_id   = data.aws_caller_identity.current.account_id
  app_base_url = local.app_base_url
}

module "route53" {
  count  = var.create_dns_zone ? 1 : 0
  source = "../../modules/route53"

  create_zone = true
  domain_name = var.domain_name
  zone_id     = var.route53_zone_id
  record_name = ""
  common_tags = local.common_tags
}

module "amplify" {
  source = "../../modules/amplify"

  name_suffix           = local.name_suffix
  common_tags           = local.common_tags
  git_branch            = "main"
  manage_git_repository = var.manage_amplify_git
  repository            = var.github_repository
  access_token          = var.github_access_token
  environment_variables = local.amplify_env
  custom_domain         = var.enable_amplify_custom_domain ? var.domain_name : null
  public_base_url       = var.amplify_web_url
  route53_zone_id = (
    var.enable_amplify_custom_domain && var.create_dns_zone
    ? module.route53[0].zone_id
    : null
  )
  amplify_domain_route53_zone_id = var.create_dns_zone ? module.route53[0].zone_id : null
  sync_branches                  = var.amplify_sync_branches
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  name_suffix       = local.name_suffix
  common_tags       = local.common_tags
  cron_endpoint_url = local.app_base_url
  cron_secret       = var.cron_secret
}

module "iam_github" {
  source = "../../modules/iam"

  name_suffix             = local.name_suffix
  github_actions_username = var.github_actions_username
  enable_ecr              = false
  enable_shared_infra     = true
}
