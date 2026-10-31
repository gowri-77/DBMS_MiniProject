-- 02_users.sql : users + role-based access (Anjali)
-- Depends on: 01_schema.sql (suppliers, retailers). Must run BEFORE 03_recall_tables.sql.

CREATE TABLE IF NOT EXISTS users (
    user_id        SERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    role           VARCHAR(20)  NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,   -- bcrypt hash only, never plaintext
    supplier_id    INTEGER,
    retailer_id    INTEGER,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT ck_users_email CHECK (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    CONSTRAINT ck_users_role CHECK (role IN ('ADMIN','SUPPLIER','QUALITY_INSPECTOR','RETAILER')),
    CONSTRAINT ck_users_hash CHECK (length(password_hash) >= 20),
    CONSTRAINT users_supplier_id_fkey FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id) ON DELETE RESTRICT,
    CONSTRAINT users_retailer_id_fkey FOREIGN KEY (retailer_id)
        REFERENCES retailers(retailer_id) ON DELETE RESTRICT,
    CONSTRAINT ck_users_role_link CHECK (
        (role = 'SUPPLIER' AND supplier_id IS NOT NULL AND retailer_id IS NULL) OR
        (role = 'RETAILER' AND retailer_id IS NOT NULL AND supplier_id IS NULL) OR
        (role IN ('ADMIN','QUALITY_INSPECTOR') AND supplier_id IS NULL AND retailer_id IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_users_role     ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_supplier ON users(supplier_id);
CREATE INDEX IF NOT EXISTS idx_users_retailer ON users(retailer_id);
