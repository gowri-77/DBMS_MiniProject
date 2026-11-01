import { NextRequest, NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import { pool } from "@/lib/db";
import { signToken, SessionUser } from "@/lib/auth";

export async function POST(req: NextRequest) {
  let body: { email?: unknown; password?: unknown };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { email, password } = body;
  if (typeof email !== "string" || typeof password !== "string" || !email || !password) {
    return NextResponse.json({ error: "email and password are required" }, { status: 400 });
  }

  try {
    const result = await pool.query(
      `SELECT user_id, email, role, password_hash, supplier_id, retailer_id, is_active
       FROM users WHERE email = $1`,
      [email.trim().toLowerCase()]
    );
    const row = result.rows[0];

    // Same message for unknown email / wrong password / disabled account
    const ok = row && row.is_active && (await bcrypt.compare(password, row.password_hash));
    if (!ok) {
      return NextResponse.json({ error: "Invalid email or password" }, { status: 401 });
    }

    const user: SessionUser = {
      user_id: row.user_id,
      email: row.email,
      role: row.role,
      supplier_id: row.supplier_id,
      retailer_id: row.retailer_id,
    };
    const token = await signToken(user);

    const res = NextResponse.json({ token, user });
    res.cookies.set("token", token, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      maxAge: 8 * 60 * 60,
      path: "/",
    });
    return res;
  } catch (error) {
    console.error("Login failed:", error);
    return NextResponse.json({ error: "Login failed" }, { status: 500 });
  }
}
