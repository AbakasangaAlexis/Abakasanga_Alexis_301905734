-- =====================================================================
-- Portfolio 2: Business queries and results
-- Each query answers a real question for NDFS users.
-- Run: psql -U postgres -d ndfs_db -f <this file>
-- =====================================================================

-- Q1: Total oil, gas and water produced by each flow station in 2025
\echo '=== Q1: Total oil, gas and water produced by each flow station in 2025'
SELECT fs.station_code, fs.station_name,
       SUM(pr.oil_bbl)   AS oil_bbl,
       SUM(pr.gas_mscf)  AS gas_mscf,
       SUM(pr.water_bbl) AS water_bbl
FROM production_reading pr
JOIN well w          ON w.well_id = pr.well_id
JOIN flow_station fs ON fs.station_id = w.station_id
WHERE pr.reading_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY fs.station_code, fs.station_name
ORDER BY oil_bbl DESC;

-- Q2: Top 10 wells by oil production in the last 90 days (to 31 Oct 2026)
\echo '=== Q2: Top 10 wells by oil production in the last 90 days (to 31 Oct 2026)'
SELECT w.well_name, fs.station_code, SUM(pr.oil_bbl) AS oil_90d
FROM production_reading pr
JOIN well w          ON w.well_id = pr.well_id
JOIN flow_station fs ON fs.station_id = w.station_id
WHERE pr.reading_date > DATE '2026-10-31' - 90
GROUP BY w.well_name, fs.station_code
ORDER BY oil_90d DESC
LIMIT 10;

-- Q3: Field-wide production on one day (daily morning report for 15 June 2026)
\echo '=== Q3: Field-wide production on one day (daily morning report for 15 June 2026)'
SELECT well_id, oil_bbl, gas_mscf, water_bbl
FROM production_reading
WHERE reading_date = DATE '2026-06-15'
ORDER BY oil_bbl DESC;

-- Q4: Maintenance history of one asset (equipment_id 55), newest first
\echo '=== Q4: Maintenance history of one asset (equipment_id 55), newest first'
SELECT work_order_id, wo_type, priority, status, raised_at, downtime_hours
FROM work_order
WHERE equipment_id = 55
ORDER BY raised_at DESC;

-- Q5: Open work-order backlog ordered by urgency (daily planner list)
\echo '=== Q5: Open work-order backlog ordered by urgency (daily planner list)'
SELECT wo.work_order_id, e.tag_number, wo.wo_type, wo.priority, wo.status, wo.raised_at
FROM work_order wo
JOIN equipment e ON e.equipment_id = wo.equipment_id
WHERE wo.status IN ('OPEN','ASSIGNED','IN_PROGRESS')
ORDER BY wo.priority, wo.raised_at;

-- Q6: Downtime hours and spare-parts cost per station, 2025 (5-table join with pre-aggregated parts cost)
\echo '=== Q6: Downtime hours and spare-parts cost per station, 2025 (5-table join with pre-aggregated parts cost)'
SELECT fs.station_code,
       COUNT(*)                         AS work_orders,
       SUM(wo.downtime_hours)           AS downtime_hours,
       SUM(pc.parts_cost)               AS parts_cost_usd
FROM work_order wo
JOIN equipment e     ON e.equipment_id = wo.equipment_id
JOIN flow_station fs ON fs.station_id  = e.station_id
JOIN (SELECT wop.work_order_id,
             SUM(wop.quantity_used * sp.unit_cost_usd) AS parts_cost
      FROM work_order_part wop
      JOIN spare_part sp ON sp.part_id = wop.part_id
      GROUP BY wop.work_order_id) pc ON pc.work_order_id = wo.work_order_id
WHERE wo.raised_at >= '2025-01-01' AND wo.raised_at < '2026-01-01'
GROUP BY fs.station_code
ORDER BY parts_cost_usd DESC;

-- Q7: Rank wells by 2025 oil production within their own station (window function)
\echo '=== Q7: Rank wells by 2025 oil production within their own station (window function)'
SELECT station_code, well_name, oil_2025,
       RANK() OVER (PARTITION BY station_code ORDER BY oil_2025 DESC) AS rank_in_station
FROM (SELECT fs.station_code, w.well_name, SUM(pr.oil_bbl) AS oil_2025
      FROM production_reading pr
      JOIN well w          ON w.well_id = pr.well_id
      JOIN flow_station fs ON fs.station_id = w.station_id
      WHERE pr.reading_date BETWEEN '2025-01-01' AND '2025-12-31'
      GROUP BY fs.station_code, w.well_name) t
ORDER BY station_code, rank_in_station
LIMIT 15;

