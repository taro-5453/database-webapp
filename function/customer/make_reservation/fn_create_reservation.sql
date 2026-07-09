-- ============================================================
-- fn_create_reservation
-- Screen: Customer > Make a Reservation / Join Queue
-- Used by: the "confirm reservation" button.
-- Creates a reservation. If p_slot_time is NULL it is treated
-- as a walk-in queue entry (status 'queued'); otherwise it is a
-- timed booking (status 'reserved'). Returns the new id.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_create_reservation(
    p_customer_id INT,
    p_branch_id   INT,
    p_table_id    INT,          -- may be NULL for queue entries
    p_slot_time   TIMESTAMP,    -- NULL => queue
    p_party_size  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_status         VARCHAR(20);
    v_reservation_id INT;
BEGIN
    IF p_party_size <= 0 THEN
        RAISE EXCEPTION 'Party size must be positive';
    END IF;

    IF p_slot_time IS NULL THEN
        v_status := 'queued';
    ELSE
        v_status := 'reserved';
    END IF;

    INSERT INTO reservation (customer_id, branch_id, table_id, slot_time, party_size, status)
    VALUES (p_customer_id, p_branch_id, p_table_id, p_slot_time, p_party_size, v_status)
    RETURNING reservation_id INTO v_reservation_id;

    RETURN v_reservation_id;
END;
$$;

-- Example call (timed booking):
-- SELECT fn_create_reservation(1, 1, 2, '2026-07-15 18:00:00', 4);
-- Example call (join queue):
-- SELECT fn_create_reservation(3, 2, NULL, NULL, 2);
-- Checking
-- SELECT * FROM reservation ORDER BY reservation_id DESC;
