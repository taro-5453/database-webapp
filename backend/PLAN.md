# Backend Plan — Flask API over the fn_* functions

The backend is deliberately thin: every business rule (tier
enforcement, capacity checks, promotion validation, checkout math)
already lives in the 24 SQL functions, and the app connects as the
EXECUTE-only `momo_app` role. So each endpoint is: parse request →
call one fn_* → shape the JSON. One phase = one working, testable
slice; later phases never rework earlier ones.

Stack: Flask + psycopg3 (with psycopg_pool). Runs locally first;
Render deployment is the last phase.

Carry-over gotchas (from DB work, already proven):
- momo_app's connection string needs `sslmode=require&channel_binding=disable`
  (Render's TLS proxy breaks SCRAM channel binding).
- Login fns return 0 rows on bad credentials (not errors) → HTTP 401.
- Business-rule failures arrive as plpgsql RAISE EXCEPTION → psycopg
  RaiseException → map to HTTP 400 with the message.

---

## Phase 0 — Skeleton + DB plumbing  ✅ DONE (tested against Render)
Goal: Flask runs and can reach Render as momo_app.
- `backend/` package: app factory, config from repo-root `.env`
  (add `MOMO_APP_URL=postgresql://momo_app:...@.../momo_paradise?sslmode=require&channel_binding=disable`)
- psycopg_pool connection pool as momo_app
- `call_fn(name, *args)` helper: parameterized `SELECT * FROM fn(...)`,
  returns list of dicts; translates RaiseException → `ApiError(400, msg)`
- error handler → consistent JSON `{"error": "..."}`
- `GET /api/health` → calls fn_get_branches, returns count
- Done when: `curl localhost:5000/api/health` shows the branch count.

## Phase 1 — Auth + sessions  ✅ DONE (tested against Render)
Goal: register/login works, later phases can protect routes.
- `POST /api/auth/register` → fn_register_customer
- `POST /api/auth/login` → fn_login_customer (0 rows → 401)
- `POST /api/auth/staff-login` → fn_login_staff (keeps role + branch_id)
- `POST /api/auth/logout`, `GET /api/auth/me`
- Flask signed session cookie holding {kind: customer|staff, id, branch_id?, role?}
  (simplest with a Next.js dev proxy; can swap to JWT later without
  touching the route bodies)
- `@customer_required` / `@staff_required` decorators
- Done when: register → login → /me round-trips via curl, wrong
  password gives 401.

## Phase 2 — Customer browse (read-only)  ✅ DONE (tested against Render)
Goal: everything a logged-in customer sees.
- `GET /api/branches` → fn_get_branches (public)
- `GET /api/branches/<id>/available-tables?party_size=N` → fn_get_available_tables (public)
- `GET /api/me/membership` → fn_get_membership
- `GET /api/me/points` → fn_get_point_history
- customer_id always comes from the session cookie, never the URL/body
- Done when: each endpoint returns sample data via curl.

## Phase 3 — Customer actions
Goal: the reserve → order → watch-the-bill flow.
- `POST /api/reservations` → fn_create_reservation (table/slot NULL = queue)
- `GET  /api/dining-sessions/<id>/menu` → fn_get_tier_menu
- `POST /api/dining-sessions/<id>/orders` → fn_place_order
- `GET  /api/dining-sessions/<id>/orders` → fn_get_session_orders
- `GET  /api/dining-sessions/<id>/bill` → fn_get_current_bill
- KNOWN GAP to decide here: the fns don't check the session belongs
  to the caller (any logged-in customer could pass another session_id).
  Options: (a) accept for course scope + note in report, (b) add a
  fn_session_owner(session_id) SQL function and check in the decorator.
- Done when: full happy path via curl against a seeded session, and
  a not-in-tier order returns the RAISE message as a 400.

## Phase 4 — Staff floor ops
Goal: the queue → seat → open session → dashboard loop.
- `GET  /api/staff/queue` → fn_get_queue (branch_id from staff cookie)
- `POST /api/staff/reservations/<id>/seat` → fn_seat_reservation
- `POST /api/staff/dining-sessions` → fn_open_session (walk-in or pre-seated)
- `GET  /api/staff/dining-sessions` → fn_get_active_sessions
- staff_id / branch_id from the cookie, never the request body
- Done when: seat a queued sample reservation and see it appear on
  the active-sessions dashboard, minutes_remaining included.

## Phase 5 — Staff kitchen, menu, promotions, checkout
Goal: the remaining staff CRUD, finishing the API surface.
- `GET   /api/staff/kitchen` → fn_get_kitchen_orders
- `PATCH /api/staff/orders/<id>` → fn_update_order_status
- `POST  /api/staff/menu-items` → fn_add_menu_item (tier_ids array)
- `PATCH /api/staff/menu-items/<id>/availability` → fn_update_item_availability
- `GET/POST /api/staff/promotions` → fn_get_promotions / fn_create_promotion
- `GET   /api/staff/promotions/validate?code=X` → fn_validate_promotion
- `POST  /api/staff/dining-sessions/<id>/checkout` → fn_checkout
- Done when: order lifecycle (ordered→preparing→served) and a full
  checkout with a promotion code work via curl.

## Phase 6 — Hardening + deploy
Goal: frontend-ready and live.
- CORS (flask-cors) for the frontend origin, cookies with credentials
- input validation pass (types/required fields → 422 before hitting the DB)
- `script/smoke_api.sh`: curl-based happy-path check in verify.sh style
- gunicorn + Render web service; env vars on Render (no .env in git)
- Done when: deployed URL passes smoke_api.sh from your laptop.

---
Suggested order of attack: 0+1 together (auth is the foundation),
then 2, 3, 4, 5 as separate sittings, 6 when the frontend starts.
