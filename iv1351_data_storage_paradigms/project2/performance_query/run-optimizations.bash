#!/usr/bin/env bash
#
# Measures the whole workload, all six queries, against all five optimizations.
#
#   A  no optimization                   optimization-a-baseline.sql
#   B  one index on course_instance      optimization-b-index-course-instance.sql
#   C  view at planned_activity grain    optimization-c-course-activity-view.sql
#   D  views at course instance grain    optimization-d-course-instance-views.sql
#   E  as D, activity names data driven  optimization-e-data-driven-activities.sql
#
# An optimization can only be measured with a query it is able to run. Optimizations A and B add no
# view, so they run the original queries in ../query_scripts/. optimization C provides a view
# only for the planned hours and the mismatch report, so its other four queries are the
# originals as well, because there is no view for them to read. optimizations D and E read their
# own query files, query-d-*.sql and query-e-*.sql.
#
# Every optimization file starts by removing everything the other optimizations create, so the
# optimizations are independent of the order they are applied in. optimization D is applied again
# at the end, since it is the chosen solution.
#
# Output:
#   results/summary-optimizations.txt    everything this script prints
#   results/measurements.csv          optimization,query,milliseconds, one line per measurement
#   results/<optimization>-<query>.txt   the last EXPLAIN ANALYZE plan of that combination

set -euo pipefail


# ----------------------------------------------------------------- configuration

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_QUERY_DIR="$(cd -- "$SCRIPT_DIR/../query_scripts" && pwd)"
OPTIMIZATION_DIR="$SCRIPT_DIR/optimizations"
QUERY_DIR="$SCRIPT_DIR/queries"
RESULT_DIR="$SCRIPT_DIR/results"

MEASUREMENTS_CSV="$RESULT_DIR/measurements.csv"
SUMMARY_FILE="$RESULT_DIR/summary-optimizations.txt"

DATABASE="course_database"
RUNS_PER_QUERY=3


# ----------------------------------------------------------------- database access

run_psql() {
    sudo -u postgres psql -X -q -P pager=off -v ON_ERROR_STOP=1 -d "$DATABASE" "$@"
}

# The SQL files end with a semicolon, which has to go before the text can be used as the
# argument of EXPLAIN ANALYZE. The files also use Windows line endings.
read_query_without_trailing_semicolon() {
    local query_file="$1"
    tr -d '\r' < "$query_file" | sed 's/;[[:space:]]*$//'
}

# Runs the query once, writes the plan to a file and prints the execution time in ms.
explain_analyze_once() {
    local sql="$1"
    local plan_file="$2"

    run_psql --command "EXPLAIN ANALYZE $sql" > "$plan_file"
    grep 'Execution Time' "$plan_file" | awk '{ print $3 }'
}

size_and_rows_of() {
    local relation="$1"
    run_psql --no-align --tuples-only --command "
        SELECT pg_size_pretty(pg_total_relation_size('$relation'))
               || ', '
               || to_char((SELECT count(*) FROM $relation), 'FM999G999G999')
               || ' rows'"
}


# ----------------------------------------------------------------- measuring

median_of_three() {
    local first="$1"
    local second="$2"
    local third="$3"

    printf '%s\n%s\n%s\n' "$first" "$second" "$third" | sort --numeric-sort | sed -n '2p'
}

# A single run is not trustworthy, because the first run of a query reads pages from disk
# while later runs find them in cache. Three runs are made and the middle one is kept.
measure_median_execution_time() {
    local optimization="$1"
    local query_name="$2"
    local query_file="$3"

    local plan_file="$RESULT_DIR/$optimization-$query_name.txt"
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

remember_measurement() {
    local optimization="$1"
    local query_name="$2"
    local milliseconds="$3"

    printf '%s,%s,%s\n' "$optimization" "$query_name" "$milliseconds" >> "$MEASUREMENTS_CSV"
}

recall_measurement() {
    local optimization="$1"
    local query_name="$2"

    awk --field-separator=, \
        --assign wanted_optimization="$optimization" \
        --assign wanted_query="$query_name" \
        '$1 == wanted_optimization && $2 == wanted_query { print $3 }' \
        "$MEASUREMENTS_CSV"
}

# Measures one query for one optimization, stores the result and prints one progress line.
measure_query() {
    local optimization="$1"
    local query_name="$2"
    local description="$3"
    local query_file="$4"

    local milliseconds
    milliseconds="$(measure_median_execution_time "$optimization" "$query_name" "$query_file")"

    remember_measurement "$optimization" "$query_name" "$milliseconds"
    printf '  %-40s %12s ms   (%s)\n' "$description" "$milliseconds" "$(basename "$query_file")"
}


# ----------------------------------------------------------------- applying an optimization

seconds_now() {
    date +%s.%N
}

seconds_since() {
    local started_at="$1"
    printf '%.1f' "$(echo "$(seconds_now) - $started_at" | bc)"
}

apply_optimization() {
    local optimization="$1"
    local description="$2"
    local optimization_file="$3"

    echo "=============== Optimization $optimization: $description ==============="

    local started_at
    started_at="$(seconds_now)"
    run_psql --file "$SCRIPT_DIR/$optimization_file" 2> /dev/null
    local build_seconds
    build_seconds="$(seconds_since "$started_at")"

    remember_measurement "$optimization" "build-seconds" "$build_seconds"
    echo "build time : $build_seconds s"
}


# ----------------------------------------------------------------- the five optimizations

measure_optimization_a() {
    apply_optimization A "no optimization" optimization-a-baseline.sql

    measure_query A threshold     "teachers above a threshold (20/day)"     "$ORIGINAL_QUERY_DIR/teaching-allocation.sql"
    measure_query A one-instance  "allocated hours, one instance (12/day)"  "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-course.sql"
    measure_query A one-teacher   "allocated hours, one teacher (12/day)"   "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-teacher.sql"
    measure_query A planned-hours "planned hours per instance (8/day)"      "$ORIGINAL_QUERY_DIR/planned-hours-calculation.sql"
    measure_query A teacher-load  "teacher load per period (5/day)"         "$ORIGINAL_QUERY_DIR/teacher-load-per-period.sql"
    measure_query A mismatches    "mismatch above 15% (3/day)"              "$ORIGINAL_QUERY_DIR/mismatches.sql"
    echo
}

measure_optimization_b() {
    apply_optimization B "index on course_instance" optimization-b-index-course-instance.sql

    # An index needs no rewritten query, so these are the same files as optimization A.
    measure_query B threshold     "teachers above a threshold (20/day)"     "$ORIGINAL_QUERY_DIR/teaching-allocation.sql"
    measure_query B one-instance  "allocated hours, one instance (12/day)"  "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-course.sql"
    measure_query B one-teacher   "allocated hours, one teacher (12/day)"   "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-teacher.sql"
    measure_query B planned-hours "planned hours per instance (8/day)"      "$ORIGINAL_QUERY_DIR/planned-hours-calculation.sql"
    measure_query B teacher-load  "teacher load per period (5/day)"         "$ORIGINAL_QUERY_DIR/teacher-load-per-period.sql"
    measure_query B mismatches    "mismatch above 15% (3/day)"              "$ORIGINAL_QUERY_DIR/mismatches.sql"
    echo
}

measure_optimization_c() {
    apply_optimization C "view per planned activity" optimization-c-course-activity-view.sql

    # Only the planned hours and the mismatch report can read course_activity_view.
    # The other four queries have no view to read, so they stay as they are.
    measure_query C threshold     "teachers above a threshold (20/day)"     "$ORIGINAL_QUERY_DIR/teaching-allocation.sql"
    measure_query C one-instance  "allocated hours, one instance (12/day)"  "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-course.sql"
    measure_query C one-teacher   "allocated hours, one teacher (12/day)"   "$ORIGINAL_QUERY_DIR/actual-hours-calculation-by-teacher.sql"
    measure_query C planned-hours "planned hours per instance (8/day)"      "$QUERY_DIR/query-c-planned-hours.sql"
    measure_query C teacher-load  "teacher load per period (5/day)"         "$ORIGINAL_QUERY_DIR/teacher-load-per-period.sql"
    measure_query C mismatches    "mismatch above 15% (3/day)"              "$QUERY_DIR/query-c-mismatches.sql"

    echo "  course_activity_view              : $(size_and_rows_of course_activity_view)"
    echo
}

measure_optimization_d() {
    apply_optimization D "views per course instance" optimization-d-course-instance-views.sql

    measure_query D threshold     "teachers above a threshold (20/day)"     "$QUERY_DIR/query-d-threshold.sql"
    measure_query D one-instance  "allocated hours, one instance (12/day)"  "$QUERY_DIR/query-d-one-instance.sql"
    measure_query D one-teacher   "allocated hours, one teacher (12/day)"   "$QUERY_DIR/query-d-one-teacher.sql"
    measure_query D planned-hours "planned hours per instance (8/day)"      "$QUERY_DIR/query-d-planned-hours.sql"
    measure_query D teacher-load  "teacher load per period (5/day)"         "$QUERY_DIR/query-d-teacher-load.sql"
    measure_query D mismatches    "mismatch above 15% (3/day)"              "$QUERY_DIR/query-d-mismatches.sql"

    echo "  course_instance_planned_view      : $(size_and_rows_of course_instance_planned_view)"
    echo "  course_instance_mismatch_view     : $(size_and_rows_of course_instance_mismatch_view)"
    echo "  teacher_period_load_view          : $(size_and_rows_of teacher_period_load_view)"
    echo
}

measure_optimization_e() {
    apply_optimization E "same, activities data driven" optimization-e-data-driven-activities.sql

    # Everything except the planned hours is identical to optimization D, so that the
    # comparison measures only the one difference between them.
    measure_query E threshold     "teachers above a threshold (20/day)"     "$QUERY_DIR/query-d-threshold.sql"
    measure_query E one-instance  "allocated hours, one instance (12/day)"  "$QUERY_DIR/query-d-one-instance.sql"
    measure_query E one-teacher   "allocated hours, one teacher (12/day)"   "$QUERY_DIR/query-d-one-teacher.sql"
    measure_query E planned-hours "planned hours per instance (8/day)"      "$QUERY_DIR/query-e-planned-hours.sql"
    measure_query E teacher-load  "teacher load per period (5/day)"         "$QUERY_DIR/query-d-teacher-load.sql"
    measure_query E mismatches    "mismatch above 15% (3/day)"              "$QUERY_DIR/query-d-mismatches.sql"

    echo "  course_instance_planned_json_view : $(size_and_rows_of course_instance_planned_json_view)"
    echo "  course_instance_mismatch_view     : $(size_and_rows_of course_instance_mismatch_view)"
    echo "  teacher_period_load_view          : $(size_and_rows_of teacher_period_load_view)"
    echo
}


# ----------------------------------------------------------------- the summary table

print_summary_row() {
    local query_name="$1"
    local description="$2"

    printf '%-40s %11s %11s %11s %11s %11s\n' \
        "$description" \
        "$(recall_measurement A "$query_name")" \
        "$(recall_measurement B "$query_name")" \
        "$(recall_measurement C "$query_name")" \
        "$(recall_measurement D "$query_name")" \
        "$(recall_measurement E "$query_name")"
}

print_summary() {
    echo "=============== summary: execution time in ms, median of $RUNS_PER_QUERY runs ==============="
    printf '%-40s %11s %11s %11s %11s %11s\n' "query (frequency)" A B C D E

    print_summary_row threshold     "teachers above a threshold (20/day)"
    print_summary_row one-instance  "allocated hours, one instance (12/day)"
    print_summary_row one-teacher   "allocated hours, one teacher (12/day)"
    print_summary_row planned-hours "planned hours per instance (8/day)"
    print_summary_row teacher-load  "teacher load per period (5/day)"
    print_summary_row mismatches    "mismatch above 15% (3/day)"
    print_summary_row build-seconds "build time (s)"
}


# ----------------------------------------------------------------- main

main() {
    echo "run-optimizations.bash, $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    measure_optimization_a
    measure_optimization_b
    measure_optimization_c
    measure_optimization_d
    measure_optimization_e

    print_summary

    echo
    echo "=============== restoring the chosen solution (optimization D) ==============="
    run_psql --file "$OPTIMIZATION_DIR/optimization-d-course-instance-views.sql" 2> /dev/null
    echo "Database left in optimization D."
}

mkdir -p "$RESULT_DIR"
: > "$MEASUREMENTS_CSV"
main 2>&1 | tee "$SUMMARY_FILE"
