-- =====================================================================
-- Portfolio 2: Create indexes
-- Run: psql -U postgres -d ndfs_db -f <this file>
-- =====================================================================

-- Index 1: covering index for date-driven production reports (Q1, Q2, Q3).
--   Leads with reading_date because these queries filter on date ranges across ALL wells.
--   The existing UNIQUE (well_id, reading_date) index leads with well_id, so it cannot help here.
--   INCLUDE adds the volumes so PostgreSQL can answer from the index alone (Index Only Scan).
CREATE INDEX idx_reading_date_cov
    ON production_reading (reading_date) INCLUDE (well_id, oil_bbl, gas_mscf, water_bbl);

-- Index 2: composite index for "history of one asset" (Q4).
--   PostgreSQL does not index foreign keys automatically. equipment_id is filtered on and
--   raised_at DESC matches the ORDER BY.
CREATE INDEX idx_wo_equipment_raised
    ON work_order (equipment_id, raised_at DESC);

-- Index 3: PARTIAL index for the open backlog (Q5).
--   Over 99.9% of work orders are COMPLETED. Only the few open ones are indexed, so the
--   index is tiny and cheap to maintain.
CREATE INDEX idx_wo_open_backlog
    ON work_order (priority, raised_at)
    WHERE status IN ('OPEN','ASSIGNED','IN_PROGRESS');

-- Index 4: date-range filter on work orders (Q6).
CREATE INDEX idx_wo_raised_at ON work_order (raised_at);

-- Index 5: foreign-key index (used by joins from equipment to station).
CREATE INDEX idx_equip_station ON equipment (station_id);

ANALYZE;

\qecho '--- Index sizes (cost of indexing: disk space and slower writes)'
SELECT indexrelname AS index_name, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE relname IN ('production_reading','work_order','equipment')
ORDER BY pg_relation_size(indexrelid) DESC;
