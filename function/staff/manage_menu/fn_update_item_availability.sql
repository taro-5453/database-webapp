-- ============================================================
-- fn_update_item_availability
-- Screen: Staff > Manage Menu (the availability toggle)
-- Used by: marking an item out of stock ("86'd") or back on the
-- menu. Customers' fn_get_tier_menu should only offer available
-- items, so flipping this hides/restores the dish immediately.
-- Returns the item_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_update_item_availability(
    p_item_id   INT,
    p_available BOOLEAN
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_item_id INT;
BEGIN
    UPDATE menu_item
    SET available = p_available
    WHERE item_id = p_item_id
    RETURNING item_id INTO v_item_id;

    IF v_item_id IS NULL THEN
        RAISE EXCEPTION 'Menu item % does not exist', p_item_id;
    END IF;

    RETURN v_item_id;
END;
$$;

-- Example call (salmon ran out):
SELECT fn_update_item_availability(5, FALSE);
-- Example call (salmon restocked):
SELECT fn_update_item_availability(5, TRUE);
-- Example call (should FAIL: no such item):
SELECT fn_update_item_availability(999, FALSE);
