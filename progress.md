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
  - next: Phase 2 (customer browse endpoints)
- Frontend - React router or Next.js


## Notes to self
- Functions are grouped by SCREEN, not by table (browse_branches = a screen, not a table)
- Read functions = safe to re-run; write functions (create_reservation) add a row each run
- Test rows I added manually (clean up later if needed): extra reservations, order_line id ~15
- Efficiency angle: indexes on reservation(branch_id, slot_time) + order_line(session_id, status)