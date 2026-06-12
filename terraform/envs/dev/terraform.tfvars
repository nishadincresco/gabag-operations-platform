aws_region = "eu-west-1"

amplify_web_url = "https://dev.gabag-operations-platform.example.com"
domain_name     = "dev.gabag-operations-platform.example.com"

create_dns_zone              = false
enable_amplify_custom_domain = false

db_name = "gabag_operations_platform_dev"

# Secrets provided via TF_VAR_* env vars (see scripts/aws-setup.sh)

github_repository       = "https://github.com/nishadincresco/gabag-operations-platform"
github_actions_username = "github-actions-user"
manage_amplify_git      = false

amplify_sync_branches = ["dev"]
