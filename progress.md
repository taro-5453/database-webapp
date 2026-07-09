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

**BLOCKED — decision needed before Phase 4 can be built properly:**
No backend endpoint lists buffet tiers (id/name/price/duration_minutes).
`fn_open_session` (called by `POST /api/staff/dining-sessions`) requires
a `tier_id`, but nothing in `backend/app/*.py` or the SQL functions
returns the tier list for a branch — checked thoroughly, it's a real
gap, not something we missed. This blocks the staff "seat -> open
session" dialog's tier picker. Options discussed with ongleevs, NOT yet
decided when this session ended:
  1. Ask the backend teammate to add `GET /api/branches/:id/tiers` (or
     similar) backed by a new simple SQL function — cleanest, but blocks
     until he does it (he's the one testing the backend, mentioned he
     might add more endpoints).
  2. Build the missing SQL function + Flask endpoint ourselves, following
     the exact same read-only pattern as fn_get_branches — low risk,
     unblocks immediately, but should still get backend teammate's review
     since backend is his area.
  3. Stub it: raw numeric tier_id input field for now, swap for a proper
     dropdown once the endpoint exists — keeps moving, worse UX
     temporarily.
**Next step on resume: ask ongleevs which option, then continue Phase 4**
(/staff queue+seat+open dialog, /staff dashboard with overtime
highlighting, /staff/kitchen with status-advance buttons — see
frontend/PLAN.md Phase 4 for full spec).

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