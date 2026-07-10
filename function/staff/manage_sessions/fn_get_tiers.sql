-- ============================================================
-- fn_get_tiers
-- Screen: Staff > Manage sessions ("open session" tier picker),
--         also Staff > Manage menu (tier checkboxes for a new item)
-- Used by: any screen that needs to show a branch's buffet tiers
-- as choosable options. Every other function takes a tier_id as
-- input but none returned the list — so the UI had nothing to
-- populate its dropdown with. This fills that gap.
-- Returns the branch's tiers, cheapest first.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_tiers(
    p_branch_id INT
)
RETURNS TABLE (
    tier_id          INT,
    name             VARCHAR,
    price_per_head   DECIMAL,
    duration_minutes INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT bt.tier_id,
           bt.name,
           bt.price_per_head,
           bt.duration_minutes
    FROM buffet_tier bt
    WHERE bt.branch_id = p_branch_id
    ORDER BY bt.price_per_head ASC;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_tiers(1);
-- Example result: branch 1's tiers (Standard, Premium) with price
-- per head and duration, cheapest first.
