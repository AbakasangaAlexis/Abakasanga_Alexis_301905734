-- Restore the spare-part stock used in the Portfolio 3 demonstrations.
-- Run this before each demo so results are repeatable.
-- (Any work orders created by earlier demos are removed first.)
DELETE FROM work_order WHERE description LIKE 'P3 DEMO%';
UPDATE spare_part SET quantity_on_hand = 12 WHERE part_number = 'MS-5521';
UPDATE spare_part SET quantity_on_hand = 20 WHERE part_number = 'BRG-6310';
UPDATE spare_part SET quantity_on_hand = 3  WHERE part_number = 'VLV-2204';
SELECT part_id, part_number, quantity_on_hand FROM spare_part WHERE part_id IN (1,2,4) ORDER BY part_id;
