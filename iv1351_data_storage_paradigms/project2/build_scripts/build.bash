#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

run_sql() {
    sudo -u postgres psql -v ON_ERROR_STOP=1 -d course_database -f "$SCRIPT_DIR/$1"
}

run_sql clean-postgresql.sql
run_sql logical-physical-postgresql.sql
run_sql trigger-postgresql.sql
# run-sql raw-insertion.data.sql
run_sql db-insertion-postgresql.sql
