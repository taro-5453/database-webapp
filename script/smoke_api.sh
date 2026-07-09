#!/usr/bin/env bash
# ============================================================
# Momo Paradise - API smoke test (happy path over HTTP)
#
# Usage:
#   ./script/smoke_api.sh [API_URL]
#     default API_URL: http://localhost:5001
#     against Render:  ./script/smoke_api.sh https://<service>.onrender.com
#
# Only needs curl + the API. Optional extras (picked up from .env):
#   SMOKE_STAFF_NAME / SMOKE_STAFF_PASSWORD -> also test staff
#     endpoints (queue + dashboard, read-only)
#   DB_URL (admin) -> delete the test customer/reservation created
#     by the run; without it they stay behind (harmless, flagged)
#
# Registers a unique smoke_<timestamp>@example.com customer, walks
# the customer happy path, and checks auth guards. Exits 0 only if
# every check passed.
# ============================================================
set -uo pipefail

cd "$(dirname "$0")/.."
[[ -f .env ]] && source .env

API="${1:-http://localhost:5001}"
EMAIL="smoke_$(date +%s)@example.com"
PASSWORD="smoke-test-pass1"

PASS=0; FAIL=0
ok()   { echo "  PASS  $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL  $1${2:+ — $2}"; FAIL=$((FAIL+1)); }
note() { echo "  ....  $1"; }

JAR=$(mktemp); SJAR=$(mktemp)
trap 'rm -f "$JAR" "$SJAR"' EXIT

# call METHOD PATH [JSON] [extra curl args...]; sets BODY and CODE
call() {
  local method=$1 path=$2 data=${3:-}
  shift; shift; [[ $# -gt 0 ]] && shift
  local out
  if [[ -n "$data" ]]; then
    out=$(curl -s -w $'\n%{http_code}' -X "$method" "$API$path" \
          -H 'Content-Type: application/json' -d "$data" "$@")
  else
    out=$(curl -s -w $'\n%{http_code}' -X "$method" "$API$path" "$@")
  fi
  CODE=${out##*$'\n'}
  BODY=${out%$'\n'*}
}

json() { # json <key> -> value from $BODY (empty if missing)
  printf '%s' "$BODY" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('$1',''))
except Exception: print('')" 2>/dev/null
}

echo "== smoke: $API =="

call GET /api/health
[[ "$CODE" == "200" && "$(json status)" == "ok" ]] \
  && ok "health ($(json branches) branches)" \
  || bad "GET /api/health" "code $CODE: $BODY"

call GET /api/branches
BRANCH_ID=$(printf '%s' "$BODY" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(d[0]['branch_id'] if d else '')" 2>/dev/null)
[[ "$CODE" == "200" && -n "$BRANCH_ID" ]] \
  && ok "branches list (using branch $BRANCH_ID)" \
  || bad "GET /api/branches" "code $CODE"

call GET "/api/branches/$BRANCH_ID/available-tables?party_size=2"
[[ "$CODE" == "200" ]] \
  && ok "available tables" \
  || bad "GET available-tables" "code $CODE: $BODY"

call POST /api/auth/register \
  "{\"name\":\"Smoke Test\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" -c "$JAR"
CUSTOMER_ID=$(json customer_id)
[[ "$CODE" == "201" && -n "$CUSTOMER_ID" ]] \
  && ok "register (customer $CUSTOMER_ID)" \
  || bad "POST /api/auth/register" "code $CODE: $BODY"

call GET /api/auth/me "" -b "$JAR"
[[ "$CODE" == "200" && "$(json kind)" == "customer" ]] \
  && ok "session cookie works (/me)" \
  || bad "GET /api/auth/me" "code $CODE: $BODY"

call GET /api/me/membership "" -b "$JAR"
[[ "$CODE" == "200" && "$(json tier)" == "standard" ]] \
  && ok "membership auto-created (standard, $(json points) points)" \
  || bad "GET /api/me/membership" "code $CODE: $BODY"

call POST /api/reservations "{\"branch_id\":$BRANCH_ID,\"party_size\":2}" -b "$JAR"
RESERVATION_ID=$(json reservation_id)
[[ "$CODE" == "201" && "$(json status)" == "queued" ]] \
  && ok "queue reservation created (id $RESERVATION_ID)" \
  || bad "POST /api/reservations" "code $CODE: $BODY"

call POST /api/auth/login "{\"email\":\"$EMAIL\",\"password\":\"wrong\"}"
[[ "$CODE" == "401" ]] \
  && ok "wrong password rejected (401)" \
  || bad "login with wrong password" "expected 401, got $CODE"

call GET /api/me/membership ""
[[ "$CODE" == "401" ]] \
  && ok "guarded route without cookie rejected (401)" \
  || bad "membership without login" "expected 401, got $CODE"

if [[ -n "${SMOKE_STAFF_NAME:-}" && -n "${SMOKE_STAFF_PASSWORD:-}" ]]; then
  call POST /api/auth/staff-login \
    "{\"name\":\"$SMOKE_STAFF_NAME\",\"password\":\"$SMOKE_STAFF_PASSWORD\"}" -c "$SJAR"
  [[ "$CODE" == "200" && -n "$(json staff_id)" ]] \
    && ok "staff login (branch $(json branch_id), $(json role))" \
    || bad "POST /api/auth/staff-login" "code $CODE: $BODY"

  call GET /api/staff/queue "" -b "$SJAR"
  [[ "$CODE" == "200" ]] && ok "staff queue view" \
                         || bad "GET /api/staff/queue" "code $CODE: $BODY"

  call GET /api/staff/dining-sessions "" -b "$SJAR"
  [[ "$CODE" == "200" ]] && ok "staff dashboard" \
                         || bad "GET /api/staff/dining-sessions" "code $CODE: $BODY"

  call GET /api/staff/queue "" -b "$JAR"
  [[ "$CODE" == "401" ]] && ok "customer blocked from staff routes (401)" \
                         || bad "customer on staff route" "expected 401, got $CODE"
else
  note "SMOKE_STAFF_NAME/PASSWORD not set -> skipping staff checks"
fi

# ---------- cleanup ----------
if [[ -n "${DB_URL:-}" ]] && command -v psql >/dev/null 2>&1; then
  psql "$DB_URL" -qtA -c "
    DELETE FROM reservation WHERE customer_id IN
      (SELECT customer_id FROM customer WHERE email = '$EMAIL');
    DELETE FROM membership WHERE customer_id IN
      (SELECT customer_id FROM customer WHERE email = '$EMAIL');
    DELETE FROM customer WHERE email = '$EMAIL';" >/dev/null \
    && ok "test rows cleaned up" \
    || bad "cleanup failed" "delete rows for $EMAIL by hand"
else
  note "no DB_URL/psql -> leftover test rows: customer $EMAIL + reservation $RESERVATION_ID"
fi

echo
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
