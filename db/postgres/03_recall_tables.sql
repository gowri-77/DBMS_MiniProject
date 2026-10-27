
-- ============================================================
-- 03_recall_tables.sql
-- Owner: Madhumitha
-- Inspection and Recall Engine
-- Requires: 01_schema.sql and 02_users.sql
-- ============================================================

-- 1. INSPECTIONS
CREATE TABLE inspections (
    inspection_id SERIAL PRIMARY KEY,
    batch_id INT NOT NULL
        REFERENCES batches(batch_id),
    inspector_id INT NOT NULL
        REFERENCES users(user_id),
    inspected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    result VARCHAR(15) NOT NULL
        CHECK (result IN ('PASS', 'FAIL', 'CONDITIONAL')),
    score NUMERIC(5,2)
        CHECK (score BETWEEN 0 AND 100),
    defect_type VARCHAR(100),
    notes TEXT,

    CONSTRAINT ck_inspections_fail_defect
        CHECK (result <> 'FAIL' OR defect_type IS NOT NULL)
);

-- 2. RECALLS
CREATE TABLE recalls (
    recall_id SERIAL PRIMARY KEY,
    recall_code VARCHAR(30) NOT NULL UNIQUE,
    source_inspection_id INT
        REFERENCES inspections(inspection_id),
    initiated_by INT NOT NULL
        REFERENCES users(user_id),
    reason TEXT NOT NULL,
    severity VARCHAR(10) NOT NULL
        CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(15) NOT NULL DEFAULT 'OPEN'
        CHECK (status IN ('OPEN', 'IN_PROGRESS', 'CLOSED')),
    initiated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,

    CONSTRAINT ck_recalls_closed_at
        CHECK (closed_at IS NULL OR status = 'CLOSED')
);

-- 3. RECALL BATCHES
CREATE TABLE recall_batches (
    recall_id INT NOT NULL
        REFERENCES recalls(recall_id) ON DELETE CASCADE,
    batch_id INT NOT NULL
        REFERENCES batches(batch_id),
    units_affected INT NOT NULL
        CHECK (units_affected >= 0),
    added_at TIMESTAMPTZ DEFAULT now(),

    PRIMARY KEY (recall_id, batch_id)
);

-- 4. AUDIT LOG
CREATE TABLE audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(10) NOT NULL
        CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_value JSONB,
    new_value JSONB,
    changed_by INT REFERENCES users(user_id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for commonly used relationships
CREATE INDEX idx_inspections_batch
    ON inspections(batch_id);

CREATE INDEX idx_inspections_inspector
    ON inspections(inspector_id);

CREATE INDEX idx_recalls_status
    ON recalls(status);

CREATE INDEX idx_recall_batches_batch
    ON recall_batches(batch_id);

CREATE INDEX idx_audit_log_changed_at
    ON audit_log(changed_at);
