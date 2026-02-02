USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
SELECT
    p.product_id,
    c.category_id,
    p.price
FROM products AS p
INNER JOIN categories AS c
    ON p.category_id = c.category_id;
-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
select
oi.order_id, o.order_datetime, s.store_name, p.product_name, oi.quantity, (oi.quantity * p.price) AS line_total
from order_items as oi
inner join orders as o
on oi.order_id = o.order_id
inner join stores as s 
on o.store_id = s.store.id
inner join products as p
on oi.product_id = p.product_id
order by
o.order_datetime,
oi.order_id;
-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select *
from customers AS c
 inner join orders AS o
on o.id = c.quantity;
-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
select first_name, last_name, city, state
from customers AS c
left join  orders AS o
on c.id = o.customer_id;
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
SELECT
    s.store_name,
    p.product_name,
    SUM(oi.quantity) AS total_units
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN stores s ON o.store_id = s.store_id
WHERE o.status = 'PAID'
GROUP BY s.store_id, s.store_name, p.product_name
HAVING SUM(oi.quantity) = (
    SELECT MAX(sub.total_units)
    FROM (
        SELECT SUM(oi2.quantity) AS total_units
        FROM orders o2
        JOIN order_items oi2 ON o2.order_id = oi2.order_id
        WHERE o2.store_id = s.store_id
          AND o2.status = 'PAID'
        GROUP BY oi2.product_id
    ) sub
)
ORDER BY store_name;

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
SELECT
    s.store_id,
    p.product_id,
    i.on_hand
FROM inventory i
JOIN stores s      ON i.store_id = s.store_id
JOIN products p    ON i.product_id = p.product_id
WHERE i.on_hand < 12
ORDER BY s.store_id, p.product_id;
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT
    s.store_id,
    e.employee_id,
    e.hire_date
FROM stores s
JOIN employees e
      ON s.store_id = e.store_id
WHERE e.title = 'Manager'
ORDER BY s.store_name;
-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
WITH product_revenue AS (
    SELECT
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    WHERE o.status = 'PAID'
    GROUP BY p.product_name
),
avg_revenue AS (
    SELECT AVG(total_revenue) AS avg_rev
    FROM product_revenue
)
SELECT
    pr.product_name,
    pr.total_revenue
FROM product_revenue pr
CROSS JOIN avg_revenue ar
WHERE pr.total_revenue > ar.avg_rev
ORDER BY pr.total_revenue DESC;
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
SELECT
    c.customer_name,
    MAX(o.order_date) AS last_paid_order_date
FROM customers c
LEFT JOIN orders o
       ON c.customer_id = o.customer_id
      AND o.status = 'PAID'     -- filter goes here!
GROUP BY c.customer_name
ORDER BY last_paid_order_date;
-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
SELECT
    s.store_name,
    c.category_name,
    SUM(oi.quantity) AS total_units,
    SUM(oi.quantity * p.price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
JOIN categories c   ON p.category_id = c.category_id
JOIN stores s       ON o.store_id = s.store_id
WHERE o.status = 'PAID'
GROUP BY
    s.store_name,
    c.category_name
ORDER BY
    s.store_name,
    c.category_name;