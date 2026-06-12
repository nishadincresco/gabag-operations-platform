# GABAG Operations Platform

Swiss manufacturer of sanitary installation systems

## Stack

- **Turborepo** + **Bun 1.3.x** monorepo
- **Next.js 16** + **React 19** + **Tailwind 4** + **shadcn/ui** (new-york / zinc)
- **Prisma 7** + **PostgreSQL 16** (rust-free engine, pg adapter)
- **NextAuth v5** (Credentials provider scaffold)
- **AWS S3** for uploads
- **AWS Amplify** hosting (WEB_COMPUTE)
- **Terraform** IaC (VPC, RDS, S3, SES, Route53, EventBridge, IAM, Amplify)
- **GitHub Actions** CI/CD (lint, typecheck, prisma generate, prisma migrate, terraform plan/apply)

## Layout

```
apps/
  web/          Next.js application
packages/
  db/           Prisma schema, client, seeds
  types/        Shared TypeScript types
  ui/           Shared React components
  logger/       Structured logger
  eslint-config/    ESLint shared config
  typescript-config/ tsconfig presets
terraform/
  modules/      vpc, rds, s3, ses, route53, eventbridge, iam, amplify
  envs/         shared (VPC+RDS), dev, prod
.github/workflows/
  ci.yml        Lint, typecheck, Prisma migrate
  terraform.yml Shared → matrix (dev/prod) plan + apply
amplify.yml     Monorepo build spec for AWS Amplify
```

## Getting started

```bash
bun install --linker=hoisted
cp .env.example .env       # fill in DATABASE_URL etc.
bun run db:generate
bun run dev                # turbo dev -> apps/web on :3000
```

## CI/CD

- Branches: **`dev`** (staging) and **`main`** (production).
- Push to `dev` → Amplify dev build, terraform `dev` apply.
- Push to `main` → Amplify prod build, terraform `prod` apply.

## Phase 2 — AWS provisioning

```bash
cd terraform/envs/shared
terraform init && terraform apply   # creates VPC + RDS + per-env DBs
cd ../dev && terraform init && terraform apply
cd ../prod && terraform init && terraform apply
```

Then connect the GitHub repo in the Amplify Console.
