import { SignJWT, jwtVerify } from "jose";
import { NextRequest, NextResponse } from "next/server";

export type Role = "ADMIN" | "SUPPLIER" | "QUALITY_INSPECTOR" | "RETAILER";

export interface SessionUser {
  user_id: number;
  email: string;
  role: Role;
  supplier_id: number | null;
  retailer_id: number | null;
}

function getSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET is not configured");
  return new TextEncoder().encode(secret);
}

export async function signToken(user: SessionUser): Promise<string> {
  return new SignJWT({ ...user })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("8h")
    .sign(getSecret());
}

// Reads the token from "Authorization: Bearer <token>" or the "token" cookie.
export async function getSession(req: NextRequest): Promise<SessionUser | null> {
  const header = req.headers.get("authorization");
  const token = header?.startsWith("Bearer ")
    ? header.slice(7)
    : req.cookies.get("token")?.value;
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, getSecret());
    return payload as unknown as SessionUser;
  } catch {
    return null;
  }
}

// 401 if not logged in, 403 if the role is not allowed.
export async function requireRole(
  req: NextRequest,
  roles: Role[]
): Promise<{ user: SessionUser } | { error: NextResponse }> {
  const user = await getSession(req);
  if (!user) {
    return { error: NextResponse.json({ error: "Authentication required" }, { status: 401 }) };
  }
  if (!roles.includes(user.role)) {
    return { error: NextResponse.json({ error: "Forbidden" }, { status: 403 }) };
  }
  return { user };
}
