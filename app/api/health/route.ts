import { NextResponse } from "next/server";
import { pool } from "@/lib/db";

export async function GET() {
  try {
    const result = await pool.query(
      "SELECT current_database() AS database, version() AS version"
    );

    return NextResponse.json({
      status: "connected",
      database: result.rows[0].database,
      version: result.rows[0].version,
    });
  } catch (error) {
    console.error("Database health check failed:", error);

    return NextResponse.json(
      { status: "error", message: "Database connection failed" },
      { status: 500 }
    );
  }
}