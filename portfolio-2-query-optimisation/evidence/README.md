# Portfolio 2: Query Processing and Optimisation

**Case study:** NDFS flow station and maintenance database (see Portfolio 1).
**DBMS:** PostgreSQL 18.6 (Windows). **Data volume after the bulk load:** about 128,000 production readings, 200,000 work orders, 400,000 assignments, 200,000 work-order parts.

## Files and run order
| Step | File | Purpose |
|---|---|---|
| 1 | `01_bulk_data.sql` | Generates synthetic history so that plans are meaningful (needs Portfolio 1 scripts 01 and 02 first) |
| 2 | `02_queries.sql` | Seven business queries with results |
| 3 | `03_explain_before_indexes.sql` | `EXPLAIN (ANALYZE, BUFFERS)` baseline |
| 4 | `04_create_indexes.sql` | Five indexes with the reasoning for each, plus index sizes |
| 5 | `05_explain_after_indexes.sql` | Same plans after indexing |
| 6 | `evidence/` | Screenshots of the outputs above (your own) |

## The queries
| # | Business question | Techniques |
|---|---|---|
| Q1 | Oil, gas, water per station in 2025 | 3-table join, aggregation, date range |
| Q2 | Top 10 wells in the last 90 days | join, aggregation, `ORDER BY ... LIMIT` |
| Q3 | Field-wide production on one day | single-table equality filter on a non-leading column |
| Q4 | Maintenance history of one asset | foreign-key filter + sort |
| Q5 | Open work-order backlog by urgency | selective filter on a skewed column |
| Q6 | Downtime and parts cost per station, 2025 | 5-table join, derived table (pre-aggregation) |
| Q7 | Rank wells within their station | window function `RANK() OVER (PARTITION BY ...)` |

## Index decisions (and why)
1. **`idx_reading_date_cov (reading_date) INCLUDE (well_id, oil_bbl, gas_mscf, water_bbl)`**
   The existing unique index is `(well_id, reading_date)`, which leads with the well. A covering index that leads
   with the date matches the date-based reports, and `INCLUDE` stores the volumes in the index so PostgreSQL can
   answer without visiting the table (*Index Only Scan*, `Heap Fetches: 0`).
2. **`idx_wo_equipment_raised (equipment_id, raised_at DESC)`**: PostgreSQL does not index foreign keys automatically.
3. **`idx_wo_open_backlog (priority, raised_at) WHERE status IN (...)`**: a *partial index*. Only 3 of 200,010
   work orders are open, so only those 3 are indexed.
4. **`idx_wo_raised_at`** and 5. **`idx_equip_station`**: supporting indexes for range filtering and joins.

## Results (measured on my machine, PostgreSQL 18.6)
Full plans: `evidence/p2_before_plans.txt`, `evidence/p2_after_plans.txt`. Summary: `evidence/p2_timings.txt`.

| Query | Plan before | Before (ms) | Plan after | After (ms) | Speed-up | Pages touched |
|---|---|---|---|---|---|---|
| Q1 | Bitmap Index Scan, `uq_reading_well_date` (skip scan) | 18.98 | Index Only Scan, `idx_reading_date_cov` | 16.69 | 1.1x | 429 -> 137 |
| Q2 | Bitmap Index Scan, `uq_reading_well_date` (skip scan) | 5.02 | Index Only Scan, `idx_reading_date_cov` | 4.65 | 1.1x | 243 -> 40 |
| Q3 | Bitmap Index Scan, `uq_reading_well_date` (skip scan) | 0.22 | Index Only Scan, `idx_reading_date_cov` | 0.07 | 3.3x | 153 -> 4 |
| Q4 | Parallel Seq Scan, `work_order` | 178.18 | Bitmap Index Scan, `idx_wo_equipment_raised` | 2.32 | 77x | 3,471 -> 1,305 |
| Q5 | Parallel Seq Scan, `work_order` | 169.85 | Bitmap Index Scan, `idx_wo_open_backlog` (partial) | 0.09 | 1,846x | 3,403 -> 4 |
| Q6 | Parallel Seq Scan, `work_order` | 341.61 | Bitmap Index Scan, `idx_wo_raised_at` | 270.71 | 1.3x | 7,234 -> 5,399 |
| Q7 | Bitmap Index Scan, `uq_reading_well_date` (skip scan) | 16.92 | Index Only Scan, `idx_reading_date_cov` | 14.15 | 1.2x | 429 -> 137 |

## Performance analysis

**Where indexing made the biggest difference.** The two work-order queries gained the most. Before I added any
indexes, Q4 and Q5 had to go through all 200,010 work orders with a `Parallel Seq Scan`, throwing away about 66,000
rows in each worker, just to return 1,645 rows (Q4) and 3 rows (Q5). After indexing, Q4 dropped from 178 ms to 2.3 ms
using `idx_wo_equipment_raised`. Q5 dropped from 170 ms to 0.09 ms using the partial index `idx_wo_open_backlog`, and
it touched only 4 pages instead of 3,403. This made sense to me once I saw the sizes: the partial index only stores the
3 open orders, which is exactly what a maintenance planner looks at every morning, so it stays tiny.

**What surprised me: skip scan in PostgreSQL 18.** I expected the production reports (Q1, Q2, Q3 and Q7) to scan the
whole table before indexing, because the only index on `production_reading` starts with `well_id`, while these
queries filter by `reading_date`. That is not what happened. PostgreSQL 18 still used that index through a skip scan,
searching it once per well (`Index Searches: 62` for 60 wells). Because of that, these queries were already quick, and
my new covering index only made them 1.1x to 3.3x faster. Where it clearly helped was the number of pages read: Q3 went
from 153 pages to 4, because the plan changed to an `Index Only Scan` with `Heap Fetches: 0`, meaning it never had to
open the table at all. On an older version of PostgreSQL without skip scan, I would expect the before-plans to be full
sequential scans and the gains to be much larger.

**Where indexing did not help much.** Q6 only improved from 342 ms to 271 ms. Reading the plan, most of the time is
spent in the `GroupAggregate` step, which adds up spare-parts cost for all 200,010 work orders before the 2025 filter is
applied. The new `idx_wo_raised_at` index finds the 2025 orders faster, but that was never the slow part. To really fix
Q6 I would rewrite the query to filter by date first, or keep a summary table of cost per work order. The lesson for me
is that an index cannot fix a query that asks the database to do too much work.

**The cost of indexes.** Indexes are not free. They take disk space (see `p2_04_indexes_created.png`), and every
INSERT or UPDATE on `production_reading` and `work_order` now has to update the indexes as well. In a real flow station
system where readings come in constantly, I would only keep the indexes that support reports people actually use. For
example, `idx_equip_station` adds very little on a table of only 120 rows.

**Limitations.** The data is synthetic and the tests ran on my laptop, so the exact milliseconds change from run to
run, and the first run after a restart is slower because data is read from disk (the `read=` values in the buffers).
For that reason I paid more attention to the plan type and the number of pages touched than to the milliseconds alone.

## Reading a plan: points shown in the screenshots
- `Seq Scan` vs `Bitmap Index Scan` / `Index Only Scan`
- `Index Searches` (skip scan in PostgreSQL 18)
- `Rows Removed by Filter` (wasted work)
- `Heap Fetches: 0` on an Index Only Scan
- `Buffers: shared hit/read` (pages touched)
- `actual time` and `Execution Time`
