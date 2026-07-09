#!/usr/bin/env bash
# ============================================================
# Momo Paradise - verify deployment + security lockdown
#
# Usage:
#   ./script/verify.sh 'postgresql://admin:pass@host.render.com/dbname' [momo_app_password]
#
# Self-contained: does NOT depend on sample_data.sql. It creates
# its own fixture rows first ('ZZ Verify ...' branch/staff/item and
# a customer registered through fn_register_customer), runs every
# check against those, and deletes them at the end (cleanup also
# runs on crash via trap, and pre-cleans leftovers from a previous
# aborted run).
#
# As admin it checks that all 25 fn_* functions are granted to
# momo_app, that registration + both logins accept/reject
# correctly, and warns if any NON-fixture rows still carry
# placeholder (non-bcrypt) password hashes.
#
# If momo_app_password is given, it also (re)sets that password
# using SCRAM (this silences the MD5 deprecation warning), then
# reconnects AS momo_app and checks the lockout: direct table
# SELECT/UPDATE must be DENIED while reads and writes through the
# fn_* functions still work. Use a URL-safe password (letters,
# digits, - and _), since it is spliced into a connection URL.
#
# Exits 0 if every check passed, 1 otherwise.
# ============================================================
set -uo pipefail

cd "$(dirname "$0")/.."

# .env (gitignored) can hold DB_URL + MOMO_APP_PASSWORD so neither
# ever appears on the command line
[[ -f .env ]] && source .env

ADMIN_URL="${1:-${DB_URL:-}}"
APP_PASS="${2:-${MOMO_APP_PASSWORD:-}}"

if [[ -z "$ADMIN_URL" ]]; then
  echo "usage: ./script/verify.sh DB_URL [momo_app_password]   (or export DB_URL)" >&2
  exit 1
fi
if ! command -v psql >/dev/null 2>&1; then
  echo "error: psql not found (macOS: brew install libpq && brew link --force libpq)" >&2
  exit 1
fi

PASS=0; FAIL=0
ok()   { echo "  PASS  $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL  $1${2:+ — $2}"; FAIL=$((FAIL+1)); }
note() { echo "  ....  $1"; }

# run a query, print result or the error text (callers match on it);
# -q keeps command tags like "INSERT 0 1" out of captured ids
sql() { psql "$1" -qtA -v ON_ERROR_STOP=1 -c "$2" 2>&1; }

is_id() { [[ "$1" =~ ^[0-9]+$ ]]; }

# ---------- fixture ----------
FIX_EMAIL='zz_verify@example.com'
FIX_PASS='verify-pass-123'

cleanup_sql="
  DELETE FROM membership WHERE customer_id IN
    (SELECT customer_id FROM customer WHERE email = '$FIX_EMAIL');
  DELETE FROM customer  WHERE email = '$FIX_EMAIL';
  DELETE FROM menu_item WHERE name = 'ZZ Verify Item';
  DELETE FROM staff     WHERE name = 'ZZ Verify Staff';
  DELETE FROM branch    WHERE name = 'ZZ Verify Branch';"

FIXTURE=0
cleanup() {
  if [[ $FIXTURE -eq 1 ]]; then
    sql "$ADMIN_URL" "$cleanup_sql" >/dev/null
    FIXTURE=0
  fi
}
trap cleanup EXIT

echo "== as admin =="

if [[ "$(sql "$ADMIN_URL" 'SELECT 1')" != "1" ]]; then
  bad "cannot connect with the admin URL"
  echo; echo "$PASS passed, $FAIL failed"; exit 1
fi
ok "connected as admin"

ext=$(sql "$ADMIN_URL" "SELECT count(*) FROM pg_extension WHERE extname = 'pgcrypto'")
[[ "$ext" == "1" ]] \
  && ok "pgcrypto extension installed (bcrypt available)" \
  || bad "pgcrypto extension missing" "rerun ./script/deploy.sh — security.sql installs it"

n=$(sql "$ADMIN_URL" "SELECT count(*) FROM pg_proc p
                      JOIN pg_namespace s ON s.oid = p.pronamespace
                      WHERE s.nspname = 'public' AND p.proname LIKE 'fn\_%'
                        AND has_function_privilege('momo_app', p.oid, 'EXECUTE')")
[[ "$n" == "25" ]] \
  && ok "momo_app has EXECUTE on all 25 fn_* functions" \
  || bad "expected 25 fn_* functions granted to momo_app" "got: $n"

echo
echo "== fixture =="

# leftovers from a previous aborted run would collide (unique email)
sql "$ADMIN_URL" "$cleanup_sql" >/dev/null
FIXTURE=1

BRANCH_ID=$(sql "$ADMIN_URL" "INSERT INTO branch (name, address)
                              VALUES ('ZZ Verify Branch', '1 Test Street')
                              RETURNING branch_id")
STAFF_ID=$(is_id "$BRANCH_ID" && sql "$ADMIN_URL" \
  "INSERT INTO staff (branch_id, name, role, password_hash)
   VALUES ($BRANCH_ID, 'ZZ Verify Staff', 'manager', crypt('$FIX_PASS', gen_salt('bf')))
   RETURNING staff_id")
ITEM_ID=$(is_id "$BRANCH_ID" && sql "$ADMIN_URL" \
  "INSERT INTO menu_item (branch_id, name, category, price, available)
   VALUES ($BRANCH_ID, 'ZZ Verify Item', 'meat', 0.00, TRUE)
   RETURNING item_id")

if is_id "$BRANCH_ID" && is_id "$STAFF_ID" && is_id "$ITEM_ID"; then
  ok "test branch/staff/item created (branch $BRANCH_ID)"
else
  bad "could not create fixture rows" "$BRANCH_ID / $STAFF_ID / $ITEM_ID"
  echo; echo "$PASS passed, $FAIL failed"; exit 1
fi

# registering through the function is itself a check
CUST_ID=$(sql "$ADMIN_URL" \
  "SELECT fn_register_customer('ZZ Verify Customer', '$FIX_EMAIL', '000-000-0000', '$FIX_PASS')")
is_id "$CUST_ID" \
  && ok "fn_register_customer created test customer (id $CUST_ID)" \
  || bad "fn_register_customer" "$CUST_ID"

echo
echo "== auth functions =="

r=$(sql "$ADMIN_URL" "SELECT count(*) FROM fn_login_customer('$FIX_EMAIL', '$FIX_PASS')")
[[ "$r" == "1" ]] && ok "fn_login_customer accepts the right password" \
                  || bad "fn_login_customer with correct password" "expected 1 row, got: $r"

r=$(sql "$ADMIN_URL" "SELECT count(*) FROM fn_login_customer('$FIX_EMAIL', 'wrongpass')")
[[ "$r" == "0" ]] && ok "fn_login_customer rejects a wrong password" \
                  || bad "fn_login_customer with wrong password" "expected 0 rows, got: $r"

r=$(sql "$ADMIN_URL" "SELECT count(*) FROM fn_login_staff('ZZ Verify Staff', '$FIX_PASS')")
[[ "$r" == "1" ]] && ok "fn_login_staff accepts the right password" \
                  || bad "fn_login_staff with correct password" "expected 1 row, got: $r"

# informational: pre-existing accounts with non-bcrypt hashes can't log in
ph=$(sql "$ADMIN_URL" "SELECT count(*) FROM customer
                       WHERE password_hash NOT LIKE '\$2%' AND email <> '$FIX_EMAIL'")
if [[ "$ph" != "0" ]]; then
  note "warning: $ph existing customer(s) have placeholder (non-bcrypt) hashes; to reset all:"
  note "  UPDATE customer SET password_hash = crypt('password123', gen_salt('bf'));"
fi

if [[ -z "$APP_PASS" ]]; then
  note "no momo_app password given -> skipping the as-momo_app lockout checks"
  note "rerun as: ./script/verify.sh '<admin url>' '<momo_app password>'"
else
  echo
  echo "== as momo_app =="

  out=$(sql "$ADMIN_URL" "SET password_encryption = 'scram-sha-256';
                          ALTER ROLE momo_app PASSWORD '$APP_PASS';")
  [[ "$out" == *"ERROR"* ]] && bad "could not set momo_app password" "$out" \
                            || ok "momo_app password set (SCRAM)"

  # same host/db, momo_app's credentials. channel_binding=disable is
  # needed on Render: its TLS-terminating proxy breaks SCRAM channel
  # binding (the reason Render defaults to MD5 passwords)
  APP_URL=$(printf '%s' "$ADMIN_URL" | sed -E "s#^(postgresql|postgres)://[^@]*@#\1://momo_app:${APP_PASS}@#")
  if [[ "$APP_URL" == *\?* ]]; then
    APP_URL="${APP_URL}&sslmode=require&channel_binding=disable"
  else
    APP_URL="${APP_URL}?sslmode=require&channel_binding=disable"
  fi

  if [[ "$(sql "$APP_URL" 'SELECT 1')" != "1" ]]; then
    bad "cannot connect as momo_app" "check the password / URL"
  else
    ok "connected as momo_app"

    out=$(sql "$APP_URL" "SELECT * FROM customer")
    [[ "$out" == *"permission denied"* ]] \
      && ok "direct SELECT on customer is denied" \
      || bad "momo_app could read the customer table directly" "$out"

    out=$(sql "$APP_URL" "UPDATE bill SET payment_status = payment_status")
    [[ "$out" == *"permission denied"* ]] \
      && ok "direct UPDATE on bill is denied" \
      || bad "momo_app could write the bill table directly" "$out"

    r=$(sql "$APP_URL" "SELECT count(*) FROM fn_get_branches()")
    [[ "$r" =~ ^[0-9]+$ && "$r" -gt 0 ]] \
      && ok "read through a function works (fn_get_branches: $r branches)" \
      || bad "fn_get_branches as momo_app" "$r"

    r=$(sql "$APP_URL" "SELECT count(*) FROM fn_login_customer('$FIX_EMAIL', '$FIX_PASS')")
    [[ "$r" == "1" ]] && ok "login through a function works as momo_app" \
                      || bad "fn_login_customer as momo_app" "expected 1 row, got: $r"

    # write through a function, against the fixture item only
    r=$(sql "$APP_URL" "SELECT fn_update_item_availability($ITEM_ID, FALSE)")
    r2=$(sql "$APP_URL" "SELECT fn_update_item_availability($ITEM_ID, TRUE)")
    [[ "$r" == "$ITEM_ID" && "$r2" == "$ITEM_ID" ]] \
      && ok "write through a function works (availability toggled off/on)" \
      || bad "fn_update_item_availability as momo_app" "got: $r / $r2"
  fi
fi

echo
echo "== cleanup =="
cleanup
left=$(sql "$ADMIN_URL" "SELECT count(*) FROM branch WHERE name = 'ZZ Verify Branch'")
[[ "$left" == "0" ]] \
  && ok "fixture rows deleted" \
  || bad "fixture rows left behind" "run the DELETEs in verify.sh's cleanup_sql by hand"

echo
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
