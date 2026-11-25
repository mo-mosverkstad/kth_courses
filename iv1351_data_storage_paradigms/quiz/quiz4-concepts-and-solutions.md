# Non-Graded Quiz 4 — Concurrency Control, Deadlocks & Isolation

Complete concept notes and worked solutions for all 14 questions, checked against the
official answer key (`Try.01.png`).

**Result: 12 of 14 correct.** Two questions were answered wrongly:

| Question | Topic | Status |
|---|---|---|
| Q12 | Transaction boundaries for a read-only operation | ❌ **wrong** — see [Q12](#q12--do-the-two-scenarios-interfere-) |
| Q14 | Bank transfer vs. concurrent sum | ❌ **wrong** — see [Q14](#q14--bank-transfer-vs-concurrent-sum-) |

Both mistakes come from the *same* root misconception, explained in
[The Two Mistakes](#part-iii--the-two-mistakes-in-depth).

---

## Table of Contents

- [Part I — Concepts You Need](#part-i--concepts-you-need)
  - [1. Transactions and ACID](#1-transactions-and-acid)
  - [2. Schedules and Conflicts](#2-schedules-and-conflicts)
  - [3. Serializability and the Conflict Graph](#3-serializability-and-the-conflict-graph)
  - [4. Recoverability Classes](#4-recoverability-classes)
  - [5. Locks and the Compatibility Matrix](#5-locks-and-the-compatibility-matrix)
  - [6. The 2PL Family](#6-the-2pl-family)
  - [7. Deadlocks and Wait-For Graphs](#7-deadlocks-and-wait-for-graphs)
  - [8. Isolation Levels and Anomalies](#8-isolation-levels-and-anomalies)
  - [9. Transaction Boundaries in Application Code](#9-transaction-boundaries-in-application-code)
- [Part II — Question by Question](#part-ii--question-by-question)
- [Part III — The Two Mistakes In Depth](#part-iii--the-two-mistakes-in-depth)
- [Part IV — Cheat Sheet](#part-iv--cheat-sheet)

---

# Part I — Concepts You Need

## 1. Transactions and ACID

A **transaction** is a unit of work that the DBMS treats as indivisible. Four guarantees:

| Property | What it actually promises | How it is implemented |
|---|---|---|
| **A**tomicity | All-or-nothing. Either every operation takes effect or none does. | Undo log, rollback |
| **C**onsistency | The DB moves from one valid state to another (integrity constraints hold). | Constraint checking |
| **I**solation | A transaction behaves as if it had the database to itself. | Locking / MVCC / serial execution |
| **D**urability | Once committed, survives crashes. | Write-ahead log on stable storage |

**The classic trap (Q6):** Atomicity and Isolation get swapped.

```
  ATOMICITY  = "all or nothing"            <- about FAILURE
  ISOLATION  = "as if I were alone"        <- about CONCURRENCY
  DURABILITY = "survives a power cut"      <- about CRASHES
```

A locking protocol (2PL, SS2PL, rigorous 2PL) delivers **Isolation**.
It can never deliver **Durability** — no arrangement of locks survives a crash.
Durability needs logging plus stable storage.

---

## 2. Schedules and Conflicts

A **schedule** interleaves the operations of several transactions.

Two operations **conflict** when all three hold:

1. they belong to **different** transactions,
2. they access the **same** data item,
3. **at least one** is a write.

```
          +--------+--------+
          | R(x)   | W(x)   |
  +-------+--------+--------+
  | R(x)  |   ok   | CONFLICT|
  +-------+--------+--------+
  | W(x)  |CONFLICT| CONFLICT|
  +-------+--------+--------+
```

So: **Read–Read never conflicts.** This single fact decides Q4.

---

## 3. Serializability and the Conflict Graph

A schedule is **conflict serializable** if it can be transformed into some serial
schedule by swapping only *non-conflicting* adjacent operations.

**Test procedure (precedence / conflict graph):**

1. One node per transaction.
2. For every conflicting pair where `Tx`'s operation comes **before** `Ty`'s,
   draw `Tx → Ty`.
3. **Acyclic ⇒ conflict serializable.** Any topological order is an equivalent serial order.
4. **Cyclic ⇒ not conflict serializable.**

```
  ACYCLIC                      CYCLIC
  T3 ──► T4 ──► T1 ──► T2      T1 ──► T2
  equivalent serial order:      ▲       │
  T3, T4, T1, T2                └───────┘
                                not serializable
```

### View serializability

A strictly weaker notion: schedules that preserve the same "reads-from" relationships.

```
   serial  ⊂  conflict serializable  ⊂  view serializable  ⊂  all schedules
```

- Every serial schedule is conflict serializable (so CS **subsumes** all serial schedules).
- Some view-serializable schedules are **not** conflict serializable — and these are
  exactly the ones involving **blind writes** (a write with no prior read of that item).
- **Conflict serializability does NOT forbid blind writes.** Blind writes are perfectly
  legal inside conflict-serializable schedules. Blind writes are merely what makes the
  two classes differ. (This is the Q6 trap.)

---

## 4. Recoverability Classes

These classes are about what happens when a transaction **aborts**.

```
  all schedules
  └── RECOVERABLE          : Tj commits only after every Ti it read from committed
      └── CASCADELESS (ACA): Tj reads only values written by COMMITTED transactions
          └── STRICT       : Tj neither reads nor overwrites uncommitted data
```

**Cascading abort** — the thing we want to avoid:

```
  T1: W(X) ─────────────────── ABORT
  T2:            R(X)  ...     must also abort!   <- cascade
                  ^
                  read uncommitted data from T1
```

**To avoid cascading aborts (= cascadeless / ACA):**
> every transaction must commit **before** any other transaction reads what it wrote.

This is the rule for Q3.

---

## 5. Locks and the Compatibility Matrix

- **S(x)** — shared lock (read lock)
- **X(x)** — exclusive lock (write lock)

```
            requested
            +-------+-------+
            |   S   |   X   |
    +-------+-------+-------+
  h |   S   |  YES  |  no   |
  e +-------+-------+-------+
  l |   X   |  no   |  no   |
  d +-------+-------+-------+
```

**Only S/S is compatible.** Memorise this — it alone decides Q8 and Q9.

A request that is not compatible with the current holder **blocks**, and the waiting
transaction gets an edge in the wait-for graph.

---

## 6. The 2PL Family

**Two-Phase Locking** = a transaction has a **growing phase** (acquire only) and a
**shrinking phase** (release only). Once you release anything, you may never acquire again.
2PL guarantees conflict serializability.

The variants differ in **when locks are acquired** and **when they are released** — which
produces a distinctive "number of locks held over time" signature:

```
  (a) CONSERVATIVE SS2PL              (b) BASIC 2PL (non-strict)
   #locks                              #locks
     ^                                   ^
   N |###############|                 N |        #####
     |###############|                   |     ###########
     |###############|                   |   ###############
     |###############|                   | #####################
   0 +---------------+--> t            0 +-----------------------+--> t
                 commit                                       commit
   vertical rise  = all locks at once   sloped rise = incremental acquire
   vertical fall AT commit = strong     sloped fall = early release


  (c) STRONG STRICT 2PL (SS2PL)        (d) NAIVE LOCKING
   #locks                              #locks
     ^                                   ^
   N |       ########|                 N |      #######
     |    ###########|                   |   #/\########
     |  #############|                   |  ###########
     |###############|                   | ##############
   0 +---------------+--> t            0 +---------------+--> t
                 commit                             commit
   sloped rise, vertical fall AT commit  jagged: acquire & release at will,
                                         all released BEFORE commit


  (e) CONSERVATIVE 2PL (non-strict)    (f) STRICT 2PL (not strong)
   #locks                              #locks
     ^                                   ^
   N |############                     N |  ~~~~WRITE LOCKS~~~~|
     |##############                     | ~~~~~~~~~~~~~~~~~~~~|
     |################                   |  //READ\\           |
     |##################                 | //LOCKS \\          |
   0 +---------------+--> t            0 +---------------------+--> t
                 commit                                     commit
   vertical rise = conservative         WRITE locks held to commit
   sloped fall   = non-strict           READ locks released early
```

### Reading the signature

| Edge of the shape | What it tells you |
|---|---|
| **Left edge vertical** (instant jump to max) | **Conservative** — all locks requested atomically up front |
| **Left edge sloped** | locks acquired incrementally as needed |
| **Right edge vertical, exactly at commit** | **Strong strict** — everything held to commit |
| **Right edge sloped, finishing at/before commit** | **non-strict** — locks released during shrinking phase |
| **Jagged / non-monotonic** | **Naive** — not two-phase at all |
| **Two bands, reads fall early, writes to commit** | **Strict (not strong)** |

### Properties summary

| Variant | Serializable? | Cascadeless? | Deadlock-free? | Repeatable reads? |
|---|---|---|---|---|
| Naive locking | ✗ | ✗ | ✗ | ✗ |
| Basic 2PL (non-strict) | ✓ | ✗ | ✗ | ✓ |
| Conservative 2PL (non-strict) | ✓ | ✗ | **✓** | ✓ |
| Strict 2PL | ✓ | ✓ | ✗ | ✗ (reads released early) |
| Strong Strict 2PL (SS2PL) | ✓ | ✓ | ✗ | ✓ |
| Conservative SS2PL | ✓ | ✓ | **✓** | ✓ |

**Only the CONSERVATIVE variants prevent deadlock.** Reason: if you obtain every lock you
will ever need in one atomic step, you never hold a lock while requesting another, so no
hold-and-wait, so no cycle.

**No 2PL variant solves phantom reads.** Phantoms need *predicate* / *index-range* locking.
Locking the rows that exist today cannot stop a new row appearing in your range tomorrow.

---

## 7. Deadlocks and Wait-For Graphs

A **wait-for graph (WFG)** has one node per transaction and an edge `Ti → Tj` meaning
"Ti is blocked waiting for a lock currently held by Tj".

> **A deadlock exists exactly when the WFG contains a cycle.**
> The number of deadlocks = the number of (distinct) cycles.

### Victim selection — the key rule

To break a deadlock you abort a **victim**. The victim must be **on the cycle**.

```
                  ┌──────────────────────────┐
                  ▼                          │
     T2 ──► T5 ──► T6 ──► T7 ──► T3 ─────────┘    <- THE CYCLE
     │                             │
     ▼                             ▼
     T1 ◄────────────────────────── (T1, T4 hang off the cycle)
     ▲
     │
     T4

   Valid victims   : T2, T5, T6, T7, T3   (any node ON the cycle)
   Invalid victims : T1, T4               (aborting them changes nothing)
```

A node with **no outgoing edges** is a *sink* — it waits for nobody, so it can never be
part of a cycle, so it is never a valid victim.

### Detection vs. prevention

| Approach | Mechanism |
|---|---|
| **Detection** | Build the WFG periodically, look for cycles, abort a victim |
| **Prevention** | Conservative 2PL (all locks up front) / timestamp ordering (wait-die, wound-wait) |
| **Avoidance by timeout** | Crude: abort anything waiting too long |

Plain Strict 2PL / SS2PL have **no** inherent deadlock handling — they need an external
detector. Only conservative locking is deadlock-free by construction.

---

## 8. Isolation Levels and Anomalies

### The anomalies

| Anomaly | Definition | Picture |
|---|---|---|
| **Dirty read** | reading data written by an **uncommitted** transaction | `T1: W(x) … T2: R(x) … T1: ABORT` |
| **Non-repeatable read** | re-reading the **same row** gives a different value | `T1: R(x)=5 … T2: W(x)=9,commit … T1: R(x)=9` |
| **Phantom read** | re-running the **same query** returns different *rows* | `T1: SELECT…WHERE p … T2: INSERT row matching p … T1: SELECT…WHERE p` |

### The SQL levels

| Level | Dirty read | Non-repeatable read | Phantom |
|---|---|---|---|
| READ UNCOMMITTED | possible | possible | possible |
| **READ COMMITTED** | **prevented** | possible | possible |
| REPEATABLE READ | prevented | prevented | possible |
| SERIALIZABLE | prevented | prevented | prevented |

### How to pick a level (the Q13 recipe)

Read the requirements and translate each clause into a constraint:

```
  "must only include data that actually happened"   -> no DIRTY reads
                                                    -> rules out READ UNCOMMITTED
  "OK if some items are missed"                     -> phantoms acceptable
                                                    -> REPEATABLE READ / SERIALIZABLE
                                                       are stronger than needed
  => pick the WEAKEST level that satisfies the constraints: READ COMMITTED
```

Picking the weakest sufficient level matters because stronger isolation means more locks
held for longer, which means less concurrency — especially when scanning huge volumes.

### Which 2PL maps to which level

```
  Naive locking  ──►  READ UNCOMMITTED  (write locks released before commit => dirty reads)
  Strict 2PL     ──►  READ COMMITTED    (write locks to commit, read locks early)
  SS2PL          ──►  REPEATABLE READ   (all locks to commit; phantoms still possible)
  SS2PL + range locks ──► SERIALIZABLE
```

---

## 9. Transaction Boundaries in Application Code

Two rules that together answer Q11 and Q12:

> **Rule 1 — A transaction must contain *all* the database calls of the operation, and nothing more.**

```
  point 1   ─┐
  user submits changes          <- USER INTERACTION: keep OUT (unbounded think-time)
  point 2   ─┼── START HERE ◄───────────────────────┐
  retrieve booking from DB      <- database call    │  the read-modify-write
  point 3    │                                      │  must be ONE atomic unit,
  apply changes in memory       <- pure computation │  otherwise another transaction
  point 4    │                                      │  slips in between => LOST UPDATE
  save new state to DB          <- database call    │
  point 5   ─┴── COMMIT HERE ◄──────────────────────┘
  UI confirms                   <- presentation: keep OUT
  point 6
```

Starting at point 1 would hold locks while a human stares at a form.
Committing at point 6 would extend lock hold time for a UI message that touches no data.

> **Rule 2 — EVERY database access needs a transaction, including read-only ones.**

A statement running outside a transaction takes **no locks** and therefore has
**no isolation whatsoever**. It can observe a half-finished concurrent write.
This is the point Q12 tests, and getting it wrong cost a mark.

---

# Part II — Question by Question

---

## Q1 — Match the locking schemes ✅

**Answer (0.6 / 0.6):**

| Figure | Signature | Scheme |
|---|---|---|
| **a)** | vertical rise, flat, vertical fall **at** commit | **Strong Strict 2PL (SS2PL) w/ conservative** |
| **b)** | sloped rise, sloped fall | **2PL (non-strict)** |
| **c)** | sloped rise, plateau, vertical fall at commit | **Strong Strict 2PL** |
| **d)** | jagged rise with a notch, falls before commit | **Naive Locking** |
| **e)** | **vertical** rise, plateau, sloped fall | **Conservative 2PL (non-strict)** |
| **f)** | read band falls early, write band to commit | **Strict 2PL (not strong)** |

### How to tell the look-alikes apart

The pairs (a, e) and (b, c) are deliberately confusable. Check the two edges separately:

```
                 LEFT EDGE                RIGHT EDGE
               (acquisition)              (release)
   a)        vertical = conservative   vertical @ commit = strong strict
   e)        vertical = conservative   sloped            = non-strict
   b)        sloped   = incremental    sloped            = non-strict
   c)        sloped   = incremental    vertical @ commit = strong strict
```

**f) is the most informative figure.** Two separately-coloured bands:

```
   #locks
     ^
     |     ~~~~~~~~~~~~~~ WRITE LOCKS ~~~~~~~~~~~~~|   held until commit
     |   ////// READ LOCKS \\\\\\                  |   released gradually
   0 +---------------------------------------------+--> t
                                             commit
```
Holding write locks to commit while letting read locks go early **is** the definition of
strict-but-not-strong 2PL.

---

## Q2 — What each scheme can do ✅

**Answer (0.4 / 0.4): mark all EXCEPT the first.**

| Statement | Verdict | Why |
|---|---|---|
| Fig.**f** can deal with **deadlocks** | ❌ | f = Strict 2PL. Acquires locks incrementally ⇒ hold-and-wait ⇒ deadlock-prone. No inherent handling. |
| Fig.**b** can deal with **non-repeatable reads** | ✅ | b = basic 2PL ⇒ conflict serializable ⇒ a re-read cannot change. You cannot release-then-reacquire under 2PL. |
| Fig.**d** can support **read uncommitted** | ✅ | d = naive locking. Write locks released before commit ⇒ dirty reads possible ⇒ that *is* read-uncommitted behaviour. |
| Fig.**e** can **prevent deadlocks** | ✅ | e = Conservative 2PL. All locks atomically up front ⇒ no hold-and-wait ⇒ deadlock-free. |
| Fig.**a** can deal with **repeatable reads** | ✅ | a = conservative SS2PL. Every lock held to commit. |
| Fig.**f** can support **read committed** | ✅ | Write locks to commit (no dirty reads) + read locks early (non-repeatable reads possible) = exactly READ COMMITTED. |

```
  DEADLOCK PREVENTION comes only from the LEFT edge being vertical:
       a) ✓ conservative        e) ✓ conservative
       b) ✗   c) ✗   d) ✗   f) ✗
```

---

## Q3 — Commit slots to avoid cascading aborts ✅

**Answer (0.3 / 0.3): T1 → slot 3, T2 → slot 5, T3 → slot 2.**

```
  Slot │  T1      T2      T3
  ─────┼───────────────────────
    1  │ R(X)    W(Y)    R(Z)        T3 reads the INITIAL Z (T2's W(Z) is later)
    2  │ W(X)                   ◄─── T3 COMMIT  (T3 done after slot 1)
    3  │         W(Z)           ◄─── T1 COMMIT  (must precede T2's R(X)!)
    4  │         R(X)                T2 reads X written by T1 in slot 2
    5  │                        ◄─── T2 COMMIT  (T2 done after slot 4)
```

### The single binding constraint

```
  slot 2:  T1 ── W(X) ───┐
                         │  reads-from dependency
  slot 4:  T2 ── R(X) ◄──┘

  Cascadeless requires: T1 commits BEFORE T2 reads X.
  T1's last operation is at slot 2  ──► earliest possible commit = slot 3
  T2's read is at slot 4            ──► latest possible commit   = slot 3
                                        ⇒ slot 3 is FORCED
```

Why it matters — if T1 committed at slot 5 instead:

```
  T1: W(X) ─────────────── ABORT
  T2:            R(X) ...  must abort too  ✗ CASCADE
```

**T2** finishes at slot 4, so the first free slot is **5**.
**T3** finishes at slot 1 and read only committed (initial) data, so it is unconstrained —
slot **2** is the earliest valid choice. Note `T2: W(Z)` at slot 3 comes *after* `T3: R(Z)`,
which is a read-then-write (anti-dependency) and creates no commit-order requirement.

---

## Q4 — Pick the conflict graph ✅

**Answer (0.1 / 0.1): the THIRD graph.**

### The schedule

```
  Time │ 1     2     3     4     5     6     7     8     9     10
  ─────┼────────────────────────────────────────────────────────────
   T1  │ R(A)                                      R(B)
   T2  │                                     R(C)              W(A)
   T3  │       W(C)                                      R(A)
   T4  │                   W(B)  W(C)
```

Linear order of operations:

```
  t1  T1:R(A)   t2  T3:W(C)   t4  T4:W(B)   t5  T4:W(C)
  t7  T2:R(C)   t8  T1:R(B)   t9  T3:R(A)   t10 T2:W(A)
```

### Deriving the edges, item by item

```
  Item A:  T1:R(A)@1 ──── T3:R(A)@9 ──── T2:W(A)@10
           └── R/R = NO CONFLICT (no edge T1→T3!)  ◄── THE TRAP
           T1:R @1  before T2:W @10   ⇒  T1 ──A──► T2
           T3:R @9  before T2:W @10   ⇒  T3 ──A──► T2

  Item B:  T4:W(B)@4 ──── T1:R(B)@8
           W/R conflict               ⇒  T4 ──B──► T1

  Item C:  T3:W(C)@2 ──── T4:W(C)@5 ──── T2:R(C)@7
           W/W                        ⇒  T3 ──C──► T4
           W/R                        ⇒  T3 ──C──► T2
           W/R                        ⇒  T4 ──C──► T2
```

### The correct graph — 6 edges

```
                      T1
                     ╱  ▲
                 A  ╱    ╲ B
                   ▼      ╲
     T3 ───C────► T2 ◄──C── T4
      │                      ▲
      └──────────C───────────┘

   Edges: T1─A─►T2   T3─A─►T2   T4─B─►T1
          T3─C─►T4   T3─C─►T2   T4─C─►T2
```

### Why the other three options fail

| Option | Defect |
|---|---|
| 1 | has the bogus `T1 ─A─► T3`, **and** is missing `T4 ─B─► T1` |
| 2 | has `T4 ─B─► T1` but keeps the bogus `T1 ─A─► T3` |
| **3** | **✅ exact match** |
| 4 | has `T4 ─B─► T1` but keeps bogus `T1 ─A─► T3` **and** drops the real `T3 ─A─► T2` |

**Two diagnostics let you solve this in seconds:**

1. **T3 must have in-degree 0.** T3's only operations are `W(C)@2` (the earliest write
   on C) and `R(A)@9`. Nothing precedes it in conflict, so *any* arrow pointing into T3
   is wrong. Three of the four options draw one.
2. **The B edge must exist.** `T4:W(B)` before `T1:R(B)` is a genuine W/R conflict.
   Option 1 omits it.

---

## Q5 — Is the schedule conflict serializable? ✅

**Answer (0.2 / 0.2): Sant (= True, Swedish).**

The graph from Q4 is acyclic. Peel off nodes with in-degree 0:

```
  Step 1:  T3 has no incoming edges      ─► remove T3
  Step 2:  T4 now has none (T3→T4 gone)  ─► remove T4
  Step 3:  T1 now has none (T4→T1 gone)  ─► remove T1
  Step 4:  T2 remains

  Equivalent serial order:   T3 ─► T4 ─► T1 ─► T2
```

Every node was removable ⇒ no cycle ⇒ **conflict serializable**.

> The other radio option ("Are there any cycles?") is a rendering glitch in the quiz, not a
> real alternative.

---

## Q6 — Mark the INCORRECT statements ✅

**Answer (0.6 / 0.6): mark statements 1, 4 and 6.**

| # | Statement | Verdict |
|---|---|---|
| 1 | Durability can be satisfied using rigorous 2PL | ❌ **incorrect — MARK** |
| 2 | Conflict serializable schedules subsume all serial schedules | ✓ correct — leave |
| 3 | Isolation can be satisfied using serial execution | ✓ correct — leave |
| 4 | Atomicity gives the transaction a dedicated (non-concurrent) view of state | ❌ **incorrect — MARK** |
| 5 | There exist view serializable schedules that are not conflict serializable | ✓ correct — leave |
| 6 | Conflict Serializability forbids blind writes | ❌ **incorrect — MARK** |

### Statement 1 — Durability ≠ locking

```
         DURABILITY                      what 2PL gives you
         ──────────                      ──────────────────
    commit ─► survives power loss        commit ─► serializable order
    needs: WAL + stable storage          needs: locks
    ──────────────────────────────────────────────────────────
    No lock protocol survives a crash. Different axis entirely.
```

"Rigorous 2PL" is another name for SS2PL (all locks to commit). It delivers Isolation
and cascadelessness — never Durability.

### Statement 4 — Atomicity vs. Isolation swapped

"a dedicated, non-concurrent view of state" is the textbook description of **Isolation**.
Atomicity is all-or-nothing on failure.

### Statement 6 — blind writes are legal

```
  A BLIND WRITE: T2 writes X without ever reading X.

  S: T1:W(X)  T2:W(X)  T1:W(X)
     ──► conflict graph: T1 ⇄ T2  (cyclic) ⇒ NOT conflict serializable
         but it IS view serializable (equivalent to T1,T1,T2 view-wise)

  S': T1:R(X) T1:W(X) T2:W(X)
     ──► contains a blind write by T2, graph T1→T2 acyclic
         ⇒ perfectly conflict serializable
```

So blind writes are allowed inside conflict-serializable schedules. They are merely the
*reason the two classes differ*, not something CS prohibits.

### Statement 2 — why "subsume" is right

```
  serial ⊂ conflict serializable
  A serial schedule has no interleaving, hence no conflicting pair out of order,
  hence an acyclic graph. So CS ⊇ serial. "Subsumes" = includes. ✓
```

---

## Q7 — Wait-for graph statements ✅

**Answer (0.6 / 0.6): only "Transaction T5 is a valid victim candidate".**

### The graph

```
            ┌──────────────────────────────────┐
            │                                  │
            ▼                                  │
           T7 ──────► T3 ──────► T2 ──────► T5 ┤
            ▲          │   ╲       │             │
            │          │    ╲      │             ▼
           T6 ◄────────┼─────╲─────┼──────────── (T5 ─► T6 ─► T7 closes it)
            ▲          │      ╲    │
            │          ▼       ▼   ▼
            └──        T4      T1 ◄┘
                        │       ▲
                        └───────┘

  Edge list:
    T6 ─► T7     T7 ─► T3     T3 ─► T4     T3 ─► T1
    T3 ─► T2     T4 ─► T1     T2 ─► T1     T2 ─► T5     T5 ─► T6
```

### Finding the cycle

```
  T2 ──► T5 ──► T6 ──► T7 ──► T3 ──► T2       ✓ ONE cycle
         └──────────────────────────┘

  T1: in-degree 3, OUT-DEGREE 0  ──► SINK, cannot be on any cycle
  T4: only edge is T4 ─► T1 (a sink) ──► dead end, cannot be on any cycle
```

### Verdicts

| Statement | Verdict | Why |
|---|---|---|
| reveals no deadlock | ❌ | there *is* a cycle |
| **T5 is a valid victim** | ✅ | T5 lies on the cycle; aborting it releases its locks and breaks the cycle |
| at least two deadlocks | ❌ | exactly one cycle |
| T1 can be a victim | ❌ | T1 waits for nobody (out-degree 0) ⇒ not on the cycle ⇒ aborting it frees nothing that matters |
| T7 is **not** a valid victim | ❌ | T7 *is* on the cycle, so it **is** valid — the statement's negation makes it false |
| T4 can be a victim | ❌ | T4 is not on the cycle |

> **The reusable trick:** compute out-degree first. Any node with out-degree 0 is a sink
> and is immediately disqualified as a victim. Here that kills T1 at a glance, and T4
> follows because its only successor is that sink.

---

## Q8 — Which schedules can deadlock? ✅

**Answer (0.5 / 0.5): schedules 2 and 5.**

### Schedule 1 — NO deadlock

```
  t:    1      2        3        4        5        6
  T1  S(A)                     X(B)   read(B)
  T2         X(B)   read(B)                     S(A)

  t4: T1 wants X(B), T2 holds X(B)  ─► T1 BLOCKS, edge T1 ─► T2
  t6: T2 wants S(A), T1 holds S(A)  ─► S/S COMPATIBLE ⇒ GRANTED ✓

  WFG:  T1 ──► T2        (no cycle)
  T2 finishes, releases B, T1 proceeds.
```

### Schedule 2 — DEADLOCK ✅

```
  t:    1      2        3        4        5        6
  T1  S(B)                     S(A)
  T2         X(A)   read(A)            X(B)   read(B)

  t4: T1 wants S(A), T2 holds X(A)  ─► BLOCK   T1 ─► T2
  t5: T2 wants X(B), T1 holds S(B)  ─► BLOCK   T2 ─► T1

  WFG:  T1 ⇄ T2   ✗ CYCLE ⇒ DEADLOCK
```

### Schedule 3 — NO deadlock

```
  T1  S(A)  read(A)                   S(B)
  T2                  S(B)  read(B)         S(A)

  Every lock is SHARED. S/S is compatible, so nothing ever blocks.
  WFG: empty.
```

### Schedule 4 — NO deadlock

```
  T1  S(A)                   read(A)
  T2         S(B)  read(B)            X(A)   X(B)

  t5: T2 wants X(A), T1 holds S(A)  ─► BLOCK   T2 ─► T1
  T1 requests NOTHING further ⇒ commits, releases A ⇒ T2 proceeds.

  WFG:  T2 ──► T1        (one-way wait is NOT a deadlock)
```

### Schedule 5 — DEADLOCK ✅

```
  t:    1      2        3        4        5        6
  T1  X(A)                   read(A)   S(B)
  T2         X(B)   read(B)                     S(A)

  t5: T1 wants S(B), T2 holds X(B)  ─► BLOCK   T1 ─► T2
  t6: T2 wants S(A), T1 holds X(A)  ─► BLOCK   T2 ─► T1

  WFG:  T1 ⇄ T2   ✗ CYCLE ⇒ DEADLOCK
```

### The pattern

```
  DEADLOCK needs a CYCLE of INCOMPATIBLE waits.

  Schedule 1 vs 5 look almost identical. The difference:
     #1: T1 holds S(A), T2 wants S(A)  ─► S/S compatible ⇒ granted, no cycle
     #5: T1 holds X(A), T2 wants S(A)  ─► X/S incompatible ⇒ block ⇒ cycle

  Always check the compatibility matrix on the LAST request.
```

---

## Q9 — Which wait-for graph, and is there a deadlock? ✅

**Answer: mark BOTH**
- "The wait-for graph that corresponds to the given lock request is **i)**"
- "There is **no deadlock** in the given request lock"

> Note: the answer key shows the previous attempt scored only 0.2/0.4 by selecting just
> the first of these two. Both are correct and both must be ticked.

### Simulating the requests

```
  Time │  1      2      3      4      5      6      7      8      9
  ─────┼──────────────────────────────────────────────────────────────
   T1  │       S(B)                                            S(A)
   T2  │                     X(A)                S(B)   S(C)
   T3  │ S(B)                       X(D)
   T4  │              X(D)                X(C)
```

| t | Request | Lock state | Result |
|---|---|---|---|
| 1 | T3: S(B) | B free | granted — B: S{T3} |
| 2 | T1: S(B) | B: S{T3} | **S/S compatible** ⇒ granted — B: S{T3,T1} |
| 3 | T4: X(D) | D free | granted — D: X{T4} |
| 4 | T2: X(A) | A free | granted — A: X{T2} |
| 5 | T3: X(D) | D: X{T4} | **X/X blocks** ⇒ `T3 ─D─► T4` |
| 6 | T4: X(C) | C free | granted — C: X{T4} |
| 7 | T2: S(B) | B: S{T3,T1} | **S/S compatible** ⇒ granted |
| 8 | T2: S(C) | C: X{T4} | **X/S blocks** ⇒ `T2 ─C─► T4` |
| 9 | T1: S(A) | A: X{T2} | **X/S blocks** ⇒ `T1 ─A─► T2` |

### The resulting WFG — exactly graph i)

```
     T1 ────A────► T2
                    │
                    C
                    │
                    ▼
     T4 ◄────D──── T3

   ( i.e.  T1 ─► T2 ─► T4  and  T3 ─► T4 )
```

### Why there is no deadlock

```
  T4 has OUT-DEGREE 0 — it waits for nothing (all its requests were granted).
  Every path therefore terminates at T4. A cycle is impossible.

  Chains:  T1 ─► T2 ─► T4 (end)
           T3 ─► T4 (end)
```

T4 will finish, release D and C, unblocking T3 and T2; then T2 releases A, unblocking T1.

### Why graph ii) is wrong

```
  ii) reverses the D edge:   T4 ─► T3   ✗
      (T4 acquired D at t3, T3 requested it at t5 ⇒ T3 waits for T4, not vice versa)

  ii) adds B edges:          T2 ⇄ T3 on B   ✗
      Every single request on B is SHARED — S(B) by T3, T1 and T2.
      S/S is compatible, so NOBODY ever waits on B. No B edge can exist.
```

The B edges in ii) are the trap: three transactions all touch B, which *looks* like
contention until you check that all three requests are shared.

---

## Q10 — Statements about SS2PL ✅

**Answer (0.5 / 0.5): statements 1 and 3.**

| # | Statement | Verdict |
|---|---|---|
| 1 | SS2PL always ensures repeatable reads | ✅ |
| 2 | SS2PL holds write locks to the end and releases read locks during the shrinking phase | ❌ |
| 3 | SS2PL avoids cascading rollbacks | ✅ |
| 4 | SS2PL solves the problem of phantom reads | ❌ |
| 5 | Deadlocks can never occur in SS2PL | ❌ |

### Statement 2 — that's plain Strict 2PL

```
  STRICT 2PL         : WRITE locks ─► commit ;  READ locks ─► released early
  STRONG STRICT 2PL  : WRITE locks ─► commit ;  READ locks ─► commit  TOO
                                                 ^^^^^^^^^^^^^^^^^^^
                                                 that's what "strong" adds
```
This is exactly the Fig.f vs Fig.c distinction from Q1.

### Statement 4 — phantoms survive SS2PL

```
  T1: SELECT * FROM events WHERE day = 5;     -- locks the 3 rows that exist
  T2: INSERT INTO events VALUES (..., day=5); -- a row that didn't exist: UNLOCKED
      commit
  T1: SELECT * FROM events WHERE day = 5;     -- 4 rows now!  ✗ PHANTOM

  Record-level locking cannot lock a row that does not yet exist.
  Needs PREDICATE / INDEX-RANGE locking (⇒ SERIALIZABLE).
```

### Statement 5 — SS2PL is deadlock-prone

```
  T1: X(A) ✓ ........ X(B) ✗ blocked by T2
  T2: X(B) ✓ ........ X(A) ✗ blocked by T1      ⇒ DEADLOCK under SS2PL

  SS2PL acquires locks INCREMENTALLY ⇒ hold-and-wait ⇒ cycles possible.
  Only the CONSERVATIVE variant (all locks up front) is deadlock-free.
```

### Statement 3 — why cascadeless follows

```
  Under SS2PL, T1's write lock on X survives until T1 commits.
  ⇒ nobody can read X before T1 commits
  ⇒ nobody ever reads uncommitted data
  ⇒ an abort of T1 can never force anyone else to abort.   ✓ no cascade
```

---

## Q11 — Transaction boundaries for a hotel booking ✅

**Answer (0.2 / 0.2): started at point 2, committed at point 5.**

Official justification: *"Yes, the transaction must include all database calls, but nothing more."*

```
  point 1   ·········· (user interaction zone — must stay OUTSIDE)
  user enters and submits changes
  ┌─ point 2 ◄══════════ BEGIN TRANSACTION
  │ retrieve booking from DB     ← DATABASE CALL #1  (the READ)
  │ point 3
  │ apply changes in memory      ← pure computation, but it sits between
  │ point 4                        the two DB calls so it must be inside
  │ save new state to DB         ← DATABASE CALL #2  (the WRITE)
  └─ point 5 ◄══════════ COMMIT
  UI confirms update             ·········· (presentation — stays OUTSIDE)
  point 6
```

### Why not earlier?

```
  Starting at point 1 puts USER THINK-TIME inside the transaction:

   BEGIN ──► [user stares at form for 4 minutes] ──► read ──► write ──► COMMIT
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
             locks held the whole time ⇒ everyone else blocks
```

### Why not later / why both calls together?

This is a **read-modify-write**. Splitting it loses the update:

```
  WITHOUT one enclosing transaction:
     A: read booking (price=100)
     B: read booking (price=100)
     A: write price=150   commit
     B: write price=200   commit     ⇒ A's change silently vanished (LOST UPDATE)
```

Committing at point 6 instead of 5 would merely hold locks across a UI message that
performs no database access — pure contention with no benefit.

---

## Q12 — Do the two scenarios interfere? ❌ **WRONG ANSWER**

| | |
|---|---|
| **My answer** | "Everything is correct, there is no risk of an erroneous result." ❌ |
| **Correct answer** | **"There is a possibility that the two scenarios might interfere, producing an erroneous result."** ✅ |
| **Official feedback** | *"No, scenario one has no transaction, and therefore does not care about locks. That means reading might be done when only a part of the writing in scenario two is done."* |

### The setup

```
  SCENARIO 1  (NO transaction at all, not even during the DB call)
    · user specifies a document name
    · program retrieves the content from the database     ◄── unprotected READ
    · program displays the content

  SCENARIO 2  (properly wrapped)
    · user views & edits
    · user clicks Save
    · BEGIN TRANSACTION
    ·   changes are written to the database
    · COMMIT
    · program reports success
```

### Why my reasoning was wrong

I assumed the read in scenario 1 was a **single atomic SQL statement**, reasoning that
autocommit would make it see either the pre-write or post-write state, never a mixture.

That assumption is not warranted, and it is not what the question says. The question is
explicit: *"There is no transaction at all in scenario one, **not even during the database
call**."* That phrase is there precisely to shut down the autocommit argument.

**No transaction ⇒ no locks are taken ⇒ no isolation of any kind.**
Scenario 1 does not participate in the locking protocol, so scenario 2's write locks
cannot hold it back. Retrieving "the content of a document" is realistically several rows
or chunks, and the read can land in the middle of scenario 2's write.

### What actually goes wrong

```
  time ──────────────────────────────────────────────────────────►

  SCENARIO 2:   BEGIN ── write chunk1 ── write chunk2 ── write chunk3 ── COMMIT
                            (new)          (new)           (new)

  SCENARIO 1:                      read chunk1  read chunk2  read chunk3
                                      NEW          NEW          OLD
                                   └──────────────────────────────────┘
                                   displays a MIXTURE of old and new text
                                   = a document that never existed  ✗
```

A locked transaction would have been made to wait (or given a consistent snapshot).
A lock-free read is simply allowed to walk straight through the middle of the write.

### Why the other options are wrong

| Option | Why not |
|---|---|
| "Everything is correct, no risk" | ❌ the unprotected read has zero isolation — my error |
| "Scenario **one alone** will **always** produce an erroneous result" | ❌ "always" is too strong. Run alone with no concurrent writer, scenario 1 is fine. The danger is conditional on interleaving. |
| "Scenario **two alone** will **always** produce an erroneous result" | ❌ scenario 2 is correctly written: transaction wraps the DB call, user interaction stays outside. Alone it is flawless. |

### The lesson

> **Read-only operations need transactions too.**
> A transaction is not only about protecting *your* writes — it is how you declare that
> you want a *consistent view* of what others are writing. Code that reads outside a
> transaction opts out of the locking protocol entirely and can observe torn,
> half-committed state.

```
   ┌──────────────────────────────────────────────────────────────┐
   │  WRONG MENTAL MODEL                                          │
   │  "it's just a read, it can't corrupt anything, so no need"    │
   │                                                              │
   │  CORRECT MENTAL MODEL                                        │
   │  "a read without a transaction takes no locks, so it has no  │
   │   isolation, so it can SEE corruption-in-progress"           │
   └──────────────────────────────────────────────────────────────┘
```

---

## Q13 — Isolation level for a report ✅

**Answer (0.2 / 0.2): READ COMMITTED.**

Official justification: *"Yes, this is the most relaxed isolation which does not read uncommitted data."*

### Translating the requirements

```
  "report must only include events that ACTUALLY HAPPENED"
         │
         └──► must not read data from transactions that later roll back
         └──► NO DIRTY READS
         └──► ✗ READ UNCOMMITTED is eliminated

  "not required that exactly all events are included; OK if a small subset is missed"
         │
         └──► phantoms / non-repeatable reads are ACCEPTABLE
         └──► ✗ REPEATABLE READ and ✗ SERIALIZABLE are stronger than needed

  "reading a HUGE number of values"
         │
         └──► strong isolation would hold enormous numbers of locks for a long time,
              throttling every concurrent writer
         └──► choose the WEAKEST SUFFICIENT level

  ⇒ READ COMMITTED
```

```
  READ UNCOMMITTED ──┬── dirty reads ⇒ could report events that never happened  ✗
                     │
  READ COMMITTED ────┼── no dirty reads ✓, phantoms allowed ✓ (acceptable)   ◄── PICK
                     │   cheapest option that meets the requirement
  REPEATABLE READ ───┼── blocks non-repeatable reads: more locks, no benefit here
                     │
  SERIALIZABLE ──────┴── range locks over a huge scan: maximum contention
```

**General principle:** pick the *weakest* isolation level that satisfies the stated
correctness requirement. Over-isolating is a performance bug.

---

## Q14 — Bank transfer vs. concurrent sum ❌ **WRONG ANSWER**

| | |
|---|---|
| **My answer** | all three options ❌ |
| **Correct answer** | **only "The sum of the balance in all the holder's account might be too low."** ✅ |

### The setup

```
  OPERATION 1 (transfer, same holder):   withdraw X from account A
                                         deposit  X into account B
  OPERATION 2 (sum):                     total money across all the holder's accounts

  Guarantee level: "transactions guarantee atomic execution of SQL STATEMENTS,
                    two SQL statements cannot access the same data at the same time.
                    NOTHING MORE is guaranteed."
```

So: **each individual statement is atomic and isolated; there is no transaction spanning
multiple statements.**

### Option-by-option

#### ✅ "The sum might be too LOW" — CORRECT

Official: *"Yes, the summing operation might read all balances after the transfer operation has withdrawn money, but before it has deposited."*

```
  time ─────────────────────────────────────────────────►

  TRANSFER:   withdraw 500 from A ─────────── deposit 500 into B
                                   ╲         ╱
                                    ╲       ╱
                                  ┌──────────────┐
  SUM:                            │  reads here  │
                                  └──────────────┘
                                   A is already −500
                                   B is not yet +500
                                   ⇒ 500 is IN FLIGHT, invisible
                                   ⇒ TOTAL TOO LOW  ✗
```

The window between the withdrawal and the deposit is the only inconsistent instant, and
during it money is **missing**, never duplicated.

#### ❌ "The sum might be too HIGH" — my error

Official: *"No, that could only happen if depositing was done before withdrawing, which is not possible."*

My reasoning was: the sum reads A *before* the withdrawal and B *after* the deposit, so
the amount gets counted twice. **The flaw: that requires the summing operation to be
several separate statements.**

But the premise says *"two SQL statements cannot access the same data at the same time"* —
the sum is **one SQL statement** (`SELECT SUM(balance) ... WHERE holder = X`) and is
therefore atomic. It reads **one instant**, not a span of time.

```
  The sum takes an ATOMIC SNAPSHOT. Only three instants are possible:

  ┌──────────────┬────────────────────────┬──────────────┐
  │ before       │ between withdraw       │ after        │
  │ withdraw     │ and deposit            │ deposit      │
  ├──────────────┼────────────────────────┼──────────────┤
  │  A=1000      │  A= 500                │  A= 500      │
  │  B=   0      │  B=   0                │  B= 500      │
  │  sum=1000 ✓  │  sum= 500  TOO LOW ✗   │  sum=1000 ✓  │
  └──────────────┴────────────────────────┴──────────────┘

  TOO HIGH would need:  A=1000 (pre-withdraw) AND B=500 (post-deposit)
  simultaneously. Impossible — the withdrawal ALWAYS precedes the deposit,
  so there is no instant where the deposit is visible but the withdrawal is not.
```

> **The ordering is the whole argument.** `withdraw → deposit` means the only
> intermediate state is *money-missing*. If the transfer deposited first, "too high"
> would become the reachable error and "too low" impossible.

#### ❌ "The holder might lose money because the transfer might not deposit what was withdrawn" — my error

Official: *"No, the other (summing) operation only reads, and can not destroy any data written by the transfer operation."*

I argued from **atomicity**: with no transaction wrapping the two statements, a crash
between them loses money. True in general — but **out of scope for this question**.

The question asks what can go wrong *because these two operations run concurrently*. The
second operation is **read-only**. A reader cannot cause a writer's second statement to
fail, cannot roll it back, cannot overwrite it.

```
  TRANSFER:  withdraw ──────────── deposit        (both statements execute)
  SUM:            read  read  read                 (pure reads, zero writes)
                     │
                     └── cannot interfere with the transfer's progress

  Losing money would require a CRASH or FAILURE between the two statements.
  That is an ATOMICITY problem, not a CONCURRENCY problem, and no failure is
  part of this scenario.
```

### Summary of the fix

```
  ┌───────────────────────────────┬──────────┬────────────────────────────────────┐
  │ Option                        │ Verdict  │ Governing fact                     │
  ├───────────────────────────────┼──────────┼────────────────────────────────────┤
  │ sum too HIGH                  │   ✗      │ withdraw ALWAYS precedes deposit   │
  │ holder loses money            │   ✗      │ the other operation only READS     │
  │ sum too LOW                   │   ✓      │ reads the withdraw/deposit gap     │
  └───────────────────────────────┴──────────┴────────────────────────────────────┘
```

### The fix in code

```sql
-- BROKEN: two independent atomic statements, no enclosing transaction
UPDATE accounts SET balance = balance - 500 WHERE id = 'A';
--  ◄── a concurrent SELECT SUM(...) here sees a total that is 500 too low
UPDATE accounts SET balance = balance + 500 WHERE id = 'B';

-- CORRECT: one transaction makes the intermediate state invisible
BEGIN;
  UPDATE accounts SET balance = balance - 500 WHERE id = 'A';
  UPDATE accounts SET balance = balance + 500 WHERE id = 'B';
COMMIT;
--  the gap still exists physically, but no other transaction can observe it
```

---

# Part III — The Two Mistakes In Depth

Both errors share one root cause: **reasoning about what the database "probably" does
instead of what the question states is guaranteed.**

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  Q12 — I ASSUMED MORE PROTECTION THAN WAS GIVEN                         │
  │                                                                         │
  │  I assumed: "a single read is atomic under autocommit, so it's safe"     │
  │  Stated:    "no transaction at all, NOT EVEN during the database call"   │
  │  Result:    invented an isolation guarantee that was explicitly denied   │
  │  Direction: too OPTIMISTIC ⇒ missed a real risk                         │
  └─────────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────┐
  │  Q14 — I ASSUMED LESS PROTECTION THAN WAS GIVEN                         │
  │                                                                         │
  │  I assumed: "the sum reads account-by-account over a span of time"      │
  │  Stated:    "atomic execution of SQL statements" ⇒ the sum is ONE        │
  │             statement ⇒ one instant                                      │
  │  Result:    invented an interleaving the guarantee rules out             │
  │  Direction: too PESSIMISTIC ⇒ flagged impossible failures                │
  └─────────────────────────────────────────────────────────────────────────┘
```

### Checklist for this question type

1. **Underline the stated guarantee and treat it as exact.** "Atomic per statement" is a
   gift (use it) *and* a limit (nothing spans statements).
2. **Count the statements.** One statement = one atomic instant. Several statements =
   a window an interleaving can exploit.
3. **Ask "is it inside a transaction?" for reads too.** No transaction = no locks = no
   isolation, for readers just as much as writers.
4. **Check operation ordering before claiming an anomaly.** In Q14, `withdraw → deposit`
   makes "too low" reachable and "too high" unreachable. Reverse the order and the
   answers swap.
5. **Separate the failure axis from the concurrency axis.** "Could a crash lose data?"
   (atomicity) is a different question from "could these two concurrent operations
   produce a wrong result?" (isolation). Answer only what was asked.

---

# Part IV — Cheat Sheet

### Final answers

| Q | Answer |
|---|---|
| 1 | a = Conservative SS2PL · b = 2PL (non-strict) · c = Strong Strict 2PL · d = Naive · e = Conservative 2PL (non-strict) · f = Strict 2PL (not strong) |
| 2 | all except "Fig.f can deal with deadlocks" |
| 3 | T1 → slot 3 · T2 → slot 5 · T3 → slot 2 |
| 4 | the third conflict graph |
| 5 | Sant (True) — serial order T3, T4, T1, T2 |
| 6 | mark: Durability-via-2PL · Atomicity-gives-isolated-view · CS-forbids-blind-writes |
| 7 | only "T5 is a valid victim candidate" |
| 8 | schedules 2 and 5 |
| 9 | "corresponds to i)" **and** "there is no deadlock" |
| 10 | "always ensures repeatable reads" · "avoids cascading rollbacks" |
| 11 | start at point 2, commit at point 5 |
| **12** | **"the two scenarios might interfere, producing an erroneous result"** |
| 13 | READ COMMITTED |
| **14** | **only "the sum might be too low"** |

### Rules worth memorising

```
  1.  Read–Read NEVER conflicts.                    (Q4)
  2.  Only S/S locks are compatible.                (Q8, Q9)
  3.  Deadlock ⟺ cycle in the wait-for graph.       (Q7, Q8, Q9)
  4.  A victim must lie ON the cycle;
      out-degree 0 ⇒ never a victim.                (Q7)
  5.  Only CONSERVATIVE 2PL prevents deadlock.      (Q2, Q10)
  6.  "Strong" = READ locks held to commit too.     (Q1, Q10)
  7.  No 2PL variant stops PHANTOMS.                (Q10)
  8.  Locking gives ISOLATION, never DURABILITY.    (Q6)
  9.  Cascadeless ⟺ read only COMMITTED data.      (Q3, Q10)
 10.  A transaction = all DB calls, nothing more.    (Q11)
 11.  READS need transactions too — no transaction
      means no locks means no isolation.            (Q12)
 12.  One SQL statement = one atomic instant;
      several statements = an exploitable window.   (Q14)
 13.  Pick the WEAKEST sufficient isolation level.  (Q13)
```

### Deriving a conflict graph — procedure

```
  1. Flatten the schedule into a single time-ordered operation list.
  2. Group the operations by DATA ITEM.
  3. Within each group, for every ordered pair (earlier, later):
        both reads?      ─► no edge
        otherwise        ─► edge earlier-transaction ──► later-transaction
  4. Union all edges. Look for a cycle.
        acyclic ─► conflict serializable; topological order = serial equivalent
        cyclic  ─► not conflict serializable
```

### Simulating lock requests — procedure

```
  1. Walk the timeline one request at a time.
  2. Maintain, per item, the mode held (S-set or X-holder).
  3. On each request, consult the compatibility matrix:
        compatible   ─► grant, extend the holder set
        incompatible ─► BLOCK; add edge requester ──► holder
  4. A blocked transaction issues no further requests.
  5. Deadlock ⟺ the resulting wait-for graph has a cycle.
```
