-- Supplier hierarchy for multi-tier tracing (owner: Anjali).
-- A row means: upstream_supplier_id supplies (materials/components to) downstream_supplier_id.
-- Example: a tier-2 supplier -> a tier-1 supplier -> the manufacturer.
-- NOTE: touches the suppliers table owned by Gowri; agree with her before running.
CREATE TABLE IF NOT EXISTS supplier_links (
  upstream_supplier_id   INT NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
  downstream_supplier_id INT NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (upstream_supplier_id, downstream_supplier_id),
  CHECK (upstream_supplier_id <> downstream_supplier_id)
);
CREATE INDEX IF NOT EXISTS idx_supplier_links_downstream ON supplier_links(downstream_supplier_id);

-- Insert the supplier relationships by hand (upstream supplier first, then the supplier it supplies).
-- Example using current supplier IDs (edit to match your real chain):
-- INSERT INTO supplier_links (upstream_supplier_id, downstream_supplier_id) VALUES
--   (2, 1),   -- Sunrise Peanut Growers   -> Western Ghats Almonds
--   (5, 3),   -- Ratnagiri Mango Orchards -> Kaveri Sugar Mills
--   (7, 4),   -- Himalayan Basmati Growers -> Deccan Flour Mills
--   (6, 2)    -- Cocoa Coast Traders      -> Sunrise Peanut Growers
-- ON CONFLICT DO NOTHING;
