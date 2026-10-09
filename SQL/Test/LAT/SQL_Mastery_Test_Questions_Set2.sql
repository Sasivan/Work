-- ============================================================================
-- SQL MASTERY ASSIGNMENT — TEST QUESTIONS, SET 2 (Levels 1-5)
-- 5 NEW medium-difficulty questions per level, 25 total.
-- Same 12-table dataset as the main assignment (employees, departments,
-- customers, orders, order_items, products, payments, projects,
-- employee_projects, employee_org_chart, attendance, product_prices_history).
-- These are a fresh set — distinct from the main assignment's 128 questions
-- AND from Test Set 1 (25 questions). Full PostgreSQL answers are provided  
-- at the end of this file.
-- ============================================================================


-- ############################################################################
-- LEVEL 1 — FUNDAMENTALS
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q1 [Tables: employees]
-- List all active employees in Engineering or Sales (department_id 1 or 2)
-- hired after 2019-01-01, ordered by hire_date ascending. Return
-- first_name, last_name, department_id, hire_date.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q2 [Tables: employees]
-- For each city, return the number of active employees and the highest
-- salary among them, sorted by employee count descending.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q3 [Tables: products]
-- Using CASE, classify every active product's list_price as 'Premium'
-- (>= 5000), 'Standard' (1000-4999), or 'Budget' (< 1000). Return
-- product_name, category, list_price, price_tier.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q4 [Tables: customers]
-- Build a masked email for every customer showing only the first 2
-- characters, then '***', then the full domain (e.g. 'ra***@mail.com').
-- Return customer_id, email, masked_email.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q5 [Tables: employees]
-- For each active employee, calculate full years and remaining months
-- employed as of 2024-06-15 (e.g. "5 years, 3 months"), as two separate
-- columns. Return employee_id, hire_date, years_employed, months_employed.
-- ----------------------------------------------------------------------------



-- ############################################################################
-- LEVEL 2 — INTERMEDIATE
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q6 [Tables: products, order_items]
-- Using a LEFT JOIN, list every product alongside the total quantity ever
-- ordered (show 0, not NULL, for products never ordered). Return
-- product_id, product_name, total_quantity_ordered.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q7 [Tables: employees]
-- Using a subquery in FROM, find every department whose average active
-- employee salary is above the company-wide average active salary.
-- Return department_id, avg_salary.
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- Q8 [Tables: projects, employee_projects]
-- Using NOT EXISTS, find every project that currently has NO employees
-- assigned to it at all. Return project_id, project_name.
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- Q9 [Tables: customers, orders]
-- Using INTERSECT, find customer_ids that are BOTH in the 'Enterprise'
-- segment AND placed at least one order (any status) in 2024.
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- Q10 [Tables: products]
-- Using GROUP BY + HAVING, detect whether any product_name appears more
-- than once in the products table. Return product_name and the count.
-- ----------------------------------------------------------------------------

-- ############################################################################
-- LEVEL 3 — ADVANCED
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q11 [Tables: employee_projects, employees]
-- Using a CTE, calculate each employee's total hours_logged across all
-- their projects, then return only employees whose total exceeds the
-- overall average total hours logged across all employees.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q12 [Tables: employee_org_chart]
-- Write a RECURSIVE CTE returning the full management chain for Pooja
-- Chawla (emp_id 14) up to the CEO. Return emp_id, emp_name, and a level
-- number where Pooja is level 1.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q13 [Tables: products]
-- Using DENSE_RANK(), find the top 2 DISTINCT list_price levels WITHIN
-- each category and return every product at those price levels.
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- Q14 [Tables: orders]
-- Using SUM() OVER (PARTITION BY ...) with NO ORDER BY, show each order's
-- total_amount alongside that customer's grand total across all their
-- orders, and what percentage of the customer's total this order
-- represents (rounded to 1 decimal).
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q15 [Tables: orders]
-- Using conditional aggregation, pivot orders so each row is a
-- ship_country, with separate columns for the count of COMPLETED orders
-- and the count of RETURNED orders.
-- ----------------------------------------------------------------------------



-- ############################################################################
-- LEVEL 4 — EXPERT
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q16 [Tables: attendance]
-- Using the row-number-difference island technique, find the SINGLE
-- longest consecutive PRESENT streak across ALL employees combined (i.e.
-- whichever employee has the overall longest streak). Return employee_id,
-- streak_start, streak_end, streak_length.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q17 [Tables: employees, departments]
-- For each department, find the MOST RECENTLY HIRED active employee.
-- Return department_id, department_name, first_name, last_name, hire_date.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q18 [Tables: projects, employee_projects]
-- Business question: "Which active projects are well-staffed?" For each
-- ACTIVE project, return the number of distinct contributors and total
-- hours logged, flagging projects with more than 2 contributors as
-- 'Well-Staffed' and everything else as 'Lean Team'.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q19 [Tables: orders]
-- Given the hypothetical query:
--   SELECT * FROM orders WHERE total_amount + 0 > 5000;
-- explain in a comment why wrapping total_amount in an arithmetic
-- expression prevents a plain index on total_amount from being used
-- efficiently, then provide the index-friendly rewrite.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q20 [Tables: projects, departments]
-- Write a transaction that starts a new project (insert into projects)
-- and simultaneously decrements that department's budget by the new
-- project's budget, with a comment on what you'd check before COMMIT vs
-- ROLLBACK (specifically: the department's budget should never go
-- negative as a result).
-- ----------------------------------------------------------------------------



-- ############################################################################
-- LEVEL 5 — DATA ENGINEERING & MODERN ANALYTICS PATTERNS
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q21 [Tables: products]
-- Using ROLLUP(category), return the count of products and total
-- list_price per category, plus a grand total row, in one query.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q22 [Tables: product_prices_history]
-- For product_id 203, find the price that was in effect on 2022-08-01
-- using a point-in-time join/lookup against product_prices_history, and
-- compare it to today's current price (effective_to IS NULL).
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q23 [Tables: product_prices_history]
-- Write an upsert for product_id 206's price: if a current price row
-- already exists, close it out; insert a new current row at 220.00
-- effective 2024-09-01.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q24 [Tables: orders]
-- Write a batched UPDATE pattern (LIMIT-based, meant to be re-run in a
-- loop) that marks PENDING orders older than 90 days as CANCELLED, in
-- batches of 100 rows at a time.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Q25 [Tables: customers]
-- Using customers.preferences JSONB, find every customer with
-- newsletter = true whose interested_categories array includes
-- "Electronics". Return customer_id, customer_name.
-- ----------------------------------------------------------------------------


-- ============================================================================
-- END OF QUESTIONS
-- ============================================================================



-- ============================================================================
-- ============================================================================
--                          ANSWER KEY — POSTGRESQL
-- ============================================================================
-- ============================================================================


-- ===== LEVEL 1 =====

-- Q1
SELECT first_name, last_name, department_id, hire_date
FROM employees
WHERE status = 'ACTIVE'
  AND department_id IN (1, 2)
  AND hire_date > '2019-01-01'
ORDER BY hire_date ASC;

-- Q2
SELECT city,
       COUNT(*) AS emp_count,
       MAX(salary) AS max_salary
FROM employees
WHERE status = 'ACTIVE'
GROUP BY city
ORDER BY emp_count DESC;

-- Q3
SELECT product_name,
       category,
       list_price,
       CASE
           WHEN list_price >= 5000 THEN 'Premium'
           WHEN list_price >= 1000 THEN 'Standard'
           ELSE 'Budget'
       END AS price_tier
FROM products
WHERE is_active = TRUE
ORDER BY list_price DESC;

-- Q4
SELECT customer_id,
       email,
       LEFT(email, 2) || '***' || SUBSTRING(email FROM POSITION('@' IN email)) AS masked_email
FROM customers;

-- Q5
SELECT employee_id,
       hire_date,
       DATE_PART('year', AGE(DATE '2024-06-15', hire_date))  AS years_employed,
       DATE_PART('month', AGE(DATE '2024-06-15', hire_date)) AS months_employed
FROM employees
WHERE status = 'ACTIVE';

SELECT
    employee_id,
    extract(YEAR from age(date '2024-06-15',hire_date)),
    extract(MONTH from age(date '2024-06-15',hire_date)) as m
FROM employees
WHERE status = 'ACTIVE'


-- ===== LEVEL 2 =====

-- Q6
SELECT p.product_id,
       p.product_name,
       COALESCE(SUM(oi.quantity), 0) AS total_quantity_ordered
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_ordered DESC;

-- Q7
SELECT dept_avgs.department_id, dept_avgs.avg_salary
FROM (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    WHERE status = 'ACTIVE' AND department_id IS NOT NULL
    GROUP BY department_id
) dept_avgs
WHERE dept_avgs.avg_salary > (
    SELECT AVG(salary) FROM employees WHERE status = 'ACTIVE'
);

-- Q8
SELECT p.project_id, p.project_name
FROM projects p
WHERE NOT EXISTS (
    SELECT 1 FROM employee_projects ep WHERE ep.project_id = p.project_id
);

-- Q9
SELECT customer_id FROM customers WHERE customer_segment = 'Enterprise'
INTERSECT
SELECT customer_id FROM orders WHERE EXTRACT(YEAR FROM order_date) = 2024;

-- Q10
SELECT product_name, COUNT(*) AS occurrence_count
FROM products
GROUP BY product_name
HAVING COUNT(*) > 1;


-- ===== LEVEL 3 =====

-- Q11
WITH emp_hours AS (
    SELECT employee_id, SUM(hours_logged) AS total_hours
    FROM employee_projects
    GROUP BY employee_id
)
SELECT eh.employee_id, e.first_name, e.last_name, eh.total_hours
FROM emp_hours eh
JOIN employees e ON e.employee_id = eh.employee_id
WHERE eh.total_hours > (SELECT AVG(total_hours) FROM emp_hours)
ORDER BY eh.total_hours DESC;

-- Q12
WITH RECURSIVE chain AS (
    SELECT emp_id, emp_name, manager_id, 1 AS level_num
    FROM employee_org_chart
    WHERE emp_id = 14
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, c.level_num + 1
    FROM employee_org_chart e
    INNER JOIN chain c ON e.emp_id = c.manager_id
)
SELECT * FROM chain ORDER BY level_num;

-- Q13
WITH ranked AS (
    SELECT product_id, product_name, category, list_price,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY list_price DESC) AS price_rank
    FROM products
)
SELECT product_id, product_name, category, list_price, price_rank
FROM ranked
WHERE price_rank <= 2
ORDER BY category, price_rank;

-- Q14
SELECT order_id,
       customer_id,
       total_amount,
       SUM(total_amount) OVER (PARTITION BY customer_id) AS customer_total,
       ROUND(
           100.0 * total_amount / NULLIF(SUM(total_amount) OVER (PARTITION BY customer_id), 0),
           1
       ) AS pct_of_customer_total
FROM orders
ORDER BY customer_id, order_date;

-- Q15
SELECT ship_country,
       SUM(CASE WHEN order_status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_count,
       SUM(CASE WHEN order_status = 'RETURNED' THEN 1 ELSE 0 END) AS returned_count
FROM orders
GROUP BY ship_country
ORDER BY ship_country;


-- ===== LEVEL 4 =====

-- Q16
WITH present_days AS (
    SELECT employee_id, attendance_date,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY attendance_date) AS rn
    FROM attendance
    WHERE status = 'PRESENT'
),
islands AS (
    SELECT employee_id, attendance_date,
           (attendance_date - (rn * INTERVAL '1 day'))::date AS island_group
    FROM present_days
),
streaks AS (
    SELECT employee_id, island_group,
           MIN(attendance_date) AS streak_start,
           MAX(attendance_date) AS streak_end,
           COUNT(*) AS streak_length
    FROM islands
    GROUP BY employee_id, island_group
)
SELECT employee_id, streak_start, streak_end, streak_length
FROM streaks
ORDER BY streak_length DESC
LIMIT 1;

-- Q17
WITH ranked AS (
    SELECT e.employee_id, e.first_name, e.last_name, e.department_id, e.hire_date,
           ROW_NUMBER() OVER (PARTITION BY e.department_id ORDER BY e.hire_date DESC) AS rn
    FROM employees e
    WHERE e.status = 'ACTIVE' AND e.department_id IS NOT NULL
)
SELECT r.department_id, d.department_name, r.first_name, r.last_name, r.hire_date
FROM ranked r
JOIN departments d ON d.department_id = r.department_id
WHERE r.rn = 1
ORDER BY r.department_id;

-- Q18
SELECT p.project_id,
       p.project_name,
       COUNT(DISTINCT ep.employee_id) AS contributor_count,
       SUM(ep.hours_logged) AS total_hours_logged,
       CASE WHEN COUNT(DISTINCT ep.employee_id) > 2 THEN 'Well-Staffed' ELSE 'Lean Team' END AS staffing_flag
FROM projects p
JOIN employee_projects ep ON ep.project_id = p.project_id
WHERE p.status = 'ACTIVE'
GROUP BY p.project_id, p.project_name
ORDER BY contributor_count DESC;

-- Q19
-- Wrapping total_amount in "+ 0" turns the WHERE predicate into a computed
-- expression that must be evaluated for every row before comparison, so the
-- planner cannot do a direct index seek on total_amount — it falls back to
-- scanning and computing the expression row by row. Rewritten, index-friendly:
SELECT * FROM orders WHERE total_amount > 5000;

-- Q20
BEGIN;

INSERT INTO projects (project_id, project_name, department_id, start_date, end_date, budget, status)
VALUES (309, 'New Analytics Initiative', 1, '2024-07-01', NULL, 400000, 'ACTIVE');

UPDATE departments
SET budget = budget - 400000
WHERE department_id = 1;

-- Check before committing: the resulting budget must not go negative.
-- SELECT budget FROM departments WHERE department_id = 1;
-- If budget < 0 here, issue ROLLBACK instead of COMMIT.

COMMIT;
-- (ROLLBACK; instead, if the pre-commit check above showed a negative budget)


-- ===== LEVEL 5 =====

-- Q21
SELECT case when GROUPING(category) = 1 then 'All' else category end as category,
       COUNT(*) AS product_count,
       SUM(list_price) AS total_list_price
FROM products
GROUP BY ROLLUP(category)
ORDER BY category;

-- Q22
SELECT
    (SELECT price FROM product_prices_history
     WHERE product_id = 203
       AND DATE '2022-08-01' >= effective_from
       AND DATE '2022-08-01' < COALESCE(effective_to, DATE '9999-12-31')) AS price_as_of_2022_08_01,
    (SELECT price FROM product_prices_history
     WHERE product_id = 203 AND effective_to IS NULL) AS current_price;

-- Q23
-- Close out the existing current row (if any)
UPDATE product_prices_history
SET effective_to = DATE '2024-09-01' - INTERVAL '1 day'
WHERE product_id = 206 AND effective_to IS NULL;

-- Insert the new current row
INSERT INTO product_prices_history (product_id, price, effective_from, effective_to)
VALUES (206, 220.00, '2024-09-01', NULL);

-- Q24
UPDATE orders
SET order_status = 'CANCELLED'
WHERE order_id IN (
    SELECT order_id FROM orders
    WHERE order_status = 'PENDING' AND order_date < CURRENT_DATE - INTERVAL '90 days'
    LIMIT 100
);
-- Re-run this statement in a loop (application/script layer) until it
-- reports 0 rows affected.

-- Q25
SELECT customer_id, customer_name
FROM customers
WHERE (preferences ->> 'newsletter')::boolean = true
  AND preferences -> 'interested_categories' @> '["Electronics"]'::jsonb;


-- ============================================================================
-- END OF ANSWER KEY
-- ============================================================================
