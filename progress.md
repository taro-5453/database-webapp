# Project Notes / Progress

## Done
- ER diagram (Lucidchart)
- schema.sql — 14 tables, live on Render, in repo
- sample_data.sql — 10+ rows per table, loaded
- README.md
- Functions written + tested + filed:
  - browse_branches: fn_get_branches, fn_get_available_tables
  - make_reservation: fn_create_reservation
  - membership: fn_get_membership, fn_get_point_history
  - ordering: fn_get_tier_menu, fn_place_order, fn_get_session_orders
  - kitchen_view: fn_get_kitchen_orders
  - checkout: fn_checkout (creates BILL, applies promotion, earns points, closes session, frees table), fn_validate_promotion
  - view_bill: fn_get_current_bill (running total for an active session, pre-checkout)
- Auth functions (written, still need testing on Render):
  - auth: fn_register_customer, fn_login_customer, fn_login_staff (bcrypt via pgcrypto)
  - schema.sql now enables pgcrypto; sample_data.sql passwords are all 'password123' (real bcrypt hashes)
- Session management functions (written, still need testing on Render):
  - manage_sessions: fn_open_session, fn_get_active_sessions
- Staff CRUD functions (written, still need testing on Render):
  - kitchen_view: fn_update_order_status
  - manage_menu: fn_add_menu_item (can link tiers in same call), fn_update_item_availability
  - manage_promotions: fn_create_promotion, fn_get_promotions
  - queue: fn_get_queue, fn_seat_reservation
  - fn_open_session updated: now also accepts a reservation pre-seated by fn_seat_reservation
- Deployed + verified on Render (verify.sh: 16/16 PASS): pgcrypto installed via security.sql,
  24 fn_* granted, register/login work, momo_app lockout proven live
  - Render gotcha: TLS proxy breaks SCRAM channel binding -> clients need channel_binding=disable
    (verify.sh handles it; Flask's psycopg needs it too when connecting as momo_app)
  - .env (gitignored) holds DB_URL + MOMO_APP_PASSWORD; deploy.sh/verify.sh read it automatically
  - sample customers still have placeholder hashes (can't log in) — reset when needed:
    UPDATE customer SET password_hash = crypt('password123', gen_salt('bf')); (same for staff)
- database/security.sql (run on Render, verified):
  - momo_app role: LOGIN, EXECUTE-only, no table access; app/Flask connects as this
  - all fn_* become SECURITY DEFINER + pinned search_path (done via loop, re-run after adding functions)
  - revokes PUBLIC's default EXECUTE on functions + CREATE on schema public
  - report material: security section = bcrypt + least-privilege role + injection blast radius

- verify.sh — post-deploy checks with PASS/FAIL output, self-contained (no sample_data dependency):
  - creates 'ZZ Verify ...' fixture rows (branch/staff/item + customer via fn_register_customer),
    deletes them at the end (trap-based cleanup + pre-clean of leftovers from aborted runs)
  - admin: 24 grants present, register/login accept+reject; warns if old rows have placeholder hashes
  - with momo_app password arg: sets it (SCRAM, kills the MD5 warning), connects AS momo_app,
    proves tables are denied but functions work (write test toggles only the fixture item)
- deploy.sh — one-command deploy to Render:
  - ./script/deploy.sh --schema --seed "$DB_URL" for a fresh DB; ./script/deploy.sh "$DB_URL" to update functions + security
  - example calls in all function files are now COMMENTED OUT (they used to be live SQL,
    which would run/fail when executing whole files) — select + run them manually in DataGrip

## Next / To Do
- Update add SQL functions to Render (can now use ./script/deploy.sh)
- Remaining functions (by screen):
  -
- Screenshots of customer screens
- Report (ER diagram, functions + example results, security & efficiency sections)
- Presentation slides
- Backend - Flask (phased plan in backend/PLAN.md; do phase by phase)
  - Phases 0+1 DONE, tested live: health + register/login/staff-login/logout/me,
    cookie sessions, fn RAISE -> 400 JSON, empty login -> 401
  - .env gained MOMO_APP_URL + FLASK_SECRET_KEY (values now single-quoted: the URL's
    & broke `source .env` in the shell scripts until quoted)
  - run dev server: backend/.venv/bin/python backend/wsgi.py (port 5001)
  - Phase 2 DONE, tested live: GET /api/branches, /api/branches/<id>/available-tables?party_size=,
    /api/me/membership, /api/me/points (cookie-guarded); custom JSON provider (Decimal->float,
    timestamps->ISO) added ahead of Phase 3
  - Phase 3 DONE, tested live: POST /api/reservations (queue or timed), dining-session
    menu/orders/bill; new fn_get_session_owner (fn #25, verify.sh expects 25 now) gives
    403 on other customers' sessions, 404 on missing; DataError/IntegrityError -> 400
  - Phase 4 DONE, tested live: staff queue/seat/open-session (walk-in AND pre-seated
    paths)/dashboard; branch+staff ids from cookie only; wrong-branch tier + occupied
    table + re-seat all rejected as 400s; int_field moved to app/util.py
  - Phase 5 DONE, tested live: kitchen view + order status lifecycle, menu add/availability,
    promotions create/list/validate, checkout with percent promo (bill math verified:
    798+88-132.90=753.10, 7 points earned, table freed, double-checkout rejected)
  - Phase 6 code DONE: CORS (FRONTEND_ORIGIN env, credentials), JSON 404/405/500,
    gunicorn verified, script/smoke_api.sh (14/14 locally; works against any URL)
  - LAST STEP (manual): create Render Web Service — exact settings in backend/PLAN.md
    Phase 6, then run ./script/smoke_api.sh https://<service>.onrender.com
  - note for report: fn_update_order_status / fn_update_item_availability trust staff on ids
    (no branch check on the id itself) — staff are semi-trusted internal users, UI only shows
    own-branch ids; customers CAN'T call these at all
- Frontend - React Router (friends' task): frontend/PLAN.md has the phased plan +
  full endpoint reference; dirs scaffolded; key rule: fetch with credentials:'include'
  - added fn_get_tiers (fn #26) + GET /api/staff/tiers for the open-session tier picker
    (friend flagged the missing endpoint); deployed, tested live, verify.sh now expects 26
  - docker-compose.yml (repo root, committed): backend + frontend + nginx proxy on :8080;
    proxy routes /api->backend, else->frontend (same-origin cookies, no CORS). frontend is
    SSR (react-router-serve :3000, uses friend's existing frontend/Dockerfile untouched).
    Tested: register->me cookie flow works through proxy. Needs root .env (MOMO_APP_URL+secret).
    nginx config baked into docker/Dockerfile (bind-mount hit Docker Desktop file-sharing block).
  - fn_get_queue now also returns customer_id (found while building the Phase 4 seat
    dialog: fn_open_session needs it explicitly and doesn't derive it from the
    reservation). Column change required DROP FUNCTION first (Postgres can't
    CREATE OR REPLACE across an OUT-param shape change) — the DROP is now baked into
    fn_get_queue.sql itself so future re-deploys stay one command. Deployed + verified
    live (queue row now includes customer_id). No psql on this machine, so deploy.sh
    itself didn't run this time — used a one-off Python/psycopg script instead, same
    file order/behavior; if you deploy from a machine with psql, script/deploy.sh
    still works unchanged.


## Notes to self
- Functions are grouped by SCREEN, not by table (browse_branches = a screen, not a table)
- Read functions = safe to re-run; write functions (create_reservation) add a row each run
- Test rows I added manually (clean up later if needed): extra reservations, order_line id ~15
- Efficiency angle: indexes on reservation(branch_id, slot_time) + order_line(session_id, status)

## Frontend — Session Handoff (2026-07-10, Claude Code)

Working with ongleevs (did the database design) on the React frontend.
Teammate (backend/Nathanon or Sorawich — check README team list) built the
whole Flask API already; frontend/PLAN.md has the phased plan we're
following. Progress below so a fresh session can pick up with zero
re-discovery.

**Phases 0-3 DONE, pushed, and verified two ways: direct API calls
(PowerShell/curl through the Vite proxy) AND manually by ongleevs
clicking through the real browser UI.**
- `f670ebf` Phase 0: scaffold (create-react-router) + Vite dev proxy
  (`/api/*` -> `localhost:5001`, see `frontend/vite.config.ts`)
- `4ee234d` Phase 1: `app/lib/api.ts` (fetch wrapper, typed `ApiError`),
  `app/lib/auth.tsx` (AuthProvider: user/login/register/staffLogin/logout),
  `app/lib/guards.tsx` (RequireCustomer/RequireStaff), /login /register
  /staff/login pages
- `18ee583` Phase 2: home = branch list, /branches/:id = table availability,
  /profile (guarded) = membership + points
- `f3472fa` Phase 3: /reserve (queue-or-slot form), /session/:id (menu +
  my-orders + running bill, polls orders/bill every 10s)
- `0c7881d` **Important fix**: Tailwind's Preflight had stripped all
  default input/button/select styling, making /register look completely
  broken (invisible borders, no button chrome) even though the logic
  worked — root-caused by tracing the actual code path, not guessing.
  Fixed with a global `@layer base` in `app/app.css` (not full Phase 6
  polish, just enough to make forms usable). Confirmed fixed by ongleevs
  in-browser: registered an account ("onglee"), wrong-password error
  displays correctly, availability check works.

**Dev environment (restart after any reboot/session change):**
- Backend: `cd backend && .venv/Scripts/python.exe wsgi.py` → port 5001
  (venv already created + deps installed, don't recreate)
- Frontend: `cd frontend && npm run dev` → port 5173 (proxies /api/* to
  5001; always browse via 5173, never hit 5001 directly)
- Repo-root `.env` exists locally (gitignored, NOT committed) with
  DB_URL/MOMO_APP_PASSWORD/MOMO_APP_URL/FLASK_SECRET_KEY/FRONTEND_ORIGIN —
  ongleevs pasted these in chat once; treat as already-known, don't ask
  again, just confirm the file still exists before assuming servers can start.

**BLOCKED note above is RESOLVED (2026-07-10, later same day):** Nathanon
added `fn_get_tiers` + `GET /api/staff/tiers` himself (commit `10850fd`,
before this handoff was even read back) — option 1 from the list below,
deployed and tested live. Kept the paragraph for the reasoning trail.

**Phase 4 DONE, pushed, and verified live in a real headless-Chromium
browser session (Playwright), not just curl:** `/staff` dashboard,
`/staff/queue` (seat dialog -> open-session dialog), `/staff/kitchen`.
Also added staff nav links (Dashboard/Queue/Kitchen) to `Header.tsx`.
- Hit a second real gap while building the seat dialog: `fn_get_queue`
  never returned `customer_id` (only name/phone), but `fn_open_session`
  requires `customer_id` explicitly and does NOT derive it from the
  reservation. Fixed by adding `customer_id` to `fn_get_queue`'s
  `RETURNS TABLE` (`function/staff/queue/fn_get_queue.sql`) — needed a
  `DROP FUNCTION` first since Postgres can't `CREATE OR REPLACE` across
  an OUT-param shape change; that DROP is now baked into the file so
  future re-deploys stay one command. Deployed + verified live (queue
  row now includes customer_id) and confirmed end-to-end in-browser:
  seated a real queued reservation onto an available table, opened its
  buffet session, watched it disappear from the queue and appear
  correctly on the dashboard.
- No `psql` on this machine, so `script/deploy.sh` itself didn't run
  this round — used a one-off Python/psycopg script instead (same file
  order/behavior as deploy.sh). `script/deploy.sh` is untouched and
  still works normally from a machine that has `psql`.
- Kitchen view's status-advance button verified interactively too
  (clicked "Mark served", order line correctly dropped off the
  unserved list).
- Test data note: branch 1's dining tables were all occupied by
  leftover test sessions from earlier phases before this session, which
  blocked testing the seat flow (no available tables). Freed table 1 via
  a normal checkout call (session 18, the exact pattern fn_checkout is
  built for) rather than touching data directly — branch 1 still has 3
  other stale test sessions occupying tables (2, 4, 18) from prior
  phases; worth a cleanup pass before a demo, not urgent otherwise.

**Phase 5 DONE, pushed, verified live in-browser (Playwright):**
`/staff/menu` (item list + availability toggle + add-item form with
tier checkboxes), `/staff/promotions` (list, greyed-out expired codes +
create form), and a checkout dialog on the dashboard (promotion code
with live validate, payment method, confirm -> shows bill_id + applied
discount). Menu/Promotions links added to Header nav.
- Third gap hit, same pattern as the last two: no function/endpoint
  listed a branch's full menu inventory. `fn_get_tier_menu` is
  session+tier-scoped and filters to available=TRUE only, so it
  couldn't serve the manage-menu screen (which needs to see unavailable
  items too, to restore them). Added `fn_get_menu_items(branch_id)`
  (brand-new function, no DROP needed this time) +
  `GET /api/staff/menu-items`. Deployed same way as the fn_get_queue
  fix (one-off Python/psycopg script, no psql on this machine).
- Verified end-to-end in-browser: added a test dish, toggled it
  unavailable, created a promotion code, validated it live at checkout,
  and checked out an actual overtime session (table 4, session 19) with
  the 10% discount applied — confirmed both in the UI (bill_id + discount
  shown) and by re-querying the API that the session left the active
  list and the table freed. This incidentally cleaned up one of the 3
  stale test sessions noted after Phase 4 (table 4 now free; tables 2
  and 18 still have leftover test sessions).
- "Show final bill" in the plan is a slight scope note: the checkout
  endpoint only returns `bill_id`, there's no staff-facing "fetch a
  finished bill" endpoint, so the dialog shows bill_id + the discount
  that was applied rather than a full itemized breakdown. Would need a
  new backend endpoint to do more — not built, not blocking.
- Left behind as harmless test data (same category as the sample promo
  codes already in the DB): menu item "Phase5 Test Dish" (branch 1,
  marked unavailable) and promotion code `PHASE5TEST10` (10% off, never
  expires).

**Also fixed (same session, before moving to Phase 6):** both
scrutinize findings from the Phase 4/5 review — checkout no longer
trusts a stale promotion validation after the code field is edited
(cleared on every keystroke), and the queue's "skip for now" copy no
longer promises a resume path that doesn't exist. Both pure frontend,
browser-verified, no backend/DB involved.

**Phase 6 DONE (polish + demo path), deploy explicitly skipped by
decision — see frontend/PLAN.md Phase 6 for the full writeup:**
- `<Header />` added to the 7 routes that were missing it (most of the
  app had no nav bar since only home.tsx got it in Jay's redesign).
- Real mobile bug fixed in Header.tsx: the wordmark could wrap
  mid-word and nav had no flex-wrap at narrow widths — both fixed,
  verified in a real 375px-wide headless browser (no more horizontal
  overflow anywhere, checked home/login/register/reserve/branch-detail/
  profile).
- Decided with ongleevs to skip public deploy for the presentation —
  Render free-tier cold-starts are a real live-demo risk. Demoing via
  `docker-compose.yml` instead (already existed, built by Nathanon).
  Verified end-to-end through the proxy at `localhost:8080`: register
  -> profile (session cookie works same-origin), staff login ->
  dashboard. If the course rubric turns out to require a public URL,
  revisit — Taro would need to create the backend Render service first.
- Loading/empty/error states were already in decent shape across the
  app before this phase (checked every customer route) — no changes
  needed there beyond the Header gap above.

**Next: nothing blocking — frontend is feature-complete through Phase
6. Remaining work is report/slides material (see top of this file) and
whatever the professor's rubric asks for beyond the app itself.**

**Also added this session:** `.claude/skills/scrutinize/SKILL.md` — a
project skill ongleevs described from another repo (outsider-perspective
review: question intent, trace the actual code path not just the diff,
concise findings with rationale). Reconstructed from the description he
pasted in chat since we didn't have the original file's full body —
worth double-checking it still reads right the first time someone
actually runs `/scrutinize`. NOTE: `.gitignore` excludes all of
`.claude/` (teammate's existing choice, likely to avoid committing
personal local settings) — we deliberately left that as-is rather than
carving out an exception, so this skill file is **local to this machine
only**, not pushed/shared. It'll still be here tomorrow on this laptop,
but won't show up if ongleevs' teammate clones fresh or he switches
machines. If the skill turns out useful, revisit whether to add
`!.claude/skills/` to .gitignore so it's shared (ask first, it's a
shared config file).