# Portfolio 3: Transactions and Concurrency

**Case study:** NDFS maintenance and spare-parts workflow. **DBMS:** PostgreSQL 18.6 on Windows (default isolation: READ COMMITTED). Two SQL Shell (psql) windows were used as Session A and Session B.

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

## What I observed (my runs)
| Experiment | What happened on my machine | Why | Evidence |
|---|---|---|---|
| 1A Commit | Bearing stock went 20 -> 18 and the work order became COMPLETED in one transaction | All steps committed together | `p3_01_*.png` |
| 1B Rollback | Stock showed 7 inside the transaction, then went back to 12 after ROLLBACK | ROLLBACK undoes every change | `p3_01_*.png` |
| 1C Failure | Asking for 5 valves with 3 in stock raised `ck_part_qty`; the transaction was aborted, 0 orders saved, stock still 3 | Atomicity: a failed step cancels the whole job | `p3_01_*.png` |
| 1D Savepoint | Only the failed step was undone; the order was kept and 2 valves were used (3 -> 1) | `ROLLBACK TO SAVEPOINT` is a partial undo | `p3_01_*.png` |
| 2A Lost update | Both sessions read 3 and both wrote 1; final stock 1 although 4 valves were issued | B overwrote A's change based on a stale read | `p3_02_lost_update.png` |
| 2B FOR UPDATE | Session B waited, then saw 1 instead of 3 | The row lock made the two officers take turns | `p3_03a/b_*.png` |
| 2C Conditional UPDATE | Session B waited, then got `UPDATE 0` | PostgreSQL re-checked `quantity_on_hand >= 2` against the committed value | `p3_03c_atomic_update.png` |
| 3A READ COMMITTED | The same query returned 12, then 9, inside one transaction | Each statement sees the latest committed data (non-repeatable read) | `p3_04a_read_committed.png` |
| 3B REPEATABLE READ | Reads stayed at 12; my UPDATE failed with `could not serialize access due to concurrent update` | Stable snapshot; conflicting writes are refused | `p3_04b_repeatable_read.png` |
| 3C SERIALIZABLE | Both sessions saw 2 active technicians; A committed, B failed with `read/write dependencies among transactions`; technician 4 stayed active | Write skew detected and prevented | `p3_05_serializable.png` |
| 4 Deadlock | Session B received `deadlock detected`; Session A completed and committed | Opposite lock order made a cycle; PostgreSQL cancelled one victim | `p3_06_deadlock.png` |
| 5 Function | First call used 2 valves and printed a REORDER ALERT; second call was refused with `Insufficient stock`; stock stayed at 1 | Lock, check, record and deduct happen as one unit | `p3_07_consume_part_function.png` |

**Something I learned the hard way.** On my first attempt at the SERIALIZABLE test, Session B read the count only
after Session A had already committed, so B saw 1 instead of 2 and no error appeared. SERIALIZABLE can only detect the
conflict when both transactions read before either one writes. Re-running it in the correct order produced the expected
error. This showed me that concurrency problems depend on exact timing, which is why they are hard to spot in testing.

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
