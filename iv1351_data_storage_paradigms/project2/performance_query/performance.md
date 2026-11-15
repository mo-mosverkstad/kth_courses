# Make it fast: indexes and materialized views

Measured on PostgreSQL 16 (WSL 2, 8 cores, 15 GB RAM) with the big database from
`db-insertion-postgresql.sql` (3,200,577 allocations, 2,267,074 planned activities,
400,072 course instances, 450,033 employees).

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
| Planned hours per course instance (8/day) | `course_activity_view` | Stores one row per planned activity with the formula and multiplication factor already applied, so the query no longer joins seven tables. Its rows are not per teacher, so planned hours are never counted twice. |
| Course instances with more than 15 % difference (3/day) | `course_activity_view` for the planned side | Rare, so it gets no view of its own. Allocations are summed per planned activity first, then joined with the view. |
| Allocated hours per teacher, one instance (12/day) | Existing indexes only | Returns a handful of rows. Every join already follows a primary key or `UNIQUE` index, so it is already fast. A view would only add refresh cost. |
| Allocated hours of one teacher (12/day) | New index `idx_teaching_allocation_employee`, filter on `employment_id` | Without the index, all 3.2 million allocations are scanned to find one teacher's rows. The teacher is selected by `employment_id`, which is `UNIQUE` and therefore indexed, instead of by name. |

Indexes on the views: `(academic_year, period_number)` on both views, because every query on
them filters by year and period. Unique indexes on the view keys, which are needed for
`REFRESH MATERIALIZED VIEW CONCURRENTLY`.

## Results (EXPLAIN ANALYZE, median of 3 runs)

| Query | Before | After | Speed-up |
|---|---|---|---|
| Teachers with more than N instances (20/day) | 906.6 ms | 73.0 ms | 12x |
| Teacher load per period (5/day) | 3,173.3 ms | 521.7 ms | 6x |
| Planned hours per course instance (8/day) | 1,734.5 ms | 1,109.2 ms | 1.6x |
| Allocated hours, one course instance (12/day) | 0.8 ms | 0.5 ms | none needed |
| Allocated hours, one teacher (12/day) | 1,677.6 ms | 0.9 ms | 1,800x |
| More than 15 % difference (3/day) | 16,154.7 ms | 4,771.0 ms | 3.4x |

Creating the views and indexes (`base-views.sql`) takes about 20 s. Every fast query returns
exactly the same rows as its original version in `query_scripts/` (checked with `EXCEPT` in both
directions).

What changed in the plans:

- **One teacher**: before, a parallel sequential scan of all 3.2 million rows of
  `teaching_allocation` and hash joins over 800,000 rows. After, an index scan on
  `employee_employment_id_key` finds the employee, and `idx_teaching_allocation_employee` returns
  their 27 allocations.
- **Teacher load and more than N**: before, joining and grouping 1.5 million allocations of the
  year. After, a bitmap scan on `teacher_period_load_view_year_period` reads the precomputed rows of
  one year or one period.
- **Planned hours**: the view replaces seven joins and the formula, but the query still groups
  566,769 planned activities of the year, so the gain is smaller.
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
3.9 s instead of 4.8 s in one measurement. The planner's estimate was too pessimistic here: the
view was just created in `planned_activity_id` order, so the index scan reads the table almost
sequentially, and the data is cached in memory. The planner's default costs assume random reads
from disk. The index is still needed, because `REFRESH MATERIALIZED VIEW CONCURRENTLY` requires a
unique index. `teacher_period_load_view_key` was also unused by the queries, for the same reason.

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
| `teacher_period_load_view` | 8.6 to 9.0 s | 16.2 s |
| `course_activity_view` | 7.7 s | 20.2 s |

A plain refresh locks the view, so queries on it wait for up to 9 s. `CONCURRENTLY` lets queries
continue, but it takes about twice as long, because it compares the new result with the old one.

## When it is worth it

- A materialized view pays off when a query is frequent and expensive, and the data changes
  rarely. `teacher_period_load_view` saves about 0.8 s on 20 queries and 2.7 s on 5 queries a day,
  about 30 s in total, for one 9 s refresh. If allocations change many times a day and the view
  must always be current, refreshing after every change would cost more than it saves.
- An index pays off when a query returns few rows out of many. `idx_teaching_allocation_employee`
  turns 1.7 s into 1 ms. It also speeds up the allocation trigger, which looks up the same column.
  Its cost is extra work on every insert into `teaching_allocation` and extra disk space.
- If the workload changed, for example to many allocation changes during planning and few reports,
  the views should be refreshed on a schedule, such as nightly, or dropped in favour of indexes.
  If reports had to be exact at every moment, the views could not be used for them.
