-- ============================================================
-- fn_validate_promotion
-- Screen: Staff > Checkout (promotion code entry)
-- Used by: checking a promotion code before/at checkout.
-- Returns the promotion's details plus is_valid (exists AND not
-- expired). Returns no rows if the code doesn't exist at all.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_validate_promotion(
    p_code VARCHAR
)
RETURNS TABLE (
    promotion_id  INT,
    discount      DECIMAL,
    discount_type VARCHAR,
    valid_until   DATE,
    is_valid      BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.promotion_id,
           p.discount,
           p.discount_type,
           p.valid_until,
           (p.valid_until IS NULL OR p.valid_until >= CURRENT_DATE) AS is_valid
    FROM promotion p
    WHERE p.code = p_code;
END;
$$;

-- Example call (valid code):
-- SELECT * FROM fn_validate_promotion('WELCOME10');
-- Example call (expired code):
-- SELECT * FROM fn_validate_promotion('SONGKRAN30');   -- valid_until 2026-04-30, already past
-- Example call (code doesn't exist -> no rows):
-- SELECT * FROM fn_validate_promotion('NOPE');
