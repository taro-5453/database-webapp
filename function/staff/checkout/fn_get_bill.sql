-- ============================================================
-- fn_get_bill
-- Screen: Staff > Checkout (the receipt shown after payment)
-- Used by: displaying the finished bill. fn_checkout writes the
-- BILL row but nothing could read it back — this returns the
-- full receipt: who/where/what tier, the money breakdown
-- (buffet + extras - discount = total), how it was paid, and the
-- membership points the bill earned.
-- Returns 0 rows if the bill does not exist.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_bill(
    p_bill_id INT
)
RETURNS TABLE (
    bill_id         INT,
    session_id      INT,
    customer_id     INT,
    customer_name   VARCHAR,
    branch_name     VARCHAR,
    table_id        INT,
    tier_name       VARCHAR,
    guest_count     INT,
    price_per_head  DECIMAL,
    buffet_total    DECIMAL,
    extra_charges   DECIMAL,
    discount_amount DECIMAL,
    promotion_code  VARCHAR,
    final_total     DECIMAL,
    payment_method  VARCHAR,
    paid_at         TIMESTAMP,
    points_earned   INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT b.bill_id,
           b.session_id,
           ds.customer_id,
           c.name  AS customer_name,
           br.name AS branch_name,
           ds.table_id,
           bt.name AS tier_name,
           ds.guest_count,
           bt.price_per_head,
           b.buffet_total,
           b.extra_charges,
           b.discount_amount,
           p.code  AS promotion_code,          -- NULL when no promo used
           b.final_total,
           b.payment_method,
           b.paid_at,
           COALESCE((SELECT pt.change_amount FROM point_transaction pt
                     WHERE pt.bill_id = b.bill_id AND pt.type = 'earn'
                     LIMIT 1), 0) AS points_earned
    FROM bill b
    JOIN dining_session ds ON ds.session_id = b.session_id
    JOIN customer c        ON c.customer_id = ds.customer_id
    JOIN branch br         ON br.branch_id  = ds.branch_id
    JOIN buffet_tier bt    ON bt.tier_id    = ds.tier_id
    LEFT JOIN promotion p  ON p.promotion_id = b.promotion_id
    WHERE b.bill_id = p_bill_id;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_bill(1);
-- Example result: the complete receipt for bill 1 (customer, branch,
-- tier, money breakdown, payment, points earned).
