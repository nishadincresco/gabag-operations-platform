# GitHub Repository Secrets

Add these secrets to your GitHub repo at:
**Settings → Secrets and variables → Actions → New repository secret**

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key for terraform + S3 |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `DB_PASSWORD` | RDS master password (from `scripts/aws-setup.sh` output) |
| `AUTH_SECRET` | NextAuth secret (from .env after setup) |
| `CRON_SECRET` | EventBridge cron secret (from .env after setup) |
| `S3_ACCESS_KEY_ID` | Same as AWS_ACCESS_KEY_ID (or separate S3 IAM user) |
| `S3_SECRET_ACCESS_KEY` | Same as AWS_SECRET_ACCESS_KEY (or separate S3 IAM user) |

**How to get the values:** Run `scripts/aws-setup.sh` first. All secrets will be in your local `.env` file.
Copy them from there into GitHub Secrets.
