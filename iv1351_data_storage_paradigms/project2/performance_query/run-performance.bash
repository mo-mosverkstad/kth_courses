#!/usr/bin/env bash
# Measures the query workload before (candidate A) and after (candidate D).
# Writes the full EXPLAIN ANALYZE plans to results/ and prints a summary.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
QUERIES="$DIR/../query_scripts"
FAST="$DIR/queries"
CAND="$DIR/candidates"
RESULTS="$DIR/results"
RUNS=3
mkdir -p "$RESULTS"

# Keep everything this script prints, so the before/after summary survives the terminal.
exec > >(tee "$RESULTS/summary.txt") 2>&1
echo "run-performance.bash, $(date '+%Y-%m-%d %H:%M:%S')"
echo

psql_run() {
    sudo -u postgres psql -X -q -P pager=off -v ON_ERROR_STOP=1 -d course_database "$@"
}

# name | query before (query_scripts) | query after (performance_query)
WORKLOAD="
planned-hours|planned-hours-calculation.sql|fast-planned-hours.sql
actual-hours-by-course|actual-hours-calculation-by-course.sql|fast-actual-hours-by-course.sql
actual-hours-by-teacher|actual-hours-calculation-by-teacher.sql|fast-actual-hours-by-teacher.sql
teacher-load-per-period|teacher-load-per-period.sql|fast-teacher-load-per-period.sql
mismatches|mismatches.sql|fast-mismatches.sql
teaching-allocation|teaching-allocation.sql|fast-teaching-allocation.sql
"

# Prints the median EXPLAIN ANALYZE execution time (ms) of a query file, saves the last plan
measure() {
    local file="$1" plan="$2" times=()
    local sql
    sql="$(tr -d '\r' < "$file" | sed 's/;[[:space:]]*$//')"
    for _ in $(seq 1 "$RUNS"); do
        psql_run -c "EXPLAIN ANALYZE $sql" > "$plan"
        times+=("$(grep 'Execution Time' "$plan" | awk '{print $3}')")
    done
    printf '%s\n' "${times[@]}" | sort -n | sed -n "$(( (RUNS + 1) / 2 ))p"
}

echo "=== before: no views, no extra index"
psql_run -f "$CAND/candidate-a-no-optimisation.sql" 2>/dev/null
psql_run -c "ANALYZE"
declare -A before
while IFS='|' read -r name q_before q_after; do
    [ -z "$name" ] && continue
    before[$name]="$(measure "$QUERIES/$q_before" "$RESULTS/before-$name.txt")"
    echo "$name: ${before[$name]} ms"
done <<< "$WORKLOAD"

echo "=== creating views and index"
start=$(date +%s.%N)
psql_run -f "$CAND/candidate-d-course-instance-views.sql" 2>/dev/null
echo "candidate-d-course-instance-views.sql: $(echo "$(date +%s.%N) - $start" | bc) s"
psql_run -c "SELECT pg_stat_reset()" > /dev/null
sleep 1

echo "=== after"
while IFS='|' read -r name q_before q_after; do
    [ -z "$name" ] && continue
    after="$(measure "$FAST/$q_after" "$RESULTS/after-$name.txt")"
    echo "$name: ${before[$name]} ms -> $after ms"
done <<< "$WORKLOAD"

sleep 1
echo "=== index usage during the 'after' runs"
psql_run -c "SELECT relname AS table_or_view, indexrelname AS index, idx_scan
             FROM pg_stat_user_indexes
             WHERE relname IN ('course_instance_planned_view', 'course_instance_mismatch_view',
                               'teacher_period_load_view', 'teaching_allocation')
             ORDER BY 1, 2"
