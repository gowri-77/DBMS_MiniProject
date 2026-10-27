
-- ============================================================
-- 04_triggers.sql
-- Owner: Madhumitha
-- Inspection and Recall Engine
-- Requires: 01_schema.sql and 03_recall_tables.sql
-- ============================================================


-- 1. QUARANTINE BATCHES WHEN AN INSPECTION FAILS
-- A failed inspection automatically quarantines its batch.
-- A batch already marked RECALLED stays RECALLED.

CREATE OR REPLACE FUNCTION quarantine_failed_batch()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.result = 'FAIL' THEN
        UPDATE batches
        SET status = 'QUARANTINED'
        WHERE batch_id = NEW.batch_id
          AND status <> 'RECALLED';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_quarantine_failed_batch
ON inspections;

CREATE TRIGGER trg_quarantine_failed_batch
AFTER INSERT OR UPDATE
ON inspections
FOR EACH ROW
EXECUTE FUNCTION quarantine_failed_batch();


-- 2. GENERIC AUDIT FUNCTION
-- Records INSERT, UPDATE and DELETE operations in audit_log.

CREATE OR REPLACE FUNCTION audit_row_change()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
    affected_record_id INT;
    actor_id INT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        new_data := to_jsonb(NEW);

    ELSIF TG_OP = 'UPDATE' THEN
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);

    ELSIF TG_OP = 'DELETE' THEN
        old_data := to_jsonb(OLD);
    END IF;

    -- Determine the record ID for the audit entry.
    affected_record_id := COALESCE(
        (new_data ->> 'inspection_id')::INT,
        (old_data ->> 'inspection_id')::INT,
        (new_data ->> 'recall_id')::INT,
        (old_data ->> 'recall_id')::INT,
        (new_data ->> 'batch_id')::INT,
        (old_data ->> 'batch_id')::INT,
        (new_data ->> 'log_id')::INT,
        (old_data ->> 'log_id')::INT
    );

    -- Read the optional application user ID.
    actor_id := NULLIF(
        current_setting('app.user_id', TRUE), ''
    )::INT;

    -- Fall back to IDs present in the row, when available.
    IF actor_id IS NULL THEN
        actor_id := COALESCE(
            (new_data ->> 'inspector_id')::INT,
            (old_data ->> 'inspector_id')::INT,
            (new_data ->> 'initiated_by')::INT,
            (old_data ->> 'initiated_by')::INT
        );
    END IF;

    INSERT INTO audit_log (
        table_name,
        record_id,
        action,
        old_value,
        new_value,
        changed_by
    )
    VALUES (
        TG_TABLE_NAME,
        affected_record_id,
        TG_OP,
        old_data,
        new_data,
        actor_id
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 3. AUDIT INSPECTION CHANGES

DROP TRIGGER IF EXISTS trg_audit_inspections
ON inspections;

CREATE TRIGGER trg_audit_inspections
AFTER INSERT OR UPDATE OR DELETE
ON inspections
FOR EACH ROW
EXECUTE FUNCTION audit_row_change();


-- 4. AUDIT RECALL CHANGES

DROP TRIGGER IF EXISTS trg_audit_recalls
ON recalls;

CREATE TRIGGER trg_audit_recalls
AFTER INSERT OR UPDATE OR DELETE
ON recalls
FOR EACH ROW
EXECUTE FUNCTION audit_row_change();


-- 5. AUDIT RECALL-BATCH ASSOCIATION CHANGES

DROP TRIGGER IF EXISTS trg_audit_recall_batches
ON recall_batches;

CREATE TRIGGER trg_audit_recall_batches
AFTER INSERT OR UPDATE OR DELETE
ON recall_batches
FOR EACH ROW
EXECUTE FUNCTION audit_row_change();
