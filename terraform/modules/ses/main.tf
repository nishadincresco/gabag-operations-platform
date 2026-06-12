resource "aws_ses_domain_identity" "main" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# IAM User for SMTP credentials
resource "aws_iam_user" "smtp_user" {
  name = "${var.name_suffix}-ses-smtp-user"
  tags = var.common_tags
}

resource "aws_iam_access_key" "smtp_user_key" {
  user = aws_iam_user.smtp_user.name
}

resource "aws_iam_user_policy" "smtp_user_policy" {
  name = "${var.name_suffix}-ses-smtp-policy"
  user = aws_iam_user.smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = "*"
      }
    ]
  })
}
