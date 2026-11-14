import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { getSession } from "@/lib/auth";

// Public: only reports connected/error. Database name and version are shown to ADMIN only.
export async function GET(req: NextRequest) {
  try {
    const result = await pool.query(
      "SELECT current_database() AS database, version() AS version"
    );
    const user = await getSession(req);
    if (user?.role === "ADMIN") {
      return NextResponse.json({
        status: "connected",
        database: result.rows[0].database,
        version: result.rows[0].version,
      });
    }
    return NextResponse.json({ status: "connected" });
  } catch (error) {
    console.error("Database health check failed:", error);
    return NextResponse.json(
      { status: "error", message: "Database connection failed" },
      { status: 500 }
    );
  }
}
