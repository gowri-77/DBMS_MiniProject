import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { requireRole } from "@/lib/auth";

// ADMIN / INSPECTOR see all batches. A SUPPLIER sees only batches
// made from raw materials that supplier provided.
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
        `SELECT v.* FROM v_expiring_batches v
         WHERE v.batch_id IN (
           SELECT bm.batch_id FROM batch_materials bm
           JOIN raw_materials rm ON rm.material_id = bm.material_id
           WHERE rm.supplier_id = $1
         )`,
        [user.supplier_id]
      );
      return NextResponse.json(result.rows);
    }

    const result = await pool.query("SELECT * FROM v_expiring_batches");
    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Batch query failed:", error);
    return NextResponse.json({ error: "Failed to load batch information" }, { status: 500 });
  }
}
