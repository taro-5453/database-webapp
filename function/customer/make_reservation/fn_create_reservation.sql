-- ============================================================
-- fn_create_reservation
-- Screen: Customer > Make a Reservation / Join Queue
-- Used by: the "confirm reservation" button.
-- Creates a reservation. If p_slot_time is NULL it is treated
-- as a walk-in queue entry (status 'queued'); otherwise it is a
-- timed booking (status 'reserved'). Returns the new id.
-- Tables are NOT assigned here — staff pick them at seating time
-- via fn_seat_reservation, which fills reservation_table (a party
-- may span several combined tables). The check below therefore
-- bounds party_size by the branch's total combinable capacity,
-- not by the largest single table.
-- p_tier_id is the customer's preferred buffet tier (NULL = decide
-- when seated); the dining session's tier, set at seating, stays
-- the authoritative one for billing.
-- ============================================================
-- Older signatures must go: the argument list changed, so
-- CREATE OR REPLACE would leave earlier overloads behind.
DROP FUNCTION IF EXISTS fn_create_reservation(INT, INT, INT, TIMESTAMP, INT);
DROP FUNCTION IF EXISTS fn_create_reservation(INT, INT, TIMESTAMP, INT);

CREATE OR REPLACE FUNCTION fn_create_reservation(
    p_customer_id INT,
    p_branch_id   INT,
    p_slot_time   TIMESTAMP,    -- NULL => queue
    p_party_size  INT,
    p_tier_id     INT           -- NULL => decide when seated
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_status         VARCHAR(20);
    v_branch_capacity INT;
    v_reservation_id INT;
BEGIN
    IF p_party_size <= 0 THEN
        RAISE EXCEPTION 'Party size must be positive';
    END IF;

    IF p_tier_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM buffet_tier bt
        WHERE bt.tier_id = p_tier_id AND bt.branch_id = p_branch_id
    ) THEN
        RAISE EXCEPTION 'Tier % does not belong to branch %', p_tier_id, p_branch_id;
    END IF;

    SELECT COALESCE(SUM(capacity), 0) INTO v_branch_capacity
    FROM dining_table
    WHERE branch_id = p_branch_id;

    IF v_branch_capacity < p_party_size THEN
        RAISE EXCEPTION 'This branch seats at most % guests even combining every table (party of %)',
                        v_branch_capacity, p_party_size;
    END IF;

    IF p_slot_time IS NULL THEN
        v_status := 'queued';
    ELSE
        v_status := 'reserved';
    END IF;

    INSERT INTO reservation (customer_id, branch_id, tier_id, slot_time, party_size, status)
    VALUES (p_customer_id, p_branch_id, p_tier_id, p_slot_time, p_party_size, v_status)
    RETURNING reservation_id INTO v_reservation_id;

    RETURN v_reservation_id;
END;
$$;

-- Example call (timed booking, Standard tier preferred):
-- SELECT fn_create_reservation(1, 1, '2026-07-15 18:00:00', 4, 1);
-- Example call (join queue, tier decided later):
-- SELECT fn_create_reservation(3, 2, NULL, 2, NULL);
-- Example call (should FAIL: party bigger than the whole branch):
-- SELECT fn_create_reservation(1, 1, '2026-07-15 18:00:00', 999, NULL);
-- Example call (should FAIL: tier belongs to another branch):
-- SELECT fn_create_reservation(1, 1, NULL, 2, 3);
-- Checking
-- SELECT * FROM reservation ORDER BY reservation_id DESC;
