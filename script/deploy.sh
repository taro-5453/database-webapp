#!/usr/bin/env bash
# ============================================================
# Momo Paradise - deploy database objects to PostgreSQL (Render)
#
# Usage:
#   ./script/deploy.sh [--schema] [--seed] [DB_URL]
#
#   DB_URL looks like postgresql://user:pass@host.render.com/dbname
#   and can also be set as an environment variable:
#     DB_URL='postgresql://...' ./script/deploy.sh
#
# What runs (in order):
#   --schema   database/schema.sql       FRESH DB ONLY: plain CREATE
#              TABLEs, fails if the tables already exist
#   --seed     database/sample_data.sql  fresh DB only: re-running
#              inserts every sample row again
#   (always)   function/**/*.sql         CREATE OR REPLACE, safe to
#              re-run any time
#   (always)   database/security.sql     idempotent; re-grants new
#              functions to momo_app
#
# So a first-time deploy is:  ./script/deploy.sh --schema --seed "$DB_URL"
# and updating functions is:  ./script/deploy.sh "$DB_URL"
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# .env (gitignored) can hold DB_URL so it never appears on the command line
[[ -f .env ]] && source .env

RUN_SCHEMA=0
RUN_SEED=0
DB_URL="${DB_URL:-}"

for arg in "$@"; do
  case "$arg" in
    --schema)  RUN_SCHEMA=1 ;;
    --seed)    RUN_SEED=1 ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "error: unknown option $arg (see --help)" >&2; exit 1 ;;
    *)         DB_URL="$arg" ;;
  esac
done

if [[ -z "$DB_URL" ]]; then
  echo "error: no database URL given." >&2
  echo "  ./script/deploy.sh 'postgresql://user:pass@host.render.com/dbname'" >&2
  echo "  (or export DB_URL first)" >&2
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "error: psql not found." >&2
  echo "  macOS: brew install libpq && brew link --force libpq" >&2
  exit 1
fi

run_sql() {
  echo "==> $1"
  psql "$DB_URL" --quiet -v ON_ERROR_STOP=1 -f "$1"
}

if [[ $RUN_SCHEMA -eq 1 ]]; then
  run_sql database/schema.sql
fi

if [[ $RUN_SEED -eq 1 ]]; then
  run_sql database/sample_data.sql
fi

# all function files, deterministic order (they are independent of
# each other, so alphabetical is fine)
while IFS= read -r file; do
  run_sql "$file"
done < <(find function -name '*.sql' | sort)

# last, so brand-new functions get SECURITY DEFINER + the grant
run_sql database/security.sql

echo "Done: functions + security applied$( [[ $RUN_SCHEMA -eq 1 ]] && echo ', schema created' )$( [[ $RUN_SEED -eq 1 ]] && echo ', sample data loaded' )."
