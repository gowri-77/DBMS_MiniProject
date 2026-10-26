import { NextResponse } from "next/server";
import { pool } from "@/lib/db";

export async function GET() {
  try {
    const result = await pool.query("SELECT * FROM v_low_stock");

    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Low-stock query failed:", error);

    return NextResponse.json(
      { error: "Failed to load low-stock information" },
      { status: 500 }
    );
  }
}