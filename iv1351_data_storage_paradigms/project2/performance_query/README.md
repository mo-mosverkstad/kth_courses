# performance_query

Everything about making the workload queries fast: five optimizations, the queries
that read them, the scripts that measure them, and the saved measurements.

The unoptimized queries themselves live one level up, in `../query_scripts/`.

**All numbers and the analysis are in [RESULTS.md](RESULTS.md).**

## Naming

Two kinds of file, both named after the optimization they belong to:

| Pattern | Meaning |
|---|---|
| `optimization-<letter>-<what it adds>.sql` | creates the indexes and materialized views of that optimization |
| `query-<letter>-<workload query>.sql` | a workload query written to read that optimization |

So `optimization-d-course-instance-views.sql` creates the objects and `query-d-*.sql` read them.
optimizations A and B add no view, so they have no queries of their own; they run the originals
in `../query_scripts/`. optimization C has two queries, because only two of the six can use its
view. optimization E has one, because it differs from D in the planned hours only.

## Layout

Three directories, all at the same level, and the scripts you run at the top.

```
performance_query/
    README.md
    RESULTS.md                 all measurements, comparison and analysis
    run-performance.bash       the solution against no optimization
    run-optimizations.bash        all five optimizations against each other
    refresh-stale-view.sql     a view going out of date, then timed refresh

    optimizations/                what each optimization creates
        optimization-a-baseline.sql         A  nothing, and the way back to it
        optimization-b-index-course-instance.sql   B  one plain index
        optimization-c-course-activity-view.sql    C  view per planned activity
        optimization-d-course-instance-views.sql   D  views per course instance (chosen)
        optimization-e-data-driven-activities.sql  E  like D, activity names data driven

    queries/                   the workload queries, named after the optimization they read
        query-c-planned-hours.sql     the 2 queries that can read optimization C
        query-c-mismatches.sql
        query-d-threshold.sql         the 6 queries of optimization D
        query-d-one-instance.sql
        query-d-one-teacher.sql
        query-d-planned-hours.sql
        query-d-teacher-load.sql
        query-d-mismatches.sql
        query-e-planned-hours.sql     optimization E differs from D only here

    results/                   saved plans, summaries and measurements.csv
```

The three files at the top are the ones you execute. Everything inside a directory is either
consumed by them or produced by them.

## The five optimizations

| | What it adds | Queries it uses | Cost |
|---|---|---|---|
| A | nothing | `../query_scripts/*.sql` | none |
| B | index on `course_instance (academic_period_id)` | `../query_scripts/*.sql` | ~9 MB, no refresh |
| C | `course_activity_view`, one row per planned activity | `query-c-*.sql`, and the originals for the other four | 295 MB, 13 s refresh |
| D | `course_instance_planned_view`, `course_instance_mismatch_view`, `teacher_period_load_view` | `query-d-*.sql` | 254 MB, 25 s refresh |
| E | as D, but `course_instance_planned_json_view` stores a JSONB map instead of fixed columns | `query-e-planned-hours.sql` plus D's other five | 300 MB |

optimization E exists because D hardcodes the seven activity names, so a new teaching activity
would get no column and would be missing from `total_hours`. E is data driven instead, and
the comparison measures what that costs.

Each optimization file starts by dropping everything the other optimizations create, so any
Optimization can be applied at any time without caring which one is active:

```bash
sudo -u postgres psql -d course_database -f optimizations/optimization-b-index-course-instance.sql
```

## How to run the measurements

```bash
# the 6 workload queries, optimization A against optimization D, plus index usage
bash run-performance.bash

# all 6 queries against all 5 optimizations
bash run-optimizations.bash

# out-of-date view and refresh timing, needs optimization D to be applied
sudo -u postgres psql -d course_database -f refresh-stale-view.sql
```

Both bash scripts need `sudo -u postgres`, take several minutes, write their output into
`results/`, and leave the database with optimization D applied.

## Where the numbers are

| Path | Contents |
|---|---|
| `RESULTS.md` | every number, the comparison and the analysis |
| `results/summary-performance.txt` | printed output of `run-performance.bash` |
| `results/summary-optimizations.txt` | printed output of `run-optimizations.bash` |
| `results/measurements.csv` | `optimization,query,milliseconds`, one line per measurement |
| `results/before-*.txt`, `results/after-*.txt` | plans, solution against no optimization |
| `results/<letter>-<query>.txt` | plans, one per optimization and workload query |

Run-to-run variation on this machine is 20 to 40 %, so every reported figure is the median
of three runs, and conclusions are only drawn from differences much larger than that.
