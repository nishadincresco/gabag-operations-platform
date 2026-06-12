# Skills Reference — GABAG Operations Platform

Architecture patterns and conventions for this project. Read `Agent.md` and `CLAUDE.md` first.

---

## Skill: Turborepo Monorepo

### Workspace layout
- Root `package.json` declares workspaces: `["apps/*", "packages/*"]`
- Internal packages use `@repo/*` namespace (e.g. `@repo/db`, `@repo/types`, `@repo/ui`)
- `turbo.json` orchestrates tasks with dependency graph

### Key dependency chain
`db:generate` → `check-types` → `build`
- TypeScript types depend on Prisma's generated client
- `turbo.json` encodes: `"check-types": { "dependsOn": ["^build", "^check-types", "^db:generate"] }`

### Gotchas
- `bun.lock` belongs in the repo — do not add to `.gitignore`
- Turbo caches respect `.env*` via `inputs: ["$TURBO_DEFAULT$", ".env*"]`

---

## Skill: Next.js 16 + React 19 + Tailwind 4

### CSS-first Tailwind
- No `tailwind.config.{js,ts}` — config lives in `app/globals.css` via `@theme inline { ... }`
- PostCSS plugin: `@tailwindcss/postcss` (not the legacy `tailwindcss` plugin)
- Import: `@import "tailwindcss";` at top of globals.css

### App Router conventions
- `app/` contains routes only — thin pages that fetch data and compose components
- Components live in `components/<domain>/` — never defined inside route files
- API routes in `app/api/` — always server-side, never called from client components
- Use `"use client"` directive only when React hooks or browser APIs are needed

### TypeScript
- Pin `@types/react@19.x` to avoid type drift
- Path alias: `"@/*": ["./*"]` (relative to `apps/web/`)

---

## Skill: shadcn/ui (new-york / zinc)

### Setup
- Config: `apps/web/components.json` — style `new-york`, `rsc: true`, baseColour `zinc`
- `tailwind.config` field is empty string (Tailwind 4 CSS-first, no config file)
- Add components: `bunx shadcn@latest add <name>`

### Rules
- Never manually edit files in `components/ui/` — they are shadcn-managed
- Extend via `cn()` from `lib/utils.ts` and Tailwind classes
- Use `cva` (class-variance-authority) for custom variants

---

## Skill: Prisma 7 + PostgreSQL 16

### Schema
- Location: `packages/db/prisma/schema.prisma`
- Engine: `engineType = "client"` (rust-free, smaller Lambda bundle)
- Adapter: `@prisma/adapter-pg` + `pg` driver

### Client singleton
- `packages/db/src/index.ts` exports a cached `PrismaClient` instance
- Import as: `import { prisma } from "@repo/db"`
- Global caching prevents hot-reload connection leaks in dev

### Migrations
- Dev: `bun --env-file=../../.env x prisma migrate dev` (from `packages/db/`)
- Deploy: `bun --env-file=../../.env x prisma migrate deploy`
- Always run `bun run db:generate` after schema changes

### Gotchas
- `DIRECT_URL` required when using connection poolers (pgBouncer) — default to same as `DATABASE_URL`
- URL-encode passwords with reserved chars in connection strings

---

## Skill: NextAuth v5

### Config
- `apps/web/auth.ts` — full NextAuth config with Prisma adapter
- `apps/web/app/api/auth/[...nextauth]/route.ts` — route handler
- Strategy: JWT (not database sessions)
- `AUTH_SECRET` + `AUTH_TRUST_HOST=true` required

### Adding providers
- Add to the `providers` array in `auth.ts`
- Update `Account` model in Prisma schema if needed
- Supported: Credentials (scaffold), Google, GitHub, etc.

---

## Skill: Terraform on AWS

### Layout
```
terraform/
├── modules/    vpc, rds, s3, ses, route53, eventbridge, iam, amplify
└── envs/       shared → dev → prod (apply in this order)
```

### Patterns
- `name_suffix = "{project}-{env}"` on every resource
- `common_tags = { Project, Environment, ManagedBy = "Terraform" }`
- S3 backend with DynamoDB locks, encrypt = true
- Dev/prod consume shared via `data "terraform_remote_state" "shared"`
- Region: `eu-west-1` (variable with default)

### Apply order
1. `terraform/envs/shared` — creates VPC + RDS
2. `terraform/envs/dev` — creates S3 (with CORS), Amplify, EventBridge, IAM for dev
3. `terraform/envs/prod` — same for prod

---

## Skill: GitHub Actions (Bun)

### Workflows
- `ci.yml` — bun lint, typecheck, prisma generate, prisma migrate deploy (branch-gated)
- `terraform.yml` — shared job first, then matrix dev/prod with plan + apply (branch-gated)

### Conventions
- `oven-sh/setup-bun@v2` with pinned `bun-version: "1.3.12"`
- `bun install --frozen-lockfile` (never `bun ci` — that doesn't exist)
- Triggers: push + pull_request on `[main, dev]`
- AWS: `aws-actions/configure-aws-credentials@v4`, region `eu-west-1`

---

## Skill: Amplify Monorepo Hosting

### Build spec (`amplify.yml`)
- `appRoot: apps/web`
- Installs bun globally, runs `bun install --linker=hoisted`
- Runs `prisma generate` in preBuild
- Writes `.env.production` from Console env vars (SSR workaround)
- Builds `@repo/types` first, then `web`
- Trims `.next/cache` and `.next/standalone` to fit 230 MB limit

### Critical
- `bunfig.toml` must set `linker = "hoisted"` — Amplify's WEB_COMPUTE needs flat `node_modules`
- `AMPLIFY_MONOREPO_APP_ROOT=apps/web` env var must be set on the Amplify app

---

## Skill: Auth Guard (middleware.ts)

### How it works
- `apps/web/middleware.ts` runs at the Edge before every request
- Uses NextAuth `auth` export to check session; redirects unauthenticated users to `/login`
- Public routes whitelist: `/login`, `/api/auth/**`, `/api/health`, `/api/cron`

### Extending RBAC
- Add a `role` field to the `User` model in Prisma schema
- Read `token.role` from the JWT in `auth.ts` callbacks and add it to the session
- In middleware, check `session.user.role` before allowing access to admin routes

### Gotchas
- Middleware runs on every matched path — keep it lightweight (no DB calls, no heavy imports)
- Use `matcher` config to exclude static assets: `"/((?!_next/static|_next/image|favicon.ico).*)`

---

## Skill: Cron Jobs (/api/cron)

### Handler location
`apps/web/app/api/cron/route.ts`

### Authentication
- EventBridge POSTs to `/api/cron` with `Authorization: Bearer <CRON_SECRET>`
- The handler validates the bearer token against `process.env.CRON_SECRET`
- Return 401 on mismatch — never log the secret

### Adding jobs
- Add a named job to the `switch` or `if` block inside the handler
- Pass `?job=<name>` query param from the EventBridge target input transformer
- Keep each job idempotent — EventBridge has at-least-once delivery

### Terraform wiring
- EventBridge rule in `modules/eventbridge/main.tf` fires on a schedule
- Target: HTTP endpoint `${var.cron_endpoint_url}/api/cron`
- Secret injected via `input_transformer` as the Authorization header value

---

## Skill: Health Endpoint (/api/health)

### Handler location
`apps/web/app/api/health/route.ts`

### What it checks
- Sends a `SELECT 1` to the database and measures round-trip latency
- Returns `200 { status: "ok", db: "ok", latency_ms: N }` on success
- Returns `503 { status: "error", db: "error", error: "..." }` on DB failure

### Usage
- Amplify health checks, uptime monitors, and load balancers hit this route
- No authentication required — does not expose sensitive data
- Keep the DB query minimal; never run migrations or seeds here

---

## Skill: S3 Presigned Uploads

### Pattern
1. Client calls a server action or API route to get a presigned PUT URL
2. Server calls `@aws-sdk/s3-request-presigner` → `getSignedUrl(s3, new PutObjectCommand(...))`
3. Client PUTs the file directly to S3 using the presigned URL (no server proxy)
4. On success, client saves the returned S3 key to the database via another server call

### Required env vars
`S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_REGION`, `S3_BUCKET_NAME`

### CORS
The S3 bucket has a CORS rule (configured in `modules/s3`) allowing PUT/GET/HEAD from
the app origin. If presigned PUT returns a CORS error, check that `app_base_url` in
`terraform/envs/dev/main.tf` matches the actual Amplify URL exactly (including `https://`).

### Gotchas
- Presigned URLs are single-use and expire (default 3600 s) — generate them at request time
- Always validate file type and size on the server before generating the URL
- Store only the S3 key (not the full URL) in the database; reconstruct URLs at read time
