-- =====================================================================
-- Portfolio 3 / Demo 4: Deadlock, detection and prevention (SESSION A and SESSION B)
-- Two jobs each need mechanical seals (part 1) and bearings (part 2),
-- but they update the two stock rows in opposite order.
-- =====================================================================

-- STEP 1 (SESSION A)
BEGIN;
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 1 WHERE part_id = 1;   -- A locks row 1

-- STEP 2 (SESSION B)
BEGIN;
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 1 WHERE part_id = 2;   -- B locks row 2

-- STEP 3 (SESSION A)
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 1 WHERE part_id = 2;   -- A waits for B

-- STEP 4 (SESSION B)  (within a second of Step 3)
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 1 WHERE part_id = 1;   -- B waits for A: cycle!
-- After about 1 second PostgreSQL detects the cycle and aborts ONE session:
--   ERROR: deadlock detected   DETAIL: Process X waits for ShareLock on transaction Y; ...
-- The other session continues.

-- STEP 5: in the surviving session -> COMMIT;   in the aborted session -> ROLLBACK;

-- PREVENTION: every transaction must lock rows in the same order (e.g. lowest part_id first).
-- With that rule B would try part 1 first, wait for A, and no cycle can form.
-- Clean up: run 00_reset_demo_data.sql, and
--   UPDATE spare_part SET quantity_on_hand = 40 WHERE part_id = 3; (not used here)
--   UPDATE spare_part SET quantity_on_hand = 12 WHERE part_id = 1;  UPDATE spare_part SET quantity_on_hand = 20 WHERE part_id = 2;
