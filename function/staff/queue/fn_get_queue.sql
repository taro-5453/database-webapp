-- ============================================================
-- fn_get_queue
-- Screen: Staff > Queue (the waiting list)
-- Used by: the staff view of parties waiting for a table at the
-- branch. Only 'queued' walk-ins appear (timed reservations live
-- on the reservations screen, not the queue).
-- queue_position is first-come-first-served by reservation_id,
-- since queued entries have no slot_time in this schema.
-- customer_id is included so the "seat" flow can pass it straight
-- into fn_open_session, which requires it explicitly and doesn't
-- derive it from the reservation itself.
-- tier_id/tier_name are the customer's preferred tier picked at
-- booking (NULL = decide when seated) so the seating dialog can
-- preselect it.
-- ============================================================
-- Adding a column changes the OUT-parameter row type, which
-- CREATE OR REPLACE can't do in place — drop first (idempotent).
DROP FUNCTION IF EXISTS fn_get_queue(INT);

CREATE OR REPLACE FUNCTION fn_get_queue(
    p_branch_id INT
)
RETURNS TABLE (
    queue_position INT,
    reservation_id INT,
    customer_id    INT,
    customer_name  VARCHAR,
    phone          VARCHAR,
    party_size     INT,
    tier_id        INT,
    tier_name      VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ROW_NUMBER() OVER (ORDER BY r.reservation_id)::INT AS queue_position,
           r.reservation_id,
           r.customer_id,
           c.name  AS customer_name,
           c.phone,
           r.party_size,
           r.tier_id,
           bt.name AS tier_name
    FROM reservation r
    JOIN customer c ON c.customer_id = r.customer_id
    LEFT JOIN buffet_tier bt ON bt.tier_id = r.tier_id
    WHERE r.branch_id = p_branch_id
      AND r.status = 'queued'
    ORDER BY r.reservation_id ASC;
END;
$$;

-- Example call:
-- SELECT * FROM fn_get_queue(2);
-- Example result: waiting parties at branch 2 in arrival order,
-- with the customer's name and phone so staff can call them.
