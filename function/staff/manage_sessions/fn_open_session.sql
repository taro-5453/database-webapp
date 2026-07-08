-- ============================================================
-- fn_open_session
-- Screen: Staff > Manage sessions (the "seat party" button)
-- Used by: opening a buffet session for a reservation or walk-in.
-- p_reservation_id is NULL for pure walk-ins. Validates that the
-- table/tier/staff all belong to the branch, that the table is
-- free and big enough, then in one transaction:
--   1. creates the dining_session (status 'active'),
--   2. marks the table 'occupied',
--   3. marks the reservation 'seated' (when one was given).
-- Returns the new session_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_open_session(
    p_reservation_id INT,          -- NULL = walk-in
    p_branch_id      INT,
    p_table_id       INT,
    p_customer_id    INT,
    p_tier_id        INT,
    p_staff_id       INT,
    p_guest_count    INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_status VARCHAR;
    v_capacity     INT;
    v_session_id   INT;
BEGIN
    IF p_guest_count <= 0 THEN
        RAISE EXCEPTION 'Guest count must be positive';
    END IF;

    -- table must exist, belong to this branch, be free, and fit the party
    SELECT dt.status, dt.capacity INTO v_table_status, v_capacity
    FROM dining_table dt
    WHERE dt.table_id = p_table_id AND dt.branch_id = p_branch_id;

    IF v_table_status IS NULL THEN
        RAISE EXCEPTION 'Table % does not exist at branch %', p_table_id, p_branch_id;
    END IF;

    IF v_table_status <> 'available' THEN
        RAISE EXCEPTION 'Table % is not available (status: %)', p_table_id, v_table_status;
    END IF;

    IF v_capacity < p_guest_count THEN
        RAISE EXCEPTION 'Table % seats only % (party of %)', p_table_id, v_capacity, p_guest_count;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM buffet_tier bt
                   WHERE bt.tier_id = p_tier_id AND bt.branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'Tier % does not belong to branch %', p_tier_id, p_branch_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM staff s
                   WHERE s.staff_id = p_staff_id AND s.branch_id = p_branch_id) THEN
        RAISE EXCEPTION 'Staff % does not belong to branch %', p_staff_id, p_branch_id;
    END IF;

    -- when seating a reservation, it must be one still waiting for a table
    IF p_reservation_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM reservation r
                       WHERE r.reservation_id = p_reservation_id
                         AND r.branch_id = p_branch_id
                         AND r.status IN ('reserved', 'queued')) THEN
            RAISE EXCEPTION 'Reservation % is not waiting to be seated at branch %',
                            p_reservation_id, p_branch_id;
        END IF;

        UPDATE reservation
        SET status = 'seated', table_id = p_table_id
        WHERE reservation_id = p_reservation_id;
    END IF;

    INSERT INTO dining_session
        (reservation_id, branch_id, table_id, customer_id, tier_id,
         staff_id, start_time, guest_count, status)
    VALUES
        (p_reservation_id, p_branch_id, p_table_id, p_customer_id, p_tier_id,
         p_staff_id, NOW(), p_guest_count, 'active')
    RETURNING session_id INTO v_session_id;

    UPDATE dining_table
    SET status = 'occupied'
    WHERE table_id = p_table_id;

    RETURN v_session_id;
END;
$$;

-- Example call (walk-in, no reservation):
SELECT fn_open_session(NULL, 1, 1, 3, 1, 1, 2);
-- Example call (seating reservation 1):
SELECT fn_open_session(1, 1, 2, 1, 1, 2, 4);
-- Example call (should FAIL: table already occupied by the first call):
SELECT fn_open_session(NULL, 1, 1, 5, 1, 1, 2);
