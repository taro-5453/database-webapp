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
  - checkout: fn_checkout (creates BILL, applies promotion, earns points, closes session, frees table)
- Auth functions (written, still need testing on Render):
  - auth: fn_register_customer, fn_login_customer, fn_login_staff (bcrypt via pgcrypto)
  - schema.sql now enables pgcrypto; sample_data.sql passwords are all 'password123' (real bcrypt hashes)
- Session management functions (written, still need testing on Render):
  - manage_sessions: fn_open_session, fn_get_active_sessions

## Next / To Do
- Remaining functions (by screen):
  - customer: view_bill
  - staff: manage_sessions (open), manage_menu, manage_promotions
- Screenshots of customer screens
- Figma wireframes for staff screens
- Report (ER diagram, functions + example results, security & efficiency sections)
- Presentation slides
- (Bonus) web app

## Notes to self
- Functions are grouped by SCREEN, not by table (browse_branches = a screen, not a table)
- Read functions = safe to re-run; write functions (create_reservation) add a row each run
- Test rows I added manually (clean up later if needed): extra reservations, order_line id ~15
- Efficiency angle: indexes on reservation(branch_id, slot_time) + order_line(session_id, status)