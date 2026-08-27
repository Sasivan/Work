-- ===============================n=============================================
-- LEVEL 1 — FUNDAMENTALS: SQL Mastery Assignment
-- ============================================================================

-- ============================================================================
-- 1. SELECT, WHERE, ORDER BY — Precise Filtering and Sorting
-- ============================================================================

-- --- Question 1 ---
-- [Tables: employees] 
-- From the employees table, list all active employees whose salary is above 100000, showing first_name, 
-- last_name, job_title, and salary, ordered by salary descending. Break ties by last_name ascending.
 
SELECT first_name, last_name, job_title, salary
FROM employees
WHERE status = 'ACTIVE' AND salary > 100000
ORDER BY salary DESC, last_name ASC;

-- --- Question 2 ---
-- [Tables: employees] 
-- List all employees whose city is Bengaluru or Pune, who are NOT in the Sales department (department_id = 2),
-- sorted by hire_date (earliest first). Include a column showing tenure isn't required — just the base columns plus hire_date.
 
SELECT employee_id, first_name, last_name, department_id, city, hire_date 
FROM employees
WHERE city IN ('Bengaluru','Pune') 
    AND department_id <> 2
ORDER BY hire_date ASC;

-- --- Question 3 ---
-- [Tables: employees, customers] 
-- Find all employees whose email contains 'sharma' or whose first_name starts with 'A'. Return employee_id, 
-- first_name, last_name, email.
 
SELECT employee_id, first_name, last_name, email
FROM employees
WHERE LOWER(email) LIKE '%sharma%'
   OR LOWER(first_name) LIKE 'a%';

-- --- Question 4 ---
-- [Tables: orders] 
-- Write a query that returns all orders placed in the second quarter of 2023 (April, May, June) with status 
-- COMPLETED, sorted by total_amount descending, limited to the top 5.
 
SELECT *
FROM orders
WHERE order_date >= '2023-04-01' AND order_date < '2023-07-01'
    AND order_status = 'COMPLETED'
ORDER BY total_amount DESC
LIMIT 5

-- --- Question 5 ---
-- [Tables: customers] 
-- Return all customers whose customer_segment is 'Enterprise' and whose country is NOT 'India', sorted by 
-- signup_date. Then explain in a one-line comment within your answer why using NOT IN would be risky if the 
-- country column could contain NULLs, even though it doesn't here.
 
SELECT * 
from customers
WHERE customer_segment = 'Enterprise'
    AND country <> 'India'
ORDER BY signup_date;
 
-- not null will filter out null also even though they are not india

-- --- Question 6 ---
-- [Tables: products] 
-- List all products with a list_price between 500 and 5000 (inclusive) that are currently active (is_active = TRUE), 
-- sorted by category ascending, then list_price descending.
 
SELECT *
FROM products
WHERE list_price BETWEEN 500 AND 1000
    AND is_active = 'True'
ORDER BY category ASC, list_price DESC;

-- --- Question 7 ---
-- [Tables: employees] 
-- Find all employees who report directly to employee_id 8 (Anita Desai). Return their employee_id, full name (as a 
-- single first_name + ' ' + last_name expression aliased full_name), and salary, sorted by salary descending.
  
SELECT employee_id, CONCAT(first_name,' ',last_name) AS full_name, salary
FROM employees
WHERE manager_id = 8
ORDER BY salary DESC;

-- ============================================================================
-- 2. Aggregate Functions, GROUP BY, and HAVING
-- ============================================================================

-- --- Question 8 ---
-- [Tables: employees] 
-- For each department_id in employees, return the number of active employees and their average salary 
-- (rounded to 2 decimal places), sorted by average salary descending.
  
SELECT 
    department_id,
    COUNT(*) AS active_employee_count,
    ROUND(AVG(salary),2) AS average_salary
FROM employees
WHERE status = 'ACTIVE'
GROUP BY department_id
ORDER BY average_salary DESC;

-- --- Question 9 ---
-- [Tables: employees] 
-- Find all departments (by department_id) that have more than 3 active employees. Return department_id and -- the count. 
 
SELECT department_id, COUNT(*) AS active_employee_count
FROM employees
WHERE status = 'ACTIVE'
GROUP BY department_id
HAVING COUNT(*) > 3;

-- --- Question 10 ---
-- [Tables: customers] 
-- For each customer_segment in customers, find the total number of customers and the earliest and latest 
-- signup_date. Only include segments with more than 3 customers.

SELECT 
    COUNT(*) AS total_customers,
    MAX(signup_date) AS earliest_signup_date,
    MIN(signup_date) AS latest_signup_date
FROM customers
GROUP BY customer_segment
HAVING COUNT(customer_segment) > 3;


-- --- Question 11 ---
-- [Tables: orders] 
-- For each ship_country in orders, calculate total revenue from COMPLETED orders only, and the count of such 
-- orders. Exclude countries where total revenue is less than 2000. Sort by total revenue descending.
    
SELECT
    ship_country,
    SUM(total_amount) AS total_revenue,
    COUNT(order_id) AS order_count
FROM orders
WHERE order_status = 'COMPLETED'
GROUP BY ship_country
HAVING SUM(total_amount) >= 2000
ORDER BY total_revenue DESC;


-- --- Question 12 ---
-- [Tables: employees] 
-- Using employees, find the difference between COUNT(*) and COUNT(manager_id) grouped by department_id. 
-- Explain in your own words (as a comment) what this difference represents in this dataset.
    
SELECT 
    COUNT(*) AS count1, 
    COUNT(manager_id) as count2
FROM employees
GROUP BY department_id;
-- this count(*) include null values whereas count(manager_id) include count of columns

-- --- Question 13 ---
-- [Tables: products] 
-- For each product category in products, return the count of products, the average list_price, and the average 
-- unit_cost, but only for categories where the average list_price exceeds 1000.
 
SELECT
  category,
  COUNT(*) AS product_count,
  AVG(list_price) AS avg_list_price,
  AVG(unit_cost) AS avg_unit_cost
FROM products
GROUP BY category
HAVING AVG(list_price) > 1000;

-- --- Question 14 ---
-- [Tables: payments] 
-- For each payment_method in payments, calculate the total amount_paid for SUCCESS payments only, and rank 
-- this in your output by sorting descending. Also include a count of distinct order_id values per method (some 
-- orders might have retried payments in real systems — use COUNT(DISTINCT ...) defensively even if you believe 
-- order_id is unique per payment here).
 
SELECT
    payment_method,
    SUM(amount_paid) AS total_amount_paid,
    COUNT(DISTINCT order_id) AS ditinct_order_id
FROM payments
WHERE payment_status = 'SUCCESS'
GROUP BY payment_method
ORDER BY total_amount_paid DESC;

-- ============================================================================
-- 3. CASE Expressions
-- ============================================================================

-- --- Question 15 ---
-- [Tables: employees] 
-- Write a query on employees that adds a column tenure_band classifying each active employee as 'New' (hired 
-- within last 2 years from 2024-06-15), 'Established' (2-5 years), or 'Veteran' (5+ years), based on hire_date. 
-- Return employee_id, full name, hire_date, tenure_band.
 
SELECT
    employee_id,
    concat(first_name,' ',last_name) AS full_name,
    hire_date, 
    CASE 
        WHEN hire_date >= '2022-06-15' THEN 'New'
        WHEN hire_date >= '2019-06-15' THEN 'Established'
        ELSE 'Veteran'
    END AS tenure_band
FROM employees
WHERE status = 'ACTIVE';

-- --- Question 16 ---
-- [Tables: orders] 
-- Using orders, add a column order_size that labels each order 'Small' (<1000), 'Medium' (1000-5000), or 'Large' 
-- (>5000) based on total_amount. Then count how many orders fall into each band, for COMPLETED orders only.

SELECT
    CASE 
        WHEN total_amount < 1000 THEN 'Small'
        WHEN total_amount <= 5000 THEN 'Medium'
        ELSE  'Large'
    END AS order_size,
    count(*) AS order_count
FROM orders
WHERE order_status = 'COMPLETED'
GROUP BY order_size;


-- --- Question 17 ---
-- [Tables: employees] 
-- For each department_id in employees, use conditional aggregation to return the count of employees earning 
-- above 150000 and the count earning 150000 or below, in a single row per department.

SELECT
    department_id,
    sum(case WHEN salary > 150000 THEN 1 else 0 END) as emp_150k,
    sum(case WHEN salary <= 150000 THEN 1 else 0 END) as emp_150k_or_below
FROM employees
GROUP BY department_id;


-- --- Question 18 ---
-- [Tables: customers] 
-- Using customers, create a column loyalty_flag that says 'Referred Customer' if referred_by is not null, otherwise 
-- 'Organic Signup'. Then count customers in each group per country.

SELECT
  country,
  CASE
    WHEN referred_by IS NOT NULL THEN 'Referred Customer'
    ELSE 'Organic Signup'
  END AS loyalty_flag,
  COUNT(*) AS customer_count
FROM customers
GROUP BY
  country,
  loyalty_flag;

-- --- Question 19 ---
-- [Tables: payments] 
-- Using payments, write a query with conditional aggregation that shows, for each payment_method, the total 
-- SUCCESS amount, total REFUNDED amount, and total FAILED amount as three separate columns (all in one row 
-- per method).

SELECT
    payment_method,
    sum(case when payment_status = 'SUCCESS' then amount_paid else 0 end) as total_success,
    sum(case when payment_status = 'REFUNDED' then amount_paid else 0 end) AS total_refunded,
    sum(case when payment_status = 'FAILED' then amount_paid else 0 end) as total_failed
FROM payments
GROUP BY payment_method;

-- ============================================================================
-- 4. String Functions
-- ============================================================================

-- --- Question 20 ---
-- [Tables: employees] 
-- From employees, create a formatted display name: 'LASTNAME, Firstname' (last name fully uppercase, comma, 
-- first name with only the first letter capitalized — you can assume first_name is already stored capitalized 
-- correctly). Return employee_id and this formatted name.

SELECT
  employee_id,
  CONCAT(UPPER(last_name), ', ', first_name) AS formatted_name
FROM employees;
 


-- --- Question 21 ---
-- [Tables: employees] 
-- From employees, extract the domain portion of each email address (everything after the @ symbol). Return 
-- employee_id, email, and domain.

SELECT
    employee_id,
    email,
    SUBSTRING(email FROM position('@' in email)+1) as doamin
from employees;

-- --- Question 22 ---
-- [Tables: customers] 
-- Find all customers whose customer_name has more than 2 words (i.e., contains at least one space beyond a 
-- normal 'First Last' — think of names like 'Fatima Al-Sayed' vs 'John Smith'; for this exercise, count words as 
-- space-separated tokens and return those with 3 or more tokens).

SELECT *
FROM customers
WHERE LENGTH(customer_name) - LENGTH(REPLACE(customer_name, ' ', '')) >= 2;

-- --- Question 23 ---
-- [Tables: products] 
-- From products, generate a product_code by combining the first 3 letters of category (uppercase) with the 
-- product_id, separated by a dash (e.g., 'ELE-201'). Return product_id, product_name, category, product_code.
 
SELECT 
    product_id, product_name, category,
    concat(upper(substring(category,1,3)),'-',product_id) as product_code
from products;

-- --- Question 24 ---
-- [Tables: customers] 
-- Clean up a hypothetical messy version of customer_name: write a query using TRIM and REPLACE that would 
-- remove any double spaces and leading/trailing spaces from customer_name (write it generically — it should 
-- work whether or not the current sample data actually has messy spacing).

SELECT
    REPLACE(trim(customer_name),'  ',' ') as customer_nname
FROM customers;

-- ============================================================================
-- 5. Date Functions
-- ============================================================================

-- --- Question 25 ---
-- [Tables: employees] 
-- From employees, calculate each active employee's tenure in years (as of 2024-06-15), rounded to 1 decimal 
-- place. Return employee_id, full name, hire_date, tenure_years, sorted by tenure_years descending.

SELECT
    employee_id,
    concat(first_name,' ',last_name) as full_name,
    hire_date,
    ROUND((DATE '2024-06-15' - hire_date) /(365.25), 1) AS tenure_years
FROM employees
WHERE status = 'ACTIVE'
ORDER BY tenure_years DESC;

-- --- Question 26 ---
-- [Tables: orders] 
-- From orders, extract the year and month of each order_date as separate columns, then count the number of 
-- COMPLETED orders per year-month combination. Sort chronologically.

SELECT  
    extract(year from order_date) as order_year,
    extract(month from order_date) as order_month,
    count(*) as order_count
FROM orders
WHERE order_status = 'COMPLETED'
GROUP BY order_year,order_month
ORDER BY order_year ASC ,order_month ASC;
    

-- --- Question 27 ---
-- [Tables: orders] 
-- Find all orders placed on a weekend (Saturday or Sunday). Return order_id, order_date, and the day name. 
-- (Note the exact function name will depend on which engine you assume — state your assumption.)

SELECT
    order_id, order_date,
    to_char(order_date,'day') as order_day
FROM orders
WHERE extract(ISODOW from order_date) in (6,7);

-- --- Question 28 ---
-- [Tables: customers] 
-- From customers, find all customers who signed up in the last 18 months relative to 2024-06-15. Return 
-- customer_id, customer_name, signup_date, and months_since_signup (rounded to nearest whole number).

SELECT
    customer_id, customer_name, signup_date,
    round(('2024-06-15' - signup_date)/30) as signup_months
from customers  
WHERE signup_date >= '2022-12-15'

-- --- Question 29 ---
-- [Tables: orders, payments] 
-- For each order, calculate the number of days between order_date and the corresponding payment_date in 
-- payments (where a payment exists). Return order_id, order_date, payment_date, days_to_pay. Handle orders 
-- that have no matching payment gracefully (they should still appear, with NULL for payment fields).
 
SELECT
  o.order_id,
  o.order_date,
  p.payment_date,
  (p.payment_date - o.order_date) AS days_to_pay
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id;

-- ============================================================================
-- 6. Numeric Functions and NULL Handling
-- ============================================================================

-- --- Question 30 ---
-- [Tables: order_items] 
-- From order_items, calculate the effective line-item revenue for every row as quantity * unit_price * (1 - 
-- discount_pct), rounded to 2 decimal places. Return order_item_id, order_id, product_id, and this calculated 
-- revenue, aliased line_revenue.
 
SELECT
  order_item_id,
  order_id,
  product_id,
  ROUND(CAST(quantity * unit_price * (1 - discount_pct) AS NUMERIC), 2) AS line_revenue
FROM order_items;

-- --- Question 31 ---
-- [Tables: employees] 
-- From employees, calculate what each employee's salary would be after a hypothetical 8% raise, rounded to the 
-- nearest whole number (no decimals). Return employee_id, full name, salary, new_salary.

SELECT
  employee_id,
  CONCAT(first_name, ' ', last_name) AS full_name,
  salary,
  ROUND(salary * 1.08, 0) AS new_salary
FROM employees;

-- --- Question 32 ---
-- [Tables: employees] 
-- From employees, safely calculate each employee's salary as a percentage of their department's total active
-- employee salary (i.e., salary / SUM(salary) per department), guarding against any department where the sum 
-- could theoretically be zero (use NULLIF defensively even though it won't trigger here) and expressing the result 
-- as a percentage rounded to 1 decimal place.

SELECT
    employee_id,
    salary,
    department_id,
    ROUND(
        salary * 100.0 / SUM(salary) OVER (PARTITION BY department_id),
        1
    ) AS pct_of_dept
FROM employees
WHERE status = 'ACTIVE';

-- --- Question 33 ---
-- [Tables: products] 
-- From products, compute the gross margin percentage for each product as (list_price - unit_cost) / list_price * 
-- 100, rounded to 1 decimal place, and sort by margin percentage descending. Handle any product where 
-- list_price might be 0 or NULL gracefully so the query never errors.

SELECT
  product_id,
  list_price,
  unit_cost,
  ROUND(((list_price - unit_cost) / NULLIF(list_price, 0)) * 100, 1) AS margin_pct
FROM products
ORDER BY margin_pct DESC;

-- --- Question 34 ---
-- [Tables: employees] 
-- From employees, use COALESCE to produce a manager_display column that shows the manager's employee_id if 
-- one exists, otherwise the text 'No Manager (Top Level)'. Note this requires you to combine a numeric column 
-- and a text fallback — think about how you'd need to CAST the numeric value to text first (write the query 
-- assuming your engine requires explicit casting for this).

SELECT
  employee_id,
  COALESCE(manager_id::VARCHAR , 'No Manager (Top Level)') AS manager_display
FROM employees;

