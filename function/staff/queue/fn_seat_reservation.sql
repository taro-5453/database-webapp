-- ============================================================
-- fn_seat_reservation
-- Screen: Staff > Queue (the "seat this party" button)
-- Used by: moving a waiting party (queued walk-in or timed
-- reservation) to one OR MORE tables: rows go into
-- reservation_table, reservation -> 'seated', tables -> 'occupied'.
-- A big party can combine tables (e.g. 12 guests on two 6-seaters),
-- so the capacity check is against the SUM of the chosen tables.
-- This only assigns tables. Opening the buffet session (which
-- needs a tier + guest count) happens next via fn_open_session.
-- Returns the reservation_id.
-- ============================================================
-- The old (INT, INT, INT) single-table version must go: the
-- argument types changed, so CREATE OR REPLACE would overload.
DROP FUNCTION IF EXISTS fn_seat_reservation(INT, INT, INT);

CREATE OR REPLACE FUNCTION fn_seat_reservation(
    p_reservation_id INT,
    p_table_ids      INT[],
    p_staff_id       INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_id      INT;
    v_party_size     INT;
    v_res_status     VARCHAR;
    v_valid_count    INT;
    v_total_capacity INT;
BEGIN
    IF p_table_ids IS NULL OR array_length(p_table_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'At least one table must be chosen';
    END IF;

    SELECT r.branch_id, r.party_size, r.status
    INTO v_branch_id, v_party_size, v_res_status
    FROM reservation r
    WHERE r.reservation_id = p_reservation_id;

    IF v_branch_id IS NULL THEN
        RAISE EXCEPTION 'Reservation % does not exist', p_reservation_id;
    END IF;

    IF v_res_status NOT IN ('queued', 'reserved') THEN
        RAISE EXCEPTION 'Reservation % is not waiting (status: %)',
                        p_reservation_id, v_res_status;
    END IF;

    -- the seating staff member must work at the reservation's branch
    IF NOT EXISTS (SELECT 1 FROM staff s
                   WHERE s.staff_id = p_staff_id AND s.branch_id = v_branch_id) THEN
        RAISE EXCEPTION 'Staff % does not belong to branch %', p_staff_id, v_branch_id;
    END IF;

    -- every chosen table must exist at this branch and be free;
    -- DISTINCT guards against the same table passed twice
    SELECT COUNT(*), COALESCE(SUM(dt.capacity), 0)
    INTO v_valid_count, v_total_capacity
    FROM dining_table dt
    WHERE dt.table_id = ANY(p_table_ids)
      AND dt.branch_id = v_branch_id
      AND dt.status = 'available';

    IF v_valid_count < (SELECT COUNT(DISTINCT t) FROM unnest(p_table_ids) AS t) THEN
        RAISE EXCEPTION 'Some chosen tables do not exist at branch % or are not available',
                        v_branch_id;
    END IF;

    IF v_total_capacity < v_party_size THEN
        RAISE EXCEPTION 'Chosen tables seat only % combined (party of %)',
                        v_total_capacity, v_party_size;
    END IF;

    INSERT INTO reservation_table (reservation_id, table_id)
    SELECT p_reservation_id, t
    FROM unnest(p_table_ids) AS t
    GROUP BY t;

    UPDATE reservation
    SET status = 'seated'
    WHERE reservation_id = p_reservation_id;

    UPDATE dining_table
    SET status = 'occupied'
    WHERE table_id = ANY(p_table_ids);

    RETURN p_reservation_id;
END;
$$;

-- Example call (queued party of 2 at branch 2 -> table 5):
-- SELECT fn_seat_reservation(3, ARRAY[5], 3);
-- Example call (party of 12 combining two tables):
-- SELECT fn_seat_reservation(1, ARRAY[2, 4], 1);
-- Example call (should FAIL: tables too small combined):
-- SELECT fn_seat_reservation(3, ARRAY[5], 3) where party > capacity;
