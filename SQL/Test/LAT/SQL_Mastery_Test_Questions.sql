SELECT datname
FROM pg_database
WHERE datistemplate = false;

SELECT current_database();

SELECT schema_name
FROM information_schema.schemata
ORDER BY schema_name;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'sql_mastery_assignment'

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'sql_mastery_assignment'
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- ============================================================================
-- SQL MASTERY ASSIGNMENT — TEST QUESTIONS (Levels 1-5)
-- 5 NEW medium-difficulty questions per level, 25 total.
-- Same 12-table dataset as the main assignment (employees, departments,
-- customers, orders, order_items, products, payments, projects,
-- employee_projects, employee_org_chart, attendance, product_prices_history).
-- None of these duplicate the 128 questions already in Levels 1-5 of the
-- main assignment or its Level 5 addendum — same topics, fresh questions.
--
-- Format: each question is a comment block. Write your answer directly
-- below it, between the "-- YOUR ANSWER:" line and the next question.
-- Treat each block like a notebook cell.
-- ============================================================================


-- ############################################################################
-- LEVEL 1 — FUNDAMENTALS
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q1 [Tables: employees]
-- List all active employees in the Finance or Marketing departments
-- (department_id 3 or 4) earning more than 80000, showing first_name,
-- last_name, department_id, and salary, ordered by salary descending.
-- ----------------------------------------------------------------------------

SELECT
    first_name,last_name,department_id,salary
FROM employees
WHERE status = 'ACTIVE' and salary > 80000 and department_id in (3,4)
ORDER BY salary desc



-- ----------------------------------------------------------------------------
-- Q2 [Tables: employees]
-- For each gender, return the count of active employees and their average
-- salary (rounded to 2 decimal places), sorted by average salary descending.
-- ----------------------------------------------------------------------------

SELECT
    gender,
    round(avg(salary),2) as avg_salary
from employees
WHERE status = 'ACTIVE'
GROUP BY gender
ORDER BY avg_salary desc


-- ----------------------------------------------------------------------------
-- Q3 [Tables: employees]
-- Add a column salary_band using CASE that labels each active employee
-- 'High' (salary >= 150000), 'Mid' (90000-149999), or 'Low' (< 90000).
-- Return employee_id, full name, salary, salary_band.
-- ----------------------------------------------------------------------------

SELECT
    concat(first_name,' ',last_name) as full_name,
    salary,
    CASE 
        WHEN salary >= 150000 THEN 'HIGH'
        WHEN salary BETWEEN 90000 and 149999 then 'MID'  
        ELSE  'LOW'
    END as salary_band
FROM employees
WHERE status = 'ACTIVE'


-- ----------------------------------------------------------------------------
-- Q4 [Tables: employees]
-- Build a lowercase "username" for each employee as the first letter of
-- first_name followed by the full last_name (e.g. Rohan Gupta -> 'rgupta').
-- Return employee_id, first_name, last_name, username.
-- ----------------------------------------------------------------------------

SELECT
    employee_id,
    first_name,
    last_name,
    lower(concat(substring(first_name,1,1),last_name))
FROM employees



-- ----------------------------------------------------------------------------
-- Q5 [Tables: orders]
-- Find all orders placed in December of any year. Return order_id,
-- order_date, the month name, and the day-of-week name. State your
-- assumed engine (the function names differ across engines).
-- ----------------------------------------------------------------------------

SELECT
    order_id,
    order_date,
    to_char(order_date,'Month') as month_name,
    to_char(order_date,'FMday') as day_name
FROM orders
WHERE extract(MONTH from order_date) = 12


-- ############################################################################
-- LEVEL 2 — INTERMEDIATE
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q6 [Tables: employees, departments]
-- Using an INNER JOIN, list every active employee based in a department
-- located in Bengaluru, showing full name, job_title, department_name,
-- and the department's budget.
-- ----------------------------------------------------------------------------

SELECT
    concat(e.first_name,' ',e.last_name) as full_name,
    e.job_title,
    d.department_name,
    d.budget
FROM employees e
INNER join departments d USING(department_id)
WHERE d.location = 'Bengaluru'


-- ----------------------------------------------------------------------------
-- Q7 [Tables: customers, orders]
-- Find all customers who have placed more than 2 orders of any status.
-- Return customer_id, customer_name, and their order count.
-- ----------------------------------------------------------------------------

SELECT  
    customer_id
from customers c
JOIN orders o USING(customer_id)
GROUP BY customer_id
HAVING count(*) > 2


-- ----------------------------------------------------------------------------
-- Q8 [Tables: departments, employees]
-- Using EXISTS, find every department that has at least one active
-- employee earning less than 70000. Return department_id, department_name.
-- ----------------------------------------------------------------------------

SELECT DISTINCT
    d.department_id,
    d.department_name
FROM departments d 
JOIN employees e using(department_id)
where EXISTS (
    SELECT 1 from employees e
    where e.department_id = d.department_id
    and e.salary < 70000 and e.status = 'ACTIVE'
)


-- ----------------------------------------------------------------------------
-- Q9 [Tables: employees, customers]
-- Using UNION ALL, build a single list combining: (a) every employee whose
-- job_title contains 'VP' (name, email, label 'Internal Leadership'), and
-- (b) every customer in the 'India' country (name, email, label 'India
-- Customer'). Return a consistent 3-column output.
-- ----------------------------------------------------------------------------

select 
    concat(first_name,' ',last_name) as name,
    employees.email,
    'Internal Leadership' as label
from employees
where job_title like '%VP%'

UNION ALL

SELECT
    customers.customer_name as name,
    customers.email,
    'India Customer' as label
FROM customers
where customers.country = 'India'


-- ----------------------------------------------------------------------------
-- Q10 [Tables: orders]
-- Using GROUP BY + HAVING, detect any customer_id that has placed two or
-- more orders with the EXACT same total_amount (a possible sign of a
-- duplicate/retried order). Return customer_id, total_amount, and the count.
-- ----------------------------------------------------------------------------

SELECT
    customer_id,
    total_amount
from orders
GROUP BY customer_id,total_amount
HAVING count(*) >= 2 


-- ############################################################################
-- LEVEL 3 — ADVANCED
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q11 [Tables: products]
-- Using a CTE, calculate the average list_price per category, then return
-- only products priced above their own category's average. Return
-- product_id, product_name, category, price, category_avg_price.
-- ----------------------------------------------------------------------------

with average as (
    SELECT DISTINCT
        category,
        avg(price) over (PARTITION BY category) as category_avg_price
    FROM products
)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    a.category_avg_price
FROM products p 
JOIN average a USING(category)
WHERE p.list_price > a.category_avg_price


-- ----------------------------------------------------------------------------
-- Q12 [Tables: employee_org_chart]
-- Write a RECURSIVE CTE that returns every person in Kavita Bhatt's
-- (emp_id 12) reporting chain at any depth (direct and indirect reports).
-- Return emp_id, emp_name, and depth relative to Kavita (direct reports =
-- depth 1, their reports = depth 2, etc.).
-- ----------------------------------------------------------------------------

with RECURSIVE cte as (
    SELECT
        emp_id,
        emp_name,
        1 as depth
    from employee_org_chart
    WHERE emp_id = 12
    UNION ALL
    SELECT
        e.emp_id,
        e.emp_name,
        c.depth + 1 as depth
    from cte c
    JOIN employee_org_chart e on e.manager_id = c.emp_id
)
SELECT
    emp_id,
    emp_name,
    depth
FROM cte
WHERE depth > 0
ORDER BY depth, emp_id;


-- ----------------------------------------------------------------------------
-- Q13 [Tables: orders]
-- Using RANK(), rank every COMPLETED order by total_amount WITHIN its
-- ship_country (highest = 1), then return only the rank-1 order per
-- country. Return ship_country, order_id, order_date, total_amount.
-- ----------------------------------------------------------------------------

with rk as (
    SELECT
    ship_country,
    order_id,
    order_date,
    total_amount,
    rank() over (PARTITION BY ship_country order by total_amount desc) as rn
from orders 
WHERE order_status = 'COMPLETED'
)
SELECT  
    ship_country,
    order_id,
    order_date,
    total_amount
FROM rk
where rn = 1


-- ----------------------------------------------------------------------------
-- Q14 [Tables: orders]
-- Using LAG(), for customer_id 101 specifically, show each of their orders
-- alongside the total_amount of their immediately previous order and the
-- difference between the two. The first order should show NULL for both.
-- ----------------------------------------------------------------------------

with prev as (
    SELECT
        customer_id,
        order_id,
        total_amount,
        lag(total_amount) over (PARTITION BY customer_id ORDER BY order_date, order_id)
    from orders
    WHERE customer_id = 101

)
SELECT *,
    (lag-total_amount) as diff
from prev


-- ----------------------------------------------------------------------------
-- Q15 [Tables: employees]
-- Using conditional aggregation (CASE + SUM), pivot employees so each row
-- is a department_id, with separate columns for the count of employees
-- hired before 2020 ('Veteran') and hired 2020 or later ('Newer').
-- ----------------------------------------------------------------------------

SELECT 
    department_id,
    sum(
        case when extract(YEAR from hire_date) < 2020 then 1 end
    ) as Veteran,
    sum(
        case when extract(YEAR from hire_date) >= 2020 then 1 end
    ) as Newer
from employees
GROUP BY department_id


-- ############################################################################
-- LEVEL 4 — EXPERT
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q16 [Tables: attendance]
-- Using the row-number-difference island technique, find the longest
-- consecutive streak of 'LEAVE' status for employee_id 4 (Sneha Iyer).
-- Return the streak's start date, end date, and length in days.
-- ----------------------------------------------------------------------------

with streak as (
    SELECT 
        employee_id,
        attendance_date,
        row_number() over (PARTITION BY employee_id ORDER BY attendance_date) as rn
    from attendance
    where status = 'LEAVE' and employee_id = 4
),island as (
    SELECT
        employee_id,
        attendance_date,
        attendance_date - rn * INTERVAL '1 day' as rk
    FROm streak
), streaks as (
    SELECT 
        employee_id,
        max(attendance_date) as end_date,
        min(attendance_date) as start_date,
        count(*) as ck
    from island
    GROUP BY employee_id,rk
    ORDER BY ck
)
SELECT * FROM streaks LIMIT 1



-- ----------------------------------------------------------------------------
-- Q17 [Tables: customers, orders]
-- For each customer_segment, find the top 2 customers by total COMPLETED
-- order value. Return customer_segment, customer_id, customer_name,
-- total_value, and decide (and state in a comment) whether ties at the
-- 2nd spot return exactly 2 rows or all tied rows per segment.
-- ----------------------------------------------------------------------------

with cte as (
    SELECT 
        customer_id,
        customer_name,
        customer_segment,
        sum(total_amount) as t
    FROM customers o 
    JOIN orders USING(customer_id)
    WHERE order_status = 'COMPLETED'
    GROUP BY customer_id,customer_name,customer_segment
), rk as (
    SELECT *,
        rank() over (PARTITION BY customer_segment ORDER BY t desc) as rn
    from cte
)
SELECT customer_segment, customer_id, customer_name,t from rk
where rn <= 2


-- ----------------------------------------------------------------------------
-- Q18 [Tables: customers, orders]
-- Business question: "Which high-value customers are showing risk signs?"
-- Using CTEs, find customers whose lifetime COMPLETED order value exceeds
-- 5000 AND whose single most recent order (by order_date, any status) was
-- CANCELLED or RETURNED. Return customer_id, customer_name,
-- lifetime_value, most_recent_order_status.
-- ----------------------------------------------------------------------------

with cte as (
    SELECT
        customer_id,
        customer_name,
        sum(total_amount) as lifetime_value
    from customers
    join orders using(customer_id)
    WHERE order_status = 'COMPLETED'
    GROUP BY customer_id,customer_name
    HAVING sum(total_amount) > 5000
    order by lifetime_value desc
), ca as (
    SELECT
        customer_id,
        order_date,
        order_status,
        ROW_NUMBER() over (PARTITION BY customer_id ORDER BY order_date desc) as rn
    from orders
)
SELECT 
    customer_id,
    customer_name,
    lifetime_value,
    order_status
from cte 
JOIN ca USING(customer_id)
WHERE rn = 1  AND order_status IN ('CANCELLED', 'RETURNED');


-- ----------------------------------------------------------------------------
-- Q19 [Tables: employees]
-- Given the hypothetical query:
--   SELECT * FROM employees WHERE LOWER(email) = 'rohan.gupta@co.com';
-- explain in a comment why wrapping the column in LOWER() prevents a plain
-- index on email from being used efficiently, and propose a rewritten
-- version (or an alternative indexing strategy) that stays index-friendly.
-- ----------------------------------------------------------------------------
-- LOWER(email) applies a function to the email column for every row.
-- A normal index on email is ordered/indexed by the original email values,
-- so the database generally cannot use that plain index efficiently to
-- search for LOWER(email) = 'rohan.gupta@co.com'.
--
-- Index-friendly option 1: use an expression/function-based index:
-- CREATE INDEX idx_employees_lower_email
-- ON employees (LOWER(email));
--
-- Then this query can use that index:
SELECT *
FROM employees
WHERE LOWER(email) = 'rohan.gupta@co.com';


-- ----------------------------------------------------------------------------
-- Q20 [Tables: orders, order_items, products]
-- Write a transaction (BEGIN/COMMIT/ROLLBACK) that inserts a new order
-- for customer_id 101 and a matching order_items row for product_id 204,
-- ensuring the whole operation rolls back if product_id 204 does not
-- actually exist in products. Include a comment on what you'd check
-- before committing.
-- ----------------------------------------------------------------------------


BEGIN;

-- Verify that product 204 exists.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM products
        WHERE product_id = 204
    ) THEN
        RAISE EXCEPTION 'Product 204 does not exist';
    END IF;
END $$;

-- Insert the order.
INSERT INTO orders (customer_id)
VALUES (101)
RETURNING order_id;

-- Use the returned order_id here.
-- Example:
INSERT INTO order_items (order_id, product_id)
VALUES (5001, 204);

-- Before committing, verify that both the order and its
-- matching order_items row were inserted correctly.

COMMIT;

-- ############################################################################
-- LEVEL 5 — DATA ENGINEERING & MODERN ANALYTICS PATTERNS
-- ############################################################################

-- ----------------------------------------------------------------------------
-- Q21 [Tables: employees]
-- Using GROUPING SETS, return in one query: (a) total active-employee
-- salary per department_id, (b) total active-employee salary per gender,
-- and (c) one company-wide grand total. No other combinations.
-- ----------------------------------------------------------------------------

SELECT
    department_id,
    gender,
    SUM(salary) AS total_salary
FROM employees
WHERE status = 'ACTIVE'
GROUP BY GROUPING SETS (
    (department_id),
    (gender),
    ()
);


-- ----------------------------------------------------------------------------
-- Q22 [Tables: orders, order_items, product_prices_history]
-- For order_id 5001 (product_id 201), find the price that was in effect
-- on the order's order_date using a point-in-time join against
-- product_prices_history, and compare it to today's current price
-- (effective_to IS NULL). Return both prices and the difference.
-- ----------------------------------------------------------------------------

SELECT
    o.order_id,
    oi.product_id,
    h.price AS order_date_price,
    current_price.price AS current_price,
    current_price.price - h.price AS price_difference
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN product_prices_history h
    ON h.product_id = oi.product_id
   AND o.order_date >= h.effective_from
   AND (
       h.effective_to IS NULL
       OR o.order_date < h.effective_to
   )
JOIN product_prices_history current_price
    ON current_price.product_id = oi.product_id
   AND current_price.effective_to IS NULL
WHERE o.order_id = 5001
  AND oi.product_id = 201;


-- ----------------------------------------------------------------------------
-- Q23 [Tables: departments]
-- Write an upsert (MERGE or Postgres ON CONFLICT) for departments: if
-- department_id 5 (HR) already exists, update its budget to 950000;
-- otherwise insert it with that budget.
-- ----------------------------------------------------------------------------

INSERT INTO departments (
    department_id,
    department_name,
    budget
)
VALUES (
    5,
    'HR',
    950000
)
ON CONFLICT (department_id)
DO UPDATE SET
    budget = EXCLUDED.budget;


    MERGE INTO departments AS d
USING (
    VALUES (5, 'HR', 950000)
) AS src(department_id, department_name, budget)
ON d.department_id = src.department_id

WHEN MATCHED THEN
    UPDATE SET budget = src.budget

WHEN NOT MATCHED THEN
    INSERT (department_id, department_name, budget)
    VALUES (src.department_id, src.department_name, src.budget);


-- ----------------------------------------------------------------------------
-- Q24 [Tables: orders]
-- Write a batched DELETE pattern (LIMIT-based, meant to be re-run in a
-- loop) that purges PENDING orders older than 2023-01-01 in batches of
-- 200 rows. Explain in a comment why batching matters here.
-- ----------------------------------------------------------------------------

DELETE from orders
where order_id in (
    SELECT order_id from orders
    where order_status = 'PENDING' and 
    order_date < date '2023-01-01'
    order by order_date
    limit 200
)


-- ----------------------------------------------------------------------------
-- Q25 [Tables: products]
-- Using the products.specifications JSONB column (see Level 5 addendum
-- schema extension), find every product whose specifications contain
-- "adjustable_height": true. Return product_name, category, and the
-- warranty_years value extracted as an integer.
-- ----------------------------------------------------------------------------

SELECT
    product_name,
    category,
    (specifications ->> 'warranty_years')::INT AS warranty_years
FROM products
WHERE specifications @> '{"adjustable_height": true}';


-- ============================================================================
-- END OF TEST QUESTIONS
-- ============================================================================
