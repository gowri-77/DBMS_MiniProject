BEGIN;

-- 1. Create a test user for inspection and recall records.
-- This assumes the temporary users table has a user_id column.
INSERT INTO users (user_id)
VALUES (1)
ON CONFLICT (user_id) DO NOTHING;


-- 2. Create a test product.
INSERT INTO products (sku, name, category)
VALUES (
    'TEST-RECALL-001',
    'Recall Test Product',
    'Testing'
);


-- 3. Create a test warehouse.
INSERT INTO warehouses (
    name,
    city,
    state,
    latitude,
    longitude,
    capacity
)
VALUES (
    'Recall Test Warehouse',
    'Bengaluru',
    'Karnataka',
    12.971600,
    77.594600,
    1000
);


-- 4. Create a test batch for the product.
INSERT INTO batches (
    product_id,
    batch_code,
    manufactured_date,
    expiry_date,
    quantity_produced,
    status
)
SELECT
    product_id,
    'TEST-BATCH-RECALL-001',
    CURRENT_DATE,
    CURRENT_DATE + 180,
    100,
    'ACTIVE'
FROM products
WHERE sku = 'TEST-RECALL-001';


-- 5. Add inventory for the test batch.
INSERT INTO inventory (
    batch_id,
    warehouse_id,
    quantity
)
SELECT
    b.batch_id,
    w.warehouse_id,
    40
FROM batches AS b
CROSS JOIN warehouses AS w
WHERE b.batch_code = 'TEST-BATCH-RECALL-001'
  AND w.name = 'Recall Test Warehouse'
  AND w.city = 'Bengaluru';


-- 6. Record a failed inspection.
-- The trigger should automatically quarantine the batch.
INSERT INTO inspections (
    batch_id,
    inspector_id,
    result,
    score,
    defect_type
)
SELECT
    batch_id,
    1,
    'FAIL',
    35,
    'Packaging defect'
FROM batches
WHERE batch_code = 'TEST-BATCH-RECALL-001';


-- 7. Check whether the failed inspection quarantined the batch.
SELECT
    batch_code,
    status AS status_after_failed_inspection
FROM batches
WHERE batch_code = 'TEST-BATCH-RECALL-001';


-- 8. Initiate a recall for the test batch.
DO $$
DECLARE
    test_batch_id INT;
BEGIN
    SELECT batch_id
    INTO test_batch_id
    FROM batches
    WHERE batch_code = 'TEST-BATCH-RECALL-001';

    CALL initiate_recall(
        'TEST-RECALL-001',
        NULL,
        1,
        'Functional test: packaging defect',
        'HIGH',
        ARRAY[test_batch_id]
    );
END;
$$;

-- 9. Check the recall summary view.
SELECT *
FROM v_recall_summary
WHERE recall_code = 'TEST-RECALL-001';


-- 10. Check the recall batch details view.
SELECT *
FROM v_recall_batch_details
WHERE batch_code = 'TEST-BATCH-RECALL-001';


-- 11. Check whether the batch was marked as recalled.
SELECT
    batch_code,
    status AS final_batch_status
FROM batches
WHERE batch_code = 'TEST-BATCH-RECALL-001';


-- 12. Check the audit log.
SELECT
    table_name,
    action,
    record_id,
    changed_at
FROM audit_log
ORDER BY changed_at DESC
LIMIT 10;


-- 13. Undo all test data so the database stays clean.
ROLLBACK;