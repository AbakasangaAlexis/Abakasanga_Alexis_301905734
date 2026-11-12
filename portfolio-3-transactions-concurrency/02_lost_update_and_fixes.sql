-- =====================================================================
-- Portfolio 3 / Demo 2: Concurrency problem (LOST UPDATE) and two control mechanisms
-- Needs TWO sessions: open two Query Tool tabs in pgAdmin (or two psql windows).
-- Label them SESSION A and SESSION B. Run the numbered steps in the order shown.
-- Before each experiment run 00_reset_demo_data.sql (VLV-2204 stock = 3).
--
-- Story: two store officers each issue 2 gate valves to different jobs.
-- Only 3 are in stock, so one of them must be refused. Watch what happens.
-- =====================================================================

-- ############ EXPERIMENT 2A: the PROBLEM (read, calculate in the application, write back) ############
-- STEP 1 (SESSION A)
BEGIN;
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'VLV-2204';      -- sees 3

-- STEP 2 (SESSION B)
BEGIN;
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'VLV-2204';      -- also sees 3

-- STEP 3 (SESSION A): application computes 3 - 2 = 1 and writes the value back
UPDATE spare_part SET quantity_on_hand = 1 WHERE part_number = 'VLV-2204';
COMMIT;

-- STEP 4 (SESSION B): application also computes 3 - 2 = 1 from its stale read
UPDATE spare_part SET quantity_on_hand = 1 WHERE part_number = 'VLV-2204';
COMMIT;

-- STEP 5 (either session): 4 valves were issued from a stock of 3, yet the database says 1 is left.
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_number = 'VLV-2204';
-- => LOST UPDATE: A's change was silently overwritten. Stock is wrong by 2.


-- ############ EXPERIMENT 2B: FIX 1 - pessimistic locking with SELECT ... FOR UPDATE ############
-- (run 00_reset_demo_data.sql first)
-- STEP 1 (SESSION A)
BEGIN;
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'VLV-2204' FOR UPDATE;   -- sees 3, locks the row

-- STEP 2 (SESSION B)
BEGIN;
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'VLV-2204' FOR UPDATE;   -- BLOCKS (waiting). Screenshot the waiting tab.

-- STEP 3 (SESSION A)
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 2 WHERE part_number = 'VLV-2204';
COMMIT;                                                                              -- releases the lock

-- STEP 4 (SESSION B): the blocked SELECT now returns 1 (not 3). The application sees only 1 left
-- and refuses to issue 2 valves.
ROLLBACK;
-- Result: stock = 1, no overselling.


-- ############ EXPERIMENT 2C: FIX 2 - one atomic conditional UPDATE (no explicit lock needed) ############
-- (run 00_reset_demo_data.sql first)
-- STEP 1 (SESSION A)
BEGIN;
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 2
WHERE part_number = 'VLV-2204' AND quantity_on_hand >= 2;            -- UPDATE 1

-- STEP 2 (SESSION B)
BEGIN;
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 2
WHERE part_number = 'VLV-2204' AND quantity_on_hand >= 2;            -- BLOCKS on A's row lock

-- STEP 3 (SESSION A)
COMMIT;

-- STEP 4 (SESSION B): PostgreSQL re-checks the WHERE clause against the committed row (qty = 1),
-- so the update matches nothing: "UPDATE 0". The application treats 0 rows as "insufficient stock".
COMMIT;
SELECT part_number, quantity_on_hand FROM spare_part WHERE part_number = 'VLV-2204';   -- 1
