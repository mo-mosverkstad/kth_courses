# Make it fast: indexes and materialized views

Measured on PostgreSQL 16 (WSL 2, 8 cores, 15 GB RAM) with the big database from
`db-insertion-postgresql.sql` (3,200,577 allocations, 2,267,074 planned activities,
400,072 course instances, 450,033 employees).

Re-measured after the project 1 triggers started storing the derived planned hours. The
queries no longer join `derived_activity_formula` or evaluate the formula, so the earlier
numbers in this file no longer applied and every row below was measured again.

## Files

| File | Purpose |
|---|---|
| `base-views.sql` | Creates the two materialized views and their indexes, and one index on `teaching_allocation` |
| `drop-views.sql` | Removes them again (the "before" state) |
| `fast-*.sql` | The workload queries rewritten to use the views and indexes |
| `run-performance.bash` | Runs every query with `EXPLAIN ANALYZE` before and after, and reports index usage |
| `stale-view.sql` | Shows that a view is out of date after an insert, and times the refresh |
| `results/` | The full `EXPLAIN ANALYZE` plans, `before-*.txt` and `after-*.txt` |

## Choices

| Query (frequency) | Choice | Reason |
|---|---|---|
| Teachers with more than N instances in the current period (20/day) | `teacher_period_load_view` | Most frequent query. It aggregates millions of allocations into one row per teacher and period, which can be computed once and reused. |
| Teacher load per period (5/day) | `teacher_period_load_view` | Same grain as the query above, so one view serves both. |
| Planned hours per course instance (8/day) | `course_activity_view` | Replaces the joins of the original query. Did **not** pay off after the trigger change, see below. |
| Course instances with more than 15 % difference (3/day) | `course_activity_view` for the planned side | Rare, so it gets no view of its own. Allocations are summed per planned activity first, then joined with the view. |
| Allocated hours per teacher, one instance (12/day) | Existing indexes only | Returns a handful of rows. Every join already follows a primary key or `UNIQUE` index, so it is already fast. A view would only add refresh cost. |
| Allocated hours of one teacher (12/day) | New index `idx_teaching_allocation_employee`, filter on `employment_id` | Without the index, all 3.2 million allocations are scanned to find one teacher's rows. |

Indexes on the views: `(academic_year, period_number)` on both views, because every query on
them filters by year and period. Unique indexes on the view keys, which are needed for
`REFRESH MATERIALIZED VIEW CONCURRENTLY`.

## Results (EXPLAIN ANALYZE, median of 3 runs)

| Query | Before | After | Speed-up |
|---|---|---|---|
| Teachers with more than N instances (20/day) | 1,482.7 ms | 73.6 ms | 20x |
| Teacher load per period (5/day) | 4,383.0 ms | 1,040.5 ms | 4.2x |
| Planned hours per course instance (8/day) | 1,981.7 ms | 2,295.8 ms | none |
| Allocated hours, one course instance (12/day) | 0.9 ms | 0.6 ms | none needed |
| Allocated hours, one teacher (12/day) | 2,387.4 ms | 1.9 ms | 1,300x |
| More than 15 % difference (3/day) | 11,320.1 ms | 8,045.0 ms | 1.4x |

Creating the views and indexes (`base-views.sql`) takes about 30 s. Every fast query returns
exactly the same rows as its original version in `query_scripts/` (checked with `EXCEPT` in both
directions, all six pairs, 0 differing rows).

What changed in the plans:

- **One teacher**: before, a parallel sequential scan of the whole `teaching_allocation` table
  (1,066,859 rows per worker over 3 workers) plus hash joins. After, an index scan on
  `employee_employment_id_key` finds the employee, and `idx_teaching_allocation_employee` returns
  their 27 allocations.
- **Teacher load and more than N**: before, scanning and grouping the whole allocation table.
  After, a bitmap index scan on `teacher_period_load_view_year_period` reads the 383,399
  precomputed rows of the year.
- **Planned hours**: no gain any more. The formula and the `derived_activity_formula` join used to
  be the expensive part, and the project 1 triggers removed them from the base query as well.
  What is left is grouping the 566,769 planned activities of the year, which costs the same from
  the view as from the base tables, and the view has to find those rows among 2.27 million through
  a bitmap index scan. The 314 ms difference is within run-to-run variation; a later single run of
  the fast query gave 1,669 ms against a 1,981 ms baseline.
- **One course instance**: already fast before. PostgreSQL moves the `HAVING course_code = 'IV1351'`
  condition into the scan, because it only refers to a grouping column, and uses
  `course_course_code_key`.

## An index PostgreSQL does not use

`course_activity_view_planned_activity`, the unique index on `planned_activity_id`, had 0 scans
during the measured workload (`pg_stat_user_indexes`). The mismatch query joins the whole view
with the summed allocations, that is all 2.27 million rows. When almost every row is needed, the
planner estimates a sequential scan plus a hash join as cheaper than 2.27 million index lookups,
since an index scan normally causes random reads.

Forcing the index (`enable_seqscan` and `enable_hashjoin` off) gives a merge join that ran in
6.8 s instead of 9.7 s in one measurement. The planner's estimate was too pessimistic here: the
view was just created in `planned_activity_id` order, so the index scan reads the table almost
sequentially, and the data is cached in memory. The planner's default costs assume random reads
from disk. The index is still needed, because `REFRESH MATERIALIZED VIEW CONCURRENTLY` requires a
unique index. `teacher_period_load_view_key` was also unused by the queries, for the same reason.

Index scan counts during the measured "after" runs:

| Table or view | Index | Scans |
|---|---|---|
| `course_activity_view` | `course_activity_view_planned_activity` | 0 |
| `course_activity_view` | `course_activity_view_year_period` | 3 |
| `teacher_period_load_view` | `teacher_period_load_view_key` | 0 |
| `teacher_period_load_view` | `teacher_period_load_view_year_period` | 6 |
| `teaching_allocation` | `idx_teaching_allocation_employee` | 15 |

## Out-of-date view and refresh

`stale-view.sql` adds one allocation for a teacher who has one course instance in 2026 P2, in a
transaction that is rolled back afterwards:

| Step | Base tables | `teacher_period_load_view` |
|---|---|---|
| Before the insert | 1 course instance | 1 course instance, 80.6 h |
| After the insert | 2 course instances | 1 course instance, 80.6 h (out of date) |
| After `REFRESH MATERIALIZED VIEW` | 2 course instances | 2 course instances, 116.6 h |

Refresh times:

| View | `REFRESH` | `REFRESH ... CONCURRENTLY` |
|---|---|---|
| `teacher_period_load_view` | 11.6 to 12.2 s | 21.4 s |
| `course_activity_view` | 9.4 s | 27.6 s |

A plain refresh locks the view, so queries on it wait for up to 12 s. `CONCURRENTLY` lets queries
continue, but it takes two to three times as long, because it compares the new result with the
old one.

## When it is worth it

- A materialized view pays off when a query is frequent and expensive, and the data changes
  rarely. `teacher_period_load_view` saves about 1.4 s on 20 queries and 3.3 s on 5 queries a day,
  about 45 s in total, for one 12 s refresh. If allocations change many times a day and the view
  must always be current, refreshing after every change would cost more than it saves.
- `course_activity_view` is the counter-example. It was justified when the planned hours had to be
  computed from the formula, and the trigger change in project task 1 removed that justification.
  It still serves the mismatch query, but for the planned hours report it now only costs refresh
  time and disk space. This is a good illustration that an optimisation is only valid for the
  workload and the schema it was measured against.
- An index pays off when a query returns few rows out of many. `idx_teaching_allocation_employee`
  turns 2.4 s into 2 ms. It also speeds up the allocation trigger, which looks up the same column.
  Its cost is extra work on every insert into `teaching_allocation` and extra disk space.
- If the workload changed, for example to many allocation changes during planning and few reports,
  the views should be refreshed on a schedule, such as nightly, or dropped in favour of indexes.
  If reports had to be exact at every moment, the views could not be used for them.
