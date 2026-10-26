import { NextResponse } from "next/server";
import { pool } from "@/lib/db";

export async function GET() {
  try {
    const result = await pool.query(
      "SELECT * FROM v_order_details ORDER BY order_date DESC"
    );

    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Order query failed:", error);

    return NextResponse.json(
      { error: "Failed to load order information" },
      { status: 500 }
    );
  }
}