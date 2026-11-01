// Creates one test user per role (bcrypt-hashed). Re-runnable.
// Run: SEED_PASSWORD='choose-a-password' node --env-file=.env.local scripts/create-test-users.mjs
import pg from "pg";
import bcrypt from "bcryptjs";

const password = process.env.SEED_PASSWORD;
if (!password || password.length < 8) {
  console.error("Set SEED_PASSWORD (8+ chars) in the command");
  process.exit(1);
}
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
try {
  const supplier = (await pool.query("SELECT supplier_id FROM suppliers ORDER BY supplier_id LIMIT 1")).rows[0];
  const retailer = (await pool.query("SELECT retailer_id FROM retailers ORDER BY retailer_id LIMIT 1")).rows[0];
  const hash = await bcrypt.hash(password, 10);
  const users = [
    ["Test Admin", "admin@test.com", "ADMIN", null, null],
    ["Test Inspector", "inspector@test.com", "QUALITY_INSPECTOR", null, null],
    ["Test Supplier", "supplier@test.com", "SUPPLIER", supplier.supplier_id, null],
    ["Test Retailer", "retailer@test.com", "RETAILER", null, retailer.retailer_id],
  ];
  for (const [name, email, role, sid, rid] of users) {
    await pool.query(
      `INSERT INTO users (name, email, role, password_hash, supplier_id, retailer_id)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash`,
      [name, email, role, hash, sid, rid]
    );
    console.log("ok:", email, role);
  }
} finally {
  await pool.end();
}
