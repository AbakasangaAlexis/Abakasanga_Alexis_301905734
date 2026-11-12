-- =====================================================================
-- Portfolio 3 / Demo 3: Isolation levels (two sessions, SESSION A and SESSION B)
-- Run 00_reset_demo_data.sql before each experiment (MS-5521 stock = 12).
-- =====================================================================

-- ############ EXPERIMENT 3A: READ COMMITTED (PostgreSQL default) - NON-REPEATABLE READ ############
-- STEP 1 (SESSION A)
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'MS-5521';      -- 12

-- STEP 2 (SESSION B)
UPDATE spare_part SET quantity_on_hand = 9 WHERE part_number = 'MS-5521';   -- autocommits

-- STEP 3 (SESSION A): same query, same transaction, different answer
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'MS-5521';      -- 9  <-- non-repeatable read
COMMIT;


-- ############ EXPERIMENT 3B: REPEATABLE READ - stable snapshot, conflict is detected ############
-- (run 00_reset_demo_data.sql first)
-- STEP 1 (SESSION A)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'MS-5521';      -- 12

-- STEP 2 (SESSION B)
UPDATE spare_part SET quantity_on_hand = 9 WHERE part_number = 'MS-5521';   -- autocommits

-- STEP 3 (SESSION A)
SELECT quantity_on_hand FROM spare_part WHERE part_number = 'MS-5521';      -- still 12: snapshot is stable

-- STEP 4 (SESSION A): trying to update a row that changed after our snapshot is refused
UPDATE spare_part SET quantity_on_hand = quantity_on_hand - 1 WHERE part_number = 'MS-5521';
-- ERROR: could not serialize access due to concurrent update  (SQLSTATE 40001)
ROLLBACK;     -- the application should retry the whole transaction


-- ############ EXPERIMENT 3C: SERIALIZABLE - write skew prevented ############
-- Rule: at least one active LEAD technician must always exist in the on-call pool.
-- Setup (run once):
--   (uses the technician table: Emem Udoh id 1 and Bassey Etim id 4, both MECHANICAL and active)
-- STEP 1 (SESSION A)
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) FROM technician WHERE trade = 'MECHANICAL' AND is_active AND technician_id IN (1,4);   -- 2

-- STEP 2 (SESSION B)
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT count(*) FROM technician WHERE trade = 'MECHANICAL' AND is_active AND technician_id IN (1,4);   -- 2

-- STEP 3 (SESSION A): sees 2, so deactivating one is "safe"
UPDATE technician SET is_active = FALSE WHERE technician_id = 1;
COMMIT;

-- STEP 4 (SESSION B): also sees 2 and deactivates the OTHER one -> would leave nobody active
UPDATE technician SET is_active = FALSE WHERE technician_id = 4;
COMMIT;
-- ERROR: could not serialize access due to read/write dependencies among transactions (40001)
--   (PostgreSQL may raise it on the UPDATE or on the COMMIT; either way Session B is rolled back)
-- Under READ COMMITTED or REPEATABLE READ both commits would succeed (write skew).

-- CLEAN UP after 3C:
UPDATE technician SET is_active = TRUE WHERE technician_id IN (1,4);
