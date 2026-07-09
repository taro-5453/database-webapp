-- Example call (timed booking):
--   SELECT fn_create_reservation(1, 1, 2, '2026-07-15 18:00:00', 4);
-- Example call (join queue):
--   SELECT fn_create_reservation(3, 2, NULL, NULL, 2);


-- ============================================================
-- fn_get_kitchen_orders
-- Screen: Staff > Kitchen View
-- Used by: the live list of orders the kitchen still needs to make.
-- Returns all order lines for active sessions at a branch that
-- are not yet served, oldest first. Uses the
-- idx_order_line_session_status index.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_kitchen_orders(
    p_branch_id INT
)
RETURNS TABLE (
    order_line_id INT,
    session_id    INT,
    table_id      INT,
    item_name     VARCHAR,
    quantity      INT,
    ordered_at    TIMESTAMP,
    status        VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ol.order_line_id,
           ol.session_id,
           ds.table_id,
           mi.name AS item_name,
           ol.quantity,
           ol.ordered_at,
           ol.status
    FROM order_line ol
    JOIN dining_session ds ON ds.session_id = ol.session_id
    JOIN menu_item mi      ON mi.item_id = ol.item_id
    WHERE ds.branch_id = p_branch_id
      AND ds.status = 'active'
      AND ol.status <> 'served'
    ORDER BY ol.ordered_at ASC;
END;
$$;

-- Dump testing data
-- INSERT INTO order_line (session_id, item_id, quantity, unit_price, ordered_at, status)
-- VALUES (1, 1, 2, 0.00, NOW(), 'ordered');

-- Example call:
-- SELECT * FROM fn_get_kitchen_orders(2);
-- Example result: unserved dishes for active tables at branch 2.
-- SELECT * FROM reservation ORDER BY reservation_id DESC;


-- Delete dump data
-- DELETE FROM order_line WHERE order_line_id = 15

