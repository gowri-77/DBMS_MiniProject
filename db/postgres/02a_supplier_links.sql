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

-- OPTIONAL demo data: link every tier-(t+1) supplier to one tier-t supplier (round-robin).
-- Skip this if you insert real links by hand.
INSERT INTO supplier_links (upstream_supplier_id, downstream_supplier_id)
SELECT up.supplier_id, down.supplier_id
FROM (
  SELECT supplier_id, tier, row_number() OVER (PARTITION BY tier ORDER BY supplier_id) AS rn
  FROM suppliers
) up
JOIN (
  SELECT supplier_id, tier, row_number() OVER (PARTITION BY tier ORDER BY supplier_id) AS rn,
         count(*) OVER (PARTITION BY tier) AS cnt
  FROM suppliers
) down ON down.tier = up.tier - 1
      AND down.rn = ((up.rn - 1) % down.cnt) + 1
ON CONFLICT DO NOTHING;
