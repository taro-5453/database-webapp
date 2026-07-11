-- ============================================================
-- Momo Paradise - Security (least-privilege app role)
-- Run AFTER schema.sql and every function/ file. Safe to re-run;
-- re-run it whenever a new fn_* function is added so the new
-- function gets picked up.
--
-- Idea: the web app never touches tables. It connects as
-- momo_app, a role whose ONLY privilege is EXECUTE on the fn_*
-- functions. Every function is made SECURITY DEFINER, so it runs
-- with the function OWNER's rights (the deploy user) while the
-- caller itself has no table access at all. Result:
--   - momo_app cannot SELECT customer/staff (no reading
--     password_hash, emails, phones straight off the tables)
--   - momo_app cannot UPDATE/DELETE anything directly; all writes
--     go through the functions and their validation (tier rules,
--     capacity checks, status checks)
--   - a SQL injection in the app is limited to calling the same
--     fn_* functions the app could already call
-- Each function also gets a pinned search_path, the standard
-- hardening for SECURITY DEFINER (stops a malicious schema from
-- shadowing table/function names the definer runs as owner).
-- ============================================================

-- ---------- 0. Extensions ----------
-- pgcrypto (bcrypt) is also in schema.sql, but a database created
-- before that line was added never got it — and this file runs on
-- every deploy, so ensure it here too. Idempotent.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------- 1. The app role ----------
-- LOGIN role the Flask backend connects as.
-- CHANGE THE PASSWORD before deploying, e.g.:
--   ALTER ROLE momo_app PASSWORD 'the-real-secret';
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'momo_app') THEN
        CREATE ROLE momo_app LOGIN PASSWORD 'change-me-before-deploy';
    END IF;
END;
$$;

-- ---------- 2. Lock the schema down ----------
-- The database name differs per environment (Render generates it),
-- so grant CONNECT dynamically.
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO momo_app', current_database());
END;
$$;

-- momo_app may resolve names in public, but not create objects there.
GRANT USAGE ON SCHEMA public TO momo_app;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- No direct table/sequence access for the app role (or anyone via
-- PUBLIC). This is what makes it EXECUTE-only.
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM momo_app, PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM momo_app, PUBLIC;

-- By default ANY role may execute ANY new function (PUBLIC gets
-- EXECUTE implicitly). Revoke that for future functions here; the
-- existing fn_* ones are revoked one by one in the loop below.
-- (Not "ON ALL FUNCTIONS IN SCHEMA public": on hosted Postgres the
-- pgcrypto helpers are owned by the postgres superuser, so that
-- form spams "no privileges could be revoked" warnings for
-- functions we cannot — and don't need to — touch.)
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- ---------- 3. SECURITY DEFINER + EXECUTE grants ----------
-- Loop over every fn_* function in public so signatures never go
-- stale: each one becomes SECURITY DEFINER with a pinned
-- search_path, loses PUBLIC's implicit EXECUTE, and momo_app gets
-- EXECUTE on it.
DO $$
DECLARE
    fn RECORD;
BEGIN
    FOR fn IN
        SELECT p.oid::regprocedure AS signature
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname LIKE 'fn\_%'
    LOOP
        EXECUTE format(
            'ALTER FUNCTION %s SECURITY DEFINER SET search_path = public, pg_temp',
            fn.signature);
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', fn.signature);
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO momo_app', fn.signature);
    END LOOP;
END;
$$;

-- Covered functions (28), by screen:
--   auth:              fn_register_customer, fn_login_customer, fn_login_staff,
--                      fn_get_session_owner (backend authorization helper)
--   browse_branches:   fn_get_branches, fn_get_available_tables
--   make_reservation:  fn_create_reservation
--   ordering:          fn_get_tier_menu, fn_place_order, fn_get_session_orders
--   membership:        fn_get_membership, fn_get_point_history
--   view_bill:         fn_get_current_bill
--   kitchen_view:      fn_get_kitchen_orders, fn_update_order_status
--   manage_sessions:   fn_open_session, fn_get_active_sessions, fn_get_tiers
--   queue:             fn_get_queue, fn_seat_reservation
--   manage_menu:       fn_add_menu_item, fn_update_item_availability, fn_get_menu_items
--   manage_promotions: fn_create_promotion, fn_get_promotions
--   checkout:          fn_validate_promotion, fn_checkout, fn_get_bill

-- ---------- 4. Verify ----------
-- What momo_app is allowed to execute (expect the 28 fn_* rows).
-- Filtered to fn_* because on hosted Postgres (Render) the pgcrypto
-- helper functions are owned by the postgres superuser, so our
-- REVOKE cannot strip PUBLIC's EXECUTE on them — harmless: they are
-- pure computation (crypt, armor, ...) with no table access.
SELECT p.oid::regprocedure AS callable_by_momo_app
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname LIKE 'fn\_%'
  AND has_function_privilege('momo_app', p.oid, 'EXECUTE')
ORDER BY 1;

-- Manual spot-check (run as the deploy user):
--   SET ROLE momo_app;
--   SELECT * FROM customer;                                  -- FAILS: permission denied
--   SELECT * FROM fn_login_customer('nattapong@example.com',
--                                   'password123');          -- works (via function)
--   RESET ROLE;
