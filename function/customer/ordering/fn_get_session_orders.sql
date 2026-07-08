

-- ============================================================
-- fn_get_session_orders
-- Screen: Customer > Order dishes ("my orders" list)
-- Used by: the list of what this session has ordered so far.
-- Returns all order lines for a session with item names, newest first.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_session_orders(
    p_session_id INT
)
RETURNS TABLE (
    order_line_id INT,
    item_name     VARCHAR,
    quantity      INT,
    unit_price    DECIMAL,
    line_total    DECIMAL,
    status        VARCHAR,
    ordered_at    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ol.order_line_id,
           mi.name AS item_name,
           ol.quantity,
           ol.unit_price,
           (ol.quantity * ol.unit_price) AS line_total,
           ol.status,
           ol.ordered_at
    FROM order_line ol
    JOIN menu_item mi ON mi.item_id = ol.item_id
    WHERE ol.session_id = p_session_id
    ORDER BY ol.ordered_at DESC;
END;
$$;

-- Example call:
SELECT * FROM fn_get_session_orders(2);
-- Example result: all dishes ordered in session 2, with line totals.