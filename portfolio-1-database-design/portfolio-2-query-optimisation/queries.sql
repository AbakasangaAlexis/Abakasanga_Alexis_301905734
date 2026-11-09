-- ============================================================================
-- PORTFOLIO 2: QUERY PROCESSING & SQL OPTIMISATION
-- System: ShopQuick E-Commerce & Retail Platform
-- Student: Alexis Abakasanga | Student ID: 301905734
-- ============================================================================

-- Query 1: Top Customer Spend Aggregation (Multi-table JOIN & GROUP BY)
SELECT 
    c.customer_id, 
    c.first_name || ' ' || c.last_name AS customer_name, 
    COUNT(o.order_id) AS total_orders, 
    SUM(o.total_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC;

-- Query 2: Low Stock Inventory Alert Query
SELECT product_id, product_name, category, price, stock_quantity
FROM Products
WHERE stock_quantity < 15
ORDER BY stock_quantity ASC;

-- B-TREE INDEX OPTIMISATION STRATEGY
-- Index for Query 1 filtering & JOIN optimization
CREATE INDEX idx_orders_customer_status ON Orders(customer_id, order_status);

-- Index for Query 2 threshold lookup
CREATE INDEX idx_products_stock ON Products(stock_quantity);

-- Composite Index for Order_Items lookups
CREATE INDEX idx_orderitems_order_product ON Order_Items(order_id, product_id);

-- Verify execution plans using EXPLAIN QUERY PLAN
EXPLAIN QUERY PLAN
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, SUM(o.total_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, customer_name;
