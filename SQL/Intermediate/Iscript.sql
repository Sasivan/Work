-- ============================================================================
-- LEVEL 2 — INTERMEDIATE: SQL Mastery Assignment
-- ============================================================================

-- ============================================================================
-- 7. Joins — INNER, LEFT, RIGHT, FULL, CROSS, SELF
-- ============================================================================

-- --- Question 35 ---
-- [Tables: employees, departments]
-- Write an INNER JOIN between employees and departments to return each active employee's full name,
-- job_title, department_name, and location.

SELECT
    concat(e.first_name,' ',e.last_name) as full_name,
    e.job_title,
    d.department_name,
    d.location
from employees e 
inner join departments d 
on e.department_id = d.department_id
where e.status = 'ACTIVE';

SELECT * FROM departments

-- --- Question 36 ---
-- [Tables: departments, employees]
-- Write a query using LEFT JOIN to find every department (including HR, which has no employees) along with a
-- count of its active employees. Departments with zero employees should show 0, not NULL.

SELECT
    d.department_name,
    sum(CASE 
        WHEN e.status = 'ACTIVE' THEN 1 ELSE 0 
    END) as emp_count
FROM departments d
LEFT JOIN  employees e
on e.department_id = d.department_id
GROUP BY d.department_id,d.department_name;


-- --- Question 37 ---
-- [Tables: customers, orders]
-- Find all customers who have never placed an order. Use a LEFT JOIN approach (you'll write the EXISTS/NOT
-- EXISTS version of this same problem later in this assignment, for comparison).

SELECT
    c.*
FROM customers c
LEFT JOIN orders o 
on c.customer_id = o.customer_id
WHERE o.order_id is null;

-- --- Question 38 ---
-- [Tables: employees]
-- Using a self join on employees, list every employee alongside their manager's full name and job_title. Employees
-- with no manager (top-level, manager_id IS NULL) should still appear, with NULLs for manager info.

SELECT
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
  CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
  m.job_title AS manager_title
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;


-- --- Question 39 ---
-- [Tables: orders, order_items, products]
-- Write a query joining orders, order_items, and products to return, for each COMPLETED order, the order_id,
-- customer_id, product_name, quantity, and line-item revenue (quantity * unit_price * (1 - discount_pct)).

SELECT
    o.order_id,
    o.customer_id,
    p.product_name,
    oi.quantity,
    (oi.quantity*p.unit_cost*(1-oi.discount_pct)) as revenue
FROM orders o
INNER JOIN order_items oi on o.order_id = oi.order_id
INNER JOIN products p on oi.product_id = p.product_id
WHERE o.order_status = 'COMPLETED'


-- --- Question 40 ---
-- [Tables: orders, payments]
-- Using a FULL OUTER JOIN (or your engine's equivalent emulation if targeting MySQL — write both versions if you
-- can), reconcile orders and payments to find: (a) orders with no matching payment, and (b) any payment rows
-- that don't correspond to a real order (there are none in the sample data, but write the query so it would
-- correctly surface any if they existed).

SELECT
  o.order_id AS order_id_from_orders,
  p.order_id AS order_id_from_payments
FROM orders o 
FULL OUTER JOIN payments p 
on o.order_id = p.order_id
WHERE p.order_id is null or o.order_id is null;


-- --- Question 41 ---
-- [Tables: departments]
-- Write a CROSS JOIN between departments and a small derived list of the 4 calendar quarters (Q1-Q4) to produce
-- a full grid of every department x every quarter — this is the kind of 'expected combinations' spine you'd build to
-- detect departments with zero project activity in a given quarter. You may hardcode the quarters as a subquery
-- or VALUES list.

SELECT
    d.department_name,
    q.quarter
FROM departments d
CROSS JOIN (
    VALUES
        ('Q1'),
        ('Q2'),
        ('Q3'),
        ('Q4')
) AS q(quarter);

-- --- Question 42 ---
-- [Tables: employees]
-- Using employees as a self join, find all PAIRS of employees who work in the same department and have the same
-- job_title but are different people. Return both employees' names and the shared department_id and job_title,
-- making sure not to return the same pair twice (i.e., avoid both (A,B) and (B,A) appearing).

SELECT
    e1.first_name AS emp1_name,
    e2.first_name AS emp2_name,
    e1.department_id,
    e1.job_title
FROM employees e1
JOIN employees e2
    ON e1.department_id = e2.department_id
    AND e1.job_title = e2.job_title
    AND e1.employee_id < e2.employee_id;

SELECT
  e1.first_name AS emp1_name,
  e2.first_name AS emp2_name,
  e1.department_id,
  e1.job_title
FROM employees e1
INNER JOIN employees e2
  ON e1.department_id = e2.department_id
  AND e1.job_title = e2.job_title
  AND e1.employee_id < e2.employee_id;

-- --- Question 43 ---
-- [Tables: employees]
-- Find all employees who earn more than the average salary of ALL active employees in the company. Return
-- employee_id, full name, department_id, salary.

SELECT
    employee_id,
    concat(first_name,' ',last_name) as full_name,
    department_id,
    salary
FROM employees
WHERE status = 'ACTIVE' 
    AND salary > (SELECT avg(salary) FROM employees);
    

-- --- Question 44 ---
-- [Tables: products]
-- Find all products whose list_price is above the average list_price within their OWN category (a correlated
-- subquery). Return product_id, product_name, category, list_price.

SELECT
    p1.product_id,p1.product_name,p1.category,p1.list_price
FROM products p1
WHERE p1.list_price > (
    SELECT avg(p2.list_price)
    from products p2
    WHERE p1.category = p2.category
)

-- --- Question 45 ---
-- [Tables: orders]
-- Using a subquery in FROM, find the average order total_amount per customer_id (COMPLETED orders only),
-- then filter to customers whose average order value exceeds 3000. Return customer_id and avg_order_value.

SELECT
    customer_id,avg_order_value
FROM (
    SELECT customer_id,round(avg(total_amount),1) as avg_order_value
    FROM orders
    WHERE order_status = 'COMPLETED'
    GROUP BY customer_id
) AS customer_avgs
WHERE avg_order_value > 3000;

-- --- Question 46 ---
-- [Tables: employees]
-- Find the employee(s) with the highest salary in each department, using a correlated subquery (do NOT use
-- window functions here — save that approach for the Level 3 version of a similar question). Return employee_id,
-- full name, department_id, salary.

SELECT
    e.employee_id,
    concat(e.first_name,' ',e.last_name) as full_name,
    e.department_id,
    e.salary
FROM employees e
WHERE e.salary = (
    SELECT max(salary)
    FROM employees d 
    WHERE e.department_id = d.department_id
)

-- --- Question 47 ---
-- [Tables: customers, orders]
-- Find all customers who have placed at least one order with total_amount greater than 10000. Use a subquery
-- with IN. Return customer_id and customer_name.

-- SELECT
--     c.customer_id,c.customer_name
-- FROM customers c 
-- WHERE 1 >= (
--     SELECT count(*)
--     FROM orders o 
--     WHERE c.customer_id = o.customer_id
--      and o.total_amount > 10000
-- ) 

SELECT 
    customer_id,customer_name
from customers  
where customer_id in (
    SELECT customer_id
    from orders
    WHERE total_amount > 10000
)

-- --- Question 48 ---
-- [Tables: products, order_items]
-- Find all products that have NEVER appeared in any order_items row. Write this using NOT IN first, then explain
-- (as a comment) the risk of this approach if order_items.product_id could ever contain NULL, even though it
-- doesn't in our sample data.

SELECT
    product_id,product_name
FROM products 
WHERE product_id not in (
    SELECT product_id FROM order_items
);
-- `NOT IN` would evaluate to UNKNOWN, returning zero rows across the board if order_item.product_id caontain even 1 null

-- --- Question 49 ---
-- [Tables: employees]
-- For each department, find the employee with the second-highest salary using a correlated subquery approach
-- (hint: think about counting how many salaries are strictly greater than each employee's own salary within their
-- department). Return employee_id, full name, department_id, salary.

SELECT 
    e1.employee_id, 
    concat(e1.first_name,' ',e1.last_name) as full_name,
    e1.department_id,
    e1.salary
from employees e1
WHERE (
    SELECT count(*)
    FROM employees e2
    WHERE e1.department_id = e2.department_id
        and e1.salary < e2.salary
) = 1;


-- --- Question 50 ---
-- [Tables: customers, orders]
-- Rewrite Question 37 (customers with no orders) using NOT EXISTS instead of LEFT JOIN. Compare mentally:
-- which do you find more readable, and would the two approaches ever give different results on this dataset?
-- Note your reasoning as a comment.

SELECT
    c.customer_id,c.customer_name
FROM customers c 
WHERE not EXISTS (
    SELECT 1
    FROM orders o 
    WHERE o.order_id is null
);
--NOT EXISTS is often more readable for "absence" logic. Both approaches give identical results here, but NOT EXISTS can occasionally be faster

-- --- Question 51 ---
-- [Tables: departments, employees]
-- Find all departments that have at least one employee earning more than 200000, using EXISTS. Return
-- department_id and department_name.

SELECT
    d.department_id, d.department_name
from departments d
WHERE EXISTS (
    SELECT 1 
    FROM employees e 
    WHERE e.salary > 200000
    and e.department_id = d.department_id    
);

-- --- Question 52 ---
-- [Tables: products, order_items]
-- Find all products that have NEVER been ordered, using NOT EXISTS (the safe version of Question 48). Return
-- product_id and product_name.

SELECT
    p.product_id,p.product_name
from products p 
WHERE not EXISTS (
    SELECT 1 
    FROM order_items o 
    WHERE o.product_id = p.product_id
);

-- --- Question 53 ---
-- [Tables: customers, orders]
-- Find all customers who have placed an order that was RETURNED but have never had an order CANCELLED,
-- using two EXISTS/NOT EXISTS conditions in the same WHERE clause. Return customer_id, customer_name.

SELECT
    c.customer_id,c.customer_name
FROM customers c 
WHERE not EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id and o.order_status = 'CANCELLED'
) 
and EXISTS (
    SELECT 1 from orders o WHERE o.customer_id = c.customer_id and o.order_status = 'RETURNED'
);


-- --- Question 54 ---
-- [Tables: employees, employee_projects]
-- Find all employees who are NOT currently assigned to any project in employee_projects, using NOT EXISTS.
-- Return employee_id, full name, department_id.

SELECT
    e.employee_id,
    concat(e.first_name,' ',e.last_name) as full_name,
    e.department_id
FROM employees e
WHERE not EXISTS (
    SELECT 1 FROM employee_projects ep 
    WHERE e.employee_id = ep.employee_id
);

-- --- Question 55 ---
-- [Tables: employees, customers]
-- Write a query that produces a single unified list of 'people to contact': all employees with job_title 'Sales
-- Executive' or 'Sales Manager' (name, email, a literal 'Internal' label) UNION ALL with all Enterprise customers
-- (name, email, a literal 'External' label). Return a consistent 3-column output: contact_name, email,
-- contact_type.

SELECT
    CONCAT(first_name, ' ', last_name) AS contact_name,
    email,
    'Internal' as contact_type
FROM employees
WHERE job_title in ('Sales Executive','Sales Manager')
UNION ALL
SELECT
    customer_name as contact_name,
    email,
    'External' as contact_type
FROM customers
WHERE customer_segment = 'Enterprise';

-- --- Question 56 ---
-- [Tables: orders]
-- Using orders, find all customer_ids that placed a COMPLETED order in 2023 AND also placed a COMPLETED
-- order in 2024, using INTERSECT. (Hint: two separate SELECT customer_id ... queries, one per year.)

SELECT customer_id
from orders
WHERE extract(YEAR from order_date) = '2023' and order_status = 'COMPLETED'
INTERSECT
SELECT customer_id
from orders
WHERE extract(YEAR from order_date) = '2024' and order_status = 'COMPLETED'

-- --- Question 57 ---
-- [Tables: products, order_items]
-- Using EXCEPT (or NOT EXISTS/LEFT JOIN if your target engine lacks EXCEPT — write whichever you think is best
-- and note your engine assumption), find all product_ids in products that have never appeared in order_items.

SELECT product_id
FROM products
EXCEPT
SELECT product_id
FROM order_items

-- --- Question 58 ---
-- Explain (in a short written comment, no query needed) a real scenario from your own work — VIVE, TFG, or
-- otherwise — where UNION ALL would be the correct choice over UNION, and specifically why deduplication
-- would either be unnecessary or actively harmful there.

/*
COMMENT: In scenarios like combining partition tables (e.g., historical records from 2023 and 2024 appended together) or unifying ledger transactions (e.g., credits and debits from different source systems), `UNION ALL` is essential. Deduplication (`UNION`) would be unnecessary because the sources are mutually exclusive by design, and it would be actively harmful because it would drop legitimately duplicated events (like two identical $50 payments made by the same user on the same day).
*/

-- --- Question 59 ---
-- [Tables: employees]
-- Write a detection query (GROUP BY + HAVING) to find if any employees table columns (email specifically) have
-- duplicate values in our current data — even though you expect the answer to be 'no duplicates found' given the
-- sample data, write the query as if you didn't know that.

SELECT email, COUNT(*) AS duplicate_count
FROM employees
GROUP BY email
HAVING count(*) > 1

-- --- Question 60 ---
-- [Tables: product_prices_history]
-- Suppose product_prices_history could (hypothetically) contain two overlapping price rows for the same
-- product_id with the same effective_from date (a data quality bug). Write a GROUP BY + HAVING query that
-- would detect this specific situation.

SELECT product_id, effective_from, COUNT(*) AS duplicate_count
FROM product_prices_history
GROUP BY product_id, effective_from
HAVING COUNT(*) > 1;

-- --- Question 61 ---
-- [Tables: orders]
-- Write a query (conceptually — you may use a placeholder comment for the ROW_NUMBER window function
-- syntax if you haven't reached Level 3 yet, or attempt the full solution if you've already read ahead) that would
-- identify, for each customer_id, only their FIRST order (by order_date) from the orders table.

WITH RankedOrders AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rn
  FROM orders
)
SELECT *
FROM RankedOrders
WHERE rn = 1;

