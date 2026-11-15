import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { requireRole } from "@/lib/auth";

export async function GET(req: NextRequest) {
  const auth = await requireRole(req, ["ADMIN", "INSPECTOR", "SUPPLIER"]);
  if ("error" in auth) return auth.error;

  try {
    const result = await pool.query("SELECT * FROM v_low_stock");
    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Low-stock query failed:", error);
    return NextResponse.json({ error: "Failed to load low-stock information" }, { status: 500 });
  }
}
