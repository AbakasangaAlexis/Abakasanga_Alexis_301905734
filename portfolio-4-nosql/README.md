# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** NDFS flow station and maintenance system (same organisation as Portfolios 1 to 3).
**NoSQL system:** MongoDB 7 (document model, plus a time-series collection).
**Status note:** the scripts were syntax-checked, but you must run them yourself against your own MongoDB (local or Atlas) and capture your own screenshots.

## Why MongoDB for part of NDFS
The relational design remains the system of record for transactional, strongly related data (stock, work-order
workflow). Two parts of the business fit a document model better.

| Need | Relational pain | MongoDB answer | Collection |
|---|---|---|---|
| Equipment specifications differ by type (pumps have `flow_rate_m3h`, compressors have `stages`, tanks have `roof`) | One wide table full of NULLs, or an entity-attribute-value table that is hard to query | Each document carries only its own attributes (schema flexibility) | `equipment_specs` |
| A work order is always read together with its technicians and parts | Joins across 3 tables (work_order, assignment, part) | **Embed** assignments and parts inside the order: one read | `work_orders` |
| Sensor telemetry (vibration, temperature, pressure) every few minutes per machine | Very high insert rate and volume; rarely updated | Time-series collection: compressed storage, fast time-window queries | `sensor_telemetry` |

## Model: embed versus reference
- **Embedded (`work_orders.assignments[]`, `work_orders.parts[]`)**: bounded size, read with the parent, never queried alone.
  Trade-off: part unit cost is copied into the order (this is useful, it preserves the price at the time of the job)
  but the part's *current* stock stays in PostgreSQL.
- **Referenced (`work_orders.equipment_tag` -> `equipment_specs.tag_number`)**: equipment is shared by thousands of orders
  and changes independently, so it is referenced, not copied. `$lookup` performs the join when needed (Q6).
- **Cross-system key:** `tag_number` is the same `UNIQUE` tag used in PostgreSQL, which makes the two systems linkable.

### Relational to document mapping
| PostgreSQL (Portfolio 1) | MongoDB (this portfolio) |
|---|---|
| `equipment` row + type-specific NULL columns | `equipment_specs` document with a `specs` sub-document |
| `work_order` + `work_order_assignment` + `work_order_part` | one `work_orders` document with arrays |
| `production_reading` (daily, per well) | would be a time-series collection too; telemetry is shown here |
| Foreign key constraint | application-level reference (validated by `$jsonSchema` for shape, not for existence) |

## Files
| File | What it does |
|---|---|
| `01_setup_collections.js` | Creates the three collections, a `$jsonSchema` validator, and the time-series collection |
| `02_insert_data.js` | Loads 10 equipment documents, 20,000 work orders and 4,032 telemetry readings |
| `03_queries.js` | Find, aggregation, `$lookup`, update, insert, delete and validation tests |
| `04_indexes_and_explain.js` | `explain("executionStats")` before and after indexes |
| `evidence/` | Your screenshots |

## How to run
Option A, MongoDB Atlas free tier (also used for Portfolio 5):
1. Create a free cluster (M0) and a database user; allow your IP in Network Access.
2. Install `mongosh`, then run: `mongosh "<your connection string>" --file 01_setup_collections.js` and continue with 02, 03, 04.

Option B, local MongoDB Community Server: `mongosh "mongodb://localhost:27017" --file 01_setup_collections.js`, and so on.

Screenshots to capture: collection list (01), document counts (02), outputs of Q1 to Q6 and the validation rejection (03),
and the COLLSCAN to IXSCAN comparison (04). Atlas users can also screenshot the Data Explorer showing the documents.

## Evaluating suitability (framework from Session 1)
| Criterion | Assessment for NDFS equipment/work-order/telemetry data |
|---|---|
| Scalability | Horizontal scaling by sharding (see Portfolio 5); telemetry grows without bound |
| Consistency vs availability | Single-document operations are atomic; replica sets favour consistency with majority write concern, tunable for telemetry |
| Query performance | Embedding removes joins for work orders; time-series buckets speed time-window scans |
| Schema flexibility | Strong fit: equipment attributes vary by type and new equipment types appear |
| Transactions | Multi-document ACID transactions exist, but stock deduction stays in PostgreSQL where constraints and joins are native |
| Security | Role-based access control, TLS, encryption at rest, auditing (Atlas provides these) |
| Operational overhead | Managed service (Atlas) removes patching and backup work |

**Why not Cassandra?** The lecture notes position Cassandra for very high-throughput IoT write loads. If NDFS
streamed thousands of sensors at second-level frequency from every station, a wide-column store such as Cassandra
(or a streaming layer such as Kafka feeding a lake) would be considered. MongoDB's time-series collection is
adequate at the volume modelled here and keeps the toolset small.

**Limitations honestly stated.** `$jsonSchema` checks document shape, not referential integrity; embedding
duplicates data (unit cost), so cross-order price updates need care; multi-document transactions cost more than in a relational system.
