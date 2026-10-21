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

## Shared table specs (decided by Gowri, final unless the team agrees to change)

### users (Anjali)
| Column | Type | Constraints |
|---|---|---|
| user_id | SERIAL | PK |
| username | VARCHAR(50) | NOT NULL, UNIQUE |
| email | VARCHAR(100) | NOT NULL, UNIQUE |
| password_hash | TEXT | NOT NULL (bcrypt) |
| role | VARCHAR(20) | NOT NULL, CHECK IN ('ADMIN','SUPPLIER','INSPECTOR','RETAILER') |
| supplier_id | INT | FK -> suppliers, nullable |
| retailer_id | INT | FK -> retailers, nullable |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| last_login | TIMESTAMPTZ | nullable |

Role rule (CHECK): SUPPLIER requires supplier_id and no retailer_id; RETAILER requires
retailer_id and no supplier_id; ADMIN and INSPECTOR have both NULL.
Suppliers and retailers see only their own data through these links.

### inspections (Madhumitha)
| Column | Type | Constraints |
|---|---|---|
| inspection_id | SERIAL | PK |
| batch_id | INT | NOT NULL, FK -> batches |
| inspector_id | INT | NOT NULL, FK -> users |
| inspected_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |
| result | VARCHAR(15) | NOT NULL, CHECK IN ('PASS','FAIL','CONDITIONAL') |
| score | NUMERIC(5,2) | CHECK (score BETWEEN 0 AND 100) |
| defect_type | VARCHAR(100) | nullable (required when result = 'FAIL') |
| notes | TEXT | nullable |

### recalls (Madhumitha)
| Column | Type | Constraints |
|---|---|---|
| recall_id | SERIAL | PK |
| recall_code | VARCHAR(30) | NOT NULL, UNIQUE |
| source_inspection_id | INT | FK -> inspections, nullable |
| initiated_by | INT | NOT NULL, FK -> users |
| reason | TEXT | NOT NULL |
| severity | VARCHAR(10) | NOT NULL, CHECK IN ('LOW','MEDIUM','HIGH','CRITICAL') |
| status | VARCHAR(15) | NOT NULL, DEFAULT 'OPEN', CHECK IN ('OPEN','IN_PROGRESS','CLOSED') |
| initiated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |
| closed_at | TIMESTAMPTZ | CHECK: set only when status = 'CLOSED' |

### recall_batches (Madhumitha)
| Column | Type | Constraints |
|---|---|---|
| recall_id | INT | FK -> recalls |
| batch_id | INT | FK -> batches |
| units_affected | INT | NOT NULL, CHECK (units_affected >= 0) |
| added_at | TIMESTAMPTZ | DEFAULT now() |
Primary key: (recall_id, batch_id).

### audit_log (Madhumitha)
| Column | Type | Constraints |
|---|---|---|
| log_id | BIGSERIAL | PK |
| table_name | VARCHAR(50) | NOT NULL |
| record_id | INT | NOT NULL |
| action | VARCHAR(10) | NOT NULL, CHECK IN ('INSERT','UPDATE','DELETE') |
| old_value | JSONB | nullable |
| new_value | JSONB | nullable |
| changed_by | INT | FK -> users, nullable |
| changed_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

## SQL file order (run in this order; each person owns their file)
| File | Owner | Contents |
|---|---|---|
| db/postgres/01_schema.sql | Gowri | core tables, constraints, indexes, ALTER and DROP demos |
| db/postgres/02_users.sql | Anjali | users table |
| db/postgres/03_recall_tables.sql | Madhumitha | inspections, recalls, recall_batches, audit_log |
| db/postgres/04_triggers.sql | Madhumitha | quarantine trigger, audit trigger |
| db/postgres/05_procedures.sql | Madhumitha | initiate_recall |
| db/postgres/05a_order_procedures.sql | Gowri | place_order, cancel_order |
| db/postgres/06a_views_inventory.sql | Gowri | inventory views |
| db/postgres/06_views.sql | Madhumitha and Gowri | active_recalls_view, inventory views |
| db/postgres/99_seed.sql | Gowri | seed data |

Why the order matters: users must exist before inspections and recalls can reference it,
and triggers and procedures need all tables to exist first.