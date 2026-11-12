-- =====================================================================
-- Portfolio 2: Bulk synthetic data so that indexes and execution plans matter.
-- Run AFTER portfolio-1 scripts 01 and 02.
--   psql -U postgres -d ndfs_db -f 01_bulk_data.sql
-- Fictional, pseudo-random data. setseed makes it repeatable.
-- =====================================================================
SELECT setseed(0.42);

-- 48 more wells (total 60), spread over the 5 stations
INSERT INTO well (station_id, well_name, well_type, status, spud_date, depth_ft)
SELECT 1 + (i % 5),
       'BLK-' || lpad(i::text, 3, '0'),
       CASE WHEN i % 10 = 0 THEN 'GAS' WHEN i % 13 = 0 THEN 'INJECTOR' ELSE 'OIL' END,
       CASE WHEN i % 11 = 0 THEN 'SHUT_IN' ELSE 'ACTIVE' END,
       DATE '2005-01-01' + (i * 90),
       8000 + (i * 97) % 6000
FROM generate_series(1,48) i;

-- 105 more pieces of equipment (total 120)
INSERT INTO equipment (station_id, tag_number, equipment_type, manufacturer, install_date, criticality, status)
SELECT 1 + (i % 5),
       'BLK-E-' || lpad(i::text, 3, '0'),
       (ARRAY['PUMP','COMPRESSOR','SEPARATOR','HEATER_TREATER','GENERATOR','VALVE','TANK'])[1 + (i % 7)],
       (ARRAY['Flowserve','Sulzer','Atlas Copco','NATCO','Caterpillar','Cameron'])[1 + (i % 6)],
       DATE '2006-01-01' + (i * 60),
       1 + (i % 3),
       'IN_SERVICE'
FROM generate_series(1,105) i;

-- 33 more technicians (total 40)
INSERT INTO technician (full_name, trade, email, hire_date)
SELECT 'Technician ' || i,
       (ARRAY['MECHANICAL','ELECTRICAL','INSTRUMENTATION','PIPING','GENERAL'])[1 + (i % 5)],
       'tech' || i || '@ndfs.example',
       DATE '2012-01-01' + (i * 100)
FROM generate_series(1,33) i;

-- Daily production: every well, 1 Jan 2021 .. 31 Oct 2026 (about 128,000 rows)
-- Output declines slowly over time with random noise; about 3% of days are zero (shut-in/outage)
INSERT INTO production_reading (well_id, reading_date, oil_bbl, gas_mscf, water_bbl, choke_size_64ths)
SELECT w.well_id, d::date,
       CASE WHEN random() < 0.03 OR w.well_type = 'INJECTOR' THEN 0
            ELSE round(((900 + (w.well_id % 7) * 150) * (1 - (d::date - DATE '2021-01-01') / 9000.0)
                       * (0.85 + random() * 0.3))::numeric, 2) END,
       round(((1200 + (w.well_id % 5) * 300) * (0.85 + random() * 0.3))::numeric, 2),
       round(((200 + (d::date - DATE '2021-01-01') / 8.0) * (0.8 + random() * 0.4))::numeric, 2),
       16 + (w.well_id % 4) * 8
FROM well w
CROSS JOIN generate_series('2021-01-01'::date, '2026-10-31'::date, '1 day') d
WHERE w.status <> 'ABANDONED'
ON CONFLICT (well_id, reading_date) DO NOTHING;

-- 200,000 historical work orders over the same period
INSERT INTO work_order (equipment_id, wo_type, priority, status, description, raised_at, started_at, completed_at, downtime_hours)
SELECT eq, t, pr,
       'COMPLETED',
       'Historical ' || lower(t) || ' job on equipment ' || eq,
       r, r + interval '4 hours', r + (interval '1 hour' * (6 + dh)), dh
FROM (
  SELECT 1 + floor(random() * 120)::int                                  AS eq,
         (ARRAY['PREVENTIVE','CORRECTIVE','INSPECTION','EMERGENCY'])[1 + floor(random()*4)::int] AS t,
         1 + floor(random() * 4)::int                                     AS pr,
         TIMESTAMP '2021-01-01' + random() * (TIMESTAMP '2026-10-25' - TIMESTAMP '2021-01-01') AS r,
         round((random() * 60)::numeric, 2)                               AS dh
  FROM generate_series(1,200000)
) s;

-- One lead technician and one member per historical order (members always differ from the lead)
INSERT INTO work_order_assignment (work_order_id, technician_id, role, hours_worked)
SELECT work_order_id, 1 + (work_order_id * 7) % 40, 'LEAD', round((2 + (work_order_id % 20))::numeric, 1)
FROM work_order WHERE work_order_id > 10
UNION ALL
SELECT work_order_id, 1 + (work_order_id * 7 + 13) % 40, 'MEMBER', round((1 + (work_order_id % 10))::numeric, 1)
FROM work_order WHERE work_order_id > 10;

-- One spare part per historical order
INSERT INTO work_order_part (work_order_id, part_id, quantity_used)
SELECT work_order_id, 1 + (work_order_id % 8), 1 + (work_order_id % 3)
FROM work_order WHERE work_order_id > 10;

ANALYZE;

SELECT 'well' AS tbl, count(*) FROM well
UNION ALL SELECT 'equipment', count(*) FROM equipment
UNION ALL SELECT 'technician', count(*) FROM technician
UNION ALL SELECT 'production_reading', count(*) FROM production_reading
UNION ALL SELECT 'work_order', count(*) FROM work_order
UNION ALL SELECT 'work_order_assignment', count(*) FROM work_order_assignment
UNION ALL SELECT 'work_order_part', count(*) FROM work_order_part;
