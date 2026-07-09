-- ============================================================
-- fn_update_order_status
-- Screen: Staff > Kitchen View (the "mark preparing / served" buttons)
-- Used by: kitchen staff advancing an order line through its
-- lifecycle: ordered -> preparing -> served.
-- Only these three statuses are accepted, matching what
-- fn_place_order writes ('ordered') and what fn_get_kitchen_orders
-- filters on (everything <> 'served' still shows in the kitchen).
-- Returns the order_line_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_update_order_status(
    p_order_line_id INT,
    p_status        VARCHAR
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_line_id INT;
BEGIN
    IF p_status NOT IN ('ordered', 'preparing', 'served') THEN
        RAISE EXCEPTION 'Invalid status % (use ordered / preparing / served)', p_status;
    END IF;

    UPDATE order_line
    SET status = p_status
    WHERE order_line_id = p_order_line_id
    RETURNING order_line_id INTO v_order_line_id;

    IF v_order_line_id IS NULL THEN
        RAISE EXCEPTION 'Order line % does not exist', p_order_line_id;
    END IF;

    RETURN v_order_line_id;
END;
$$;

-- Example call (kitchen starts cooking line 1):
-- SELECT fn_update_order_status(1, 'preparing');
-- Example call (dish delivered to the table):
-- SELECT fn_update_order_status(1, 'served');
-- Example call (should FAIL: not a valid status):
-- SELECT fn_update_order_status(1, 'eaten');
