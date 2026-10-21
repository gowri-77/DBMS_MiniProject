-- =====================================================================
-- 01_schema.sql  |  Supply Chain Traceability System  |  Owner: Gowri (M1)
-- Core tables, constraints, indexes, full-text search, ALTER and DROP demos.
-- Requires PostgreSQL 13+ (generated columns, trusted pg_trgm extension).
-- Run order: 01_schema.sql, then 02_users.sql, 03_recall_tables.sql, ...
-- =====================================================================

-- ---------- Extensions ----------
CREATE EXTENSION IF NOT EXISTS pg_trgm;      -- fuzzy / partial batch-code search

-- =====================================================================
-- 1. TABLES
-- Status values are enforced with CHECK constraints (see docs/contract.md).
-- =====================================================================

CREATE TABLE suppliers (
    supplier_id    SERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL UNIQUE,
    contact_email  VARCHAR(100) UNIQUE,
    country        VARCHAR(60),
    tier           INT NOT NULL DEFAULT 1,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_suppliers_tier  CHECK (tier BETWEEN 1 AND 3),
    CONSTRAINT ck_suppliers_email CHECK (contact_email IS NULL OR
        contact_email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
);

CREATE TABLE raw_materials (
    material_id    SERIAL PRIMARY KEY,
    supplier_id    INT NOT NULL REFERENCES suppliers(supplier_id) ON DELETE RESTRICT,
    name           VARCHAR(100) NOT NULL,
    lot_number     VARCHAR(30)  NOT NULL,
    received_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    quantity       NUMERIC(12,2) NOT NULL,
    unit           VARCHAR(10) NOT NULL DEFAULT 'kg',
    CONSTRAINT ck_raw_materials_qty  CHECK (quantity >= 0),
    CONSTRAINT ck_raw_materials_unit CHECK (unit IN ('kg','litre','piece')),
    CONSTRAINT uq_supplier_lot       UNIQUE (supplier_id, lot_number)
);

CREATE TABLE products (
    product_id       SERIAL PRIMARY KEY,
    sku              VARCHAR(30)  NOT NULL UNIQUE,
    name             VARCHAR(100) NOT NULL,
    category         VARCHAR(50),
    description      TEXT,
    shelf_life_days  INT,
    -- full-text search column, kept in sync automatically by PostgreSQL
    search_vector    tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(name,'')),        'A') ||
        setweight(to_tsvector('english', coalesce(category,'')),    'B') ||
        setweight(to_tsvector('english', coalesce(description,'')), 'C')
    ) STORED,
    CONSTRAINT ck_products_shelf_life CHECK (shelf_life_days IS NULL OR shelf_life_days > 0)
);

CREATE TABLE batches (
    batch_id           SERIAL PRIMARY KEY,
    product_id         INT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    batch_code         VARCHAR(40) NOT NULL UNIQUE,
    manufactured_date  DATE NOT NULL,
    expiry_date        DATE,
    quantity_produced  INT NOT NULL,
    status             VARCHAR(15) NOT NULL DEFAULT 'ACTIVE',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_batches_qty    CHECK (quantity_produced > 0),
    CONSTRAINT ck_batches_status CHECK (status IN ('ACTIVE','QUARANTINED','RECALLED')),
    CONSTRAINT ck_batches_expiry CHECK (expiry_date IS NULL OR expiry_date > manufactured_date)
);

-- M:N  batches <-> raw_materials  (which material lots went into which batch)
CREATE TABLE batch_materials (
    batch_id       INT NOT NULL REFERENCES batches(batch_id)          ON DELETE CASCADE,
    material_id    INT NOT NULL REFERENCES raw_materials(material_id) ON DELETE RESTRICT,
    quantity_used  NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (batch_id, material_id),
    CONSTRAINT ck_batch_materials_qty CHECK (quantity_used > 0)
);

CREATE TABLE warehouses (
    warehouse_id  SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    city          VARCHAR(60),
    state         VARCHAR(60),
    latitude      NUMERIC(9,6) NOT NULL,      -- needed by the geo impact map
    longitude     NUMERIC(9,6) NOT NULL,
    capacity      INT NOT NULL,
    CONSTRAINT ck_warehouses_lat      CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT ck_warehouses_lon      CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_warehouses_capacity CHECK (capacity > 0)
);

CREATE TABLE retailers (
    retailer_id    SERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    city           VARCHAR(60),
    state          VARCHAR(60),
    latitude       NUMERIC(9,6) NOT NULL,
    longitude      NUMERIC(9,6) NOT NULL,
    contact_email  VARCHAR(100) UNIQUE,
    CONSTRAINT ck_retailers_lat   CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT ck_retailers_lon   CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_retailers_email CHECK (contact_email IS NULL OR
        contact_email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
);

-- stock of a batch held at a warehouse
CREATE TABLE inventory (
    inventory_id  SERIAL PRIMARY KEY,
    batch_id      INT NOT NULL REFERENCES batches(batch_id)       ON DELETE CASCADE,
    warehouse_id  INT NOT NULL REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT,
    quantity      INT NOT NULL DEFAULT 0,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_inventory_qty       CHECK (quantity >= 0),       -- stock can never go negative
    CONSTRAINT uq_inventory_batch_wh  UNIQUE (batch_id, warehouse_id)
);

CREATE TABLE orders (
    order_id         SERIAL PRIMARY KEY,
    retailer_id      INT NOT NULL REFERENCES retailers(retailer_id) ON DELETE RESTRICT,
    order_date       TIMESTAMPTZ NOT NULL DEFAULT now(),
    status           VARCHAR(15) NOT NULL DEFAULT 'PENDING',
    total_quantity   INT NOT NULL DEFAULT 0,
    CONSTRAINT ck_orders_status CHECK (status IN ('PENDING','CONFIRMED','SHIPPED','DELIVERED','CANCELLED')),
    CONSTRAINT ck_orders_qty    CHECK (total_quantity >= 0)
);

CREATE TABLE order_items (
    order_id  INT NOT NULL REFERENCES orders(order_id)   ON DELETE CASCADE,
    batch_id  INT NOT NULL REFERENCES batches(batch_id)  ON DELETE RESTRICT,
    quantity  INT NOT NULL,
    PRIMARY KEY (order_id, batch_id),
    CONSTRAINT ck_order_items_qty CHECK (quantity > 0)
);

-- warehouse -> warehouse  OR  warehouse -> retailer
CREATE TABLE shipments (
    shipment_id        SERIAL PRIMARY KEY,
    from_warehouse_id  INT NOT NULL REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT,
    to_warehouse_id    INT REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT,
    to_retailer_id     INT REFERENCES retailers(retailer_id)   ON DELETE RESTRICT,
    shipped_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at       TIMESTAMPTZ,
    status             VARCHAR(15) NOT NULL DEFAULT 'IN_TRANSIT',
    CONSTRAINT ck_shipments_status CHECK (status IN ('PENDING','IN_TRANSIT','DELIVERED','CANCELLED')),
    -- exactly one destination: a warehouse OR a retailer
    CONSTRAINT ck_shipments_one_dest CHECK (
        (to_warehouse_id IS NOT NULL)::int + (to_retailer_id IS NOT NULL)::int = 1),
    CONSTRAINT ck_shipments_not_self CHECK (to_warehouse_id IS NULL OR from_warehouse_id <> to_warehouse_id),
    CONSTRAINT ck_shipments_dates    CHECK (delivered_at IS NULL OR delivered_at >= shipped_at)
);

CREATE TABLE shipment_items (
    shipment_id  INT NOT NULL REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    batch_id     INT NOT NULL REFERENCES batches(batch_id)      ON DELETE RESTRICT,
    quantity     INT NOT NULL,
    PRIMARY KEY (shipment_id, batch_id),
    CONSTRAINT ck_shipment_items_qty CHECK (quantity > 0)
);

-- =====================================================================
-- 2. INDEXES
-- PostgreSQL does NOT auto-index foreign keys, so each FK used in joins or
-- trace queries gets one. Composite primary keys already cover their
-- leading column, so only the second column is indexed where needed.
-- =====================================================================

-- upstream trace: batch -> materials -> supplier
CREATE INDEX idx_raw_materials_supplier  ON raw_materials(supplier_id);
CREATE INDEX idx_batch_materials_material ON batch_materials(material_id);  -- "which batches used this lot?"

CREATE INDEX idx_batches_product ON batches(product_id);
CREATE INDEX idx_batches_expiry  ON batches(expiry_date);
-- partial index: only non-ACTIVE batches (a tiny fraction) are looked up by status
CREATE INDEX idx_batches_flagged ON batches(status) WHERE status <> 'ACTIVE';

CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);

-- downstream trace: batch -> shipments -> warehouses / retailers
CREATE INDEX idx_shipment_items_batch ON shipment_items(batch_id);
CREATE INDEX idx_shipments_from       ON shipments(from_warehouse_id);
CREATE INDEX idx_shipments_to_wh      ON shipments(to_warehouse_id)  WHERE to_warehouse_id IS NOT NULL;
CREATE INDEX idx_shipments_to_ret     ON shipments(to_retailer_id)   WHERE to_retailer_id  IS NOT NULL;
CREATE INDEX idx_shipments_shipped_at ON shipments(shipped_at);

CREATE INDEX idx_orders_retailer     ON orders(retailer_id);
CREATE INDEX idx_order_items_batch   ON order_items(batch_id);

-- full-text search on products, and partial-match search on batch codes
CREATE INDEX idx_products_fts        ON products USING GIN (search_vector);
CREATE INDEX idx_batches_code_trgm   ON batches  USING GIN (batch_code gin_trgm_ops);

-- =====================================================================
-- 3. KEEP updated_at CORRECT (small helper trigger)
-- =====================================================================
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_batches_updated   BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_inventory_updated BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 4. ALTER DEMOS (schema migrations discovered while designing the app)
-- =====================================================================

-- Migration 1: link shipments to the order they fulfil. NULL for plain
-- warehouse-to-warehouse transfers. Needed by the process_order transaction.
ALTER TABLE shipments
    ADD COLUMN order_id INT REFERENCES orders(order_id) ON DELETE SET NULL;
CREATE INDEX idx_shipments_order ON shipments(order_id) WHERE order_id IS NOT NULL;

-- Migration 2: soft-deactivate suppliers instead of deleting them
-- (raw_materials references them, so a hard delete is blocked anyway).
ALTER TABLE suppliers
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Migration 3: lot numbers from some suppliers exceed 30 characters.
ALTER TABLE raw_materials
    ALTER COLUMN lot_number TYPE VARCHAR(50);

-- Migration 4: add a constraint after the fact.
ALTER TABLE warehouses
    ADD CONSTRAINT uq_warehouse_name_city UNIQUE (name, city);

-- =====================================================================
-- 5. DROP DEMOS
-- =====================================================================

-- Demo A: a scratch table used for a one-off supplier CSV import, then removed.
CREATE TABLE tmp_supplier_import (
    raw_line  TEXT,
    loaded_at TIMESTAMPTZ DEFAULT now()
);
DROP TABLE tmp_supplier_import;

-- Demo B: an index that duplicates what an existing constraint already provides.
-- UNIQUE (batch_id, warehouse_id) already serves lookups by batch_id alone.
CREATE INDEX idx_inventory_batch ON inventory(batch_id);
DROP INDEX idx_inventory_batch;
