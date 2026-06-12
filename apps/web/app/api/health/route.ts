import { NextResponse } from "next/server";
import { prisma } from "@repo/db";

/**
 * GET /api/health
 *
 * Returns service health with database connectivity check.
 * Used by uptime monitors, load balancers, and Amplify health checks.
 */
export async function GET() {
  const start = Date.now();

  try {
    // Ping the database with a lightweight query
    await prisma.$queryRaw`SELECT 1`;
    const dbLatencyMs = Date.now() - start;

    return NextResponse.json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      checks: {
        database: { status: "up", latencyMs: dbLatencyMs },
      },
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "unhealthy",
        timestamp: new Date().toISOString(),
        checks: {
          database: {
            status: "down",
            error: error instanceof Error ? error.message : String(error),
          },
        },
      },
      { status: 503 }
    );
  }
}
