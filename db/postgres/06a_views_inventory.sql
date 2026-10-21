-- =====================================================================
-- 06a_views_inventory.sql  |  Owner: Gowri (M1)
-- Views that feed the inventory dashboard and the order/batch pages.
-- Run after 01_schema.sql (and 99_seed.sql if you want data in them).
-- =====================================================================

-- 1. Stock per batch across all warehouses (batches page, dashboard)
CREATE OR REPLACE VIEW v_inventory_summary AS
SELECT b.batch_id, b.batch_code, p.name AS product, p.category, b.status,
       b.expiry_date,
       COALESCE(SUM(i.quantity), 0)         AS total_stock,
       COUNT(i.warehouse_id) FILTER (WHERE i.quantity > 0) AS warehouses_holding
FROM batches b
JOIN products p        ON p.product_id = b.product_id
LEFT JOIN inventory i  ON i.batch_id   = b.batch_id
GROUP BY b.batch_id, b.batch_code, p.name, p.category, b.status, b.expiry_date;

-- 2. Stock and utilisation per warehouse (dashboard cards)
CREATE OR REPLACE VIEW v_warehouse_stock AS
SELECT w.warehouse_id, w.name, w.city, w.state, w.capacity,
       COALESCE(SUM(i.quantity), 0) AS units_in_stock,
       COUNT(i.batch_id) FILTER (WHERE i.quantity > 0) AS batches_held,
       ROUND(100.0 * COALESCE(SUM(i.quantity), 0) / w.capacity, 1) AS utilisation_pct
FROM warehouses w
LEFT JOIN inventory i ON i.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.name, w.city, w.state, w.capacity;

-- 3. Low-stock alerts: a batch holding fewer than 500 units at a warehouse
--    (threshold is a plain number here; change it in this one place)
CREATE OR REPLACE VIEW v_low_stock AS
SELECT w.name AS warehouse, b.batch_code, p.name AS product, i.quantity
FROM inventory i
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
JOIN batches b    ON b.batch_id     = i.batch_id
JOIN products p   ON p.product_id   = b.product_id
WHERE i.quantity < 500 AND b.status = 'ACTIVE';

-- 4. Batches that still have stock and expire within 120 days
CREATE OR REPLACE VIEW v_expiring_batches AS
SELECT b.batch_id, b.batch_code, p.name AS product, b.expiry_date,
       (b.expiry_date - CURRENT_DATE) AS days_left,
       SUM(i.quantity) AS units_in_stock
FROM batches b
JOIN products p  ON p.product_id = b.product_id
JOIN inventory i ON i.batch_id   = b.batch_id
WHERE b.expiry_date IS NOT NULL
  AND b.expiry_date <= CURRENT_DATE + 120
  AND b.status = 'ACTIVE'
GROUP BY b.batch_id, b.batch_code, p.name, b.expiry_date
HAVING SUM(i.quantity) > 0;

-- 5. Orders with retailer, item count and shipment status (orders page)
CREATE OR REPLACE VIEW v_order_details AS
SELECT o.order_id, o.order_date, o.status AS order_status,
       r.retailer_id, r.name AS retailer, r.city,
       COUNT(DISTINCT oi.batch_id)       AS batches_ordered,
       o.total_quantity,
       MAX(s.status)                     AS shipment_status,
       MAX(s.delivered_at)               AS delivered_at
FROM orders o
JOIN retailers r        ON r.retailer_id = o.retailer_id
LEFT JOIN order_items oi ON oi.order_id  = o.order_id
LEFT JOIN shipments s    ON s.order_id   = o.order_id
GROUP BY o.order_id, o.order_date, o.status, r.retailer_id, r.name, r.city, o.total_quantity;
