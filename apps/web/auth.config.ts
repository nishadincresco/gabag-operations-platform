import type { NextAuthConfig } from "next-auth";

// Edge-safe config: no Prisma, no Node.js-only modules.
// Imported by both auth.ts (full Node runtime) and middleware.ts (Edge runtime).
export const authConfig: NextAuthConfig = {
  session: { strategy: "jwt" },
  trustHost: true,
  pages: { signIn: "/login" },
  // Providers that require DB access are added in auth.ts only.
  providers: [],
};
