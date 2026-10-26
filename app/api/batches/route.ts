import { NextResponse } from "next/server";
import { pool } from "@/lib/db";

export async function GET() {
  try {
    const result = await pool.query(
      "SELECT * FROM v_expiring_batches"
    );

    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Batch query failed:", error);

    return NextResponse.json(
      { error: "Failed to load batch information" },
      { status: 500 }
    );
  }
}