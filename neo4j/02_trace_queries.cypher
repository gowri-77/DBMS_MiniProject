// UPSTREAM: batch -> raw materials -> contributing suppliers
// Param: $batchId (integer)
MATCH (b:Batch {batch_id: $batchId})<-[u:USED_IN]-(m:RawMaterial)<-[:SUPPLIED]-(s:Supplier)
RETURN s.supplier_id AS supplier_id, s.name AS supplier, s.tier AS tier,
       m.material_id AS material_id, m.name AS material, m.lot_number AS lot,
       u.quantity_used AS quantity_used
ORDER BY s.tier, s.name;

// DOWNSTREAM: batch -> shipments -> warehouses / retailers that received it
MATCH (b:Batch {batch_id: $batchId})-[x:SHIPPED_AS]->(s:Shipment)
OPTIONAL MATCH (s)-[:SHIPPED_FROM]->(src:Warehouse)
OPTIONAL MATCH (s)-[:DELIVERED_TO]->(dest)
RETURN s.shipment_id AS shipment_id, s.status AS status, x.quantity AS quantity,
       src.name AS from_warehouse, labels(dest)[0] AS dest_type, dest.name AS destination
ORDER BY s.shipment_id;

// MULTI-TIER UPSTREAM: suppliers behind the direct suppliers, up to N tiers.
// Needs SUPPLIES_RAW_MATERIAL_TO edges (db/postgres/02a_supplier_links.sql + neo4j/import.mjs).
// Cypher cannot take the depth as a parameter; the API substitutes a validated integer (1-5).
MATCH (b:Batch {batch_id: $batchId})<-[:USED_IN]-(:RawMaterial)<-[:SUPPLIED]-(s:Supplier)
WITH DISTINCT s
MATCH p = (up:Supplier)-[:SUPPLIES_RAW_MATERIAL_TO*1..3]->(s)
RETURN s.supplier_id AS direct_supplier_id, s.name AS direct_supplier,
       up.supplier_id AS supplier_id, up.name AS supplier, up.tier AS tier,
       length(p) AS hops, [n IN nodes(p) | n.name] AS path
ORDER BY hops, supplier;
