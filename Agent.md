# Agent.md — GABAG Operations Platform

Read this file first before making any changes to this project.

## Architecture (locked)

This project was scaffolded with a fixed architecture. Do not change these fundamentals:

- **Turborepo monorepo** — `apps/web` + `packages/*`, managed by Turbo 2.9+
- **Bun 1.3.12** — pinned via `packageManager` field and `bunfig.toml`; never use npm/yarn/pnpm
- **Next.js 16** with App Router, React 19
- **Tailwind 4** — CSS-first config (`@import "tailwindcss"` + `@theme inline`); no `tailwind.config.{js,ts}` file
- **shadcn/ui** — style `new-york`, base colour `zinc`, lucide icons
- **Prisma 7** — `engineType = "client"` + `@prisma/adapter-pg` (rust-free)
- **PostgreSQL 16** on shared RDS
- **NextAuth v5** — JWT strategy, Credentials provider scaffold
- **AWS Amplify** — WEB_COMPUTE platform, hoisted bun linker
- **Terraform** — 8 modules (vpc, rds, s3, ses, route53, eventbridge, iam, amplify), 3 envs (shared/dev/prod)

## Reading order

1. This file (`Agent.md`)
2. `CLAUDE.md` — Claude Code rules, file placement, build commands
3. `skills/SKILL.md` — Architecture patterns and conventions
4. `.env.example` — Required environment variables

## Rules

1. **Bun everywhere.** No npm/yarn/pnpm commands in any file, script, workflow, or documentation.
2. **Single `.env` at root.** Never create `.env` files inside `apps/` or `packages/`.
3. **shadcn/ui only.** Never create custom component libraries; use and extend shadcn primitives.
4. **Server-side API calls.** Never call external APIs from client components; use `lib/services/`.
5. **Prisma generate before typecheck.** `check-types` depends on `db:generate` (encoded in `turbo.json`).
6. **Region: eu-west-1.** Default for all AWS resources unless explicitly overridden.
7. **Keep files under 500 lines.** Split into modules when approaching the limit.
8. **Read before edit.** Always read a file before modifying it.
9. **No unnecessary files.** Never proactively create docs, READMEs, or test stubs unless asked.
