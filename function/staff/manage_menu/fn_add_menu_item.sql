-- ============================================================
-- fn_add_menu_item
-- Screen: Staff > Manage Menu (the "add item" form)
-- Used by: adding a new dish/drink to a branch's menu.
-- price = 0 means buffet-included; > 0 means extra charge.
-- p_tier_ids (optional) links the new item to that branch's
-- buffet tiers in the same call — without at least one
-- TIER_MENU_ITEM row the item can never be ordered, because
-- fn_place_order enforces the tier rule.
-- Returns the new item_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_add_menu_item(
    p_branch_id INT,
    p_name      VARCHAR,
    p_category  VARCHAR,
    p_price     DECIMAL(10,2),
    p_tier_ids  INT[] DEFAULT NULL   -- tiers that may order this item
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_item_id INT;
BEGIN
    IF p_name IS NULL OR btrim(p_name) = '' THEN
        RAISE EXCEPTION 'Item name is required';
    END IF;

    IF p_price IS NULL OR p_price < 0 THEN
        RAISE EXCEPTION 'Price must be 0 (buffet-included) or positive';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM branch b WHERE b.branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'Branch % does not exist', p_branch_id;
    END IF;

    -- every tier being linked must belong to the same branch
    IF p_tier_ids IS NOT NULL AND EXISTS (
        SELECT 1 FROM unnest(p_tier_ids) AS t(tier_id)
        WHERE NOT EXISTS (SELECT 1 FROM buffet_tier bt
                          WHERE bt.tier_id = t.tier_id
                            AND bt.branch_id = p_branch_id)
    ) THEN
        RAISE EXCEPTION 'All tier ids must belong to branch %', p_branch_id;
    END IF;

    INSERT INTO menu_item (branch_id, name, category, price, available)
    VALUES (p_branch_id, btrim(p_name), p_category, p_price, TRUE)
    RETURNING item_id INTO v_item_id;

    IF p_tier_ids IS NOT NULL THEN
        INSERT INTO tier_menu_item (tier_id, item_id)
        SELECT DISTINCT t.tier_id, v_item_id
        FROM unnest(p_tier_ids) AS t(tier_id);
    END IF;

    RETURN v_item_id;
END;
$$;

-- Example call (buffet-included item, orderable by both branch-1 tiers):
SELECT fn_add_menu_item(1, 'Lamb Slices', 'meat', 0.00, ARRAY[1, 2]);
-- Example call (extra-charge dessert, premium tier only):
SELECT fn_add_menu_item(1, 'Matcha Parfait', 'dessert', 89.00, ARRAY[2]);
-- Example call (should FAIL: tier 3 belongs to branch 2):
SELECT fn_add_menu_item(1, 'Wrong Tier Item', 'meat', 0.00, ARRAY[3]);
