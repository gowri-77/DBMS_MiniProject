# Team Contract

## Members and ownership
| Member | Name | Role | Owns folders |
|---|---|---|---|
| M1 | Gowri | Core SQL, inventory, orders | db/postgres/schema.sql, seed.sql, app/(core) |
| M2 | Madhumitha | Inspections and recall engine | db/postgres/triggers.sql, procedures.sql, views.sql |
| M3 | Anjali | Graph, analytics, auth | db/neo4j/, lib/neo4j.ts, auth, app/trace |

## Branches
| Person | Branch |
|---|---|
| Gowri T N | feat/core-sql |
| Madhumitha Dhondi | feat/recall-engine |
| Anjali Arun | feat/graph-auth |

## Status enums (use exactly these strings)
- batch_status: ACTIVE, QUARANTINED, RECALLED
- inspection_result: PASS, FAIL, CONDITIONAL
- recall_status: OPEN, IN_PROGRESS, CLOSED
- order_status: PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
- user_role: ADMIN, SUPPLIER, INSPECTOR, RETAILER

## Naming conventions
- Tables: snake_case, plural (batches, raw_materials)
- Primary keys: <singular>_id (batch_id), type SERIAL/INT
- Timestamps: created_at, updated_at (TIMESTAMPTZ)

## Core tables (Gowri delivers schema.sql)
suppliers, raw_materials, products, batches, batch_materials,
warehouses, retailers, inventory, shipments, shipment_items,
orders, order_items

## Tables owned by others
- Madhumitha: inspections, recalls, recall_batches, audit_log
- Anjali: users

## Cross-member rules
- Only edit your own folders. Shared files go through a PR.
- Schema changes after Day 4 need a message in the group chat.
- Never commit .env files.
- Each person commits with their own name and GitHub email.