# Normalisation Explanation

## 1. Starting point: an unnormalised maintenance sheet
A maintenance planner might first record work in one wide spreadsheet row:

| WO# | Equipment tag | Station | Station region | Technicians | Parts used | Description |
|---|---|---|---|---|---|---|
| 3 | OBG-P-101 | Obagi Flow Station 3 | ONSHORE_WEST | Bassey Etim, Tamuno Briggs | MS-5521 x1 | Seal leak |

Problems: several values in one cell (technicians, parts), and station details
repeated on every row for that station.

## 2. First Normal Form (1NF): atomic values, no repeating groups
Rule: every column holds a single value and there are no repeating groups.
- "Technicians" and "Parts used" held lists, so they move out into their own rows.
- Each (work order, technician) pair becomes one row in `work_order_assignment`;
  each (work order, part) pair becomes one row in `work_order_part`.
- Every table has a primary key.

## 3. Second Normal Form (2NF): no partial dependency on part of a composite key
Rule: in a table with a composite key, every non-key column must depend on the
whole key.
- `work_order_assignment(work_order_id, technician_id, role, hours_worked)`: `role` and
  `hours_worked` describe a technician *on a particular job*, so they depend on both
  key parts together. OK.
- `work_order_part(work_order_id, part_id, quantity_used)`: `quantity_used` depends on
  the pair. OK.
- Part description and unit cost depend only on `part_id`, so they were moved to
  `spare_part`. Technician name and trade depend only on `technician_id`, so they sit
  in `technician`. Keeping them in the junction tables would be a partial dependency.

## 4. Third Normal Form (3NF): no transitive dependency
Rule: non-key columns must depend on the key, "the whole key and nothing but the key".
- In the original sheet, `station region` depends on `Station`, which depends on the
  equipment tag. That is a transitive chain (equipment -> station -> region).
- Station name, region, state and capacity were therefore moved to `flow_station`.
  `equipment` and `well` carry only `station_id`.
- Result: renaming a station or correcting its region is **one update in one row**,
  not an edit on every well and equipment row (no update anomaly). Deleting the last
  well does not erase the station (no deletion anomaly). A new station can be added
  before it has wells (no insertion anomaly).

## 5. Table-by-table check (all in 3NF)
| Table | Key | Why it is in 3NF |
|---|---|---|
| flow_station | station_id | Attributes describe only the station. |
| well | well_id | Station facts are not repeated; only the FK `station_id`. |
| equipment | equipment_id | Same: station facts live in `flow_station`. |
| production_reading | reading_id (and unique well_id + reading_date) | Volumes depend on well and day only. |
| technician | technician_id | Only technician facts. |
| work_order | work_order_id | Equipment facts are not copied; only `equipment_id`. |
| work_order_assignment | (work_order_id, technician_id) | Both columns depend on the full pair. |
| spare_part | part_id | Only part facts. |
| work_order_part | (work_order_id, part_id) | `quantity_used` depends on the pair. |
| hse_incident | incident_id | Station is a FK; equipment FK is optional (nullable). |

## 6. Deliberate decisions and trade-offs
- **Surrogate keys** (`SERIAL`) are used as primary keys and natural identifiers
  (`tag_number`, `part_number`, `station_code`) are kept `UNIQUE`. Tag numbers can be
  re-issued, while surrogate keys never change.
- **`hse_incident` has both `station_id` and `equipment_id`.** The station can be
  derived through the equipment, but an incident may involve no equipment (for example
  a slip or a near miss), so `station_id` is required and `equipment_id` is optional.
  When equipment is present, the application should check it belongs to that station.
  This is a documented trade-off, not an accident.
- **Production readings are not pre-aggregated.** Station totals are computed by query
  (Portfolio 2). Storing totals would create a derived-data redundancy that could go
  out of sync.
- **Constraints enforce business rules in the database**: `CHECK` for allowed values
  and non-negative volumes, `UNIQUE (well_id, reading_date)` for one reading per day,
  `ON DELETE RESTRICT` so history cannot be orphaned. See `03_constraint_tests.sql`.
- **Controlled denormalisation** is considered later: in MongoDB (Portfolio 4) a work
  order is embedded with its parts and assignments because they are read together.
