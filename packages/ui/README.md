# @repo/ui

Stub package reserved for shared UI components that need to run across multiple
apps (e.g. a future React Native / Expo mobile app).

**For web development, use `apps/web/components/ui` (shadcn/ui components) instead.**
The shadcn components live alongside the app and are configured via
`apps/web/components.json` (new-york style, zinc palette).

This package exists so Turborepo's dependency graph is wired up for the
eventual mobile app. Until a mobile app is added there is nothing useful here.
