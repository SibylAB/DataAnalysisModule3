-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;


-- Q1) Compute total items per order.
--     Return (order_id, total_items) from order_items.
select count(*)
from order_items;
-- Q2) Compute total items per order for PAID orders only.
--     Return (order_id, total_items). Hint: order_id IN (SELECT ... FROM orders WHERE status='paid').
select count(*)
from orders 
where status='paid';
-- Q3) How many orders were placed per day (all statuses)?
--     Return (order_date, orders_count) from orders.
select count(*) as totalorders
from orders;

-- Q4) What is the average number of items per PAID order?
--     Use a subquery or CTE over order_items filtered by order_id IN (...).
select AVG(order_id) as order_item_id
from order_items;
-- Q5) Which products (by product_id) have sold the most units overall across all stores?
--     Return (product_id, total_units), sorted desc.
select product_id , price
from products
order by price DESC;

-- Q6) Among PAID orders only, which product_ids have the most units sold?
--     Return (product_id, total_units_paid), sorted desc.
--     Hint: order_id IN (SELECT order_id FROM orders WHERE status='paid').
select order_id  from orders, order_items
where status='paid'
order by product_id, order_id DESC;

-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
--     Return (store_id, unique_customers) using only the orders table.
select store_id from orders
where customer_id;

-- Q8) Which day of week has the highest number of PAID orders?
--     Return (day_name, orders_count). Hint: DAYNAME(order_datetime). Return ties if any.
  select dayname(order_datetime) as dayname, count(order_id) as orders_count
  from orders
  where status='paid'
  group by dayname(order_datetime)
  order by orders_count DESC 
  Limit 1;

-- Q9) Show the calendar days whose total orders (any status) exceed 3.
--     Use HAVING. Return (order_date, orders_count).
select count (order_datetime), orders_count
from orders 
group by status
having count (orders_count) > 3;
-- Q10) Per store, list payment_method and the number of PAID orders.
--      Return (store_id, payment_method, paid_orders_count).
select payment_method from orders 
where store_id 
order by paid_orders_count;

-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
--      Return a single row with pct_app_paid_orders (0–100).
SELECT 
    status,
    (SUM(CASE WHEN payment_method = 'app' THEN 1 ELSE 0 END) * 100.0 
     / COUNT(*)) AS percent_app
FROM orders
GROUP BY status;

-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.
SELECT 
    EXTRACT(HOUR FROM order_date) AS hour_of_day,
    COUNT(*) AS orders_count
FROM orders
WHERE status = 'PAID'
GROUP BY EXTRACT(HOUR FROM order_date)
ORDER BY orders_count DESC;

-- ================
