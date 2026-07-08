-- ============================================================
-- fn_get_point_history
-- Screen: Customer > Profile / Membership (points history)
-- Used by: the "points activity" list on the profile screen.
-- Returns every point transaction for a customer, newest first.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_point_history(
    p_customer_id INT
)
RETURNS TABLE (
    transaction_id INT,
    change_amount  INT,
    type           VARCHAR,
    bill_id        INT,
    created_at     TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT pt.transaction_id,
           pt.change_amount,
           pt.type,
           pt.bill_id,
           pt.created_at
    FROM point_transaction pt
    JOIN membership m ON m.membership_id = pt.membership_id
    WHERE m.customer_id = p_customer_id
    ORDER BY pt.created_at DESC;
END;
$$;

-- Example call:
--   SELECT * FROM fn_get_point_history(2);
-- Example result: customer 2's earn/redeem history, newest first.