// Uniqueness constraints (also create indexes for fast trace entry points).
// IDs match the PostgreSQL primary keys.
CREATE CONSTRAINT supplier_id IF NOT EXISTS FOR (n:Supplier) REQUIRE n.supplier_id IS UNIQUE;
CREATE CONSTRAINT material_id IF NOT EXISTS FOR (n:RawMaterial) REQUIRE n.material_id IS UNIQUE;
CREATE CONSTRAINT batch_id IF NOT EXISTS FOR (n:Batch) REQUIRE n.batch_id IS UNIQUE;
CREATE CONSTRAINT shipment_id IF NOT EXISTS FOR (n:Shipment) REQUIRE n.shipment_id IS UNIQUE;
CREATE CONSTRAINT warehouse_id IF NOT EXISTS FOR (n:Warehouse) REQUIRE n.warehouse_id IS UNIQUE;
CREATE CONSTRAINT retailer_id IF NOT EXISTS FOR (n:Retailer) REQUIRE n.retailer_id IS UNIQUE;
