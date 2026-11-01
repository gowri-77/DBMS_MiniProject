import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { requireRole } from "@/lib/auth";

// Lists batches so the trace page can offer a picker.
export async function GET(req: NextRequest) {
  const auth = await requireRole(req, ["ADMIN", "QUALITY_INSPECTOR"]);
  if ("error" in auth) return auth.error;

  try {
    const result = await pool.query(
      `SELECT b.batch_id, b.batch_code, b.status, p.name AS product
       FROM batches b JOIN products p ON p.product_id = b.product_id
       ORDER BY b.batch_id`
    );
    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Batch list failed:", error);
    return NextResponse.json({ error: "Failed to load batches" }, { status: 500 });
  }
}
