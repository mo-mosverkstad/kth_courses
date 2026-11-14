# Bulk insertion: index vs. disabled trigger

The insert script `db-insertion-postgresql.sql` generates about 9.9 million rows, of which
3,200,577 are teaching allocations. Every allocation fires the trigger
`trigger_4_instances_each_study_period`, which counts the teacher's existing allocations in the
same academic period. This document compares two ways of making that insert finish in a
reasonable time.

## Test setup

- PostgreSQL 16 on Ubuntu (WSL 2), 8 CPU cores, 15 GB RAM
- Each run starts from an empty schema: `clean-postgresql.sql`, `logical-physical-postgresql.sql`,
  `trigger-postgresql.sql`, then the insert script
- Timed with `sql_scripts/benchmark.bash <insert-script>`, which reports the time of the insert
  script, the whole build, and every statement (`\timing on`)
- Both scripts generate identical data; they only differ around the `teaching_allocation` insert
- Script 2 was run first, then the database was cleaned and script 1 was run

## The alternatives

| | Script 1 | Script 2 |
|---|---|---|
| File | `db-insertion-postgresql-index.sql` | `db-insertion-postgresql-notrigger.sql` |
| Before the allocation insert | `CREATE INDEX tmp_teaching_allocation_employee ON teaching_allocation (employee_id);` | `ALTER TABLE teaching_allocation DISABLE TRIGGER trigger_4_instances_each_study_period;` |
| After the allocation insert | `DROP INDEX tmp_teaching_allocation_employee;` | `ALTER TABLE teaching_allocation ENABLE TRIGGER trigger_4_instances_each_study_period;` |
| Rule checked during the load | yes, by the trigger, for every row | no, the generator is trusted |

Both scripts leave the same final schema: no extra index, and the trigger enabled.

## Results

| Measurement | Script 1 (index) | Script 2 (no trigger) |
|---|---|---|
| `teaching_allocation` insert | 267.9 s | 44.3 s |
| Whole insert script | 382.7 s | 186.4 s |
| Whole build | 383.2 s | 187.3 s |

The other statements take the same time in both scripts within normal run-to-run variation
(for example `planned_activity` 27.5 s vs. 27.1 s, `employee_skill` 26.4 s vs. 31.0 s).
The five slowest statements:

| Statement | Script 1 | Script 2 |
|---|---|---|
| `INSERT INTO teaching_allocation` | 267.9 s | 44.3 s |
| `INSERT INTO planned_activity` | 27.5 s | 27.1 s |
| `INSERT INTO employee_skill` | 26.4 s | 31.0 s |
| `UPDATE employee` (supervisors) | 12.3 s | 17.9 s |
| `INSERT INTO employee` | 9.7 s | 11.6 s |

## Analysis

**Script 2 is about twice as fast overall, and the allocation insert is six times faster.**
Without the trigger, the insert only computes the rows and checks the two foreign keys through
primary-key indexes. With the trigger, every one of the 3.2 million rows runs three extra
queries. The difference, 223.6 s, is about 70 microseconds per row, which is the cost of the
trigger when its lookup can use the index.

**Without an index and with the trigger enabled, the load does not finish in practice.** This is
the variant that was tried first: it was cancelled after 36 minutes without having finished. The
trigger's count query has to scan the whole, growing `teaching_allocation` table for every new
row, so the total work grows with the square of the number of rows. One such lookup on the full
table takes 130 to 200 ms (measured with `EXPLAIN ANALYZE`, using a parallel sequential scan).
On average the table is half full during the load, so 3.2 million lookups take in the order of
3 to 10 days.

**The index turns each lookup into a few index reads.** With
`tmp_teaching_allocation_employee`, the trigger only reads the handful of allocations that the
teacher already has, so the cost per row stays constant while the table grows. Creating the
index on the empty table takes 5 ms, and dropping it afterwards 5 ms. It is dropped so that the
final schema is exactly the one in `logical-physical-postgresql.sql`, which also keeps the
"before and after indexing" measurements of task 2 meaningful.

**Script 2 trades safety for speed.** With the trigger disabled, the database no longer checks
the rule that a teacher may teach at most four course instances per period during the load.
The data is only correct because the generator is designed to stay within the limit. This was
checked after the load:

| Check on script 2 data | Result |
|---|---|
| Allocations | 3,200,577 |
| Highest number of course instances per teacher and period | 4 |
| Teacher and period combinations above 4 | 0 |
| Trigger enabled again | yes (`tgenabled = O`) |

If the generator were changed and broke the rule, script 2 would load invalid data without any
error, and the trigger would not detect it afterwards, since triggers only check new or changed
rows. Script 1 would stop at the first invalid row.

## Conclusion

- **Script 1** is the safe choice: the database itself guarantees the rule for every row. With a
  temporary index, the cost of the trigger is acceptable, about 3.7 minutes for 3.2 million rows.
- **Script 2** is the fast choice for a bulk load of trusted, generated data. It halves the total
  time, but the rule must be verified separately with a query after the load.
- The index, not the trigger itself, is what decides whether the load is feasible at all. A
  trigger that looks up related rows should always have an index on the column it filters on.

The database currently contains the data loaded by script 1.
