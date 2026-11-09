-- ============================================================================
-- PORTFOLIO 3: TRANSACTIONS & CONCURRENCY CONTROL (ACID)
-- System: ShopQuick E-Commerce & Retail Platform
-- Student: Alexis Abakasanga | Student ID: 301905734
-- ============================================================================

-- 1. ATOMIC CHECKOUT TRANSACTION (SUCCESSFUL COMMIT)
BEGIN TRANSACTION;

-- Step A: Check inventory stock availability
SELECT stock_quantity, price FROM Products WHERE product_id = 4;

-- Step B: Deduct product stock atomically
UPDATE Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 4;

-- Step C: Create new order record
INSERT INTO Orders (customer_id, total_amount, order_status) 
VALUES (1, 32000.00, 'Processing');

-- Step D: Create line-item record
INSERT INTO Order_Items (order_id, product_id, quantity, unit_price) 
VALUES (6, 4, 1, 32000.00);

-- Step E: Record successful payment
INSERT INTO Payments (order_id, amount, payment_method, payment_status) 
VALUES (6, 32000.00, 'Debit Card', 'Successful');

-- Step F: Commit transaction permanently
COMMIT;


-- 2. TRANSACTION FAILURE RECOVERY (ROLLBACK DEMONSTRATION)
BEGIN TRANSACTION;

-- Deduct stock
UPDATE Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 4;

-- Payment processing fails due to insufficient bank funds
INSERT INTO Payments (order_id, amount, payment_method, payment_status) 
VALUES (7, 32000.00, 'Debit Card', 'Failed');

-- Abort transaction and restore initial database state
ROLLBACK;
