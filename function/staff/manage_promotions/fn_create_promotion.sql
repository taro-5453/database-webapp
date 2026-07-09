-- ============================================================
-- fn_create_promotion
-- Screen: Staff > Manage Promotions (the "new promotion" form)
-- Used by: staff creating a discount code for checkout.
-- discount_type 'percent' = % off the bill (max 100);
-- 'fixed' = flat amount off. Codes are stored UPPERCASE and
-- checked case-insensitively so 'welcome10' can't duplicate
-- 'WELCOME10'. valid_until NULL = never expires.
-- Returns the new promotion_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_create_promotion(
    p_staff_id      INT,
    p_code          VARCHAR,
    p_discount      DECIMAL(10,2),
    p_discount_type VARCHAR,
    p_valid_until   DATE
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_code         VARCHAR;
    v_promotion_id INT;
BEGIN
    IF p_code IS NULL OR btrim(p_code) = '' THEN
        RAISE EXCEPTION 'Promotion code is required';
    END IF;
    v_code := upper(btrim(p_code));

    IF p_discount_type NOT IN ('percent', 'fixed') THEN
        RAISE EXCEPTION 'discount_type must be percent or fixed';
    END IF;

    IF p_discount IS NULL OR p_discount <= 0 THEN
        RAISE EXCEPTION 'Discount must be positive';
    END IF;

    IF p_discount_type = 'percent' AND p_discount > 100 THEN
        RAISE EXCEPTION 'Percent discount cannot exceed 100';
    END IF;

    IF p_valid_until IS NOT NULL AND p_valid_until < CURRENT_DATE THEN
        RAISE EXCEPTION 'valid_until % is already in the past', p_valid_until;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM staff s WHERE s.staff_id = p_staff_id) THEN
        RAISE EXCEPTION 'Staff % does not exist', p_staff_id;
    END IF;

    IF EXISTS (SELECT 1 FROM promotion p WHERE upper(p.code) = v_code) THEN
        RAISE EXCEPTION 'Promotion code % already exists', v_code;
    END IF;

    INSERT INTO promotion (staff_id, code, discount, discount_type, valid_until)
    VALUES (p_staff_id, v_code, p_discount, p_discount_type, p_valid_until)
    RETURNING promotion_id INTO v_promotion_id;

    RETURN v_promotion_id;
END;
$$;

-- Example call (15% off until New Year):
SELECT fn_create_promotion(1, 'NEWYEAR15', 15.00, 'percent', '2026-12-31');
-- Example call (flat 80 baht off, never expires):
SELECT fn_create_promotion(3, 'TAKE80', 80.00, 'fixed', NULL);
-- Example call (should FAIL: duplicate of sample code WELCOME10):
SELECT fn_create_promotion(1, 'welcome10', 10.00, 'percent', '2026-12-31');
