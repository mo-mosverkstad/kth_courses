# Performance results, comparison and analysis

All measurements in one place: the chosen solution against no optimization, the five
optimizations against each other, index usage, refresh cost, and the conclusions drawn from them.

- Environment: PostgreSQL 16, Ubuntu on WSL 2, 8 cores, 15 GB RAM
- Dataset: 3,200,577 teaching allocations, 2,267,074 planned activities, 400,072 course
  instances, 450,033 employees
- Every figure is the **median of 3 runs** of `EXPLAIN ANALYZE`
- Raw evidence: `results/`
- Insert and bulk load performance is a separate topic, in `../insertion-performance.md`

---

## 1. The workload, and what was done for each query

| Query | Frequency | What was added | Why |
|---|---|---|---|
| Teachers above a threshold in a period | 20/day | `teacher_period_load_view` | Most frequent query. Collapses millions of allocations into one row per teacher and period. |
| Teacher load per period | 5/day | `teacher_period_load_view` | Same grain as the query above, so one view serves both. |
| Planned hours per course instance | 8/day | `course_instance_planned_view` | One row per course instance, hours already summed per activity, so no grouping is left. |
| Mismatch above 15 % | 3/day | `course_instance_mismatch_view` | Both sides already summed per course instance, so the query only compares them. |
| Allocated hours per teacher, one instance | 12/day | nothing | Already 0.9 ms. Every join follows a primary key or `UNIQUE` index. A view would only add refresh cost. |
| Allocated hours of one teacher | 12/day | `idx_teaching_allocation_employee` | Without it, all 3.2 million allocations are scanned to find one teacher's rows. |

## 2. The solution against no optimization

Measured by `run-performance.bash`. Plans in `results/before-*.txt` and `results/after-*.txt`.

| Query (frequency) | Before | After | Speed-up |
|---|---|---|---|
| Teachers above a threshold (20/day) | 1,002.3 ms | 56.8 ms | 18x |
| Teacher load per period (5/day) | 2,950.4 ms | 540.6 ms | 5.5x |
| Planned hours per course instance (8/day) | 1,696.6 ms | 86.6 ms | 20x |
| Allocated hours, one course instance (12/day) | 0.9 ms | 0.4 ms | not needed |
| Allocated hours, one teacher (12/day) | 3,235.7 ms | 0.5 ms | 6,600x |
| Mismatch above 15 % (3/day) | 8,782.0 ms | 159.8 ms | 55x |

Building all three views and the index takes about 24 s. Every optimized query returns
exactly the same rows as its original, checked with `EXCEPT` in both directions for all six
pairs, 0 differing rows.

What the plans show:

- **One teacher**: before, a parallel sequential scan of the whole allocation table. After, an
  index scan on `employee_employment_id_key` finds the employee and
  `idx_teaching_allocation_employee` returns their 27 allocations.
- **Teacher load and above a threshold**: before, scanning and grouping the whole allocation
  table. After, a bitmap index scan reads 383,399 precomputed rows of the year.
- **Planned hours**: before, grouping 566,769 planned activities. After, reading 100,018
  already aggregated rows.
- **One course instance**: already fast. PostgreSQL pushes `HAVING course_code = 'IV1351'`
  into the scan, because it only refers to a grouping column, and uses `course_course_code_key`.

## 3. The five optimizations

Measured by `optimizations/run-optimizations.bash` on all six workload queries. Plans in
`results/`, 30 files, six per optimization.

Which query text each optimization runs depends on what it actually provides. A and B add no
view, so they run the original queries in `query_scripts/`. C provides a view only for the
planned hours and the mismatch report, so the other four queries run the originals as well,
since there is no view for them to read. D runs the rewritten queries in `queries/`, and E
runs the same except for the planned hours, which unpacks the JSONB map.

| State | What it adds | Queries |
|---|---|---|
| A | nothing | `../query_scripts/*.sql` |
| B | index on `course_instance (academic_period_id)` | `../query_scripts/*.sql` |
| C | `course_activity_view`, one row per planned activity | `queries/query-c-*.sql` |
| D | `course_instance_planned_view` + `course_instance_mismatch_view`, one row per course instance | `queries/query-d-*.sql` |
| E | as D, but planned hours in a JSONB map keyed by activity name | `queries/query-e-planned-hours.sql` |

Execution time in ms, median of 3 runs, from the run saved in `results/summary-optimizations.txt`
and `results/measurements.csv`. The fastest optimization per query is in bold.

| Query (frequency) | A | B | C | D | E |
|---|---|---|---|---|---|
| Teachers above a threshold (20/day) | 1,258.6 | 1,283.7 | 1,920.6 | **41.2** | 53.2 |
| Allocated hours, one instance (12/day) | 0.89 | 1.06 | 0.82 | 0.69 | **0.56** |
| Allocated hours, one teacher (12/day) | 3,401.6 | 2,429.0 | 1,945.7 | 1.06 | **0.74** |
| Planned hours per instance (8/day) | 2,725.9 | 1,747.9 | 1,882.7 | **89.2** | 138.8 |
| Teacher load per period (5/day) | 5,071.6 | 4,389.1 | 4,169.4 | **519.2** | 558.4 |
| Mismatch above 15 % (3/day) | 12,991.2 | 9,630.0 | 7,176.1 | **177.0** | 216.3 |
| Build time (s) | 4.2 | **0.7** | 11.3 | 25.2 | 29.9 |

Storage:

| State | Objects | Total |
|---|---|---|
| A | – | – |
| B | index on `course_instance` | ~9 MB |
| C | `course_activity_view`, 2,267,074 rows | 295 MB |
| D | planned 60 MB + mismatch 28 MB + teacher load 166 MB | 254 MB |
| E | planned JSON 106 MB + mismatch 28 MB + teacher load 166 MB | 300 MB |

### How large is the measurement error

D and E use **identical objects and identical query text for five of the six queries**, so any
difference on those five is pure run-to-run variation. Measured: 41.2 against 53.2 ms, 0.69
against 0.56 ms, 1.06 against 0.74 ms, 519.2 against 558.4 ms, 177.0 against 216.3 ms. That is
a built-in control, and it says the error bar is roughly 30 % even between two states that are
byte for byte the same. Only differences much larger than that are meaningful.

### Replication across four runs

The planned hours query, measured four times:

| State | run 1 | run 2 | run 3 | run 4 |
|---|---|---|---|---|
| A | 2,109.1 | 2,555.9 | 3,139.0 | 2,725.9 |
| B | 1,455.5 | 2,208.3 | 1,794.0 | 1,747.9 |
| C | 1,683.8 | 3,173.8 | 3,239.5 | 1,882.7 |
| D | 112.7 | 212.2 | 254.6 | 89.2 |
| E | – | 204.9 | 165.3 | 138.8 |

Absolute times vary by 20 to 40 %. The separation between A, B, C on one side and D, E on the
other is a factor of ten or more in every run, so that conclusion is solid. The ordering
*within* the A, B, C group is not stable across runs and no conclusion is drawn from it, and
the same is true of D against E.

## 4. Analysis: why the optimizations behave as they do

**The grain of the view decides everything.** A, B and C are all the same order of magnitude,
between 1.6 s and 2.5 s. Only D and E are different, by more than a factor of ten. The reason
is that A, B and C all still group the 566,769 planned activities of the academic year on
every execution. In 2025 there are 100,018 course instances, so the grouping collapses 5.67
rows into 1, and that work is the dominant cost. An index only makes finding the rows cheaper,
and `course_activity_view` only removes the joins. Neither removes the grouping. D and E store
one row per course instance, which is the grain of the result, so there is nothing left to
aggregate.

**A, B and C cannot be separated from each other.** This is worth stating plainly, because it
is tempting to read a ranking into the numbers. Across four runs the order of A, B and C
changes every time. In the saved run C is faster than A on four of the six queries; in the
previous run it was slower than A on three of them. optimization B improved the most frequent
query by a factor of nearly three in one run and not at all in another. None of these
differences survives repetition, and the reason is structural: all three optimizations still
group the 566,769 planned activities of the academic year on every execution, so they differ
only in how cheaply they reach those rows, which is the small part of the cost.

The one difference within that group that *does* replicate is the mismatch report, where C is
the fastest of the three in every run, 7,176 ms against 12,991 for A in the saved run. That is
the one query which genuinely joins 2.27 million rows, which is the work C removes.

**The cheap optimization is not worse than the expensive one.** B costs about 9 MB and no refresh
at all, against C's 295 MB and 13 s per refresh, and it is indistinguishable from C across the
workload. Spending 33 times the storage and a refresh cycle bought nothing measurable outside
the mismatch report.

**The query that needed nothing confirms it needed nothing.** The allocated hours for one
course instance stays at about 1 ms in all five optimizations, from 0.78 to 1.34 ms, even though
it runs 12 times a day. Every join already follows a primary key or a `UNIQUE` index. Adding
a view for it would have added refresh cost for no gain, and the measurement across all five
states is the evidence for that choice.

**Denormalising into a wider table costs I/O.** `course_activity_view` has exactly as many
rows as `planned_activity`, 2,267,074, but it is *larger* than the table it replaces, 295 MB
against 213 MB, because each row carries a copy of the course code, instance ID and activity
name. Row width is 67 bytes against 16. `EXPLAIN (ANALYZE, BUFFERS)` on the planned hours
query shows the consequence: reading through the view takes 30,047 page reads against 25,456
for the base tables, and spills 9,065 temp pages during aggregation against 651, because the
wider rows exhaust `work_mem` sooner.

**Arithmetic was never the bottleneck.** The base query multiplies `planned_hours` by the
multiplication factor for all 566,769 rows; the C query reads a column where the factor is
already applied and does no multiplication at all. The version doing the arithmetic is the
faster one. The cost is reading rows and grouping them, not computing with them.

**`course_activity_view` was not useless everywhere.** It is the best of A, B and C for the
mismatch query in all three runs, because that query genuinely does join 2.27 million rows and
the view removes those joins. It is only worthless for the planned hours, where the work it
removed had already been removed by the triggers of project task 1 that store the derived
hours in `planned_activity`.

**optimization E costs disk, not query time.** D writes the seven activity names into the view as
string literals, so a teaching activity added to `teaching_activity` afterwards gets no column
and is not counted in `total_hours` either. That contradicts the requirement in the project
description that the database must be flexible enough to add more activities. E removes every
activity name from the view by storing a JSONB map keyed by whatever names exist in the table.

The cost of that flexibility is smaller than it first appeared. On the planned hours query E
measured 204.9 ms against D's 212.2 ms in one run and 165.3 ms against 254.6 ms in another, so
on query time the two are indistinguishable. The real price is storage: the planned hours view
grows from 60 MB to 106 MB, because the activity name is repeated as a JSON key on every one
of the 400,072 rows instead of being implied by the column layout. The build is also about
two seconds longer.

**Why D was chosen.** It uses less disk, 254 MB against 300 MB in total, and its planned hours
view can be read without unpacking a JSONB value, which keeps the query simpler. On speed
there is nothing to choose between them.

That makes the choice a close one, and it would flip if teaching activities were ever added.
D would silently exclude a new activity from both its columns and its total and would have to
be rewritten, while E would include it with no change to the view and one more line in the
query. With seven activities that have not changed, D was kept and the brittleness is
documented rather than hidden.

## 5. Indexes that PostgreSQL does not use

Scan counts from `pg_stat_user_indexes`, with the statistics reset immediately before the
measured runs so the counts belong to this workload only.

| Table or view | Index | Scans |
|---|---|---|
| `course_instance_planned_view` | `course_instance_planned_view_key` | **0** |
| `course_instance_planned_view` | `course_instance_planned_view_year_period` | 3 |
| `course_instance_mismatch_view` | `course_instance_mismatch_view_key` | **0** |
| `teacher_period_load_view` | `teacher_period_load_view_key` | **0** |
| `teacher_period_load_view` | `teacher_period_load_view_year_period` | 6 |
| `teaching_allocation` | `idx_teaching_allocation_employee` | 15 |

Three indexes are never used, and all three are the unique keys of the views. No query looks
up a single row by a view key. The mismatch query reads the whole view to compare every course
instance, and when almost every row is needed the planner estimates a sequential scan as
cheaper than 400,072 index lookups, since index scans normally cause random reads. The two
queries that filter by time use the `(academic_year, period_number)` indexes instead.

The three unused indexes are still necessary, because `REFRESH MATERIALIZED VIEW CONCURRENTLY`
requires a unique index on the view. They exist for the refresh, not for the queries, which is
a good example of an index motivated by something other than read performance.

## 6. Out-of-date view and refresh cost

`refresh-stale-view.sql` inserts one allocation for a teacher who has one course instance in 2026 P2,
inside a transaction that is rolled back afterwards.

| Step | Base tables | `teacher_period_load_view` |
|---|---|---|
| Before the insert | 1 course instance | 1 course instance, 80.6 h |
| After the insert | 2 course instances | 1 course instance, 80.6 h (out of date) |
| After `REFRESH MATERIALIZED VIEW` | 2 course instances | 2 course instances, 116.6 h |

| View | `REFRESH` | `REFRESH ... CONCURRENTLY` |
|---|---|---|
| `teacher_period_load_view` | 11.4 s | 16.7 s |
| `course_instance_planned_view` | 5.0 s | 10.2 s |
| `course_instance_mismatch_view` | 8.8 s | 15.7 s |

A plain refresh locks the view, so queries wait up to 11 s. `CONCURRENTLY` lets them keep
reading the old content but takes about twice as long, because it compares the new result with
the old one. Refreshing all three costs about 25 s in total.

## 7. When is it worth the cost

- **A materialized view pays off when a query is frequent and expensive and the data changes
  rarely.** `teacher_period_load_view` saves about 0.95 s on 20 queries and 2.4 s on 5 queries
  a day, roughly 31 s, for one 11 s refresh. If allocations changed many times a day and the
  reports had to be current, refreshing after every change would cost more than it saves.
- **An index pays off when a query returns few rows out of many.**
  `idx_teaching_allocation_employee` turns 3.2 s into 0.5 ms, and it also speeds up the
  allocation trigger, which filters on the same column. Its cost is extra work on every insert
  into `teaching_allocation`, which the bulk load measurements in
  `../insertion-performance.md` quantify.
- **An optimization is only valid for the schema and workload it was measured against.**
  `course_activity_view` was justified when the planned hours had to be computed from the
  formula on every read. The triggers added in project task 1 moved that work to write time
  and silently invalidated the view, which only showed up because it was measured again.
- **If the workload changed**, for example to many allocation changes during planning and few
  reports, the views should be refreshed on a schedule rather than on demand, or dropped in
  favour of indexes. If the reports had to be exact at every moment, materialized views could
  not be used for them at all, and optimization B would be the only acceptable option.

## 8. Where the raw evidence is

| Path | Contents |
|---|---|
| `results/summary-performance.txt` | printed before/after summary and index usage |
| `results/before-*.txt`, `results/after-*.txt` | full plans, 6 queries before and after |
| `results/summary-optimizations.txt` | printed A to E comparison |
| `results/measurements.csv` | `optimization,query,milliseconds`, one line per measurement |
| `results/{A,B,C,D,E}-*.txt` | full plans, every optimization and every workload query |
| `../insertion-performance.md` | bulk load: trigger with a temporary index against disabled trigger |
