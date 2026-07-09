# Frontend Plan — React Router over the Flask API

Self-contained guide for the frontend team. The backend is DONE and
tested (see `backend/PLAN.md`): a Flask JSON API where every business
rule already lives in the database, so the frontend is purely screens
+ fetch calls. Work phase by phase; each phase is a usable slice.

## How the API works (read this first)

- Base URL: `http://localhost:5001` in dev (start it with
  `backend/.venv/bin/python backend/wsgi.py` from the repo root).
- Auth is a **session cookie**, not a token. Every fetch MUST send
  `credentials: 'include'` or nothing auth-related will work.
- Two kinds of logins: customer (register/login) and staff
  (staff-login). A browser session is one or the other at a time.
- Errors are always `{"error": "human-readable message"}` with
  status 400 (bad input / business rule), 401 (not logged in),
  403 (not yours), 404, 503 (db down). Show `error` to the user —
  the messages are written for humans ("Table 5 is not available
  (status: occupied)").
- Money comes as JSON numbers, timestamps as ISO 8601 strings.
- Dev credentials: register any customer you like; staff logins are
  name + `password123` (e.g. `Somchai Jaidee` manager branch 1,
  `Anan Wattana` manager branch 2 — see database/sample_data.sql).

### Endpoint reference

Auth
- `POST /api/auth/register`      {name, email, phone?, password(≥8)} → 201 {customer_id}, logs you in
- `POST /api/auth/login`         {email, password} → customer row; 401 on bad creds
- `POST /api/auth/staff-login`   {name, password} → {staff_id, branch_id, name, role}
- `POST /api/auth/logout`
- `GET  /api/auth/me`            → session content, 401 if not logged in

Customer (public)
- `GET /api/branches`
- `GET /api/branches/<id>/available-tables?party_size=N`

Customer (logged in)
- `GET  /api/me/membership`      → {points, tier, ...}
- `GET  /api/me/points`          → point transactions
- `POST /api/reservations`       {branch_id, party_size} = join queue;
                                 + slot_time (ISO), table_id? = timed booking → 201
- `GET  /api/dining-sessions/<id>/menu`     (403 if not your session)
- `POST /api/dining-sessions/<id>/orders`   {item_id, quantity} → 201
- `GET  /api/dining-sessions/<id>/orders`
- `GET  /api/dining-sessions/<id>/bill`     → {buffet_total, extra_charges, running_total, ...}

Staff (staff login; branch is implied by the logged-in staff)
- `GET   /api/staff/queue`                          waiting parties
- `POST  /api/staff/reservations/<id>/seat`         {table_id}
- `POST  /api/staff/dining-sessions`                {table_id, customer_id, tier_id,
                                                    guest_count, reservation_id?} → 201
- `GET   /api/staff/dining-sessions`                dashboard, minutes_remaining
                                                    (negative = overtime)
- `GET   /api/staff/kitchen`                        unserved order lines
- `PATCH /api/staff/orders/<id>`                    {status: ordered|preparing|served}
- `POST  /api/staff/menu-items`                     {name, category?, price, tier_ids?} → 201
- `PATCH /api/staff/menu-items/<id>/availability`   {available: bool}
- `GET   /api/staff/promotions`
- `POST  /api/staff/promotions`                     {code, discount, discount_type:
                                                    percent|fixed, valid_until?} → 201
- `GET   /api/staff/promotions/validate?code=X`     → {is_valid, ...}
- `POST  /api/staff/dining-sessions/<id>/checkout`  {promotion_code?, payment_method?}
                                                    → 201 {bill_id}

---

## Phase 0 — Scaffold
- `npx create-react-router@latest` INTO this frontend/ directory
  (the app/routes, app/components, app/lib, public dirs here match
  its layout; let the generator overwrite/merge)
- Add a Vite dev proxy so `/api/*` forwards to `http://localhost:5001`
  — then fetches are same-origin in dev and the session cookie just
  works, no CORS setup needed
- Done when: the starter page renders and
  `fetch('/api/health')` from the browser console returns branches.

## Phase 1 — API client + auth
- `app/lib/api.ts`: one fetch wrapper — JSON in/out,
  `credentials: 'include'`, throws {status, error} on non-2xx
- Auth context: call `/api/auth/me` on load; expose
  {user, login, register, staffLogin, logout}
- Routes: /login, /register, /staff/login; guard components that
  redirect by session kind (customer vs staff)
- Done when: register → land logged in → refresh keeps you logged
  in → logout works; wrong password shows the API's message.

## Phase 2 — Customer browse screens
- / — branch list (GET /api/branches)
- /branches/:id — available tables (party-size picker)
- /profile — membership tier + points + point history
- Done when: all three render live data.

## Phase 3 — Customer reserve + dine screens
- /reserve — form: branch, party size, "join queue now" vs
  "book a time slot" (slot_time as ISO string)
- /session/:id — THE main customer screen, three panels:
  menu (add-to-order buttons), my orders (with statuses), running
  bill; poll orders+bill every ~10s so kitchen updates show up
- Surface 400s inline (e.g. ordering an item not in your tier)
- Done when: a seated customer can order and watch the bill grow.

## Phase 4 — Staff floor screens
- /staff — dashboard of active sessions; highlight negative
  minutes_remaining (overtime) in red; poll ~30s
- /staff/queue — waiting list; "seat" button opens dialog:
  pick table → seat → optional "open session" (tier, guest count)
- /staff/kitchen — unserved lines, oldest first; one-tap
  status advance (ordered → preparing → served); poll ~10s
- Done when: queue→seat→open→order→kitchen→served round-trips
  between a customer tab and a staff tab.

## Phase 5 — Staff manage + checkout screens
- /staff/menu — item list, availability toggles, add-item form
  (tier checkboxes)
- /staff/promotions — list (grey out is_valid=false), create form
- Checkout dialog on the dashboard: promotion code field with
  live validate call, payment method, confirm → show final bill
- Done when: full lifecycle incl. discounted checkout works from
  the UI.

## Phase 6 — Polish + deploy
- Loading/empty/error states everywhere; mobile layout for the
  customer screens (staff screens can stay desktop)
- Deploy the built app (Render static site or Vercel)
- Point it at the deployed API: set the API base URL for prod, and
  on the BACKEND service set FRONTEND_ORIGIN=<deployed frontend URL>
  and COOKIE_CROSS_SITE=1 (different-domain cookies need it)
- Done when: the deployed frontend logs in against the deployed
  backend.

---
Tips
- Test data lives in database/sample_data.sql (10 branches; menu
  items exist only for branch 1; tiers 1-2 are branch 1's).
- Sample staff all have password `password123`.
- Sample customers can't log in unless their placeholder hashes were
  reset — just register fresh customers instead.
- The backend rejects everything invalid with a clear message, so
  when in doubt: send it and render `error`.
