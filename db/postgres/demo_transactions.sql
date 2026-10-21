-- =====================================================================
-- demo_transactions.sql  |  Owner: Gowri (M1)
-- Shows atomicity for the demo and the report. Everything runs inside
-- BEGIN ... ROLLBACK, so the seed data is left untouched and this file
-- can be run again and again.
-- Run: psql -U postgres -d supplychain -f db/postgres/demo_transactions.sql
-- =====================================================================
BEGIN;

\echo '--- Stock of batch 1 (AM-260801) at Bengaluru DC BEFORE:'
SELECT quantity FROM inventory WHERE batch_id = 1 AND warehouse_id = 1;

\echo '--- TEST 1: successful order (retailer 2, from warehouse 1, 100 units of batch 1)'
SELECT place_order(2, 1, '[{"batch_id":1,"quantity":100}]') AS new_order_id;
SELECT quantity AS stock_after_order FROM inventory WHERE batch_id = 1 AND warehouse_id = 1;

\echo '--- TEST 2: cancel it, stock must come back'
SELECT cancel_order(currval(pg_get_serial_sequence('orders','order_id'))::int);
SELECT quantity AS stock_after_cancel FROM inventory WHERE batch_id = 1 AND warehouse_id = 1;

\echo '--- TEST 3: two items, the second has too little stock -> WHOLE order rolls back'
DO $$
DECLARE before_orders INT; after_orders INT; stock_before INT; stock_after INT;
BEGIN
    SELECT count(*) INTO before_orders FROM orders;
    SELECT quantity INTO stock_before FROM inventory WHERE batch_id = 1 AND warehouse_id = 1;
    BEGIN
        PERFORM place_order(2, 1, '[{"batch_id":1,"quantity":50},{"batch_id":2,"quantity":999999}]');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Rejected as expected: %', SQLERRM;
    END;
    SELECT count(*) INTO after_orders FROM orders;
    SELECT quantity INTO stock_after FROM inventory WHERE batch_id = 1 AND warehouse_id = 1;
    RAISE NOTICE 'orders before=%, after=%  |  stock of batch 1 before=%, after=%  (must be equal)',
                 before_orders, after_orders, stock_before, stock_after;
END $$;

\echo '--- TEST 4: quarantined batch cannot be sold'
UPDATE batches SET status = 'QUARANTINED' WHERE batch_id = 1;
DO $$
BEGIN
    PERFORM place_order(2, 1, '[{"batch_id":1,"quantity":10}]');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Rejected as expected: %', SQLERRM;
END $$;

\echo '--- TEST 5: delivered order cannot be cancelled'
DO $$
BEGIN
    PERFORM cancel_order(1);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Rejected as expected: %', SQLERRM;
END $$;

ROLLBACK;   -- undo every change made above
\echo '--- Stock AFTER rollback (back to the seeded value):'
SELECT quantity FROM inventory WHERE batch_id = 1 AND warehouse_id = 1;
