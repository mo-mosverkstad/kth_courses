#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

run_sql() {
    sudo -u postgres psql -v ON_ERROR_STOP=1 -d course_database -f "$SCRIPT_DIR/$1"
}

echo "--- Teaching cost calculation ---"
run_sql teaching-cost.sql
echo

echo "--- Course instance modification ---"
run_sql course-instance-modification.sql
echo

echo "--- Allocation/Deallocation ---"
run_sql allocate-deallocate.sql
echo

echo "--- New teaching activity ---"
run_sql new-teaching-activity.sql
echo