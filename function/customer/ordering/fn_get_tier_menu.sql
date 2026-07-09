-- ============================================================
-- Momo Paradise - Ordering Functions
-- Screen: Customer > Order dishes during a dining session
-- ============================================================


-- ============================================================
-- fn_get_tier_menu
-- Screen: Customer > Order dishes (menu shown during a session)
-- Used by: the menu list the customer picks dishes from.
-- Returns only the items allowed for THIS session's buffet tier,
-- by joining through TIER_MENU_ITEM. This is the signature feature:
-- a standard-tier table only sees standard items, a premium table
-- sees premium items too.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_tier_menu(
    p_session_id INT
)
RETURNS TABLE (
    item_id   INT,
    name      VARCHAR,
    category  VARCHAR,
    price     DECIMAL,
    available BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT mi.item_id, mi.name, mi.category, mi.price, mi.available
    FROM dining_session ds
    JOIN tier_menu_item tmi ON tmi.tier_id = ds.tier_id
    JOIN menu_item mi       ON mi.item_id = tmi.item_id
    WHERE ds.session_id = p_session_id
      AND mi.available = TRUE
    ORDER BY mi.category, mi.name;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_tier_menu(2);
-- Example result: items the tier of session 2 is allowed to order.

