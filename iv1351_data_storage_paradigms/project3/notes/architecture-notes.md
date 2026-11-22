# Architectural notes, IV1351 project task 3

Working notes on the decisions taken while building `courseDb`, and the reasoning behind
them. This is raw material for the report, not report prose. The headings say which
chapter each item belongs in.

---

## For the Method chapter

### Order of work: SQL first, then DAOs

Every statement was written and run manually in `sql_scripts` before any Java was
written. Each script corresponds to one of the four required functions, and each
statement in a script corresponds to one method in a DAO. The reason is that a prepared
statement is hard to debug through the application: a wrong join or a missing
multiplication factor surfaces as a wrong number rather than as an error. Running the
statement in `psql` first separates "is the SQL right" from "is the Java right".

The translation from script to DAO is mechanical: string literals become `?` parameters,
and `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` and `\set` are dropped, because in JDBC
those are expressed by `setAutoCommit(false)`, `commit()`, `rollback()` and
`setSavepoint()` rather than by SQL text.

### Scripts are repeatable

Each script that changes data runs inside `BEGIN ... ROLLBACK`. The first version of
`course-instance-modification.sql` instead ended with a manual `UPDATE` resetting the
old value, which is unsafe: `psql -f` runs each statement in its own transaction, so a
failure halfway through commits the change and never reaches the reset. This was verified
by running two conflicting inserts from a file, where the first one persisted.

### Tools

PostgreSQL 16 on Ubuntu in WSL, `psql` for manual statements, Maven with the PostgreSQL
JDBC driver 42.2.16 for the program, Java 17.

---

## For the Result chapter

### Layers and packages

```
se.kth.iv1351.startup       Main
se.kth.iv1351.view          View, BasicView
se.kth.iv1351.controller    CourseDBController
se.kth.iv1351.integration   DatabaseConnection, DAOs, exceptions
se.kth.iv1351.config        Config
```

The view calls only the controller, the controller calls only the integration layer and
the model, and the integration layer calls only the database. `View` is an interface so
that the command line view can be replaced without touching the controller.

### Transaction boundaries belong to the controller

`DatabaseConnection` sets `setAutoCommit(false)` once, and exposes `commit()` and
`rollback()`. No DAO method commits. The controller calls `commit()` when a use case
succeeds and `rollback()` when it fails.

This differs from the JDBC bank example, where most DAO methods end with
`connection.commit()`. The example shows why that doesn't scale: to support `withdraw`,
`findAccountByAcctNo` had to take a `boolean lockExclusive` parameter whose documented
meaning is partly "do not commit when this method returns". A flag that tells a DAO
whether to commit is the design conceding that the decision belongs to the caller. The
same method also contains a defect that follows from the mixed approach: the commit is
placed after an `if (result.next()) { return ...; }`, so when the account is found the
commit is never reached and the transaction is left open, contrary to its javadoc.

Three of the four required functions need a transaction spanning several DAO calls:

- increasing the number of students: locking read, then calculation, then update
- allocating a teacher: locking read of the employee, read of the allocations, decision,
  then insert
- adding the Exercise activity: three inserts that must either all happen or none

If each DAO call committed, the first two would lose the lock before the write, which is
exactly the lost update anomaly described in `seminar3-tips-and-tricks.pdf`, and the
third could leave an orphan teaching activity behind.

### Read-only operations are also committed

With auto-commit off, a transaction is open from the first statement whether it writes or
not. Leaving it open holds the snapshot, which blocks vacuum, and holds any locks taken.
Therefore every use case ends with `commit()` or `rollback()`, including the ones that
only read.

### Locking

Two locking reads are used, both with `FOR NO KEY UPDATE` rather than `FOR UPDATE`, since
the primary key is not updated and the weaker lock still prevents the lost update while
allowing inserts that reference the locked row.

The lock for the allocation rule is taken on the `employee` row, not on the allocation
rows. This is not obvious and is worth stating: the decision is based on rows that may
not exist yet, and a row lock cannot protect rows that do not exist. A teacher with no
allocations has nothing to lock, so two concurrent transactions would both read zero
allocations and both insert. Locking the employee row serialises the decision instead.

### No business logic in the integration layer

DAO method names are restricted to `find`, `create`, `update` and `delete`, as suggested
in the tips document. The allocation rule is enforced in the model: the DAO returns the
course instances the teacher already occupies, and the model decides whether another one
is allowed. Returning a `COUNT` from the DAO was rejected for two reasons. It computes
part of the rule in SQL, and more importantly a count cannot answer the question: if the
teacher already occupies the target course instance, a further activity inside that same
instance is allowed, so the set of occupied instances is needed, not their number.

### Exceptions

`java.sql.SQLException` never leaves the integration layer. The DAOs wrap it in
`CourseDBException` and `DatabaseConnection` wraps it in `DatabaseConnectionException`.
Both carry a message and the cause via `super(message, cause)`, so the original stack
trace survives. `DatabaseConnection.getConnection()` is package-private, so the raw
`Connection` cannot leave the integration layer and no other layer can execute SQL.

### Hours are decimal, not integer

`teaching_activity.multiplication_factor` is `NUMERIC(4,2)`, so hours multiplied by a
factor are not integers. Reading the sum with `getInt` truncated 645.60 to 645, losing 36
minutes on a single course instance, and the error would compound when multiplied by a
salary. The DAO therefore returns `BigDecimal`.

---

## For the Discussion chapter

### What the teaching cost does and does not include

The project description restricts this deliberately:

> The database will not be used for any financial purpose like bookkeeping, salary or
> bank contacts. What is written above regarding salary is only about calculating the
> total teaching cost of a course instance or a department over a particular period.

A real cost of running a course would include premises, equipment, maintenance and
subsidies. The requirement is teaching cost only, and "the database must store all data
described above ... but no other data" forbids adding tables for the rest. Worth stating
explicitly so the limitation reads as a decision rather than an oversight.

### Average salary versus actual salary

The task offers an average salary "for computation of the planned cost". That restriction
is meaningful: when hours are only planned, the teachers are not yet known, so an average
is the only option. The actual cost is computed from `teaching_allocation`, where the
allocated teachers are known, so each teacher's own salary could be used instead. Using
the average on both sides is simpler but uses less of the available data.

A second decision concerns salary versions. `employee_salary` holds one row per change,
and roughly a third of the 450 033 employees have more than one row. Taking the latest
version per employee with `DISTINCT ON` avoids a bias that a plain `AVG` over all salary
rows would introduce, since employees with more salary changes would weigh more heavily.
A stricter version would pick the salary valid during the course instance's academic
period, using `valid_from`, rather than the latest one.

Turning a monthly salary into an hourly cost requires a divisor that the requirements do
not give. A constant of 160 working hours per month was assumed. This must be stated as
an assumption, since it scales the entire result.

### Isolation level, and a claim not to make

It would be wrong to claim that putting the three cost queries in one transaction makes
their results mutually consistent. PostgreSQL's default isolation is Read Committed,
where each statement takes a fresh snapshot, so another session can commit between the
planned hours query and the allocated hours query. A consistent view would require
`REPEATABLE READ`. What one transaction does guarantee is that locks are held across the
read-modify-write sequences, which is what the lost update problem requires.

### Concurrency that is not handled

Two concurrent transactions each adding a fifth course instance for the same teacher are
prevented by the lock on the employee row. The database trigger is a second line of
defence. Neither protects against the rule being broken from another direction: updating
`planned_activity.course_instance_id` moves a planned activity with its allocations into
a different course instance, and updating `course_instance.academic_period_id` moves a
whole instance into another period. Both can push a teacher over the limit without any
row of `teaching_allocation` being touched. Triggers were added for these two cases in
task 1; the program does not check them, since it never performs those updates.

### Redundancy between the program and the triggers

The allocation rule is enforced twice, in the model and by a trigger. This is intentional.
The program needs its own check so it can refuse the operation with a readable message
instead of surfacing a raw SQL error, and the trigger protects the database against any
client that does not perform the check. The cost is that the rule exists in two places
and could drift apart.

### Not found versus zero

An aggregate query over a course instance that does not exist returns 0 rather than an
error, because `COALESCE` turns the empty sum into a number. In `psql` this is obvious,
in the program it is not: a mistyped course instance identifier would be reported as a
teaching cost of 0 KSEK. The same applies to the allocation rule check, where a
non-existent instance makes the period subquery `NULL`, the count 0, and the teacher
appear free. The chosen solution is to read the course instance first and fail if it is
absent, then pass its identifiers as parameters, rather than re-deriving them inside each
query.

### How to divide the DAOs

One DAO per table does not survive these queries, since the planned hours query spans
three tables and the allocation query spans six, so any split forces arbitrary decisions
about which DAO owns a join. The alternatives are a single DAO holding all statements, as
in the bank example, or one DAO per use case area. Whichever is chosen, the connection
handling, the result set closing and the exception wrapping must live in one place, since
avoiding duplicated code is an explicit assessment criterion.

### Credentials in the source code

`Config` holds the database name, user and password as constants. This is better than
inlining them in the DAO, but they are still compiled into the jar and committed to
version control. A properties file in `src/main/resources`, read at startup, would keep
them out of the source. The database name is a constructor parameter of
`DatabaseConnection`, so the same class can open connections to different databases.
