# Portfolio 3: Transactions and Concurrency

**Case study:** NDFS maintenance and spare-parts workflow. **DBMS:** PostgreSQL 16 (default isolation: READ COMMITTED).

Business scenario: when a technician finishes a job, the system records the work, records the parts used and deducts
stock. Several store officers and planners do this at the same time, so the database must keep stock correct.

## Files
| File | Demonstrates |
|---|---|
| `00_reset_demo_data.sql` | Restores the stock figures so every demo is repeatable |
| `01_commit_rollback_savepoint.sql` | Atomicity: COMMIT, ROLLBACK, automatic rollback on error, SAVEPOINT |
| `02_lost_update_and_fixes.sql` | A concurrency **problem** (lost update) and two **control mechanisms** (`FOR UPDATE`, atomic conditional UPDATE) |
| `03_isolation_levels.sql` | Non-repeatable read (READ COMMITTED), snapshot + conflict detection (REPEATABLE READ), write skew prevented (SERIALIZABLE) |
| `04_deadlock.sql` | Deadlock detection and prevention by consistent lock ordering |
| `05_consume_part_function.sql` | All of the above combined in a reusable function |
| `evidence/` | Your screenshots |

Demos 02 to 04 need **two sessions**: open two Query Tool tabs in pgAdmin (or two psql windows) and run the steps
in the order labelled. Screenshot each session side by side.

## ACID mapped to this project
| Property | Where it is shown |
|---|---|
| Atomicity | 1A, 1C (the failed job leaves no partial work order or part record) |
| Consistency | `CHECK (quantity_on_hand >= 0)`, foreign keys, `ck_wo_dates`: a transaction that would break a rule is rejected |
| Isolation | Demos 02 and 03 (what one session can see of another's uncommitted/committed changes) |
| Durability | After COMMIT the change survives; PostgreSQL writes it to the write-ahead log (WAL) first |

## Expected observations (compare with your screenshots)
| Experiment | What you should see | Why |
|---|---|---|
| 2A | Final stock = 1 although 4 valves were issued from 3 | Both sessions wrote a value calculated from a stale read: **lost update** |
| 2B | Session B waits, then sees 1 | `FOR UPDATE` row lock serialises the two officers |
| 2C | Session B reports `UPDATE 0` | The WHERE clause is re-evaluated on the committed row; insufficient stock is detected without an explicit lock |
| 3A | Same query returns 12 then 9 | READ COMMITTED sees each newly committed value: non-repeatable read |
| 3B | Reads stay 12; the UPDATE fails with SQLSTATE 40001 | REPEATABLE READ gives a stable snapshot and refuses conflicting writes; the application retries |
| 3C | One of two commits is rejected with 40001 | SERIALIZABLE detects write skew (both transactions saw 2 active technicians) |
| 4 | `ERROR: deadlock detected` in one session | Opposite lock order creates a cycle; PostgreSQL aborts one victim |

## Choosing a control mechanism (discussion for your write-up)
- **Atomic conditional UPDATE (2C)** is the simplest and fastest when the rule is a single-row check.
- **`SELECT ... FOR UPDATE` (2B)** suits multi-step logic that must read, decide, then write (as `consume_part` does),
  at the cost of waiting. Keep such transactions short.
- **Higher isolation levels (3B, 3C)** protect rules that span several rows, but the application must be ready
  to retry on SQLSTATE 40001.
- **Deadlocks** cannot be eliminated by the database; the application prevents them by locking in a fixed order and
  retries the victim.
- **Link to the lectures:** these are the ACID guarantees of relational systems and the trade-off against the
  availability-oriented BASE model discussed in Session 1 and Session 2 (CAP).
