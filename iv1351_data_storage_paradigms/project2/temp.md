# IV1351 Project 2: SQL and OLAP

These scripts target PostgreSQL and the Project 1 schema. Run them in a fresh database in this order:

1. `project1/sql_scripts/logical-physical-postgresql.sql`
2. `project1/sql_scripts/trigger-postgresql.sql`
3. `project1/sql_scripts/db-insertion-postgresql.sql`
4. `project2/scale-data-postgresql.sql`
5. `project2/performance-postgresql.sql`

Run `queries.sql` when you want the four base reports and the correct and intentionally incorrect mismatch reports. Use `psql -v ON_ERROR_STOP=1`. The current-year and current-period conditions use PostgreSQL `current_date`; to demonstrate the examples for another year, replace the year predicate with a chosen year.

## Query intent

1. Planned hours computes the examination and administration hours from the stored formula and each instance's student count and HP. It applies the activity factor and returns activity detail plus a windowed course total.
2. Allocation detail groups raw hours by teacher, activity, and instance before applying the factor, then returns per-instance totals.
3. Teacher load sums adjusted allocation hours over course instances in the current year.
4. Period threshold counts distinct instances, so multiple activities in one instance count once. Set the psql variable `course_instance_limit` before running it.
5. The higher-grade mismatch query independently aggregates the planned and allocated sides before joining. The deliberately wrong query joins each planned activity to its allocations first, which repeats its planned hours once per allocated teacher and inflates the result.

## Performance study procedure

The data script creates one million course instances and one million planned activities, plus 2026 instances for the current-year reports. Run `EXPLAIN (ANALYZE, BUFFERS)` on representative base queries before `performance-postgresql.sql`, then again afterward. Save the complete plans and report actual execution time, buffer reads/hits, and row counts; timings depend on the machine and PostgreSQL settings, so they must be collected on the submission environment.

The indexes support period filtering, instance-to-plan traversal, and employee allocation lookups. The three materialized views pre-aggregate inputs used by frequent reports; their unique indexes support joins and concurrent refresh. They trade query time for storage and refresh work. The boolean expression index is expected not to be used for `allocation_hours > 0` when nearly every row matches, because a sequential scan is cheaper. Confirm that with `EXPLAIN ANALYZE` on the loaded dataset.

For the freshness demonstration, record a course's materialized total, insert a new allocation on an existing activity/employee pair that is not already present, and query the base tables and materialized view. The view remains unchanged until refresh. Capture refresh duration with `\\timing on` in psql, then run `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_allocated_instance_hours` and query it again. Ensure the chosen employee remains within the four-instance rule for the period.

## Report text to adapt

### Method

The implementation uses PostgreSQL [insert version] and [psql/pgAdmin]. SQL was developed and checked by rebuilding a clean database from the schema and data scripts, executing each report, and checking the results against hand-calculated cases and known sample rows. Performance was evaluated with `EXPLAIN (ANALYZE, BUFFERS)` before and after indexing and materialization.

### Results

The four required OLAP queries and their outputs are in `queries.sql`; database creation and insertion scripts are in the Project 1 SQL directory, and `scale-data-postgresql.sql` supplies the large Task 2 dataset. Repository: [insert repository URL]. Include the output from each query here or in an appendix. Also include the correct mismatch output and the wrong query output, explaining that joining first duplicates planned hours for activities with multiple allocations.

### Discussion

The mismatch reports aggregate each side to one row per course instance before joining. The incorrect version joins activity plans to allocation rows and sums both measures at that finer grain. If an activity has three teachers, its planned amount appears three times. This is a fan-out error, not a rounding difference.

Indexes help when a predicate or join narrows a large relation enough to avoid scanning most rows. They consume disk, add write and vacuum work, and can be ignored when a table is small or the predicate matches most rows. The boolean expression index is a low-selectivity example: if almost all allocations have positive hours, a sequential scan reads the table more efficiently. Use the observed query plan to support this explanation.

Materialized views make repeated aggregation cheaper for a read-heavy workload, especially the planned and allocated instance totals and teacher-period totals. They store redundant derived data, use disk, and become stale after writes. Refreshing costs time and I/O; concurrent refresh also needs a qualifying unique index and additional resources. Here the listed daily report frequencies make precomputation plausible, while the refresh interval must reflect how quickly allocation changes need to appear. If writes became frequent or reports rare, ordinary queries or regular views could cost less overall. If report traffic grew while updates stayed low, more pre-aggregations could be justified.

Attach measured before/after execution times, actual plans, the unused-index plan, and the materialized-view refresh duration. Do not substitute estimated or invented timings: query plans vary by hardware, cache state, data distribution, and PostgreSQL version.
