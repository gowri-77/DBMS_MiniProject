// Loads PostgreSQL data into Neo4j. Safe to re-run (uses MERGE, refreshes properties).
// Run: node --env-file=.env.local neo4j/import.mjs
import fs from 'node:fs';
import pg from 'pg';
import neo4j from 'neo4j-driver';

const { DATABASE_URL, NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD } = process.env;
if (!DATABASE_URL || !NEO4J_URI || !NEO4J_USER || !NEO4J_PASSWORD) {
  console.error('Missing DATABASE_URL / NEO4J_URI / NEO4J_USER / NEO4J_PASSWORD in env');
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: DATABASE_URL });
const driver = neo4j.driver(NEO4J_URI, neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD));
const session = driver.session();

async function load(label, sql, cypher, filter = () => true) {
  const { rows } = await pool.query(sql);
  const data = rows.filter(filter);
  if (data.length) await session.run(cypher, { rows: data });
  console.log(`${label}: ${data.length}`);
}

try {
  // constraints
  const stmts = fs.readFileSync(new URL('./01_constraints.cypher', import.meta.url), 'utf8')
    .split(';').map(s => s.trim()).filter(s => s.includes('CREATE'));
  for (const s of stmts) await session.run(s.replace(/^\/\/.*$/gm, ''));

  // nodes
  await load('suppliers', 'SELECT supplier_id, name, tier FROM suppliers',
    `UNWIND $rows AS r MERGE (n:Supplier {supplier_id: toInteger(r.supplier_id)})
     SET n.name = r.name, n.tier = toInteger(r.tier)`);
  await load('raw_materials', 'SELECT material_id, supplier_id, name, lot_number FROM raw_materials',
    `UNWIND $rows AS r MERGE (m:RawMaterial {material_id: toInteger(r.material_id)})
     SET m.name = r.name, m.lot_number = r.lot_number
     WITH m, r MATCH (s:Supplier {supplier_id: toInteger(r.supplier_id)})
     MERGE (s)-[:SUPPLIED]->(m)`);
  await load('batches', 'SELECT batch_id, product_id, batch_code, status, manufactured_date::text AS manufactured_date FROM batches',
    `UNWIND $rows AS r MERGE (b:Batch {batch_id: toInteger(r.batch_id)})
     SET b.product_id = toInteger(r.product_id), b.batch_code = r.batch_code,
         b.status = r.status, b.manufactured_date = r.manufactured_date`);
  await load('warehouses', 'SELECT warehouse_id, name FROM warehouses',
    `UNWIND $rows AS r MERGE (w:Warehouse {warehouse_id: toInteger(r.warehouse_id)}) SET w.name = r.name`);
  await load('retailers', 'SELECT retailer_id, name FROM retailers',
    `UNWIND $rows AS r MERGE (t:Retailer {retailer_id: toInteger(r.retailer_id)}) SET t.name = r.name`);
  await load('shipments', `SELECT shipment_id, status, shipped_at::text AS shipped_at, delivered_at::text AS delivered_at FROM shipments`,
    `UNWIND $rows AS r MERGE (s:Shipment {shipment_id: toInteger(r.shipment_id)})
     SET s.status = r.status, s.shipped_at = r.shipped_at, s.delivered_at = r.delivered_at`);

  // relationships
  await load('batch_materials', 'SELECT batch_id, material_id, quantity_used FROM batch_materials',
    `UNWIND $rows AS r
     MATCH (m:RawMaterial {material_id: toInteger(r.material_id)}), (b:Batch {batch_id: toInteger(r.batch_id)})
     MERGE (m)-[u:USED_IN]->(b) SET u.quantity_used = toInteger(r.quantity_used)`);
  await load('shipment_items', 'SELECT shipment_id, batch_id, quantity FROM shipment_items',
    `UNWIND $rows AS r
     MATCH (b:Batch {batch_id: toInteger(r.batch_id)}), (s:Shipment {shipment_id: toInteger(r.shipment_id)})
     MERGE (b)-[x:SHIPPED_AS]->(s) SET x.quantity = toInteger(r.quantity)`);
  await load('shipped_from', 'SELECT shipment_id, from_warehouse_id FROM shipments',
    `UNWIND $rows AS r
     MATCH (s:Shipment {shipment_id: toInteger(r.shipment_id)}), (w:Warehouse {warehouse_id: toInteger(r.from_warehouse_id)})
     MERGE (s)-[:SHIPPED_FROM]->(w)`, r => r.from_warehouse_id != null);
  await load('delivered_to_warehouse', 'SELECT shipment_id, to_warehouse_id FROM shipments',
    `UNWIND $rows AS r
     MATCH (s:Shipment {shipment_id: toInteger(r.shipment_id)}), (w:Warehouse {warehouse_id: toInteger(r.to_warehouse_id)})
     MERGE (s)-[:DELIVERED_TO]->(w)`, r => r.to_warehouse_id != null);
  await load('delivered_to_retailer', 'SELECT shipment_id, to_retailer_id FROM shipments',
    `UNWIND $rows AS r
     MATCH (s:Shipment {shipment_id: toInteger(r.shipment_id)}), (t:Retailer {retailer_id: toInteger(r.to_retailer_id)})
     MERGE (s)-[:DELIVERED_TO]->(t)`, r => r.to_retailer_id != null);

  console.log('Import complete');
} finally {
  await session.close();
  await driver.close();
  await pool.end();
}
