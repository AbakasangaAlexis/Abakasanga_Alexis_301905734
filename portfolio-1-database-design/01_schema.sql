-- =====================================================================
-- Portfolio 1: Relational schema
-- Case study : Niger Delta Flow Systems Ltd (NDFS) - fictional upstream
--              operator. Flow station and asset maintenance database.
-- DBMS       : PostgreSQL 16
-- Run        : psql -U postgres -d ndfs_db -f 01_schema.sql
-- =====================================================================

DROP TABLE IF EXISTS work_order_part       CASCADE;
DROP TABLE IF EXISTS work_order_assignment CASCADE;
DROP TABLE IF EXISTS hse_incident          CASCADE;
DROP TABLE IF EXISTS work_order            CASCADE;
DROP TABLE IF EXISTS production_reading    CASCADE;
DROP TABLE IF EXISTS equipment             CASCADE;
DROP TABLE IF EXISTS well                  CASCADE;
DROP TABLE IF EXISTS spare_part            CASCADE;
DROP TABLE IF EXISTS technician            CASCADE;
DROP TABLE IF EXISTS flow_station          CASCADE;

-- ---------------------------------------------------------------------
-- 1. flow_station : a facility that gathers fluids from several wells
-- ---------------------------------------------------------------------
CREATE TABLE flow_station (
    station_id        SERIAL        PRIMARY KEY,
    station_code      VARCHAR(10)   NOT NULL UNIQUE,
    station_name      VARCHAR(80)   NOT NULL,
    region            VARCHAR(20)   NOT NULL,
    state             VARCHAR(40)   NOT NULL,
    commissioned_date DATE          NOT NULL,
    design_capacity_bopd INTEGER    NOT NULL,
    CONSTRAINT ck_station_region   CHECK (region IN ('ONSHORE_EAST','ONSHORE_WEST','SWAMP','OFFSHORE')),
    CONSTRAINT ck_station_capacity CHECK (design_capacity_bopd > 0)
);

-- ---------------------------------------------------------------------
-- 2. well : each well flows into exactly one station
-- ---------------------------------------------------------------------
CREATE TABLE well (
    well_id     SERIAL       PRIMARY KEY,
    station_id  INTEGER      NOT NULL REFERENCES flow_station(station_id)
                             ON UPDATE CASCADE ON DELETE RESTRICT,
    well_name   VARCHAR(30)  NOT NULL UNIQUE,
    well_type   VARCHAR(10)  NOT NULL,
    status      VARCHAR(12)  NOT NULL DEFAULT 'ACTIVE',
    spud_date   DATE         NOT NULL,
    depth_ft    INTEGER      NOT NULL,
    CONSTRAINT ck_well_type   CHECK (well_type IN ('OIL','GAS','INJECTOR')),
    CONSTRAINT ck_well_status CHECK (status IN ('ACTIVE','SHUT_IN','SUSPENDED','ABANDONED')),
    CONSTRAINT ck_well_depth  CHECK (depth_ft > 0)
);

-- ---------------------------------------------------------------------
-- 3. equipment : tagged assets housed at a station
-- ---------------------------------------------------------------------
CREATE TABLE equipment (
    equipment_id   SERIAL       PRIMARY KEY,
    station_id     INTEGER      NOT NULL REFERENCES flow_station(station_id)
                                ON UPDATE CASCADE ON DELETE RESTRICT,
    tag_number     VARCHAR(20)  NOT NULL UNIQUE,
    equipment_type VARCHAR(20)  NOT NULL,
    manufacturer   VARCHAR(60),
    install_date   DATE         NOT NULL,
    criticality    SMALLINT     NOT NULL DEFAULT 2,
    status         VARCHAR(15)  NOT NULL DEFAULT 'IN_SERVICE',
    CONSTRAINT ck_equip_type CHECK (equipment_type IN
        ('PUMP','COMPRESSOR','SEPARATOR','HEATER_TREATER','GENERATOR','VALVE','TANK')),
    CONSTRAINT ck_equip_crit   CHECK (criticality BETWEEN 1 AND 3),   -- 1 = highest
    CONSTRAINT ck_equip_status CHECK (status IN ('IN_SERVICE','UNDER_REPAIR','STANDBY','DECOMMISSIONED'))
);

-- ---------------------------------------------------------------------
-- 4. production_reading : one row per well per day (high-volume table)
-- ---------------------------------------------------------------------
CREATE TABLE production_reading (
    reading_id   BIGSERIAL     PRIMARY KEY,
    well_id      INTEGER       NOT NULL REFERENCES well(well_id)
                               ON UPDATE CASCADE ON DELETE RESTRICT,
    reading_date DATE          NOT NULL,
    oil_bbl      NUMERIC(10,2) NOT NULL DEFAULT 0,
    gas_mscf     NUMERIC(10,2) NOT NULL DEFAULT 0,
    water_bbl    NUMERIC(10,2) NOT NULL DEFAULT 0,
    choke_size_64ths SMALLINT,
    CONSTRAINT uq_reading_well_date UNIQUE (well_id, reading_date),
    CONSTRAINT ck_reading_nonneg CHECK (oil_bbl >= 0 AND gas_mscf >= 0 AND water_bbl >= 0),
    CONSTRAINT ck_reading_choke  CHECK (choke_size_64ths IS NULL OR choke_size_64ths BETWEEN 1 AND 128)
);

-- ---------------------------------------------------------------------
-- 5. technician
-- ---------------------------------------------------------------------
CREATE TABLE technician (
    technician_id SERIAL       PRIMARY KEY,
    full_name     VARCHAR(80)  NOT NULL,
    trade         VARCHAR(20)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    hire_date     DATE         NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_tech_trade CHECK (trade IN
        ('MECHANICAL','ELECTRICAL','INSTRUMENTATION','PIPING','GENERAL'))
);

-- ---------------------------------------------------------------------
-- 6. work_order : a maintenance job raised against one piece of equipment
-- ---------------------------------------------------------------------
CREATE TABLE work_order (
    work_order_id  SERIAL        PRIMARY KEY,
    equipment_id   INTEGER       NOT NULL REFERENCES equipment(equipment_id)
                                 ON UPDATE CASCADE ON DELETE RESTRICT,
    wo_type        VARCHAR(12)   NOT NULL,
    priority       SMALLINT      NOT NULL DEFAULT 3,
    status         VARCHAR(12)   NOT NULL DEFAULT 'OPEN',
    description    TEXT          NOT NULL,
    raised_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at     TIMESTAMP,
    completed_at   TIMESTAMP,
    downtime_hours NUMERIC(7,2)  NOT NULL DEFAULT 0,
    CONSTRAINT ck_wo_type     CHECK (wo_type IN ('PREVENTIVE','CORRECTIVE','INSPECTION','EMERGENCY')),
    CONSTRAINT ck_wo_priority CHECK (priority BETWEEN 1 AND 4),      -- 1 = most urgent
    CONSTRAINT ck_wo_status   CHECK (status IN ('OPEN','ASSIGNED','IN_PROGRESS','COMPLETED','CANCELLED')),
    CONSTRAINT ck_wo_downtime CHECK (downtime_hours >= 0),
    CONSTRAINT ck_wo_dates    CHECK (completed_at IS NULL OR completed_at >= raised_at),
    CONSTRAINT ck_wo_completed_status CHECK (status <> 'COMPLETED' OR completed_at IS NOT NULL)
);

-- ---------------------------------------------------------------------
-- 7. work_order_assignment : resolves many-to-many work_order <-> technician
-- ---------------------------------------------------------------------
CREATE TABLE work_order_assignment (
    work_order_id INTEGER      NOT NULL REFERENCES work_order(work_order_id)
                               ON UPDATE CASCADE ON DELETE CASCADE,
    technician_id INTEGER      NOT NULL REFERENCES technician(technician_id)
                               ON UPDATE CASCADE ON DELETE RESTRICT,
    role          VARCHAR(10)  NOT NULL DEFAULT 'MEMBER',
    hours_worked  NUMERIC(6,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (work_order_id, technician_id),
    CONSTRAINT ck_assign_role  CHECK (role IN ('LEAD','MEMBER')),
    CONSTRAINT ck_assign_hours CHECK (hours_worked >= 0)
);

-- ---------------------------------------------------------------------
-- 8. spare_part : inventory
-- ---------------------------------------------------------------------
CREATE TABLE spare_part (
    part_id          SERIAL        PRIMARY KEY,
    part_number      VARCHAR(30)   NOT NULL UNIQUE,
    description      VARCHAR(120)  NOT NULL,
    unit_cost_usd    NUMERIC(10,2) NOT NULL,
    quantity_on_hand INTEGER       NOT NULL DEFAULT 0,
    reorder_level    INTEGER       NOT NULL DEFAULT 5,
    CONSTRAINT ck_part_cost  CHECK (unit_cost_usd >= 0),
    CONSTRAINT ck_part_qty   CHECK (quantity_on_hand >= 0),      -- stock can never go negative
    CONSTRAINT ck_part_reord CHECK (reorder_level >= 0)
);

-- ---------------------------------------------------------------------
-- 9. work_order_part : resolves many-to-many work_order <-> spare_part
-- ---------------------------------------------------------------------
CREATE TABLE work_order_part (
    work_order_id INTEGER NOT NULL REFERENCES work_order(work_order_id)
                          ON UPDATE CASCADE ON DELETE CASCADE,
    part_id       INTEGER NOT NULL REFERENCES spare_part(part_id)
                          ON UPDATE CASCADE ON DELETE RESTRICT,
    quantity_used INTEGER NOT NULL,
    PRIMARY KEY (work_order_id, part_id),
    CONSTRAINT ck_wop_qty CHECK (quantity_used > 0)
);

-- ---------------------------------------------------------------------
-- 10. hse_incident : health, safety and environment events
-- ---------------------------------------------------------------------
CREATE TABLE hse_incident (
    incident_id    SERIAL       PRIMARY KEY,
    station_id     INTEGER      NOT NULL REFERENCES flow_station(station_id)
                                ON UPDATE CASCADE ON DELETE RESTRICT,
    equipment_id   INTEGER      REFERENCES equipment(equipment_id)
                                ON UPDATE CASCADE ON DELETE SET NULL,   -- optional link
    incident_date  DATE         NOT NULL,
    category       VARCHAR(20)  NOT NULL,
    severity       SMALLINT     NOT NULL,
    description    TEXT         NOT NULL,
    lost_time_days INTEGER      NOT NULL DEFAULT 0,
    CONSTRAINT ck_hse_cat CHECK (category IN
        ('LEAK','FIRE','INJURY','SPILL','NEAR_MISS','EQUIPMENT_FAILURE')),
    CONSTRAINT ck_hse_sev  CHECK (severity BETWEEN 1 AND 5),         -- 5 = most severe
    CONSTRAINT ck_hse_lost CHECK (lost_time_days >= 0)
);

-- Foreign-key columns are not indexed automatically in PostgreSQL.
-- Indexes for query performance are added deliberately in Portfolio 2.
