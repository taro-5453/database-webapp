-- ============================================================
-- fn_get_membership
-- Screen: Customer > Profile / Membership
-- Used by: the profile screen's points + tier display.
-- Returns the membership summary for one customer.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_membership(
    p_customer_id INT
)
RETURNS TABLE (
    membership_id INT,
    customer_name VARCHAR,
    points        INT,
    tier          VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT m.membership_id,
           c.name AS customer_name,
           m.points,
           m.tier
    FROM membership m
    JOIN customer c ON c.customer_id = m.customer_id
    WHERE m.customer_id = p_customer_id;
END;
$$;

-- Example call:
SELECT * FROM fn_get_membership(2);
-- Example result: membership id, name, points, and tier for customer 2.
