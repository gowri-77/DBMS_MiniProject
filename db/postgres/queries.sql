-- =====================================================================
-- queries.sql  |  Important queries  |  Owner: Gowri (M1)
-- Written against the data in 99_seed.sql. Each query names the concept it shows.
-- Run: psql -U postgres -d supplychain -f db/postgres/queries.sql
-- =====================================================================

\echo '== Q1  JOIN (4 tables): upstream lineage of batch AM-260801 =='
SELECT b.batch_code, p.name AS product, m.name AS material, m.lot_number,
       s.name AS supplier, s.country, bm.quantity_used
FROM batches b
JOIN products p        ON p.product_id  = b.product_id
JOIN batch_materials bm ON bm.batch_id  = b.batch_id
JOIN raw_materials m   ON m.material_id = bm.material_id
JOIN suppliers s       ON s.supplier_id = m.supplier_id
WHERE b.batch_code = 'AM-260801'
ORDER BY s.name;

\echo '== Q2  JOIN + DISTINCT: every retailer reached by almond lot ALM-2026-A1 (recall scope) =='
SELECT DISTINCT r.name AS retailer, r.city, b.batch_code, si.quantity AS units
FROM raw_materials m
JOIN batch_materials bm ON bm.material_id = m.material_id
JOIN batches b          ON b.batch_id     = bm.batch_id
JOIN shipment_items si  ON si.batch_id    = b.batch_id
JOIN shipments sh       ON sh.shipment_id = si.shipment_id
JOIN retailers r        ON r.retailer_id  = sh.to_retailer_id
WHERE m.lot_number = 'ALM-2026-A1'
ORDER BY r.city, r.name, b.batch_code;

\echo '== Q3  GROUP BY + HAVING + ORDER BY: suppliers whose lots feed 3 or more batches =='
SELECT s.name AS supplier, count(DISTINCT bm.batch_id) AS batches_fed,
       count(DISTINCT p.product_id) AS products_fed
FROM suppliers s
JOIN raw_materials m    ON m.supplier_id = s.supplier_id
JOIN batch_materials bm ON bm.material_id = m.material_id
JOIN batches b          ON b.batch_id = bm.batch_id
JOIN products p         ON p.product_id = b.product_id
GROUP BY s.name
HAVING count(DISTINCT bm.batch_id) >= 3
ORDER BY batches_fed DESC, supplier;

\echo '== Q4  Aggregates: warehouse stock and capacity utilisation =='
SELECT w.name, w.city, sum(i.quantity) AS units_in_stock, w.capacity,
       round(100.0 * sum(i.quantity) / w.capacity, 1) AS utilisation_pct
FROM warehouses w
LEFT JOIN inventory i ON i.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.name, w.city, w.capacity
ORDER BY utilisation_pct DESC NULLS LAST;

\echo '== Q5  Subquery (NOT EXISTS): batches that have never been shipped anywhere =='
SELECT b.batch_code, p.name AS product, b.quantity_produced
FROM batches b JOIN products p ON p.product_id = b.product_id
WHERE NOT EXISTS (SELECT 1 FROM shipment_items si WHERE si.batch_id = b.batch_id)
ORDER BY b.batch_code;

\echo '== Q6  Scalar subquery: batches holding more stock than the average per-batch stock =='
SELECT b.batch_code, sum(i.quantity) AS total_stock
FROM batches b JOIN inventory i ON i.batch_id = b.batch_id
GROUP BY b.batch_id, b.batch_code
HAVING sum(i.quantity) > (SELECT avg(t.total) FROM (SELECT sum(quantity) AS total FROM inventory GROUP BY batch_id) t)
ORDER BY total_stock DESC;

\echo '== Q7  Subquery with IN: retailers that received anything containing Kaveri Sugar Mills lots =='
SELECT r.name, r.city
FROM retailers r
WHERE r.retailer_id IN (
    SELECT sh.to_retailer_id
    FROM shipments sh
    JOIN shipment_items si  ON si.shipment_id = sh.shipment_id
    JOIN batch_materials bm ON bm.batch_id    = si.batch_id
    JOIN raw_materials m    ON m.material_id  = bm.material_id
    JOIN suppliers s        ON s.supplier_id  = m.supplier_id
    WHERE s.name = 'Kaveri Sugar Mills' AND sh.to_retailer_id IS NOT NULL)
ORDER BY r.city, r.name;

\echo '== Q8  Window function: rank warehouses by units shipped out =='
SELECT w.name, sum(si.quantity) AS units_shipped_out,
       RANK() OVER (ORDER BY sum(si.quantity) DESC) AS rank
FROM warehouses w
JOIN shipments sh      ON sh.from_warehouse_id = w.warehouse_id
JOIN shipment_items si ON si.shipment_id = sh.shipment_id
GROUP BY w.warehouse_id, w.name
ORDER BY rank;

\echo '== Q9  Date aggregation: units shipped per month =='
SELECT date_trunc('month', sh.shipped_at)::date AS month, count(DISTINCT sh.shipment_id) AS shipments,
       sum(si.quantity) AS units
FROM shipments sh JOIN shipment_items si ON si.shipment_id = sh.shipment_id
GROUP BY 1 ORDER BY 1;

\echo '== Q10 Full-text search: products matching "almond" =='
SELECT sku, name, round(ts_rank(search_vector, q)::numeric, 3) AS relevance
FROM products, websearch_to_tsquery('english', 'almond') q
WHERE search_vector @@ q
ORDER BY relevance DESC;

\echo '== Q11 Partial-match search on batch codes (uses the trigram index) =='
SELECT batch_code, status FROM batches WHERE batch_code ILIKE '%2608%' ORDER BY batch_code;

\echo '== Q12 WITH RECURSIVE: how many hops did batch AM-260801 travel? (the query Neo4j makes simple) =='
WITH RECURSIVE edges AS (            -- every movement of this batch, as (from warehouse -> destination)
    SELECT sh.from_warehouse_id AS src,
           COALESCE('W' || sh.to_warehouse_id, 'R' || sh.to_retailer_id) AS dst
    FROM shipments sh
    JOIN shipment_items si ON si.shipment_id = sh.shipment_id
    JOIN batches b         ON b.batch_id = si.batch_id
    WHERE b.batch_code = 'AM-260801'
), trace AS (
    SELECT e.src, e.dst, 1 AS hop, ARRAY['W' || e.src, e.dst] AS path
    FROM edges e
    WHERE 'W' || e.src NOT IN (SELECT dst FROM edges)        -- start at the origin warehouse
  UNION ALL
    SELECT e.src, e.dst, t.hop + 1, t.path || e.dst
    FROM trace t JOIN edges e ON 'W' || e.src = t.dst
    WHERE NOT e.dst = ANY (t.path)                          -- cycle guard
)
SELECT hop, array_to_string(path, ' -> ') AS route FROM trace WHERE dst LIKE 'R%' ORDER BY hop, route;
