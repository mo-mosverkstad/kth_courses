#!/usr/bin/env bash
#
# Measures the six workload queries before and after the chosen solution, and reports which
# indexes the planner actually used.
#
#   before  optimization A, no optimization, running the original queries in ../query_scripts/
#   after   optimization D, the chosen views and index, running the query-d-*.sql queries
#
# For the comparison of all five optimizations against each other, use run-optimizations.bash.
#
# Output:
#   results/summary-performance.txt     everything this script prints
#   results/before-<query>.txt          the last plan of each query without optimization
#   results/after-<query>.txt           the last plan of each query with the solution

set -euo pipefail


# ----------------------------------------------------------------- configuration

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_QUERY_DIR="$(cd -- "$SCRIPT_DIR/../query_scripts" && pwd)"
OPTIMIZATION_DIR="$SCRIPT_DIR/optimizations"
QUERY_DIR="$SCRIPT_DIR/queries"
RESULT_DIR="$SCRIPT_DIR/results"

SUMMARY_FILE="$RESULT_DIR/summary-performance.txt"

DATABASE="course_database"
RUNS_PER_QUERY=3


# ----------------------------------------------------------------- database access

run_psql() {
    sudo -u postgres psql -X -q -P pager=off -v ON_ERROR_STOP=1 -d "$DATABASE" "$@"
}

read_query_without_trailing_semicolon() {
    local query_file="$1"
    tr -d '\r' < "$query_file" | sed 's/;[[:space:]]*$//'
}

explain_analyze_once() {
    local sql="$1"
    local plan_file="$2"

    run_psql --command "EXPLAIN ANALYZE $sql" > "$plan_file"
    grep 'Execution Time' "$plan_file" | awk '{ print $3 }'
}


# ----------------------------------------------------------------- measuring

median_of_three() {
    printf '%s\n%s\n%s\n' "$1" "$2" "$3" | sort --numeric-sort | sed -n '2p'
}

measure_median_execution_time() {
    local query_file="$1"
    local plan_file="$2"

    local sql
    sql="$(read_query_without_trailing_semicolon "$query_file")"

    local first_run
    local second_run
    local third_run
    first_run="$(explain_analyze_once "$sql" "$plan_file")"
    second_run="$(explain_analyze_once "$sql" "$plan_file")"
    third_run="$(explain_analyze_once "$sql" "$plan_file")"

    median_of_three "$first_run" "$second_run" "$third_run"
}

# Set by measure_before and read by measure_after, so that the two can be printed together.
declare -A BEFORE_MILLISECONDS

measure_before() {
    local query_name="$1"
    local description="$2"
    local query_file="$3"

    BEFORE_MILLISECONDS[$query_name]="$(
        measure_median_execution_time "$query_file" "$RESULT_DIR/before-$query_name.txt"
    )"
    printf '  %-40s %12s ms\n' "$description" "${BEFORE_MILLISECONDS[$query_name]}"
}

measure_after() {
    local query_name="$1"
    local description="$2"
    local query_file="$3"

    local after_milliseconds
    after_milliseconds="$(
        measure_median_execution_time "$query_file" "$RESULT_DIR/after-$query_name.txt"
    )"
    printf '  %-40s %12s ms  ->  %12s ms\n' \
        "$description" "${BEFORE_MILLISECONDS[$query_name]}" "$after_milliseconds"
}


# ----------------------------------------------------------------- the two states

measure_without_optimization() {
    echo "=============== before: optimization A, no views and no extra index ==============="
    run_psql --file "$OPTIMIZATION_DIR/optimization-a-baseline.sql" 2> /dev/null
    run_psql --command "ANALYZE"

    measure_before threshold     "teachers above a threshold (20/day)"     "$ORIGINAL_QUERY_DIR/teaching-allocation.sql"
    measure_before one-instance  "allocated hours, one instance (12/day)"  "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-course.sql"
    measure_before one-teacher   "allocated hours, one teacher (12/day)"   "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-teacher.sql"
    measure_before planned-hours "planned hours per instance (8/day)"      "$ORIGINAL_QUERY_DIR/planned-hours-calculation.sql"
    measure_before teacher-load  "teacher load per period (5/day)"         "$ORIGINAL_QUERY_DIR/teacher-load-per-period.sql"
    measure_before mismatches    "mismatch above 15% (3/day)"              "$ORIGINAL_QUERY_DIR/mismatches.sql"
    echo
}

apply_the_solution() {
    echo "=============== applying optimization D, the chosen solution ==============="

    local started_at
    started_at="$(date +%s.%N)"
    run_psql --file "$OPTIMIZATION_DIR/optimization-d-course-instance-views.sql" 2> /dev/null
    printf 'build time : %.1f s\n' "$(echo "$(date +%s.%N) - $started_at" | bc)"

    # The index usage report below should count only the measured runs.
    run_psql --command "SELECT pg_stat_reset()" > /dev/null
    sleep 1
    echo
}

measure_with_the_solution() {
    echo "=============== after: optimization D ==============="

    measure_after threshold     "teachers above a threshold (20/day)"     "$QUERY_DIR/query-d-threshold.sql"
    measure_after one-instance  "allocated hours, one instance (12/day)"  "$QUERY_DIR/query-d-one-instance.sql"
    measure_after one-teacher   "allocated hours, one teacher (12/day)"   "$QUERY_DIR/query-d-one-teacher.sql"
    measure_after planned-hours "planned hours per instance (8/day)"      "$QUERY_DIR/query-d-planned-hours.sql"
    measure_after teacher-load  "teacher load per period (5/day)"         "$QUERY_DIR/query-d-teacher-load.sql"
    measure_after mismatches    "mismatch above 15% (3/day)"              "$QUERY_DIR/query-d-mismatches.sql"
    echo
}

report_index_usage() {
    echo "=============== index usage during the measured runs ==============="
    echo "An index with 0 scans was never used by the planner."
    sleep 1
    run_psql --command "
        SELECT relname AS table_or_view, indexrelname AS index, idx_scan AS scans
        FROM pg_stat_user_indexes
        WHERE relname IN ('course_instance_planned_view', 'course_instance_mismatch_view',
                          'teacher_period_load_view', 'teaching_allocation')
        ORDER BY relname, indexrelname"
}


# ----------------------------------------------------------------- main

main() {
    echo "run-performance.bash, $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    measure_without_optimization
    apply_the_solution
    measure_with_the_solution
    report_index_usage

    echo
    echo "Database left in optimization D, the chosen solution."
}

mkdir -p "$RESULT_DIR"
main 2>&1 | tee "$SUMMARY_FILE"
