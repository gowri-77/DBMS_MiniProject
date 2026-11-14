import { NextRequest, NextResponse } from "next/server";
import { pool } from "@/lib/db";
import { requireRole } from "@/lib/auth";

// ADMIN sees every order. A RETAILER sees only orders placed by their own retailer.
export async function GET(req: NextRequest) {
  const auth = await requireRole(req, ["ADMIN", "RETAILER"]);
  if ("error" in auth) return auth.error;
  const { user } = auth;

  try {
    if (user.role === "RETAILER") {
      if (user.retailer_id == null) {
        return NextResponse.json({ error: "Forbidden" }, { status: 403 });
      }
      const result = await pool.query(
        `SELECT v.* FROM v_order_details v
         JOIN orders o ON o.order_id = v.order_id
         WHERE o.retailer_id = $1
         ORDER BY v.order_date DESC`,
        [user.retailer_id]
      );
      return NextResponse.json(result.rows);
    }

    const result = await pool.query(
      "SELECT * FROM v_order_details ORDER BY order_date DESC"
    );
    return NextResponse.json(result.rows);
  } catch (error) {
    console.error("Order query failed:", error);
    return NextResponse.json({ error: "Failed to load order information" }, { status: 500 });
  }
}
