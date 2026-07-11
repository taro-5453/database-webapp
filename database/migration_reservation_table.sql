-- ============================================================
-- Migration: reservation <-> dining_table becomes many-to-many
-- (2026-07-11, after the demo: a party of 12 could be reserved
--  even though no single table seats 12 — reservation.table_id
--  forced an optional 1-to-1 that can't model combined tables.)
--
-- Run this ONCE on the already-deployed database. Fresh installs
-- don't need it: schema.sql already creates the new shape.
-- After running, re-apply the changed functions
--   function/customer/make_reservation/fn_create_reservation.sql
--   function/staff/queue/fn_seat_reservation.sql
--   function/staff/manage_sessions/fn_open_session.sql
--   function/staff/checkout/fn_checkout.sql
-- and re-run database/security.sql to re-grant EXECUTE.
-- ============================================================

BEGIN;

CREATE TABLE reservation_table (
    reservation_id INT NOT NULL REFERENCES reservation(reservation_id),
    table_id       INT NOT NULL REFERENCES dining_table(table_id),
    PRIMARY KEY (reservation_id, table_id)
);

-- carry over the tables that were already assigned the old way
INSERT INTO reservation_table (reservation_id, table_id)
SELECT reservation_id, table_id
FROM reservation
WHERE table_id IS NOT NULL;

ALTER TABLE reservation DROP COLUMN table_id;

-- the old signatures die with the column; the new ones differ in
-- argument types, so CREATE OR REPLACE alone would leave these behind
DROP FUNCTION IF EXISTS fn_create_reservation(INT, INT, INT, TIMESTAMP, INT);
DROP FUNCTION IF EXISTS fn_seat_reservation(INT, INT, INT);

COMMIT;
