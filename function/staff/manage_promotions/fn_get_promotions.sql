-- ============================================================
-- fn_get_promotions
-- Screen: Staff > Manage Promotions (the promotions list)
-- Used by: the staff table of all promotion codes.
-- is_active = not yet past valid_until (NULL = never expires),
-- so the UI can grey out expired codes without hiding them.
-- Active codes first, soonest-to-expire at the top.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_promotions()
RETURNS TABLE (
    promotion_id  INT,
    code          VARCHAR,
    discount      DECIMAL(10,2),
    discount_type VARCHAR,
    valid_until   DATE,
    is_active     BOOLEAN,
    created_by    VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.promotion_id,
           p.code,
           p.discount,
           p.discount_type,
           p.valid_until,
           (p.valid_until IS NULL OR p.valid_until >= CURRENT_DATE) AS is_active,
           s.name AS created_by
    FROM promotion p
    JOIN staff s ON s.staff_id = p.staff_id
    ORDER BY (p.valid_until IS NULL OR p.valid_until >= CURRENT_DATE) DESC,
             p.valid_until ASC NULLS LAST;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_promotions();
-- Example result: every promotion with its creator; active codes
-- first (soonest to expire on top), expired codes at the bottom.
