-- ============================================================
-- fn_get_current_bill
-- Screen: Customer > View Bill (running total, before checkout)
-- Used by: the "current total" display while a session is still
-- active. Same buffet_total/extra_charges math as fn_checkout,
-- but read-only - no BILL row is created here.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_current_bill(
    p_session_id INT
)
RETURNS TABLE (
    tier_id        INT,
    price_per_head DECIMAL,
    guest_count    INT,
    buffet_total   DECIMAL,
    extra_charges  DECIMAL,
    running_total  DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ds.tier_id,
           bt.price_per_head,
           ds.guest_count,
           (bt.price_per_head * ds.guest_count) AS buffet_total,
           COALESCE(ol.extra_charges, 0)        AS extra_charges,
           (bt.price_per_head * ds.guest_count) + COALESCE(ol.extra_charges, 0) AS running_total
    FROM dining_session ds
    JOIN buffet_tier bt ON bt.tier_id = ds.tier_id
    LEFT JOIN (
        SELECT session_id, SUM(quantity * unit_price) AS extra_charges
        FROM order_line
        WHERE session_id = p_session_id
        GROUP BY session_id
    ) ol ON ol.session_id = ds.session_id
    WHERE ds.session_id = p_session_id;
END;
$$;

-- Example call:
SELECT * FROM fn_get_current_bill(1);
-- Example result: running total for session 1 so far (buffet + extras ordered).
