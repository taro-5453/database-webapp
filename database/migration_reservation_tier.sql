-- ============================================================
-- Migration: customers pick a preferred buffet tier at booking
-- (2026-07-12, prof feedback #3: the reservation page showed the
--  tiers but the customer couldn't choose one.)
--
-- Run this ONCE on the already-deployed database, AFTER
-- migration_reservation_table.sql. Fresh installs don't need it:
-- schema.sql already creates the new shape.
-- After running, re-apply the changed functions
--   function/customer/make_reservation/fn_create_reservation.sql
--   function/staff/queue/fn_get_queue.sql
-- and re-run database/security.sql to re-grant EXECUTE.
-- ============================================================

BEGIN;

-- nullable: "decide when seated" stays allowed; the dining session's
-- tier (chosen at seating) remains the authoritative one for billing
ALTER TABLE reservation ADD COLUMN tier_id INT REFERENCES buffet_tier(tier_id);

-- the signature grows a tier parameter, so the tier-less version
-- must go or CREATE OR REPLACE would leave two overloads behind
DROP FUNCTION IF EXISTS fn_create_reservation(INT, INT, TIMESTAMP, INT);

COMMIT;
