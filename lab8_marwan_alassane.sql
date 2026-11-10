-- Task 1: Single CTE
-- Customers whose total spend is above the average customer total.
-- customer_spend: one row per customer (599 rows).
-- The outer query compares each total with the average of all totals.
WITH customer_spend AS (
  SELECT
    customer_id,
    SUM(amount) AS total_spent
  FROM `sakila-aly6600.sakila.payment`
  GROUP BY customer_id
)
SELECT
  customer_id,
  total_spent
FROM customer_spend
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_spend)
ORDER BY total_spent DESC;

-- Task 2: Chained CTEs
-- Top five cities by number of above-average-spending customers,
-- with each city's total revenue from those customers.
WITH customer_spend AS (
  -- Step 1: total spend per customer (599 rows)
  SELECT
    customer_id,
    SUM(amount) AS total_spent
  FROM `sakila-aly6600.sakila.payment`
  GROUP BY customer_id
),
overall_avg AS (
  -- Step 2: average of those totals (1 row: 112.53)
  SELECT AVG(total_spent) AS avg_spent
  FROM customer_spend
),
above_average AS (
  -- Step 3: keep customers above the average (CROSS JOIN attaches
  -- the one-row average to every customer, as on slide 12)
  SELECT
    cs.customer_id,
    cs.total_spent
  FROM customer_spend AS cs
  CROSS JOIN overall_avg AS oa
  WHERE cs.total_spent > oa.avg_spent
),
customer_city AS (
  -- Step 4: join through customer and address to get each city
  SELECT
    ct.city_id,
    ct.city,
    aa.customer_id,
    aa.total_spent
  FROM above_average AS aa
  INNER JOIN `sakila-aly6600.sakila.customer` AS c
    ON aa.customer_id = c.customer_id
  INNER JOIN `sakila-aly6600.sakila.address` AS a
    ON c.address_id = a.address_id
  INNER JOIN `sakila-aly6600.sakila.city` AS ct
    ON a.city_id = ct.city_id
)
-- Final step: aggregate by city, rank, keep the top five.
-- Grouped by city_id as well as name, because Sakila has two cities
-- named London. Ties on customer count are broken by revenue.
SELECT
  city,
  COUNT(*)         AS above_avg_customers,
  SUM(total_spent) AS total_revenue
FROM customer_city
GROUP BY city_id, city
ORDER BY above_avg_customers DESC, total_revenue DESC
LIMIT 5;
