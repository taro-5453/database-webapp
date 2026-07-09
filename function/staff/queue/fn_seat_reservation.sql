-- ============================================================
-- fn_seat_reservation
-- Screen: Staff > Queue (the "seat this party" button)
-- Used by: moving a waiting party (queued walk-in or timed
-- reservation) to a table: reservation -> 'seated' with the table
-- recorded, table -> 'occupied'.
-- This only assigns the table. Opening the buffet session (which
-- needs a tier + guest count) happens next via fn_open_session,
-- which accepts a reservation already seated at that table.
-- Returns the reservation_id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_seat_reservation(
    p_reservation_id INT,
    p_table_id       INT,
    p_staff_id       INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_id    INT;
    v_party_size   INT;
    v_res_status   VARCHAR;
    v_table_status VARCHAR;
    v_capacity     INT;
BEGIN
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

    SELECT dt.status, dt.capacity INTO v_table_status, v_capacity
    FROM dining_table dt
    WHERE dt.table_id = p_table_id AND dt.branch_id = v_branch_id;

    IF v_table_status IS NULL THEN
        RAISE EXCEPTION 'Table % does not exist at branch %', p_table_id, v_branch_id;
    END IF;

    IF v_table_status <> 'available' THEN
        RAISE EXCEPTION 'Table % is not available (status: %)', p_table_id, v_table_status;
    END IF;

    IF v_capacity < v_party_size THEN
        RAISE EXCEPTION 'Table % seats only % (party of %)', p_table_id, v_capacity, v_party_size;
    END IF;

    UPDATE reservation
    SET status = 'seated', table_id = p_table_id
    WHERE reservation_id = p_reservation_id;

    UPDATE dining_table
    SET status = 'occupied'
    WHERE table_id = p_table_id;

    RETURN p_reservation_id;
END;
$$;

-- Example call (queued party of 2 at branch 2 -> table 5):
-- SELECT fn_seat_reservation(3, 5, 3);
-- Example call (should FAIL: reservation 4 is already seated):
-- SELECT fn_seat_reservation(4, 5, 3);
-- Example call (should FAIL: table 6 is occupied):
-- SELECT fn_seat_reservation(3, 6, 3);
