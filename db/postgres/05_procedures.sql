
-- ============================================================
-- 05_procedures.sql
-- Owner: Madhumitha
-- Inspection and Recall Engine
-- Requires: 03_recall_tables.sql and core schema
-- ============================================================

CREATE OR REPLACE PROCEDURE initiate_recall(
    p_recall_code VARCHAR(30),
    p_source_inspection_id INT,
    p_initiated_by INT,
    p_reason TEXT,
    p_severity VARCHAR(10),
    p_batch_ids INT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_recall_id INT;
    v_batch_id INT;
    v_units INT;
BEGIN
    -- Validate the batch list.
    IF p_batch_ids IS NULL
       OR cardinality(p_batch_ids) = 0 THEN
        RAISE EXCEPTION
            'A recall must include at least one batch';
    END IF;

    IF array_position(p_batch_ids, NULL) IS NOT NULL THEN
        RAISE EXCEPTION
            'Batch IDs cannot contain NULL values';
    END IF;

    -- Reject batch IDs that do not exist.
    IF EXISTS (
        SELECT 1
        FROM unnest(p_batch_ids) AS requested(batch_id)
        LEFT JOIN batches b
            ON b.batch_id = requested.batch_id
        WHERE b.batch_id IS NULL
    ) THEN
        RAISE EXCEPTION
            'One or more batch IDs do not exist';
    END IF;

    -- Create the recall record.
    INSERT INTO recalls (
        recall_code,
        source_inspection_id,
        initiated_by,
        reason,
        severity,
        status
    )
    VALUES (
        p_recall_code,
        p_source_inspection_id,
        p_initiated_by,
        p_reason,
        p_severity,
        'OPEN'
    )
    RETURNING recall_id INTO v_recall_id;

    -- Link each unique batch to this recall.
    FOR v_batch_id IN
        SELECT DISTINCT requested.batch_id
        FROM unnest(p_batch_ids) AS requested(batch_id)
    LOOP
        -- Calculate units currently present in inventory.
        SELECT COALESCE(SUM(i.quantity), 0)::INT
        INTO v_units
        FROM inventory i
        WHERE i.batch_id = v_batch_id;

        INSERT INTO recall_batches (
            recall_id,
            batch_id,
            units_affected
        )
        VALUES (
            v_recall_id,
            v_batch_id,
            v_units
        );

        -- Mark the batch as recalled.
        UPDATE batches
        SET status = 'RECALLED'
        WHERE batch_id = v_batch_id;
    END LOOP;

    RAISE NOTICE 'Recall % created successfully: recall ID %',
        p_recall_code, v_recall_id;
END;
$$;
