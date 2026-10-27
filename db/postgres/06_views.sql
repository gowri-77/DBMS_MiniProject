
-- ============================================================
-- 06_views.sql
-- Inspection and Recall Engine views
-- Owner: Madhumitha (recall/inspection views)
-- Requires: 03_recall_tables.sql
-- Does not depend on users table joins
-- ============================================================

-- 1. Inspection history with associated batch details.
CREATE OR REPLACE VIEW v_inspection_history AS
SELECT
    i.inspection_id,
    i.batch_id,
    b.batch_code,
    b.product_id,
    b.status AS batch_status,
    i.inspector_id,
    i.inspected_at,
    i.result,
    i.score,
    i.defect_type,
    i.notes
FROM inspections i
JOIN batches b
    ON b.batch_id = i.batch_id;


-- 2. Recall summary: number of affected batches and units.
CREATE OR REPLACE VIEW v_recall_summary AS
SELECT
    r.recall_id,
    r.recall_code,
    r.source_inspection_id,
    r.initiated_by,
    r.reason,
    r.severity,
    r.status AS recall_status,
    r.initiated_at,
    r.closed_at,
    COUNT(rb.batch_id) AS affected_batch_count,
    COALESCE(SUM(rb.units_affected), 0) AS total_units_affected
FROM recalls r
LEFT JOIN recall_batches rb
    ON rb.recall_id = r.recall_id
GROUP BY
    r.recall_id,
    r.recall_code,
    r.source_inspection_id,
    r.initiated_by,
    r.reason,
    r.severity,
    r.status,
    r.initiated_at,
    r.closed_at;


-- 3. Detailed list of batches associated with each recall.
CREATE OR REPLACE VIEW v_recall_batch_details AS
SELECT
    r.recall_id,
    r.recall_code,
    r.severity,
    r.status AS recall_status,
    rb.batch_id,
    b.batch_code,
    b.product_id,
    b.status AS batch_status,
    rb.units_affected,
    rb.added_at
FROM recalls r
JOIN recall_batches rb
    ON rb.recall_id = r.recall_id
JOIN batches b
    ON b.batch_id = rb.batch_id;


-- 4. Inspections that failed and may require follow-up.
CREATE OR REPLACE VIEW v_failed_inspections AS
SELECT
    i.inspection_id,
    i.batch_id,
    b.batch_code,
    b.product_id,
    i.inspector_id,
    i.inspected_at,
    i.score,
    i.defect_type,
    i.notes,
    b.status AS batch_status
FROM inspections i
JOIN batches b
    ON b.batch_id = i.batch_id
WHERE i.result = 'FAIL';
