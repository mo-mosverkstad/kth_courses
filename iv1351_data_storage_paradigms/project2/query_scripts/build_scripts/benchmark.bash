#!/usr/bin/env bash
# Usage: ./benchmark.bash <insert-script>
# Rebuilds course_database (clean, create, trigger) and times the given insert script.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSERT_SCRIPT="${1:?usage: ./benchmark.bash <insert-script>}"

run_sql() {
    sudo -u postgres psql -q -v ON_ERROR_STOP=1 -d course_database -f "$SCRIPT_DIR/$1" > /dev/null
}

build_start=$(date +%s.%N)
run_sql clean-postgresql.sql
run_sql logical-physical-postgresql.sql
run_sql trigger-postgresql.sql

insert_start=$(date +%s.%N)
sudo -u postgres psql -v ON_ERROR_STOP=1 -d course_database -c '\timing on' -f "$SCRIPT_DIR/$INSERT_SCRIPT" \
    | grep -E '^Time:' > "/tmp/benchmark-statements.txt"
end=$(date +%s.%N)

printf 'insert script: %s\n' "$INSERT_SCRIPT"
printf 'insert time:   %.1f s\n' "$(echo "$end - $insert_start" | bc)"
printf 'build time:    %.1f s\n' "$(echo "$end - $build_start" | bc)"
echo 'slowest statements:'
sort -t' ' -k2 -n -r /tmp/benchmark-statements.txt | head -5
