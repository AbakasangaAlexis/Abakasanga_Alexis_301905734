-- =====================================================================
-- Portfolio 3 / Demo 1: Atomicity - COMMIT, ROLLBACK and SAVEPOINT
-- Business rule: closing a work order must (a) record the technician, (b) record the
-- part used, (c) deduct stock and (d) mark the order COMPLETED - all together or not at all.
-- Run one block at a time (psql or pgAdmin Query Tool) and screenshot each result.
-- Run 00_reset_demo_data.sql first.
-- =====================================================================

-- ---------- 1A. Successful transaction: COMMIT ----------
\echo '--- 1A: BEFORE (bearing set BRG-6310 stock)'
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_number = 'BRG-6310';

BEGIN;
INSERT INTO work_order (equipment_id, wo_type, priority, status, description)
VALUES (12, 'CORRECTIVE', 2, 'IN_PROGRESS', 'P3 DEMO 1A replace pump bearings');

INSERT INTO work_order_assignment (work_order_id, technician_id, role, hours_worked)
VALUES (currval('work_order_work_order_id_seq'), 4, 'LEAD', 6);

INSERT INTO work_order_part (work_order_id, part_id, quantity_used)
VALUES (currval('work_order_work_order_id_seq'), 2, 2);

UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 2 WHERE part_id = 2;

UPDATE work_order SET status = 'COMPLETED', completed_at = CURRENT_TIMESTAMP
WHERE work_order_id = currval('work_order_work_order_id_seq');
COMMIT;

\echo '--- 1A: AFTER COMMIT (stock should be 18, order COMPLETED)'
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_number = 'BRG-6310';
SELECT work_order_id, status, description FROM work_order WHERE description LIKE 'P3 DEMO 1A%';

-- ---------- 1B: Explicit ROLLBACK ----------
BEGIN;
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 5 WHERE part_number = 'MS-5521';
\echo '--- 1B: inside the transaction (stock shows 7, visible only to this session)'
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_number = 'MS-5521';
ROLLBACK;
\echo '--- 1B: after ROLLBACK (stock back to 12)'
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_number = 'MS-5521';

-- ---------- 1C: Automatic rollback when a constraint fails ----------
-- Only 3 gate valves (VLV-2204) are in stock; the job asks for 5.
BEGIN;
INSERT INTO work_order (equipment_id, wo_type, priority, status, description)
VALUES (11, 'CORRECTIVE', 2, 'IN_PROGRESS', 'P3 DEMO 1C replace gate valve');
INSERT INTO work_order_part (work_order_id, part_id, quantity_used)
VALUES (currval('work_order_work_order_id_seq'), 4, 5);
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 5 WHERE part_id = 4;  -- FAILS: CHECK (quantity_on_hand >= 0)
\echo '--- 1C: transaction is now aborted; further statements are refused until ROLLBACK'
SELECT 1;
ROLLBACK;
\echo '--- 1C: nothing from the failed job was saved (expect 0 rows for the order, stock still 3)'
SELECT count(*) AS orders_saved FROM work_order WHERE description LIKE 'P3 DEMO 1C%';
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_id = 4;

-- ---------- 1D: SAVEPOINT - partial rollback ----------
BEGIN;
INSERT INTO work_order (equipment_id, wo_type, priority, status, description)
VALUES (11, 'CORRECTIVE', 2, 'IN_PROGRESS', 'P3 DEMO 1D valve repair with savepoint');
SAVEPOINT before_part;
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 5 WHERE part_id = 4;  -- fails
ROLLBACK TO SAVEPOINT before_part;   -- undo only the failed step
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 2 WHERE part_id = 4;  -- use what we have
COMMIT;
\echo '--- 1D: order kept, only 2 valves consumed (stock 3 -> 1)'
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_id = 4;
SELECT work_order_id, status, description FROM work_order WHERE description LIKE 'P3 DEMO 1D%';
