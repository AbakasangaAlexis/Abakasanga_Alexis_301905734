-- =====================================================================
-- Portfolio 1: Constraint tests. Every statement below is EXPECTED TO FAIL.
-- A failure proves the constraint is enforced. Take a screenshot of the output.
-- Run: psql -U postgres -d ndfs_db -f 03_constraint_tests.sql
-- (do not use ON_ERROR_STOP here: we want to see every error)
-- =====================================================================

\echo '--- T1: duplicate primary key (station_id 1 already exists)'
INSERT INTO flow_station VALUES (1,'DUP-FS','Duplicate','SWAMP','Rivers','2020-01-01',1000);

\echo '--- T2: foreign key violation (well points to non-existent station 99)'
INSERT INTO well (station_id, well_name, well_type, spud_date, depth_ft)
VALUES (99,'GHOST-001','OIL','2020-01-01',9000);

\echo '--- T3: CHECK violation (negative oil volume)'
INSERT INTO production_reading (well_id, reading_date, oil_bbl) VALUES (1,'2026-12-01',-50);

\echo '--- T4: UNIQUE violation (one reading per well per day)'
INSERT INTO production_reading (well_id, reading_date, oil_bbl) VALUES (1,'2026-11-01',500);

\echo '--- T5: CHECK violation (work order completed before it was raised)'
INSERT INTO work_order (equipment_id, wo_type, description, raised_at, completed_at, status)
VALUES (1,'CORRECTIVE','bad dates','2026-11-05 10:00','2026-11-04 10:00','COMPLETED');

\echo '--- T6: CHECK violation (stock cannot go negative)'
UPDATE spare_part SET quantity_on_hand = -1 WHERE part_number = 'VLV-2204';

\echo '--- T7: ON DELETE RESTRICT (cannot delete a station that still has wells)'
DELETE FROM flow_station WHERE station_id = 1;

\echo '--- T8: NOT NULL violation (technician without a name)'
INSERT INTO technician (full_name, trade, email, hire_date) VALUES (NULL,'GENERAL','x@ndfs.example','2026-01-01');
