# Momo Paradise – Database Project

A database system for a multi-branch all-you-can-eat shabu/sukiyaki
restaurant chain, supporting reservations, queues, buffet dining
sessions, ordering, billing, membership, and promotions.

Course: ICCS 225 Database Foundations — Term 2025-26 T3

## Team
- Chaiyanun Sakulsaowapakkul 6681299
- Sorawich Pimsen 6681297
- Nathanon Chirattithphan 6780756

## Tech Stack
- Database: PostgreSQL (hosted on Render)
- Tooling: DataGrip

## Repository Structure
```
database/                  schema, sample data, security
├── schema.sql             creates all 14 tables (keys, constraints, indexes) + pgcrypto
├── sample_data.sql        sample rows for every table
└── security.sql           EXECUTE-only momo_app role the web app connects as

function/                  SQL functions, grouped by screen
├── auth/                  fn_register_customer, fn_login_customer, fn_login_staff
├── customer/
│   ├── browse_branches/   fn_get_branches, fn_get_available_tables
│   ├── make_reservation/  fn_create_reservation
│   ├── ordering/          fn_get_tier_menu, fn_place_order, fn_get_session_orders
│   ├── membership/        fn_get_membership, fn_get_point_history
│   └── view_bill/         fn_get_current_bill
└── staff/
    ├── queue/             fn_get_queue, fn_seat_reservation
    ├── manage_sessions/   fn_open_session, fn_get_active_sessions
    ├── kitchen_view/      fn_get_kitchen_orders, fn_update_order_status
    ├── manage_menu/       fn_add_menu_item, fn_update_item_availability
    ├── manage_promotions/ fn_create_promotion, fn_get_promotions
    └── checkout/          fn_validate_promotion, fn_checkout

script/
├── deploy.sh              runs all SQL against a DB URL (see How to Run)
└── verify.sh              checks the deploy: grants, bcrypt, momo_app lockout

document/                  report and ER diagram
backend/                   Flask API (planned)
frontend/                  React Router / Next.js app (planned)
progress.md                running task list / project notes
```

## Database
- 14 tables, normalized, with foreign keys and CHECK constraints
- Security: passwords stored as bcrypt hashes (pgcrypto); the app
  connects as an EXECUTE-only role (`momo_app`) with no direct
  table access — everything goes through SECURITY DEFINER functions
- Efficiency: indexes on frequently queried columns

## How to Run
1. Create a PostgreSQL database (e.g. on Render).
2. First-time deploy (tables + sample data + functions + security):
   ```sh
   ./script/deploy.sh --schema --seed 'postgresql://user:pass@host.render.com/dbname'
   ```
3. After changing/adding functions, re-deploy just those:
   ```sh
   ./script/deploy.sh 'postgresql://user:pass@host.render.com/dbname'
   ```
   (needs `psql`; macOS: `brew install libpq && brew link --force libpq`)
4. Verify the deploy (grants, registration/login, and — with a
   password — that `momo_app` can call functions but not touch
   tables). Self-contained: creates its own test rows and deletes
   them afterwards, so it works with or without sample data:
   ```sh
   ./script/verify.sh 'postgresql://user:pass@host.render.com/dbname' 'new-momo-app-password'
   ```

Or manually in DataGrip, in this order: `database/schema.sql` →
`database/sample_data.sql` → every `function/**/*.sql` →
`database/security.sql` (re-run security.sql after adding any new
function, and change the `momo_app` placeholder password before
deploying).