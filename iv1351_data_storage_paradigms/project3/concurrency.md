Best shown with your own schema. The difference is about foreign keys.That's the whole difference, measured on your schema:

```
parent locked with FOR UPDATE          -> inserting a planned_activity took 3189 ms
parent locked with FOR NO KEY UPDATE   -> inserting a planned_activity took   52 ms
the second FOR NO KEY UPDATE waited    3044 ms
```

Same row, same holder, same four-second hold. `FOR UPDATE` made an unrelated insert wait for the lock to be released. `FOR NO KEY UPDATE` let it through immediately. And two writers still serialise against each other, which is the part you actually need.

## Why

When PostgreSQL inserts a row with a foreign key, it has to make sure the parent row doesn't vanish, so it takes a weak lock on the parent called `FOR KEY SHARE`. That lock means "this row must keep existing with this key", nothing more.

- `FOR UPDATE` conflicts with `FOR KEY SHARE`. So locking a `course_instance` with `FOR UPDATE` blocks any other transaction from inserting a `planned_activity` that references it.
- `FOR NO KEY UPDATE` does not conflict with `FOR KEY SHARE`. Child inserts proceed.

Both conflict with each other and with `FOR UPDATE`, so either one prevents the lost update. The difference is only in how much *unrelated* work they block.

The name says it: "I am going to update this row, but **not** its key." That promise is what lets PostgreSQL keep allowing references to it.

## The rule to remember

1. **No write based on the read? No locking clause.** This is most queries, including all your aggregates and both allocation lists.
2. **Writing a non-key column?** `FOR NO KEY UPDATE`. This is the normal case.
3. **Changing a primary or unique key, or deleting the row?** `FOR UPDATE`, because then references really can break.
4. Add `OF <table>` whenever the query joins, or you lock a row in every joined table.

PostgreSQL applies the same logic itself: a plain `UPDATE` that touches no key column takes `FOR NO KEY UPDATE` internally, and only `DELETE` or an update of a key column takes `FOR UPDATE`.

## In your program

**`course_instance`**, in `findCurrentYearCourseInstanceForUpdate`. You update `num_students`, which is not a key, so rule 2 gives `FOR NO KEY UPDATE`. This is also where the choice has teeth: `planned_activity` references `course_instance`, and your own `addTeachingActivity` inserts a `planned_activity`. With `FOR UPDATE`, one user adding students would block another user adding an Exercise activity to that same instance, for no reason.

**`employee`**, in `findEmployeeForUpdate`. This one is unusual, because you never update the employee at all. The lock is a mutex: the allocation decision rests on rows that don't exist yet, so you serialise on the employee row instead. `FOR NO KEY UPDATE` is right because you're not changing the employee's key, and the third measurement shows it still serialises two concurrent allocations for the same teacher, which is the point. `FOR UPDATE` would additionally block `employee_skill` and `employee_salary` inserts for that employee, which has nothing to do with teaching allocations.

So in this project the answer is `FOR NO KEY UPDATE` both times, and `FOR UPDATE` never. If you had a use case that deleted a course instance or changed its `instance_id`, that one would need `FOR UPDATE`.

Two more modes exist for completeness, `FOR SHARE` and `FOR KEY SHARE`, which let several readers hold the row while blocking writers. They're for "I need this row to stay as it is while I do something else", and you don't need them here.

---

If two transactions read the same row, but only one uses `FOR UPDATE`, they do not block each other just because one acquired a row lock.

PostgreSQL uses MVCC, so ordinary SELECT statements can read rows even when another transaction has locked them.

Let's look at the scenarios.

## 1. Transaction A uses FOR UPDATE, Transaction B uses normal SELECT

Transaction A

sql

```sql
BEGIN;

SELECT *
FROM accounts
WHERE id = 1
FOR UPDATE;
```

Transaction B

sql

```sql
BEGIN;

SELECT *
FROM accounts
WHERE id = 1;
```

No blockingTransaction B can read the row immediately.

Why? Because a normal `SELECT` doesn't acquire a conflicting row lock. It uses MVCC to read a visible row version.

## 2. What if Transaction B also wants to update?

Transaction A

sql

```sql
BEGIN;

SELECT *
FROM accounts
WHERE id = 1
FOR UPDATE;
```

Transaction B

sql

```sql
BEGIN;

SELECT *
FROM accounts
WHERE id = 1;

UPDATE accounts
SET balance = 200
WHERE id = 1;
```

UPDATE blocksTransaction B can execute its SELECT, but its UPDATE must wait for Transaction A to release its row lock.

## 3. What if both use FOR UPDATE?

Transaction A

sql

```sql
BEGIN;

SELECT *
FROM accounts
WHERE id = 1
FOR UPDATE;
```

Transaction B

sql

```sql
BEGIN;

SELECT *
FROM accounts
WHERE id = 1
FOR UPDATE;
```

Second SELECT blocksTransaction B must wait until Transaction A commits or rolls back.

After that, B acquires the lock.

## 4. Summary

| Transaction A | Transaction B | Does B block? |
| --- | --- | --- |
| FOR UPDATE | SELECT | No |
| FOR UPDATE | FOR UPDATE | Yes |
| FOR UPDATE | FOR NO KEY UPDATE | Yes |
| FOR UPDATE | UPDATE | Yes |
| FOR NO KEY UPDATE | SELECT | No |
| FOR NO KEY UPDATE | FOR KEY SHARE | No |

The key concept:

`SELECT FOR UPDATE` doesn't prevent other transactions from reading the row. It prevents conflicting operations from modifying or acquiring incompatible locks on that row.

This is one of the most important characteristics of PostgreSQL's MVCC architecture.