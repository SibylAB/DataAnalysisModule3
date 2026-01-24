USE coffeeshop_db;

-- =====================
-- BASICS (Selected Keys)
-- =====================

-- Q1
SELECT name, price
FROM products
ORDER BY price DESC;

-- Q2
SELECT * FROM customers
WHERE city = 'Lihue';

-- Q3
SELECT order_id, order_datetime
FROM orders
ORDER BY order_datetime ASC
LIMIT 5;

-- Q4
SELECT * FROM products
WHERE name LIKE '%Latte%';

-- Q5
SELECT DISTINCT payment_method FROM orders;

-- Q6
SELECT name, CONCAT(city, ', ', state) AS location
FROM stores;

-- Q7
SELECT o.order_id, o.status,
       SUM(oi.quantity) AS total_items
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.status;

-- Q8
SELECT *
FROM orders
WHERE DATE(order_datetime) = '2025-09-04';

-- Q9
SELECT name, price
FROM products
ORDER BY price DESC
LIMIT 3;

-- Q10
SELECT CONCAT(last_name, ', ', first_name) AS customer_name
FROM customers;

-- ==================================
-- FILTERS & AGGREGATION (Selected)
-- ==================================

-- Q1
SELECT 
  order_id,
  SUM(quantity) AS total_items
FROM order_items
GROUP BY order_id
ORDER BY order_id;

-- Q2
SELECT 
  order_id,
  SUM(quantity) AS total_items
FROM order_items
WHERE order_id IN (
  SELECT order_id FROM orders WHERE status = 'paid'
)
GROUP BY order_id
ORDER BY order_id;

-- Q3
SELECT 
  DATE(order_datetime) AS order_date,
  COUNT(*) AS orders_count
FROM orders
GROUP BY DATE(order_datetime)
ORDER BY order_date;

-- Q4
WITH per_paid_order AS (
  SELECT 
    order_id, 
    SUM(quantity) AS total_items
  FROM order_items
  WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'paid')
  GROUP BY order_id
)
SELECT AVG(total_items) AS avg_items_per_paid_order
FROM per_paid_order;

-- Q5
SELECT 
  product_id,
  SUM(quantity) AS total_units
FROM order_items
GROUP BY product_id
ORDER BY total_units DESC, product_id;

-- Q6
SELECT 
  product_id,
  SUM(quantity) AS total_units_paid
FROM order_items
WHERE order_id IN (
  SELECT order_id FROM orders WHERE status = 'paid'
)
GROUP BY product_id
ORDER BY total_units_paid DESC, product_id;

-- Q7
SELECT 
  store_id,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
WHERE status = 'paid'
GROUP BY store_id
ORDER BY unique_customers DESC, store_id;

-- Q8
WITH paid_by_dow AS (
  SELECT 
    DAYNAME(order_datetime) AS day_name,
    COUNT(*) AS orders_count
  FROM orders
  WHERE status = 'paid'
  GROUP BY DAYNAME(order_datetime)
)
SELECT *
FROM paid_by_dow
WHERE orders_count = (SELECT MAX(orders_count) FROM paid_by_dow)
ORDER BY day_name;

-- Q9
SELECT 
  DATE(order_datetime) AS order_date,
  COUNT(*) AS orders_count
FROM orders
GROUP BY DATE(order_datetime)
HAVING COUNT(*) > 3
ORDER BY orders_count DESC, order_date;

-- Q10
SELECT 
  store_id,
  payment_method,
  COUNT(*) AS paid_orders_count
FROM orders
WHERE status = 'paid'
GROUP BY store_id, payment_method
ORDER BY store_id, payment_method;

-- Q11 (Optional)
SELECT 
  100.0 * SUM(CASE WHEN payment_method = 'app' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS pct_app_paid_orders
FROM orders
WHERE status = 'paid';

-- Q12 (Optional)
SELECT 
  HOUR(order_datetime) AS hour_of_day,
  COUNT(*) AS orders_count
FROM orders
WHERE status = 'paid'
GROUP BY HOUR(order_datetime)
ORDER BY orders_count DESC, hour_of_day;

-- ============================
-- JOINS & RELATIONS (Selected)
-- ============================

USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE - ANSWER KEY
-- =========================================================

-- Q1) products × categories
SELECT 
  p.name AS product_name,
  c.name AS category_name,
  p.price
FROM products p
JOIN categories c ON c.category_id = p.category_id
ORDER BY c.name, p.name;

-- Q2) order items with line totals (quantity * products.price)
SELECT 
  o.order_id,
  o.order_datetime,
  s.name AS store_name,
  p.name AS product_name,
  oi.quantity,
  (oi.quantity * p.price) AS line_total
FROM order_items oi
JOIN orders   o ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN stores   s ON s.store_id   = o.store_id
ORDER BY o.order_datetime, o.order_id, p.name;

-- Q3) customer paid order history with order_total
SELECT
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  s.name AS store_name,
  o.order_datetime,
  SUM(oi.quantity * p.price) AS order_total
FROM orders o
JOIN customers c  ON c.customer_id = o.customer_id
JOIN stores    s  ON s.store_id    = o.store_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p    ON p.product_id = oi.product_id
WHERE o.status = 'paid'
GROUP BY o.order_id, customer_name, s.name, o.order_datetime
ORDER BY o.order_datetime;

-- Q4) customers who have never placed an order
SELECT 
  c.first_name, c.last_name, c.city, c.state
FROM customers c
LEFT JOIN orders o 
  ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.last_name, c.first_name;

-- Q5) per-store top-selling product by units (paid only)
WITH per_store AS (
  SELECT
    s.store_id,
    s.name AS store_name,
    p.product_id,
    p.name AS product_name,
    SUM(oi.quantity) AS total_units,
    ROW_NUMBER() OVER (
      PARTITION BY s.store_id 
      ORDER BY SUM(oi.quantity) DESC, p.name
    ) AS rn
  FROM orders o
  JOIN stores s       ON s.store_id    = o.store_id
  JOIN order_items oi ON oi.order_id   = o.order_id
  JOIN products p     ON p.product_id  = oi.product_id
  WHERE o.status = 'paid'
  GROUP BY s.store_id, s.name, p.product_id, p.name
)
SELECT store_name, product_name, total_units
FROM per_store
WHERE rn = 1
ORDER BY store_name;

-- Q6) inventory items with low stock
SELECT 
  s.name AS store_name,
  p.name AS product_name,
  i.on_hand
FROM inventory i
JOIN stores s   ON s.store_id   = i.store_id
JOIN products p ON p.product_id = i.product_id
WHERE i.on_hand < 12
ORDER BY s.name, p.name;

-- Q7) manager roster
SELECT 
  s.name AS store_name,
  CONCAT(e.first_name, ' ', e.last_name) AS manager_name,
  e.hire_date
FROM stores s
JOIN employees e ON e.store_id = s.store_id
WHERE e.title = 'Manager'
ORDER BY s.name, manager_name;

-- Q8) products whose PAID revenue > average PAID product revenue
WITH product_rev AS (
  SELECT 
    p.product_id,
    p.name AS product_name,
    SUM(oi.quantity * p.price) AS total_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE o.status = 'paid'
  GROUP BY p.product_id, p.name
),
avg_rev AS (
  SELECT AVG(total_revenue) AS avg_revenue FROM product_rev
)
SELECT pr.product_name, pr.total_revenue
FROM product_rev pr
JOIN avg_rev a
  ON pr.total_revenue > a.avg_revenue
ORDER BY pr.total_revenue DESC, pr.product_name;

-- Q9) customers with their last PAID order date (NULL if none)
SELECT 
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  MAX(o.order_datetime) AS last_paid_order
FROM customers c
LEFT JOIN orders o 
  ON o.customer_id = c.customer_id
 AND o.status = 'paid'    -- filter in ON clause to keep customers with no paid orders
GROUP BY c.customer_id, customer_name
ORDER BY last_paid_order IS NULL, last_paid_order DESC, customer_name;

-- Q10) store × category mix (paid only)
SELECT 
  s.name  AS store_name,
  cat.name AS category_name,
  SUM(oi.quantity)           AS units,
  SUM(oi.quantity * p.price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN stores s       ON s.store_id    = o.store_id
WHERE o.status = 'paid'
GROUP BY s.name, cat.name
ORDER BY s.name, revenue DESC, cat.name;
