locals {
  ecr_statements = concat(
    var.enable_ecr ? [{
      Effect   = "Allow"
      Action   = "ecr:GetAuthorizationToken"
      Resource = "*"
    }] : [],
    var.enable_ecr ? [{
      Effect = "Allow"
      Action = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
      Resource = var.ecr_repository_arns
    }] : [],
    var.enable_ecr ? [{
      Effect = "Allow"
      Action = [
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ]
      Resource = "*"
    }] : [],
  )

  # Permissions for terraform plan/apply in GitHub Actions (dev/prod/shared app stacks).
  terraform_statements = [
    {
      Effect = "Allow"
      Action = [
        "iam:Get*",
        "iam:List*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:UpdateRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:AttachUserPolicy",
        "iam:DetachUserPolicy",
        "iam:PassRole",
      ]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["events:*"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["route53:*"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["amplify:*"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["logs:*"]
      Resource = "*"
    },
    {
      Effect = "Allow"
      Action = [
        "s3:Get*",
        "s3:List*",
        "s3:Put*",
        "s3:DeleteObject",
      ]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["ses:*"]
      Resource = "*"
    },
  ]

  # VPC + RDS (terraform/envs/shared). Attach via enable_shared_infra on dev/prod IAM module.
  shared_infra_statements = var.enable_shared_infra ? [
    {
      Effect   = "Allow"
      Action   = ["ec2:*"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["rds:*"]
      Resource = "*"
    },
  ] : []

  base_statements = concat(local.terraform_statements, local.shared_infra_statements)
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.name_suffix}-github-actions-policy"
  description = "Policy for GitHub Actions CI/CD"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(local.base_statements, local.ecr_statements)
  })
}

resource "aws_iam_user_policy_attachment" "github_actions" {
  user       = var.github_actions_username
  policy_arn = aws_iam_policy.github_actions.arn
}
