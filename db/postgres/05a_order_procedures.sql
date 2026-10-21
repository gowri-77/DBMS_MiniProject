-- =====================================================================
-- 05a_order_procedures.sql  |  Owner: Gowri (M1)
-- Atomic order processing. Each function runs as ONE transaction:
-- if any step raises an exception, every change it made is rolled back.
-- Depends only on the core tables (01_schema.sql). Madhumitha's quarantine
-- trigger works with it: place_order refuses any batch that is not ACTIVE.
-- =====================================================================

-- ---------------------------------------------------------------------
-- place_order(retailer, source warehouse, items)
--   items is a JSON array: [{"batch_id": 1, "quantity": 100}, ...]
--   Steps: validate -> create order -> create shipment -> for each item:
--   check batch status and expiry, LOCK the stock row, check stock,
--   decrement inventory, write order_items and shipment_items.
--   Returns the new order_id.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION place_order(p_retailer_id INT, p_warehouse_id INT, p_items JSONB)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id     INT;
    v_shipment_id  INT;
    v_item         RECORD;
    v_status       VARCHAR(15);
    v_expiry       DATE;
    v_stock        INT;
    v_total        INT := 0;
BEGIN
    -- 1. validate the request itself
    IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'An order must contain at least one item';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM retailers  WHERE retailer_id  = p_retailer_id) THEN
        RAISE EXCEPTION 'Retailer % does not exist', p_retailer_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE warehouse_id = p_warehouse_id) THEN
        RAISE EXCEPTION 'Warehouse % does not exist', p_warehouse_id;
    END IF;
    IF (SELECT count(*) <> count(DISTINCT e->>'batch_id') FROM jsonb_array_elements(p_items) e) THEN
        RAISE EXCEPTION 'The same batch appears more than once in the order';
    END IF;

    -- 2. create the order and its shipment (stock is reserved immediately)
    INSERT INTO orders (retailer_id, status) VALUES (p_retailer_id, 'CONFIRMED')
        RETURNING order_id INTO v_order_id;
    INSERT INTO shipments (from_warehouse_id, to_retailer_id, status, order_id)
        VALUES (p_warehouse_id, p_retailer_id, 'PENDING', v_order_id)
        RETURNING shipment_id INTO v_shipment_id;

    -- 3. process each item; ORDER BY batch_id gives every transaction the same
    --    lock order, which prevents deadlocks between concurrent orders
    FOR v_item IN
        SELECT (e->>'batch_id')::INT AS batch_id, (e->>'quantity')::INT AS quantity
        FROM jsonb_array_elements(p_items) e
        ORDER BY 1
    LOOP
        IF v_item.quantity IS NULL OR v_item.quantity <= 0 THEN
            RAISE EXCEPTION 'Quantity for batch % must be a positive number', v_item.batch_id;
        END IF;

        SELECT status, expiry_date INTO v_status, v_expiry
          FROM batches WHERE batch_id = v_item.batch_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Batch % does not exist', v_item.batch_id;
        END IF;
        IF v_status <> 'ACTIVE' THEN
            RAISE EXCEPTION 'Batch % is % and cannot be sold', v_item.batch_id, v_status;
        END IF;
        IF v_expiry IS NOT NULL AND v_expiry < CURRENT_DATE THEN
            RAISE EXCEPTION 'Batch % expired on %', v_item.batch_id, v_expiry;
        END IF;

        -- FOR UPDATE locks this stock row until we commit, so two concurrent
        -- orders cannot both take the last units
        SELECT quantity INTO v_stock FROM inventory
         WHERE batch_id = v_item.batch_id AND warehouse_id = p_warehouse_id
         FOR UPDATE;
        IF NOT FOUND OR v_stock < v_item.quantity THEN
            RAISE EXCEPTION 'Insufficient stock for batch %: requested %, available %',
                v_item.batch_id, v_item.quantity, COALESCE(v_stock, 0);
        END IF;

        UPDATE inventory SET quantity = quantity - v_item.quantity
         WHERE batch_id = v_item.batch_id AND warehouse_id = p_warehouse_id;
        INSERT INTO order_items    (order_id,    batch_id, quantity) VALUES (v_order_id,    v_item.batch_id, v_item.quantity);
        INSERT INTO shipment_items (shipment_id, batch_id, quantity) VALUES (v_shipment_id, v_item.batch_id, v_item.quantity);
        v_total := v_total + v_item.quantity;
    END LOOP;

    UPDATE orders SET total_quantity = v_total WHERE order_id = v_order_id;
    RETURN v_order_id;
END;
$$;

-- ---------------------------------------------------------------------
-- cancel_order(order)
--   Only PENDING or CONFIRMED orders can be cancelled. Reserved stock is
--   returned to the warehouse the shipment was going to leave from.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cancel_order(p_order_id INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_status  VARCHAR(15);
    v_ship    RECORD;
BEGIN
    SELECT status INTO v_status FROM orders WHERE order_id = p_order_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id;
    END IF;
    IF v_status NOT IN ('PENDING','CONFIRMED') THEN
        RAISE EXCEPTION 'Order % is % and can no longer be cancelled', p_order_id, v_status;
    END IF;

    -- put reserved stock back (only shipments that have not left yet)
    FOR v_ship IN
        SELECT s.shipment_id, s.from_warehouse_id, si.batch_id, si.quantity
          FROM shipments s JOIN shipment_items si USING (shipment_id)
         WHERE s.order_id = p_order_id AND s.status = 'PENDING'
    LOOP
        INSERT INTO inventory (batch_id, warehouse_id, quantity)
        VALUES (v_ship.batch_id, v_ship.from_warehouse_id, v_ship.quantity)
        ON CONFLICT (batch_id, warehouse_id)
        DO UPDATE SET quantity = inventory.quantity + EXCLUDED.quantity;
    END LOOP;

    UPDATE shipments SET status = 'CANCELLED' WHERE order_id = p_order_id AND status = 'PENDING';
    UPDATE orders    SET status = 'CANCELLED' WHERE order_id = p_order_id;
END;
$$;
