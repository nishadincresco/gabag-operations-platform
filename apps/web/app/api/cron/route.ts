import { NextRequest, NextResponse } from "next/server";

/**
 * POST /api/cron
 *
 * Called by AWS EventBridge on a schedule. Validates the shared secret
 * before running any jobs. Add your scheduled tasks inside the try block.
 */
export async function POST(req: NextRequest) {
  const authHeader = req.headers.get("authorization");
  const expectedSecret = process.env.CRON_SECRET;

  if (!expectedSecret) {
    return NextResponse.json(
      { error: "CRON_SECRET not configured" },
      { status: 500 }
    );
  }

  // EventBridge sends: Authorization: Bearer <CRON_SECRET>
  const token = authHeader?.replace("Bearer ", "");
  if (token !== expectedSecret) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    // ── Add your scheduled jobs here ──────────────────────────────────────
    // Example:
    // await processQueue();
    // await sendDigestEmails();
    // await cleanupExpiredSessions();

    const startedAt = Date.now();

    // Placeholder — replace with your actual cron logic
    console.log("[cron] Job started at", new Date().toISOString());

    return NextResponse.json({
      ok: true,
      durationMs: Date.now() - startedAt,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("[cron] Job failed:", error);
    return NextResponse.json(
      { error: "Cron job failed", message: String(error) },
      { status: 500 }
    );
  }
}
