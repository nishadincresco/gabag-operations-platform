data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  amplify_env_with_monorepo = merge(
    var.environment_variables,
    { AMPLIFY_MONOREPO_APP_ROOT = "apps/web" },
  )

  effective_sync_branches = var.sync_branches != null ? var.sync_branches : [var.git_branch]

  # Amplify default URL: slashes in branch names become hyphens in the hostname.
  default_branch_url = "https://${replace(var.git_branch, "/", "-")}.${aws_amplify_app.main.default_domain}"

  branch_base_url = {
    for branch in local.effective_sync_branches : branch => (
      branch == var.git_branch
      ? coalesce(
        var.custom_domain != null ? "https://${var.custom_domain}" : null,
        var.public_base_url,
        local.default_branch_url,
      )
      : "https://${replace(branch, "/", "-")}.${aws_amplify_app.main.default_domain}"
    )
  }

  amplify_branch_env = {
    for branch in local.effective_sync_branches : branch => merge(
      local.amplify_env_with_monorepo,
      {
        NEXTAUTH_URL        = local.branch_base_url[branch]
        AUTH_URL            = local.branch_base_url[branch]
        NEXT_PUBLIC_APP_URL = local.branch_base_url[branch]
      },
    )
  }
}

resource "aws_amplify_app" "main" {
  name = var.name_suffix

  repository   = var.manage_git_repository ? var.repository : null
  access_token = var.manage_git_repository ? var.access_token : null

  iam_service_role_arn = aws_iam_role.amplify_role.arn

  # Console Git connect: set manage_git_repository = false. Terraform still may set repo on first create when true.
  lifecycle {
    ignore_changes = [repository, access_token]
  }

  platform = "WEB_COMPUTE"

  environment_variables = local.amplify_env_with_monorepo

  # Uses root amplify.yml from the connected GitHub repo (monorepo appRoot: apps/web).
  # Do not set build_spec here — it would override the repo file.

  tags = var.common_tags
}

# Write branch env JSON to disk so sensitive values (DATABASE_URL, secrets) are not
# stripped when passed via provisioner environment (Terraform marks them as sensitive).
resource "local_sensitive_file" "amplify_branch_env" {
  for_each = toset(local.effective_sync_branches)

  content  = jsonencode(local.amplify_branch_env[each.value])
  filename = "${path.module}/.amplify-branch-env/${replace(replace(each.value, "/", "_"), ".", "_")}.json"
}

# Branch-level env vars override app-level vars at SSR runtime. When the branch is
# Console-connected (manage_git_repository=false), AWS may seed it with Gen2-only
# vars (AMPLIFY_BACKEND_*, USER_BRANCH), which hides our real secrets from the
# Lambda. Push the same env map onto every branch listed in var.sync_branches.
resource "null_resource" "branch_env_sync" {
  for_each = toset(local.effective_sync_branches)

  triggers = {
    branch   = each.value
    app_id   = aws_amplify_app.main.id
    env_hash = local_sensitive_file.amplify_branch_env[each.value].content_sha256
    region   = data.aws_region.current.name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      if ! aws amplify get-branch \
        --app-id "${aws_amplify_app.main.id}" \
        --branch-name "${each.value}" \
        --region "${data.aws_region.current.name}" >/dev/null 2>&1; then
        echo "Branch ${each.value} does not exist yet on app ${aws_amplify_app.main.id} — skipping env sync."
        exit 0
      fi

      aws amplify update-branch \
        --app-id "${aws_amplify_app.main.id}" \
        --branch-name "${each.value}" \
        --region "${data.aws_region.current.name}" \
        --environment-variables "file://${local_sensitive_file.amplify_branch_env[each.value].filename}" >/dev/null

      echo "Synced env vars to branch ${each.value}"
    EOT
  }

  depends_on = [
    aws_amplify_app.main,
    aws_amplify_branch.main,
    local_sensitive_file.amplify_branch_env,
  ]
}

# When manage_git_repository = false, create the branch in Amplify Console after connecting GitHub.
resource "aws_amplify_branch" "main" {
  count = var.manage_git_repository ? 1 : 0

  app_id      = aws_amplify_app.main.id
  branch_name = var.git_branch

  framework = "Next.js - SSR"

  stage = var.git_branch == "main" ? "PRODUCTION" : "DEVELOPMENT"

  enable_auto_build = var.access_token != null

  environment_variables = local.amplify_branch_env[var.git_branch]
}

# Separate from aws_iam_role.amplify_role (app SSR/build). Amplify Hosting looks up this
# exact name when Route53 is in the same account; AWS used to create it implicitly.
resource "aws_iam_role" "amplify_domain" {
  count = var.amplify_domain_route53_zone_id != null ? 1 : 0

  name = "AWSAmplifyDomainRole-${replace(var.amplify_domain_route53_zone_id, "/hostedzone/", "")}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = "sts:AssumeRole"

        Principal = {
          Service = "amplify.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "amplify_domain_route53" {
  count = var.amplify_domain_route53_zone_id != null ? 1 : 0

  role       = aws_iam_role.amplify_domain[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_amplify_domain_association" "main" {
  count = var.custom_domain != null ? 1 : 0

  app_id      = aws_amplify_app.main.id
  domain_name = var.custom_domain

  wait_for_verification = false

  sub_domain {
    branch_name = var.git_branch
    prefix      = ""
  }
}

locals {
  amplify_sub_domain = var.custom_domain != null ? one([
    for sd in aws_amplify_domain_association.main[0].sub_domain :
    sd if sd.branch_name == var.git_branch
  ]) : null

  # Amplify returns e.g. " CNAME d123.cloudfront.net" — Route53 needs the hostname only.
  amplify_cloudfront_target = local.amplify_sub_domain != null ? trimspace(replace(
    replace(local.amplify_sub_domain.dns_record, "CNAME", ""),
    "cname",
    "",
  )) : null
}

# Apex alias (CNAME is not allowed at zone apex; Amplify targets CloudFront).
resource "aws_route53_record" "domain_app" {
  count = local.amplify_cloudfront_target != null ? 1 : 0

  zone_id         = var.route53_zone_id
  name            = var.custom_domain
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.amplify_cloudfront_target
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_iam_role" "amplify_role" {
  name = "amplify-role-${var.name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = "sts:AssumeRole"

        Principal = {
          Service = "amplify.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "amplify_ssm" {
  role       = aws_iam_role.amplify_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "amplify_secrets" {
  role       = aws_iam_role.amplify_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy" "amplify_vpc_permissions" {
  name = "amplify-vpc-permissions-${var.name_suffix}"

  role = aws_iam_role.amplify_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]

        Resource = "*"
      }
    ]
  })
}

# WEB_COMPUTE SSR runtime logs → CloudWatch (/aws/amplify/<app-id>/[<branch>])
# AWS recommends Resource "arn:aws:logs:*:*:*" (amplify-hosting#3964); scoped paths alone
# can block log group creation at deploy time.
resource "aws_iam_role_policy" "amplify_cloudwatch_logs" {
  name = "amplify-cloudwatch-logs-${var.name_suffix}"

  role = aws_iam_role.amplify_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]

        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

# Pre-create the app log group. Streams are named <branch>/<date>/<id> under this group.
resource "aws_cloudwatch_log_group" "amplify_app" {
  name              = "/aws/amplify/${aws_amplify_app.main.id}"
  retention_in_days = 14

  tags = var.common_tags
}

# ── CloudWatch alarms ────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.name_suffix}-app-errors"
  log_group_name = aws_cloudwatch_log_group.amplify_app.name
  pattern        = "\"level\":\"error\""

  metric_transformation {
    name          = "AppErrorCount"
    namespace     = "Forge/${var.name_suffix}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_error_rate" {
  alarm_name          = "${var.name_suffix}-app-error-rate"
  alarm_description   = "More than ${var.error_alarm_threshold} application errors in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AppErrorCount"
  namespace           = "Forge/${var.name_suffix}"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_alarm_threshold
  treat_missing_data  = "notBreaching"
  tags                = var.common_tags
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx" {
  name           = "${var.name_suffix}-http-5xx"
  log_group_name = aws_cloudwatch_log_group.amplify_app.name
  pattern        = "\"statusCode\":5"

  metric_transformation {
    name          = "Http5xxCount"
    namespace     = "Forge/${var.name_suffix}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "http_5xx_rate" {
  alarm_name          = "${var.name_suffix}-http-5xx-rate"
  alarm_description   = "More than ${var.http_5xx_alarm_threshold} HTTP 5xx responses in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Http5xxCount"
  namespace           = "Forge/${var.name_suffix}"
  period              = 300
  statistic           = "Sum"
  threshold           = var.http_5xx_alarm_threshold
  treat_missing_data  = "notBreaching"
  tags                = var.common_tags
}

resource "aws_security_group" "amplify_sg" {
  count = var.vpc_id != null ? 1 : 0

  name        = "amplify-sg-${var.name_suffix}"
  description = "Security group for Amplify SSR compute"
  vpc_id      = var.vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}
