-- ============================================================
-- fn_get_active_sessions
-- Screen: Staff > Manage sessions (the dashboard list)
-- Used by: the staff dashboard showing every active session at
-- the branch, with time remaining against the tier's duration.
-- minutes_remaining counts down from the tier's duration_minutes;
-- NEGATIVE means the party is overtime by that many minutes, so
-- the dashboard can highlight tables that should be closing.
-- Sessions with the least time left come first.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_get_active_sessions(
    p_branch_id INT
)
RETURNS TABLE (
    session_id        INT,
    table_id          INT,
    customer_name     VARCHAR,
    guest_count       INT,
    tier_name         VARCHAR,
    duration_minutes  INT,
    start_time        TIMESTAMP,
    ends_at           TIMESTAMP,
    minutes_remaining INT,
    staff_name        VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ds.session_id,
           ds.table_id,
           c.name AS customer_name,
           ds.guest_count,
           bt.name AS tier_name,
           bt.duration_minutes,
           ds.start_time,
           ds.start_time + (bt.duration_minutes * INTERVAL '1 minute') AS ends_at,
           -- minutes until session ends, rounded up (negative = overdue)
           CEIL(EXTRACT(EPOCH FROM
                (ds.start_time + (bt.duration_minutes * INTERVAL '1 minute')) - NOW()
           ) / 60)::INT AS minutes_remaining,
           s.name AS staff_name
    FROM dining_session ds
    JOIN customer    c  ON c.customer_id = ds.customer_id
    JOIN buffet_tier bt ON bt.tier_id    = ds.tier_id
    JOIN staff       s  ON s.staff_id    = ds.staff_id
    WHERE ds.branch_id = p_branch_id
      AND ds.status = 'active'
    -- ordering by the alias would be ambiguous inside plpgsql
    -- (minutes_remaining is also an output variable), so repeat
    -- the end-time expression: soonest to end first
    ORDER BY ds.start_time + (bt.duration_minutes * INTERVAL '1 minute') ASC;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_active_sessions(1);
-- Example result: one row per active session at branch 1, with the
-- tier's time limit, when it ends, and minutes remaining (negative
-- = overtime), most urgent first.
