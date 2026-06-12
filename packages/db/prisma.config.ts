import path from "node:path";
import { defineConfig } from "prisma/config";
import { PrismaPg } from "@prisma/adapter-pg";
import pg from "pg";

const { Pool } = pg;

export default defineConfig({
  schema: path.join(import.meta.dirname, "prisma/schema.prisma"),

  migrate: {
    async adapter(env: Record<string, string | undefined>) {
      const connectionString = env["DATABASE_URL"];
      if (!connectionString) {
        throw new Error(
          "DATABASE_URL is not set — required for prisma migrate deploy.\n" +
            "  Local: ensure DATABASE_URL is in your root .env\n" +
            "  CI:    add DATABASE_URL as a GitHub Actions secret"
        );
      }
      const pool = new Pool({ connectionString });
      return new PrismaPg(pool);
    },
  },
});
