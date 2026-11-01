import { NextRequest, NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import { pool } from "@/lib/db";
import { requireRole } from "@/lib/auth";

const ROLES = ["ADMIN", "SUPPLIER", "QUALITY_INSPECTOR", "RETAILER"];

export async function POST(req: NextRequest) {
  const auth = await requireRole(req, ["ADMIN"]);
  if ("error" in auth) return auth.error;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { name, email, password, role, supplier_id, retailer_id } = body;
  if (
    typeof name !== "string" || !name.trim() ||
    typeof email !== "string" || !email.trim() ||
    typeof password !== "string" ||
    typeof role !== "string"
  ) {
    return NextResponse.json({ error: "name, email, password and role are required" }, { status: 400 });
  }
  if (!ROLES.includes(role)) {
    return NextResponse.json({ error: `role must be one of ${ROLES.join(", ")}` }, { status: 400 });
  }
  if (password.length < 8) {
    return NextResponse.json({ error: "password must be at least 8 characters" }, { status: 400 });
  }

  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO users (name, email, role, password_hash, supplier_id, retailer_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING user_id, name, email, role, supplier_id, retailer_id`,
      [name.trim(), email.trim().toLowerCase(), role, hash, supplier_id ?? null, retailer_id ?? null]
    );
    return NextResponse.json(result.rows[0], { status: 201 });
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code === "23505") {
      return NextResponse.json({ error: "Email already registered" }, { status: 409 });
    }
    if (code === "23514" || code === "23503") {
      // CHECK (role/supplier/retailer link) or FK violation from the database
      return NextResponse.json({ error: "Invalid role / supplier / retailer combination" }, { status: 400 });
    }
    console.error("Register failed:", error);
    return NextResponse.json({ error: "Registration failed" }, { status: 500 });
  }
}
