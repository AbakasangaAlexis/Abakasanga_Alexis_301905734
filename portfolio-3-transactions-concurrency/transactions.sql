-- ============================================================================
-- PORTFOLIO 3: TRANSACTIONS & CONCURRENCY CONTROL (ACID)
-- System: ShopQuick E-Commerce & Retail Platform
-- Student: Alexis Abakasanga | Student ID: 301905734
-- ============================================================================

-- 1. ATOMIC CHECKOUT TRANSACTION (SUCCESSFUL COMMIT)
BEGIN TRANSACTION;

SELECT stock_quantity, price FROM Products WHERE product_id = 4;
UPDATE Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 4;
INSERT INTO Orders (customer_id, total_amount, order_status) VALUES (1, 32000.00, 'Processing');
INSERT INTO Order_Items (order_id, product_id, quantity, unit_price) VALUES (6, 4, 1, 32000.00);
INSERT INTO Payments (order_id, amount, payment_method, payment_status) VALUES (6, 32000.00, 'Debit Card', 'Successful');

COMMIT;

-- 2. TRANSACTION FAILURE RECOVERY (ROLLBACK DEMONSTRATION)
BEGIN TRANSACTION;

UPDATE Products SET stock_quantity = stock_quantity - 1 WHERE product_id = 4;
INSERT INTO Payments (order_id, amount, payment_method, payment_status) VALUES (7, 32000.00, 'Debit Card', 'Failed');

ROLLBACK;
