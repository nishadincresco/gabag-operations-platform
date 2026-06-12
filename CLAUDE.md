# Claude Code Configuration — GABAG Operations Platform

## Project Context

Swiss manufacturer of sanitary installation systems

## Architecture

- **Monorepo:** Turborepo + Bun 1.3.12
- **Frontend:** Next.js 16 (App Router) + React 19 + Tailwind 4 + shadcn/ui (new-york / zinc)
- **Database:** Prisma 7 (rust-free engine, @prisma/adapter-pg) + PostgreSQL 16
- **Auth:** NextAuth v5 (Credentials provider, JWT strategy)
- **Storage:** AWS S3 (@aws-sdk/client-s3 + presigner)
- **Hosting:** AWS Amplify (WEB_COMPUTE, hoisted bun linker)
- **IaC:** Terraform (8 modules, 3 envs: shared/dev/prod, region eu-west-1)
- **CI/CD:** GitHub Actions (bun-based lint, typecheck, prisma migrate, terraform plan/apply)

## File Organisation

```
gabag-operations-platform/
├── apps/
│   └── web/                — Next.js application (App Router)
│       ├── app/            — Routes, layouts, API handlers
│       ├── components/     — Feature + UI components
│       │   └── ui/         — shadcn/ui primitives (do not edit manually)
│       ├── lib/            — Utilities (cn, logger, helpers)
│       ├── auth.ts         — NextAuth v5 config
│       └── middleware.ts   — Auth/RBAC guard (Edge runtime)
├── packages/
│   ├── db/                 — Prisma schema, client, seeds
│   ├── types/              — Shared TypeScript types + Zod schemas
│   ├── ui/                 — Shared React components
│   ├── logger/             — Structured JSON logger
│   ├── eslint-config/      — Shared ESLint presets
│   └── typescript-config/  — Shared tsconfig presets
├── terraform/
│   ├── modules/            — vpc, rds, s3, ses, route53, eventbridge, iam, amplify
│   └── envs/               — shared (VPC+RDS), dev, prod
├── .github/workflows/
│   ├── ci.yml              — Lint, typecheck, Prisma migrate
│   └── terraform.yml       — Shared then matrix dev/prod plan + apply
├── amplify.yml             — Monorepo build spec
├── CLAUDE.md               — This file
├── Agent.md                — Agent rules
└── skills/SKILL.md         — Architecture skills reference
```

## Behavioural Rules (Always Enforced)

- Do what has been asked; nothing more, nothing less
- NEVER create files unless they are absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files
- ALWAYS call APIs from the server side — never directly from client components
- ALWAYS use service modules (e.g. `lib/services/`) to encapsulate API calls
- ALWAYS use the root `.env` for all environment variables; NEVER create local `.env` files in `apps/` or `packages/`

## Environment Variables

- **Single `.env` at monorepo root** — never in sub-packages
- Bun loads the root `.env` automatically for all scripts
- All variables tracked in `turbo.json` globalEnv
- NEVER commit `.env`; always update `.env.example` when adding new variables
- See `.env.example` for the full list

## Design System

- ALWAYS use shadcn/ui for all UI components — no custom component libraries
- Add new components via `bunx shadcn@latest add <component>`
- Extend via `cn()` utility and Tailwind classes — do not replace primitives
- Component source: `apps/web/components/ui/` (shadcn default output path)
- Style: new-york, base colour: zinc, icons: lucide

## Placement Rules

- **Route pages** (`app/**/page.tsx`) — data fetching and layout only; no component definitions
- **Feature components** — `components/<domain>/` (e.g. `components/customers/`)
- **Shared primitives** — `components/ui/` (shadcn only, never custom)
- **Layout chrome** — `components/layout/` (header, sidebar, shell)
- **API utilities** — `lib/` (auth helpers, logger, utils)
- **Auth config** — `apps/web/auth.ts` and `apps/web/auth.config.ts` (Next.js convention)
- NEVER save files to the monorepo root or `apps/web/` root

## Build and Test

```bash
bun install                    # Install dependencies
bun run build                  # Build all packages
bun run check-types            # Type-check all packages
bun run lint                   # Lint all packages
bun run db:generate            # Generate Prisma client (after schema changes)
bun run db:push                # Push DB schema (dev)
bun run db:seed                # Seed admin user
bun run dev                    # Start dev server (apps/web on :3000)
```

- ALWAYS run `bun run check-types` after making code changes
- ALWAYS verify build succeeds before committing
- Use `bun` everywhere — never `npm` or `yarn`

## Security Rules

- NEVER hardcode API keys, secrets, or credentials in source files
- NEVER commit .env files or any file containing secrets
- Always validate user input at system boundaries
- Always sanitise file paths to prevent directory traversal

## Terraform

- Region: **eu-west-1** (default)
- State: S3 bucket `gabag-operations-platform-tf-state` + DynamoDB `gabag-operations-platform-terraform-locks`
- Envs: `shared` (VPC + RDS) → `dev` and `prod` consume via `terraform_remote_state`
- Apply order: shared first, then dev, then prod
- Secrets via `TF_VAR_*` environment variables in CI — never in tfvars files
