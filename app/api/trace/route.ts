import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { requireRole } from "@/lib/auth";

// Lists batches so the trace page can offer a picker.
// SUPPLIER sees only batches that contain their materials.
export async function GET(req: NextRequest) {
  const auth = await requireRole(req, ["ADMIN", "INSPECTOR", "SUPPLIER"]);
  if ("error" in auth) return auth.error;
  const { user } = auth;

  try {
    if (user.role === "SUPPLIER") {
      if (user.supplier_id == null) {
        return NextResponse.json({ error: "Forbidden" }, { status: 403 });
      }
      const result = await pool.query(
        `SELECT b.batch_id, b.batch_code, b.status, p.name AS product
         FROM batches b JOIN products p ON p.product_id = b.product_id
         WHERE b.batch_id IN (
           SELECT bm.batch_id FROM batch_materials bm
           JOIN raw_materials rm ON rm.material_id = bm.material_id
           WHERE rm.supplier_id = $1)
         ORDER BY b.batch_id`,
        [user.supplier_id]
      );
      return NextResponse.json(result.rows);
    }
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
