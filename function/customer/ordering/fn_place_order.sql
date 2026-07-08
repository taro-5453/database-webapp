-- ============================================================
-- fn_place_order
-- Screen: Customer > Order dishes (the "add to order" button)
-- Used by: placing an order line during a session.
-- Enforces the tier rule: rejects any item that is NOT in the
-- session's tier (via TIER_MENU_ITEM). Copies the current
-- menu_item.price into unit_price so past bills stay correct if
-- prices later change. Returns the new order_line_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_place_order(
    p_session_id INT,
    p_item_id    INT,
    p_quantity   INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_tier_id       INT;
    v_allowed       BOOLEAN;
    v_price         DECIMAL(10,2);
    v_order_line_id INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be positive';
    END IF;

    -- find the session's tier (and confirm the session exists & is active)
    SELECT tier_id INTO v_tier_id
    FROM dining_session
    WHERE session_id = p_session_id AND status = 'active';

    IF v_tier_id IS NULL THEN
        RAISE EXCEPTION 'Session % is not active or does not exist', p_session_id;
    END IF;

    -- tier enforcement: is this item allowed for the session's tier?
    SELECT EXISTS (
        SELECT 1 FROM tier_menu_item
        WHERE tier_id = v_tier_id AND item_id = p_item_id
    ) INTO v_allowed;

    IF NOT v_allowed THEN
        RAISE EXCEPTION 'Item % is not included in this session''s tier', p_item_id;
    END IF;

    -- copy the current price at order time
    SELECT price INTO v_price FROM menu_item WHERE item_id = p_item_id;

    INSERT INTO order_line (session_id, item_id, quantity, unit_price, ordered_at, status)
    VALUES (p_session_id, p_item_id, p_quantity, v_price, NOW(), 'ordered')
    RETURNING order_line_id INTO v_order_line_id;

    RETURN v_order_line_id;
END;
$$;

-- Example call (allowed item):
SELECT fn_place_order(2, 3, 2);
-- Example call (should FAIL if item not in tier):
SELECT fn_place_order(4, 3, 1);   -- item 3 (wagyu) not in standard tier
