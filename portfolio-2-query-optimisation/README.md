# Portfolio 2: Query Processing and Optimisation

**Case study:** NDFS flow station and maintenance database (see Portfolio 1).
**DBMS:** PostgreSQL 16. **Data volume after the bulk load:** about 128,000 production readings, 200,000 work orders, 400,000 assignments, 200,000 work-order parts.

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
   The existing unique index is `(well_id, reading_date)`. A B-tree can only be searched efficiently from its
   leading column, so it cannot serve queries that filter on date alone. A new index leading with the date fixes that.
   `INCLUDE` stores the measured columns in the index, enabling an *Index Only Scan* (no table visits).
2. **`idx_wo_equipment_raised (equipment_id, raised_at DESC)`**: PostgreSQL does not auto-index foreign keys;
   the sort order matches the query, so no separate sort is needed.
3. **`idx_wo_open_backlog (priority, raised_at) WHERE status IN (...)`**: a *partial index*. More than 99.9% of
   work orders are completed, so only the few open ones are indexed.
4. **`idx_wo_raised_at`** and 5. **`idx_equip_station`**: supporting indexes for range filtering and joins.

## Results: record YOUR measurements here
Run files 03 and 05 on your machine. Copy the `Execution Time` from each plan.

| Query | Plan node before | Time before (ms) | Plan node after | Time after (ms) | Speed-up |
|---|---|---|---|---|---|
| Q1 | Seq Scan | | Index Only Scan | | |
| Q2 | Seq Scan | | Index Only Scan | | |
| Q3 | Seq Scan | | Index Only Scan | | |
| Q4 | (Parallel) Seq Scan | | Bitmap Index Scan | | |
| Q5 | (Parallel) Seq Scan | | Index Scan (partial) | | |
| Q6 | Seq/Index Scan mix | | similar | | |
| Q7 | Seq Scan | | Index Only Scan | | |

## Performance analysis (edit using your own numbers and wording)
**What improved most.** Queries that pick a small slice of a large table (Q3 one day out of ~2,100; Q5 a handful of
open orders out of 200,000) improved by one to two orders of magnitude, because the plan changed from reading every
page (`Seq Scan`) to reading only the matching index entries. `Q5` shows why a partial index is attractive:
the index is a few kilobytes rather than megabytes.

**What improved a little.** Q1 and Q7 read about one-sixth of the production table (all of 2025), so the gain is
moderate; an index only reduces work when it avoids reading most of the table. The covering index still helps because
the plan no longer touches the table (Index Only Scan, see the `Heap Fetches` line).

**What did not improve much.** Q6 joins and aggregates large tables. Most of its time goes into aggregating
`work_order_part` for every work order in the database, because the derived table does not know about the date
filter. Adding an index does not remove that work. A better fix would be restructuring the query (filter first) or
pre-aggregating into a summary table. This is why reading the plan matters more than blindly adding indexes.

**Cost of indexing.** Each index uses disk space (see the size listing printed by `04_create_indexes.sql`) and
adds work to every INSERT/UPDATE/DELETE on its table. For a write-heavy table such as `production_reading`,
we keep only the indexes that serve real reports.

**Limitations.** Data is synthetic and the machine is small. Timings vary run to run (the first run may be slower
because of a cold cache), so compare plan shapes as well as milliseconds.

## Reading a plan: things to point out in your screenshots
- `Seq Scan` vs `Index Scan` / `Index Only Scan` / `Bitmap Index Scan`
- `cost=` (planner estimate) vs `actual time=` (measured)
- `rows=` estimated vs actual (large gaps suggest stale statistics; run `ANALYZE`)
- `Buffers: shared hit/read` (pages touched)
- `Heap Fetches` on an Index Only Scan
