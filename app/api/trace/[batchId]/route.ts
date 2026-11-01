import { NextRequest, NextResponse } from "next/server";
import { driver } from "@/lib/neo4j";
import { requireRole } from "@/lib/auth";

const UPSTREAM = `
MATCH (b:Batch {batch_id: $batchId})<-[u:USED_IN]-(m:RawMaterial)<-[:SUPPLIED]-(s:Supplier)
RETURN s.supplier_id AS supplier_id, s.name AS supplier, s.tier AS tier,
       m.material_id AS material_id, m.name AS material, m.lot_number AS lot,
       u.quantity_used AS quantity_used
ORDER BY s.tier, s.name`;

const DOWNSTREAM = `
MATCH (b:Batch {batch_id: $batchId})-[x:SHIPPED_AS]->(s:Shipment)
OPTIONAL MATCH (s)-[:SHIPPED_FROM]->(src:Warehouse)
OPTIONAL MATCH (s)-[:DELIVERED_TO]->(dest)
RETURN s.shipment_id AS shipment_id, s.status AS status, x.quantity AS quantity,
       src.name AS from_warehouse, labels(dest)[0] AS dest_type, dest.name AS destination
ORDER BY s.shipment_id`;

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ batchId: string }> }
) {
  const auth = await requireRole(req, ["ADMIN", "QUALITY_INSPECTOR"]);
  if ("error" in auth) return auth.error;

  const { batchId: raw } = await params;
  const batchId = Number(raw);
  if (!Number.isInteger(batchId) || batchId <= 0) {
    return NextResponse.json({ error: "batchId must be a positive integer" }, { status: 400 });
  }

  const direction = req.nextUrl.searchParams.get("direction") ?? "both";
  if (!["upstream", "downstream", "both"].includes(direction)) {
    return NextResponse.json({ error: "direction must be upstream, downstream or both" }, { status: 400 });
  }

  const session = driver.session();
  try {
    const exists = await session.run(
      "MATCH (b:Batch {batch_id: $batchId}) RETURN b.batch_code AS batch_code, b.status AS status",
      { batchId }
    );
    if (exists.records.length === 0) {
      return NextResponse.json({ error: `Batch ${batchId} not found` }, { status: 404 });
    }
    const batch = exists.records[0].toObject();

    const out: Record<string, unknown> = { batch_id: batchId, ...batch };
    if (direction !== "downstream") {
      out.upstream = (await session.run(UPSTREAM, { batchId })).records.map((r) => r.toObject());
    }
    if (direction !== "upstream") {
      out.downstream = (await session.run(DOWNSTREAM, { batchId })).records.map((r) => r.toObject());
    }
    return NextResponse.json(out);
  } catch (error) {
    console.error("Trace query failed:", error);
    return NextResponse.json({ error: "Failed to run trace query" }, { status: 500 });
  } finally {
    await session.close();
  }
}
