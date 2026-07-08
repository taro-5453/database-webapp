-- ============================================================
-- fn_checkout
-- Screen: Staff > Checkout
-- Used by: the "close bill" button once a table is done dining.
-- The big transaction for ending a session:
--   1. computes buffet_total from the session's tier price x guest count
--   2. computes extra_charges from the session's order lines
--   3. applies an optional promotion code (validated + not expired)
--   4. inserts the BILL
--   5. earns membership points on the bill and updates the running balance
--   6. closes the session and frees the table
-- Returns the new bill_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_checkout(
    p_session_id     INT,
    p_promotion_code VARCHAR DEFAULT NULL,
    p_payment_method VARCHAR DEFAULT 'cash'
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_id        INT;
    v_customer_id     INT;
    v_tier_id         INT;
    v_guest_count     INT;
    v_price_per_head  DECIMAL(10,2);
    v_buffet_total    DECIMAL(10,2);
    v_extra_charges   DECIMAL(10,2);
    v_promotion_id    INT;
    v_discount        DECIMAL(10,2);
    v_discount_type   VARCHAR(10);
    v_discount_amount DECIMAL(10,2) := 0;
    v_final_total     DECIMAL(10,2);
    v_bill_id         INT;
    v_membership_id   INT;
    v_points_earned   INT;
BEGIN
    -- lock the session row so two staff can't check out the same table twice at once
    SELECT table_id, customer_id, tier_id, guest_count
    INTO v_table_id, v_customer_id, v_tier_id, v_guest_count
    FROM dining_session
    WHERE session_id = p_session_id AND status = 'active'
    FOR UPDATE;

    IF v_tier_id IS NULL THEN
        RAISE EXCEPTION 'Session % is not active or does not exist', p_session_id;
    END IF;

    -- buffet portion: tier price x guest count (the invariant that went stale as hand-typed data before)
    SELECT price_per_head INTO v_price_per_head
    FROM buffet_tier
    WHERE tier_id = v_tier_id;

    v_buffet_total := v_price_per_head * v_guest_count;

    -- extra-charge portion: sum of everything ordered (buffet-included items carry unit_price 0)
    SELECT COALESCE(SUM(quantity * unit_price), 0) INTO v_extra_charges
    FROM order_line
    WHERE session_id = p_session_id;

    -- optional promotion code
    IF p_promotion_code IS NOT NULL THEN
        SELECT promotion_id, discount, discount_type
        INTO v_promotion_id, v_discount, v_discount_type
        FROM promotion
        WHERE code = p_promotion_code
          AND (valid_until IS NULL OR valid_until >= CURRENT_DATE);

        IF v_promotion_id IS NULL THEN
            RAISE EXCEPTION 'Promotion code % is invalid or expired', p_promotion_code;
        END IF;

        IF v_discount_type = 'percent' THEN
            v_discount_amount := ROUND((v_buffet_total + v_extra_charges) * v_discount / 100, 2);
        ELSE
            v_discount_amount := v_discount;
        END IF;
    END IF;

    v_final_total := GREATEST(v_buffet_total + v_extra_charges - v_discount_amount, 0);

    INSERT INTO bill
        (session_id, promotion_id, buffet_total, extra_charges, discount_amount, final_total, payment_method, payment_status, paid_at)
    VALUES
        (p_session_id, v_promotion_id, v_buffet_total, v_extra_charges, v_discount_amount, v_final_total, p_payment_method, 'paid', NOW())
    RETURNING bill_id INTO v_bill_id;

    -- earn points if this customer is a member (walk-ins with no membership row just skip this)
    SELECT membership_id INTO v_membership_id
    FROM membership
    WHERE customer_id = v_customer_id;

    IF v_membership_id IS NOT NULL THEN
        v_points_earned := FLOOR(v_final_total / 100);

        INSERT INTO point_transaction (membership_id, bill_id, change_amount, type)
        VALUES (v_membership_id, v_bill_id, v_points_earned, 'earn');

        UPDATE membership
        SET points = points + v_points_earned
        WHERE membership_id = v_membership_id;
    END IF;

    UPDATE dining_session SET status = 'closed', end_time = NOW() WHERE session_id = p_session_id;
    UPDATE dining_table SET status = 'available' WHERE table_id = v_table_id;

    RETURN v_bill_id;
END;
$$;

-- Example call (no promotion):
SELECT fn_checkout(1, NULL, 'cash');
-- Example call (with a promotion code):
SELECT fn_checkout(1, 'WELCOME10', 'credit_card');
-- Example call (should FAIL, session already closed or missing):
SELECT fn_checkout(999);
