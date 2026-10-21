-- =====================================================================
-- 99_seed.sql  |  Supply Chain Traceability System  |  Owner: Gowri (M1)
-- Realistic demo data. Run AFTER 01_schema.sql (fresh tables).
-- To re-seed: run 00_reset.sql, then all SQL files again.
-- Whole script is one transaction: any error rolls everything back.
--
-- Story built into the data (use it for the demo):
--   * Almond lot ALM-2026-A1 (supplier 1) went into almond milk AM-260801
--     AND almond chocolate CH-260805  -> a recall touches 2 products.
--   * Kaveri Sugar Mills (supplier 3) feeds 10 of the 12 batches across 5 products
--     -> a structural single point of failure (supplier risk score).
--   * Chains are multi-hop, e.g. Bengaluru -> Hyderabad -> Mumbai -> retailer.
-- =====================================================================
BEGIN;

-- ---------- Suppliers ----------
INSERT INTO suppliers (supplier_id, name, contact_email, country, tier) VALUES
 (1, 'Western Ghats Almonds Pvt Ltd',  'sales@wgalmonds.in',          'India', 1),
 (2, 'Sunrise Peanut Growers Co-op',   'contact@sunrisepeanuts.in',   'India', 2),
 (3, 'Kaveri Sugar Mills',             'orders@kaverisugar.in',       'India', 1),
 (4, 'Deccan Flour Mills',             'info@deccanflour.in',         'India', 1),
 (5, 'Ratnagiri Mango Orchards',       'sales@ratnagirimango.in',     'India', 2),
 (6, 'Cocoa Coast Traders',            'export@cocoacoast.com.gh',    'Ghana', 3),
 (7, 'Himalayan Basmati Growers',      'trade@himalayanbasmati.in',   'India', 2),
 (8, 'PackRight Containers',           'sales@packright.in',          'India', 1);

-- ---------- Raw materials (each row is one supplier lot) ----------
INSERT INTO raw_materials (material_id, supplier_id, name, lot_number, received_date, quantity, unit) VALUES
 ( 1, 1, 'Almonds',        'ALM-2026-A1', '2026-07-20',  1000, 'kg'),
 ( 2, 1, 'Almonds',        'ALM-2026-A2', '2026-09-05',  1000, 'kg'),
 ( 3, 2, 'Peanuts',        'PNT-2026-P1', '2026-07-25',  2000, 'kg'),
 ( 4, 2, 'Peanuts',        'PNT-2026-P2', '2026-09-08',  2000, 'kg'),
 ( 5, 3, 'Sugar',          'SUG-2026-S1', '2026-07-15',  5000, 'kg'),
 ( 6, 3, 'Sugar',          'SUG-2026-S2', '2026-08-25',  5000, 'kg'),
 ( 7, 4, 'Wheat Flour',    'WHT-2026-F1', '2026-09-25',  5000, 'kg'),
 ( 8, 5, 'Mango Pulp',     'MNG-2026-M1', '2026-08-20',  5000, 'kg'),
 ( 9, 6, 'Cocoa Mass',     'COC-2026-C1', '2026-07-28',  1000, 'kg'),
 (10, 6, 'Cocoa Mass',     'COC-2026-C2', '2026-09-18',  1000, 'kg'),
 (11, 7, 'Basmati Rice',   'RCE-2026-R1', '2026-07-30', 50000, 'kg'),
 (12, 8, 'Glass Bottles',  'PKG-2026-B1', '2026-07-10', 15000, 'piece'),
 (13, 8, 'Plastic Jars',   'PKG-2026-J1', '2026-07-10',  6000, 'piece');

-- ---------- Products ----------
INSERT INTO products (product_id, sku, name, category, description, shelf_life_days) VALUES
 (1, 'BEV-ALM-1L',  'Organic Almond Milk 1L',     'Beverages',    'Unsweetened plant-based almond milk, cold filled in glass bottles', 180),
 (2, 'SPR-PNB-340', 'Creamy Peanut Butter 340g',  'Spreads',      'Roasted peanut spread with a little sugar, no palm oil',            270),
 (3, 'BAK-RSK-300', 'Multigrain Rusk 300g',       'Bakery',       'Twice-baked wheat rusk, long shelf life',                           120),
 (4, 'BEV-MNG-1L',  'Alphonso Mango Juice 1L',    'Beverages',    'Fruit juice from Ratnagiri Alphonso mango pulp',                    270),
 (5, 'CNF-ADC-100', 'Almond Dark Chocolate 100g', 'Confectionery','Dark chocolate bar with roasted almond pieces',                     365),
 (6, 'STP-BAS-5K',  'Premium Basmati Rice 5kg',   'Staples',      'Aged long-grain basmati rice',                                      540);

-- ---------- Batches (expiry = manufactured date + product shelf life) ----------
INSERT INTO batches (batch_id, product_id, batch_code, manufactured_date, expiry_date, quantity_produced)
SELECT v.id, p.product_id, v.code, v.mdate, v.mdate + p.shelf_life_days, v.qty
FROM (VALUES
 ( 1, 'BEV-ALM-1L',  'AM-260801', DATE '2026-08-01', 5000),
 ( 2, 'BEV-ALM-1L',  'AM-260915', DATE '2026-09-15', 4000),
 ( 3, 'SPR-PNB-340', 'PB-260805', DATE '2026-08-05', 2500),
 ( 4, 'SPR-PNB-340', 'PB-260918', DATE '2026-09-18', 2500),
 ( 5, 'BAK-RSK-300', 'RK-261005', DATE '2026-10-05', 3000),
 ( 6, 'BAK-RSK-300', 'RK-261012', DATE '2026-10-12', 3000),
 ( 7, 'BEV-MNG-1L',  'MJ-260901', DATE '2026-09-01', 3500),
 ( 8, 'BEV-MNG-1L',  'MJ-261002', DATE '2026-10-02', 3500),
 ( 9, 'CNF-ADC-100', 'CH-260805', DATE '2026-08-05', 2000),
 (10, 'CNF-ADC-100', 'CH-260930', DATE '2026-09-30', 2000),
 (11, 'STP-BAS-5K',  'RC-260810', DATE '2026-08-10', 4000),
 (12, 'STP-BAS-5K',  'RC-260905', DATE '2026-09-05', 4000)
) AS v(id, sku, code, mdate, qty)
JOIN products p ON p.sku = v.sku;

-- ---------- Which raw-material lots went into which batch ----------
INSERT INTO batch_materials (batch_id, material_id, quantity_used)
SELECT b.batch_id, m.material_id, v.qty
FROM (VALUES
 ('AM-260801','ALM-2026-A1',  400), ('AM-260801','SUG-2026-S1', 120), ('AM-260801','PKG-2026-B1', 5000),
 ('AM-260915','ALM-2026-A2',  320), ('AM-260915','SUG-2026-S1', 100), ('AM-260915','PKG-2026-B1', 4000),
 ('PB-260805','PNT-2026-P1',  900), ('PB-260805','SUG-2026-S1', 150), ('PB-260805','PKG-2026-J1', 2500),
 ('PB-260918','PNT-2026-P2',  900), ('PB-260918','SUG-2026-S2', 150), ('PB-260918','PKG-2026-J1', 2500),
 ('RK-261005','WHT-2026-F1', 1200), ('RK-261005','SUG-2026-S1', 200),
 ('RK-261012','WHT-2026-F1', 1200), ('RK-261012','SUG-2026-S2', 200),
 ('MJ-260901','MNG-2026-M1', 1400), ('MJ-260901','SUG-2026-S2', 300), ('MJ-260901','PKG-2026-B1', 3500),
 ('MJ-261002','MNG-2026-M1', 1400), ('MJ-261002','SUG-2026-S2', 300), ('MJ-261002','PKG-2026-B1', 3500),
 ('CH-260805','COC-2026-C1',  500), ('CH-260805','SUG-2026-S1', 400), ('CH-260805','ALM-2026-A1',  150),
 ('CH-260930','COC-2026-C2',  500), ('CH-260930','SUG-2026-S2', 400), ('CH-260930','ALM-2026-A2',  150),
 ('RC-260810','RCE-2026-R1',20000),
 ('RC-260905','RCE-2026-R1',20000)
) AS v(code, lot, qty)
JOIN batches b       ON b.batch_code  = v.code
JOIN raw_materials m ON m.lot_number  = v.lot;

-- ---------- Warehouses (real city coordinates) ----------
INSERT INTO warehouses (warehouse_id, name, city, state, latitude, longitude, capacity) VALUES
 (1, 'Bengaluru Central DC',      'Bengaluru', 'Karnataka',   12.971600, 77.594600, 60000),
 (2, 'Chennai Port Warehouse',    'Chennai',   'Tamil Nadu',  13.082700, 80.270700, 45000),
 (3, 'Hyderabad Distribution Hub','Hyderabad', 'Telangana',   17.385000, 78.486700, 50000),
 (4, 'Mumbai Bhiwandi Warehouse', 'Mumbai',    'Maharashtra', 19.076000, 72.877700, 70000),
 (5, 'Delhi NCR Hub',             'Gurugram',  'Haryana',     28.459500, 77.026600, 65000),
 (6, 'Kolkata East Hub',          'Kolkata',   'West Bengal', 22.572600, 88.363900, 40000);

-- ---------- Retailers ----------
INSERT INTO retailers (retailer_id, name, city, state, latitude, longitude, contact_email) VALUES
 ( 1, 'FreshMart Indiranagar',      'Bengaluru', 'Karnataka',   12.978400, 77.640800, 'indiranagar@freshmart.in'),
 ( 2, 'FreshMart Whitefield',       'Bengaluru', 'Karnataka',   12.969800, 77.750000, 'whitefield@freshmart.in'),
 ( 3, 'Mysuru Daily Needs',         'Mysuru',    'Karnataka',   12.295800, 76.639400, 'hello@mysurudaily.in'),
 ( 4, 'Coimbatore Grocers',         'Coimbatore','Tamil Nadu',  11.016800, 76.955800, 'orders@cbegrocers.in'),
 ( 5, 'Chennai Super Bazaar',       'Chennai',   'Tamil Nadu',  13.041800, 80.234100, 'tnagar@chennaibazaar.in'),
 ( 6, 'Hitech Mart',                'Hyderabad', 'Telangana',   17.443500, 78.377200, 'store@hitechmart.in'),
 ( 7, 'Vijayawada Fresh Market',    'Vijayawada','Andhra Pradesh',16.506200,80.648000,'care@vjwfresh.in'),
 ( 8, 'Andheri Stores',             'Mumbai',    'Maharashtra', 19.113600, 72.869700, 'andheri@mumbaistores.in'),
 ( 9, 'Kothrud Mart',               'Pune',      'Maharashtra', 18.507400, 73.807700, 'kothrud@punemart.in'),
 (10, 'Saket Market',               'Delhi',     'Delhi',       28.524500, 77.206600, 'saket@delhimarket.in'),
 (11, 'Sector 29 Store',            'Gurugram',  'Haryana',     28.467000, 77.056000, 'sec29@ggnstore.in'),
 (12, 'Salt Lake Mart',             'Kolkata',   'West Bengal', 22.580000, 88.417000, 'saltlake@kolmart.in');

-- ---------- Orders (1-12 fulfilled by shipments 13-24; 13-14 not yet shipped) ----------
INSERT INTO orders (order_id, retailer_id, status) VALUES
 ( 1,  1, 'DELIVERED'), ( 2,  2, 'DELIVERED'), ( 3,  3, 'DELIVERED'), ( 4,  5, 'DELIVERED'),
 ( 5,  4, 'DELIVERED'), ( 6,  6, 'DELIVERED'), ( 7,  7, 'DELIVERED'), ( 8,  8, 'DELIVERED'),
 ( 9,  9, 'SHIPPED'),   (10, 10, 'SHIPPED'),   (11, 11, 'DELIVERED'), (12, 12, 'DELIVERED'),
 (13,  1, 'PENDING'),   (14,  3, 'CONFIRMED');

-- ---------- Shipments: 1-12 warehouse->warehouse, 13-24 warehouse->retailer ----------
INSERT INTO shipments (shipment_id, from_warehouse_id, to_warehouse_id, to_retailer_id,
                       shipped_at, delivered_at, status, order_id)
SELECT id, f, tw, tr, ts,
       CASE WHEN st = 'DELIVERED' THEN ts + days * INTERVAL '1 day' END,
       st, oid
FROM (VALUES
 ( 1, 1, 2, NULL::int, TIMESTAMPTZ '2026-08-10 09:00+05:30', 2, 'DELIVERED',  NULL::int),
 ( 2, 1, 3, NULL, TIMESTAMPTZ '2026-08-12 09:00+05:30', 2, 'DELIVERED',  NULL),
 ( 3, 3, 4, NULL, TIMESTAMPTZ '2026-08-20 09:00+05:30', 3, 'DELIVERED',  NULL),
 ( 4, 5, 6, NULL, TIMESTAMPTZ '2026-08-20 09:00+05:30', 3, 'DELIVERED',  NULL),
 ( 5, 1, 6, NULL, TIMESTAMPTZ '2026-09-01 09:00+05:30', 4, 'DELIVERED',  NULL),
 ( 6, 4, 5, NULL, TIMESTAMPTZ '2026-09-10 09:00+05:30', 3, 'DELIVERED',  NULL),
 ( 7, 4, 1, NULL, TIMESTAMPTZ '2026-09-15 09:00+05:30', 3, 'DELIVERED',  NULL),
 ( 8, 1, 2, NULL, TIMESTAMPTZ '2026-09-20 09:00+05:30', 2, 'DELIVERED',  NULL),
 ( 9, 1, 4, NULL, TIMESTAMPTZ '2026-10-05 09:00+05:30', 3, 'DELIVERED',  NULL),
 (10, 3, 1, NULL, TIMESTAMPTZ '2026-10-08 09:00+05:30', 2, 'DELIVERED',  NULL),
 (11, 4, 5, NULL, TIMESTAMPTZ '2026-10-12 09:00+05:30', 3, 'DELIVERED',  NULL),
 (12, 2, 3, NULL, TIMESTAMPTZ '2026-09-25 09:00+05:30', 2, 'DELIVERED',  NULL),
 (13, 1, NULL,  1, TIMESTAMPTZ '2026-08-25 09:00+05:30', 1, 'DELIVERED',  1),
 (14, 1, NULL,  2, TIMESTAMPTZ '2026-09-22 09:00+05:30', 1, 'DELIVERED',  2),
 (15, 1, NULL,  3, TIMESTAMPTZ '2026-10-14 09:00+05:30', 2, 'DELIVERED',  3),
 (16, 2, NULL,  5, TIMESTAMPTZ '2026-08-18 09:00+05:30', 1, 'DELIVERED',  4),
 (17, 2, NULL,  4, TIMESTAMPTZ '2026-09-28 09:00+05:30', 2, 'DELIVERED',  5),
 (18, 3, NULL,  6, TIMESTAMPTZ '2026-10-15 09:00+05:30', 1, 'DELIVERED',  6),
 (19, 3, NULL,  7, TIMESTAMPTZ '2026-08-30 09:00+05:30', 2, 'DELIVERED',  7),
 (20, 4, NULL,  8, TIMESTAMPTZ '2026-10-16 09:00+05:30', 1, 'DELIVERED',  8),
 (21, 4, NULL,  9, TIMESTAMPTZ '2026-10-17 09:00+05:30', 2, 'IN_TRANSIT', 9),
 (22, 5, NULL, 10, TIMESTAMPTZ '2026-10-18 09:00+05:30', 1, 'IN_TRANSIT', 10),
 (23, 5, NULL, 11, TIMESTAMPTZ '2026-09-25 09:00+05:30', 2, 'DELIVERED',  11),
 (24, 6, NULL, 12, TIMESTAMPTZ '2026-09-10 09:00+05:30', 2, 'DELIVERED',  12)
) AS v(id, f, tw, tr, ts, days, st, oid);

-- order date = two days before its shipment left
UPDATE orders o SET order_date = s.shipped_at - INTERVAL '2 days'
FROM shipments s WHERE s.order_id = o.order_id;

-- ---------- Shipment items (staged once, reused for order_items) ----------
CREATE TEMP TABLE tmp_items (shipment_id INT, batch_code TEXT, qty INT);
INSERT INTO tmp_items VALUES
 ( 1,'AM-260801',1500), ( 1,'PB-260805', 600),
 ( 2,'AM-260801',1200), ( 2,'CH-260805', 500),
 ( 3,'CH-260805', 200),
 ( 4,'RC-260810', 600),
 ( 5,'PB-260805', 300),
 ( 6,'MJ-260901', 800),
 ( 7,'MJ-260901', 500),
 ( 8,'AM-260915',1000),
 ( 9,'AM-260915', 800), ( 9,'CH-260930', 400),
 (10,'RK-261005', 700),
 (11,'CH-260930', 200),
 (12,'AM-260801', 200),
 (13,'AM-260801', 300), (13,'PB-260805', 100),
 (14,'AM-260801', 250), (14,'AM-260915', 200),
 (15,'CH-260805', 150), (15,'RK-261005', 120),
 (16,'AM-260801', 500), (16,'PB-260805', 200),
 (17,'AM-260801', 400), (17,'AM-260915', 300),
 (18,'AM-260801', 450), (18,'RK-261005', 300),
 (19,'AM-260801', 300), (19,'CH-260805', 150),
 (20,'CH-260805', 120), (20,'MJ-260901', 200), (20,'CH-260930', 100),
 (21,'MJ-260901', 250), (21,'AM-260915', 150),
 (22,'RC-260810', 200), (22,'CH-260930', 120),
 (23,'MJ-260901', 300), (23,'RC-260810', 150),
 (24,'RC-260810', 250), (24,'PB-260805', 120);

INSERT INTO shipment_items (shipment_id, batch_id, quantity)
SELECT t.shipment_id, b.batch_id, t.qty
FROM tmp_items t JOIN batches b ON b.batch_code = t.batch_code;

-- order items = what each retailer-bound shipment carried
INSERT INTO order_items (order_id, batch_id, quantity)
SELECT s.order_id, b.batch_id, t.qty
FROM tmp_items t
JOIN shipments s ON s.shipment_id = t.shipment_id
JOIN batches   b ON b.batch_code  = t.batch_code
WHERE s.order_id IS NOT NULL;

-- the two open orders (no shipment yet)
INSERT INTO order_items (order_id, batch_id, quantity)
SELECT v.oid, b.batch_id, v.qty
FROM (VALUES (13,'RK-261005',100), (14,'AM-260915',200), (14,'CH-260930',50)) AS v(oid, code, qty)
JOIN batches b ON b.batch_code = v.code;

UPDATE orders o SET total_quantity =
    (SELECT COALESCE(SUM(quantity), 0) FROM order_items i WHERE i.order_id = o.order_id);

-- ---------- Inventory, derived from the movement ledger ----------
-- stock(batch, warehouse) = produced there + received - shipped out
CREATE TEMP TABLE tmp_origin (batch_code TEXT, warehouse_id INT);
INSERT INTO tmp_origin VALUES
 ('AM-260801',1), ('AM-260915',1), ('PB-260805',1), ('PB-260918',1), ('CH-260805',1), ('CH-260930',1),
 ('RK-261005',3), ('RK-261012',3),
 ('MJ-260901',4), ('MJ-261002',4),
 ('RC-260810',5), ('RC-260905',5);

CREATE TEMP VIEW tmp_stock_ledger AS
    SELECT b.batch_id, o.warehouse_id, b.quantity_produced AS delta
      FROM batches b JOIN tmp_origin o ON o.batch_code = b.batch_code
    UNION ALL
    SELECT si.batch_id, s.to_warehouse_id, si.quantity
      FROM shipment_items si JOIN shipments s USING (shipment_id)
     WHERE s.to_warehouse_id IS NOT NULL
    UNION ALL
    SELECT si.batch_id, s.from_warehouse_id, -si.quantity
      FROM shipment_items si JOIN shipments s USING (shipment_id);

-- sanity check: the seed must never ship more than a warehouse holds
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM tmp_stock_ledger GROUP BY batch_id, warehouse_id HAVING SUM(delta) < 0) THEN
        RAISE EXCEPTION 'Seed error: a shipment moves more stock than the warehouse holds';
    END IF;
END $$;

INSERT INTO inventory (batch_id, warehouse_id, quantity)
SELECT batch_id, warehouse_id, SUM(delta)
FROM tmp_stock_ledger
GROUP BY batch_id, warehouse_id
HAVING SUM(delta) > 0;

-- ---------- Keep SERIAL sequences ahead of the explicit ids used above ----------
DO $$
BEGIN
    PERFORM setval(pg_get_serial_sequence('suppliers','supplier_id'),     (SELECT MAX(supplier_id)  FROM suppliers));
    PERFORM setval(pg_get_serial_sequence('raw_materials','material_id'), (SELECT MAX(material_id)  FROM raw_materials));
    PERFORM setval(pg_get_serial_sequence('products','product_id'),       (SELECT MAX(product_id)   FROM products));
    PERFORM setval(pg_get_serial_sequence('batches','batch_id'),          (SELECT MAX(batch_id)     FROM batches));
    PERFORM setval(pg_get_serial_sequence('warehouses','warehouse_id'),   (SELECT MAX(warehouse_id) FROM warehouses));
    PERFORM setval(pg_get_serial_sequence('retailers','retailer_id'),     (SELECT MAX(retailer_id)  FROM retailers));
    PERFORM setval(pg_get_serial_sequence('orders','order_id'),           (SELECT MAX(order_id)     FROM orders));
    PERFORM setval(pg_get_serial_sequence('shipments','shipment_id'),     (SELECT MAX(shipment_id)  FROM shipments));
    PERFORM setval(pg_get_serial_sequence('inventory','inventory_id'),    (SELECT MAX(inventory_id) FROM inventory));
END $$;

COMMIT;
