Close, but not yet. Twelve of the statements map straight onto DAO methods; five things need changing first.

## What maps directly

| Statement | DAO method |
|---|---|
| planned hours by instance | `findPlannedHoursByCourseInstance` |
| allocated hours by instance | `findAllocatedHoursByCourseInstance` |
| average salary | `findAverageTeacherSalary` |
| `employee.id` by `employment_id` + `FOR NO KEY UPDATE` | `findEmployeeForUpdate` |
| `INSERT teaching_allocation` | `createAllocation` |
| `DELETE teaching_allocation` | `deleteAllocation` |
| `INSERT teaching_activity` | `createTeachingActivity` |
| `INSERT planned_activity` | `createPlannedActivity` |
| `UPDATE course_instance` | `updateCourseInstance` |

The duplication is already handled well: the allocation insert and the planned-hours sum each appear in two scripts but are one statement, so one DAO method serves both use cases.

## Five things to fix

**1. A missing read: the course instance itself.** Nothing returns `course_code`, `period_name`, `academic_year` for an instance. You need them for two reasons: the output table in the task has Course Code, Course Instance and Period columns, and the limit check needs the instance's academic period. Right now `course-instance-modification.sql` reads only `num_students`.

**2. `SET num_students = num_students + 100` can't go into the DAO as it stands.** Adding 100 is a business rule, and in SQL it sits in the integration layer. For the program the statement must be `SET num_students = ?`, with the model doing the arithmetic. Keep the `+ 100` version in the script if you like it for manual runs, but the DAO needs the parameterised one. This is also what makes the `FOR NO KEY UPDATE` read meaningful: read, compute in the model, write back.

**3. The limit check should not return a `COUNT`.** This is the one I'd change first, for two reasons.

The layering reason: task B says the controller reads the allocations, then decides. `COUNT(DISTINCT course_instance.id)` computes part of the rule in SQL, which is exactly what `seminar3-tips-and-tricks.pdf` section 2 tells you to keep out of the integration layer.

The correctness reason matters more. A bare count can't answer the actual question. If the teacher already has four instances **and one of them is the target instance**, another activity in that same instance is legal, and your trigger allows it. With only a count, the program would refuse it. Return the instance ids instead:

```sql
SELECT DISTINCT course_instance.instance_id
FROM teaching_allocation
INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
WHERE teaching_allocation.employee_id = ?
  AND course_instance.academic_period_id = ?
```

Then the model holds the set and answers "may this teacher take this instance". That's the same subtlety that broke the trigger twice.

**4. The display query is hardcoded to Exercise.** `WHERE teaching_activity.activity_name = 'Exercise'` is right for the script but the DAO wants it keyed on the course instance, so the same method can list allocations after an allocate, a deallocate, or a new activity.

**5. The salary read needs two decisions made.** Whether to pick the version valid during the instance's period rather than the latest, and whether the actual cost uses per-teacher salaries instead of the average. Both change this statement's shape, so decide before writing the DAO rather than after. Also note `AVG` on `NUMERIC` gave `50833.039928183044`; read it as `BigDecimal` and round in the model.

## Mechanical points when you translate

Literals become `?`. That's most of the work, and it's what turns `'2026-50000011'` into a parameter.

The locking and non-locking versions of the same read must be two separate prepared statements. You can't add `FOR NO KEY UPDATE` conditionally to one.

`\set`, `BEGIN`, `ROLLBACK` and `SAVEPOINT` do not belong in prepared statements. In JDBC the transaction comes from `setAutoCommit(false)` plus `commit()` and `rollback()`, and a savepoint is `Connection.setSavepoint()`. Those lines are psql scaffolding for manual runs only.

One statement per `prepareStatement` call. Your `.sql` files hold many statements separated by semicolons; each becomes its own prepared statement, created once in the DAO constructor.

The `COALESCE(..., 0)` you now have means the hours methods can return a plain `int` without null handling. Keep it.

Two statements are demo-only and get no DAO method: the lookup of `employment_id` by first and last name, and the deliberate over-limit insert.

If you want, I can write the DAO method signatures that follow from this, with the SQL parameterised, so you can see the full interface before implementing bodies.