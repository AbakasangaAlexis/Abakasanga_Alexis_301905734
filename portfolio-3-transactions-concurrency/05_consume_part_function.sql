-- =====================================================================
-- Portfolio 3 / Demo 5: Putting it together - a safe, reusable transaction as a function
-- consume_part() locks the stock row, checks availability, records usage and deducts stock
-- as ONE atomic unit. Concurrent callers queue on the row lock, so stock can never go negative
-- and nothing is lost.
-- =====================================================================
CREATE OR REPLACE FUNCTION consume_part(p_work_order INT, p_part INT, p_qty INT)
RETURNS INT                          -- returns remaining stock
LANGUAGE plpgsql AS $$
DECLARE
    v_stock   INT;
    v_reorder INT;
BEGIN
    IF p_qty <= 0 THEN
        RAISE EXCEPTION 'Quantity must be positive (got %)', p_qty;
    END IF;

    SELECT quantity_on_hand, reorder_level INTO v_stock, v_reorder
    FROM spare_part WHERE part_id = p_part
    FOR UPDATE;                                         -- row lock: serialises concurrent users
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown part_id %', p_part;
    END IF;

    IF v_stock < p_qty THEN
        RAISE EXCEPTION 'Insufficient stock for part %: requested %, on hand %', p_part, p_qty, v_stock
              USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO work_order_part (work_order_id, part_id, quantity_used)
    VALUES (p_work_order, p_part, p_qty)
    ON CONFLICT (work_order_id, part_id)
    DO UPDATE SET quantity_used = work_order_part.quantity_used + EXCLUDED.quantity_used;

    UPDATE spare_part SET quantity_on_hand = quantity_on_hand - p_qty WHERE part_id = p_part;

    IF v_stock - p_qty < v_reorder THEN
        RAISE NOTICE 'REORDER ALERT: part % is at % (reorder level %)', p_part, v_stock - p_qty, v_reorder;
    END IF;
    RETURN v_stock - p_qty;
END;
$$;

-- Test (run 00_reset_demo_data.sql first). Work order 6 is an open inspection order.
SELECT consume_part(6, 4, 2) AS remaining;     -- OK: 3 -> 1, prints a REORDER ALERT (level is 2)
SELECT consume_part(6, 4, 2) AS remaining;     -- ERROR: Insufficient stock; nothing changes
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_id = 4;   -- 1
SELECT * FROM work_order_part WHERE work_order_id = 6 AND part_id = 4;    -- quantity_used = 2
