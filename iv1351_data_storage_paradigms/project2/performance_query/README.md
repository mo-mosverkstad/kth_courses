# performance_query

Everything about making the workload queries fast: the chosen solution, the candidates that
were considered and rejected, the scripts that measure them, and the saved measurements.

The unoptimised queries themselves live one level up, in `../query_scripts/`.

## Layout

Each candidate is one self-contained SQL file. Candidate D is the chosen solution, so there
is no separate file for it: applying candidate D is what creates the views and the index,
and applying candidate A is what removes them again.

```
performance_query/
    RESULTS.md            >>> all measurements, comparison and analysis <<<
    refresh-stale-view.sql  shows a view going out of date, then refreshes it and times it
    run-performance.bash  measures all 6 workload queries before and after
    queries/              the 6 workload queries rewritten to use the views
    results/              saved EXPLAIN ANALYZE plans and summary of the above

    candidates/
        candidate-a-no-optimisation.sql          A  nothing, and the way back to it
        candidate-b-index-course-instance.sql    B  one plain index
        candidate-c-course-activity-view.sql     C  view per planned activity
        candidate-d-course-instance-views.sql    D  views per course instance (chosen)
        candidate-e-data-driven-activities.sql   E  like D, activity names data driven
        queries/          the 3 queries that read candidates C and E
        run-candidates.bash  measures A to E against each other
        results/          saved plans and summary of the comparison
```

**All numbers and the analysis are in [RESULTS.md](RESULTS.md).**

## The four candidates

| | What it adds | Queries it uses | Cost |
|---|---|---|---|
| A | nothing | `../query_scripts/*.sql` | none |
| B | index on `course_instance (academic_period_id)` | `../query_scripts/*.sql` | ~9 MB, no refresh |
| C | `course_activity_view`, one row per planned activity | `candidates/queries/cand-*-activity-grain.sql` | 295 MB, 13 s refresh |
| D | `course_instance_planned_view`, `course_instance_mismatch_view`, `teacher_period_load_view` | `queries/fast-*.sql` | 88 MB + 166 MB, 25 s refresh |
| E | as D, but `course_instance_planned_json_view` stores a JSONB map instead of fixed columns | `candidates/queries/cand-planned-hours-json.sql`, `queries/fast-mismatches.sql` | 134 MB + 166 MB |

Candidate E exists because D hardcodes the seven activity names, so a new teaching activity
would get no column and would be missing from `total_hours`. E is data driven instead, and
the comparison measures what that costs.

Each candidate file starts by dropping everything the other candidates create, so any
candidate can be applied at any time without caring which one is active:

```bash
sudo -u postgres psql -d course_database -f candidates/candidate-b-index-course-instance.sql
```

## How to run the measurements

```bash
# all 6 workload queries, before (candidate A) and after (candidate D), plus index usage
bash run-performance.bash

# A, B, C and D compared on the 2 queries where the choice was not obvious
bash candidates/run-candidates.bash

# out-of-date view and refresh timing, needs candidate D to be applied
sudo -u postgres psql -d course_database -f refresh-stale-view.sql
```

Both bash scripts need `sudo -u postgres`, take a few minutes, write their output to
`results/summary.txt` in their own folder, and leave the database with the chosen solution
applied.

## Where the numbers are

- `RESULTS.md` for every number, the comparison and the analysis
- `results/summary.txt` and `results/{before,after}-*.txt` for the raw plans of the solution
- `candidates/results/summary.txt` and `candidates/results/{A,B,C,D,E}-*.txt` for the comparison

Run-to-run variation on this machine is 20 to 40 %, so every reported figure is the median
of three runs, and conclusions are only drawn from differences much larger than that.
