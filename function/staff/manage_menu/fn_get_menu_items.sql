-- ============================================================
-- fn_get_menu_items
-- Screen: Staff > Manage Menu (the item list + availability toggles)
-- Used by: showing every item at a branch, available or not, so
-- staff can 86/restore dishes. fn_get_tier_menu can't serve this —
-- it's session+tier-scoped and filters to available=TRUE only, so
-- there was no way to see the full branch inventory. This fills
-- that gap.
-- Returns every item at the branch, unfiltered, cheapest category
-- grouping first.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_menu_items(
    p_branch_id INT
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
    FROM menu_item mi
    WHERE mi.branch_id = p_branch_id
    ORDER BY mi.category, mi.name;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_menu_items(1);
-- Example result: every item at branch 1, including unavailable ones.
