-- =====================================================================
-- Portfolio 1: Hand-written sample data (small, readable)
-- All names, tags and figures are fictional.
-- Run after 01_schema.sql:  psql -U postgres -d ndfs_db -f 02_sample_data.sql
-- =====================================================================

INSERT INTO flow_station (station_code, station_name, region, state, commissioned_date, design_capacity_bopd) VALUES
 ('EKT-FS1','Eket Flow Station 1',        'ONSHORE_EAST','Akwa Ibom','2008-03-15', 45000),
 ('IBN-FS2','Ibeno Flow Station 2',       'ONSHORE_EAST','Akwa Ibom','2011-09-01', 30000),
 ('OBG-FS3','Obagi Flow Station 3',       'ONSHORE_WEST','Rivers',   '2005-06-20', 60000),
 ('BNY-FS4','Bonny Swamp Flow Station 4', 'SWAMP',       'Rivers',   '2014-01-10', 25000),
 ('OSH-FS5','Oshi Offshore Platform 5',   'OFFSHORE',    'Delta',    '2017-11-30', 80000);

INSERT INTO well (station_id, well_name, well_type, status, spud_date, depth_ft) VALUES
 (1,'EKT-001','OIL','ACTIVE','2007-05-11', 9800),
 (1,'EKT-002','OIL','ACTIVE','2008-01-23', 10250),
 (1,'EKT-003','GAS','ACTIVE','2009-07-02', 11400),
 (2,'IBN-001','OIL','ACTIVE','2010-10-14', 8700),
 (2,'IBN-002','OIL','SHUT_IN','2011-02-19', 9100),
 (3,'OBG-001','OIL','ACTIVE','2004-08-30', 10900),
 (3,'OBG-002','OIL','ACTIVE','2005-03-12', 11200),
 (3,'OBG-003','INJECTOR','ACTIVE','2006-12-01', 9600),
 (4,'BNY-001','OIL','ACTIVE','2013-04-05', 12300),
 (4,'BNY-002','OIL','SUSPENDED','2013-09-18', 12050),
 (5,'OSH-001','OIL','ACTIVE','2016-06-21', 13400),
 (5,'OSH-002','GAS','ACTIVE','2016-11-08', 14100);

INSERT INTO equipment (station_id, tag_number, equipment_type, manufacturer, install_date, criticality, status) VALUES
 (1,'EKT-P-101','PUMP',          'Flowserve',        '2008-03-01',1,'IN_SERVICE'),
 (1,'EKT-P-102','PUMP',          'Flowserve',        '2008-03-01',1,'STANDBY'),
 (1,'EKT-C-201','COMPRESSOR',    'Atlas Copco',      '2010-05-20',1,'IN_SERVICE'),
 (1,'EKT-S-301','SEPARATOR',     'NATCO',            '2008-02-12',2,'IN_SERVICE'),
 (2,'IBN-P-101','PUMP',          'Sulzer',           '2011-08-15',2,'IN_SERVICE'),
 (2,'IBN-G-401','GENERATOR',     'Caterpillar',      '2012-01-10',1,'IN_SERVICE'),
 (2,'IBN-T-501','TANK',          'Local Fabricator', '2011-07-01',3,'IN_SERVICE'),
 (3,'OBG-P-101','PUMP',          'Flowserve',        '2005-05-30',1,'UNDER_REPAIR'),
 (3,'OBG-C-201','COMPRESSOR',    'Dresser-Rand',     '2006-02-14',1,'IN_SERVICE'),
 (3,'OBG-H-601','HEATER_TREATER','NATCO',            '2005-06-01',2,'IN_SERVICE'),
 (3,'OBG-V-701','VALVE',         'Cameron',          '2007-09-09',2,'IN_SERVICE'),
 (4,'BNY-P-101','PUMP',          'Sulzer',           '2014-01-05',1,'IN_SERVICE'),
 (4,'BNY-G-401','GENERATOR',     'Caterpillar',      '2014-01-05',1,'IN_SERVICE'),
 (5,'OSH-C-201','COMPRESSOR',    'Dresser-Rand',     '2017-10-20',1,'IN_SERVICE'),
 (5,'OSH-S-301','SEPARATOR',     'NATCO',            '2017-10-20',1,'IN_SERVICE');

INSERT INTO technician (full_name, trade, email, hire_date, is_active) VALUES
 ('Emem Udoh',        'MECHANICAL',     'emem.udoh@ndfs.example',        '2012-02-01', TRUE),
 ('Chidi Okeke',      'ELECTRICAL',     'chidi.okeke@ndfs.example',      '2014-06-16', TRUE),
 ('Ngozi Eze',        'INSTRUMENTATION','ngozi.eze@ndfs.example',        '2016-09-05', TRUE),
 ('Bassey Etim',      'MECHANICAL',     'bassey.etim@ndfs.example',      '2010-11-22', TRUE),
 ('Tamuno Briggs',    'PIPING',         'tamuno.briggs@ndfs.example',    '2018-03-12', TRUE),
 ('Ifeanyi Nwosu',    'GENERAL',        'ifeanyi.nwosu@ndfs.example',    '2020-01-20', TRUE),
 ('Aniekan Inyang',   'ELECTRICAL',     'aniekan.inyang@ndfs.example',   '2019-07-08', FALSE);

INSERT INTO spare_part (part_number, description, unit_cost_usd, quantity_on_hand, reorder_level) VALUES
 ('MS-5521','Mechanical seal, centrifugal pump',        850.00, 12, 4),
 ('BRG-6310','Bearing set, pump drive end',             240.00, 20, 6),
 ('FLT-0098','Lube oil filter, compressor',              95.50, 40, 10),
 ('VLV-2204','Gate valve 4in, 600 class',              1900.00,  3, 2),
 ('GSK-7710','Gasket kit, separator manway',             60.00, 35, 10),
 ('SNS-3301','Pressure transmitter 0-1000 psi',         780.00,  8, 3),
 ('BLT-1180','Drive belt set, generator cooling fan',    42.00, 25, 8),
 ('RLY-9012','Protection relay, 11kV',                 1250.00,  2, 2);

INSERT INTO work_order (equipment_id, wo_type, priority, status, description, raised_at, started_at, completed_at, downtime_hours) VALUES
 (1, 'PREVENTIVE',3,'COMPLETED','Quarterly bearing inspection and lubrication',   '2026-01-05 08:00','2026-01-06 09:00','2026-01-06 15:00', 6.00),
 (3, 'CORRECTIVE',2,'COMPLETED','High vibration alarm on compressor',             '2026-01-20 14:30','2026-01-21 07:30','2026-01-22 18:00', 34.50),
 (8, 'EMERGENCY', '1','IN_PROGRESS','Pump OBG-P-101 mechanical seal leak',          '2026-10-28 03:15','2026-10-28 05:00', NULL, 52.00),
 (8, 'CORRECTIVE',2,'COMPLETED','Replace worn coupling after seal failure',       '2026-06-02 10:00','2026-06-03 08:00','2026-06-03 17:30', 9.50),
 (6, 'PREVENTIVE',3,'COMPLETED','Generator 1000-hour service',                    '2026-02-14 08:00','2026-02-15 08:00','2026-02-15 16:00', 8.00),
 (12,'INSPECTION',4,'OPEN',     'Annual pump alignment check',                    '2026-11-02 09:00', NULL, NULL, 0),
 (9, 'CORRECTIVE',2,'ASSIGNED', 'Replace lube oil filter, low differential alarm','2026-11-05 11:20', NULL, NULL, 0),
 (14,'PREVENTIVE',3,'COMPLETED','Compressor 8000-hour overhaul',                  '2026-03-10 07:00','2026-03-11 07:00','2026-03-14 12:00', 77.00),
 (11,'CORRECTIVE',2,'COMPLETED','Valve stem packing leak',                        '2026-04-22 13:00','2026-04-23 09:00','2026-04-23 14:00', 5.00),
 (4, 'INSPECTION',3,'COMPLETED','Separator internal visual inspection',           '2026-05-18 08:00','2026-05-19 08:00','2026-05-19 16:00', 8.00);

INSERT INTO work_order_assignment (work_order_id, technician_id, role, hours_worked) VALUES
 (1,1,'LEAD',6.0),(1,6,'MEMBER',6.0),
 (2,1,'LEAD',20.0),(2,2,'MEMBER',14.0),(2,3,'MEMBER',10.0),
 (3,4,'LEAD',18.0),(3,5,'MEMBER',12.0),
 (4,4,'LEAD',9.5),
 (5,2,'LEAD',8.0),
 (7,1,'LEAD',0),
 (8,1,'LEAD',60.0),(8,4,'MEMBER',55.0),(8,3,'MEMBER',30.0),
 (9,5,'LEAD',5.0),
 (10,1,'LEAD',8.0);

INSERT INTO work_order_part (work_order_id, part_id, quantity_used) VALUES
 (1,2,1),
 (2,3,2),(2,6,1),
 (3,1,1),
 (4,2,2),
 (5,7,2),
 (8,3,4),(8,2,2),
 (9,5,1),
 (10,5,1);

INSERT INTO hse_incident (station_id, equipment_id, incident_date, category, severity, description, lost_time_days) VALUES
 (3, 8, '2026-10-28','LEAK',             3,'Produced-water leak at pump seal contained within bund',0),
 (1, NULL,'2026-03-03','NEAR_MISS',      2,'Unsecured scaffold plank found during rounds',0),
 (4, 13,'2026-07-19','FIRE',             4,'Small electrical fire in generator panel, extinguished',2),
 (2, NULL,'2026-05-07','INJURY',         3,'Hand laceration during tank gauge maintenance',3),
 (5, 14,'2026-08-25','EQUIPMENT_FAILURE',3,'Compressor trip caused flaring for 6 hours',0);

-- Small hand-written daily production for the first 7 days of November 2026
-- (the bulk generator in Portfolio 2 adds several years of history)
INSERT INTO production_reading (well_id, reading_date, oil_bbl, gas_mscf, water_bbl, choke_size_64ths)
SELECT w.well_id, d::date,
       CASE WHEN w.status='ACTIVE' AND w.well_type='OIL' THEN 800 + w.well_id*35 + (EXTRACT(DAY FROM d)::int % 5)*12 ELSE 0 END,
       CASE WHEN w.status='ACTIVE' THEN 1500 + w.well_id*60 ELSE 0 END,
       CASE WHEN w.status='ACTIVE' THEN 300 + w.well_id*10 ELSE 0 END,
       24
FROM well w, generate_series('2026-11-01'::date,'2026-11-07'::date,'1 day') d;
