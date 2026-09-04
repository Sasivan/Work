-- ============================================================================
-- LEVEL 4 — EXPERT: SQL Mastery Assignment
-- ============================================================================

-- ============================================================================
-- 15. Gaps and Islands, Streaks, and Consecutive-Day Problems
-- ============================================================================

-- --- Question 84 ---
-- [Tables: attendance] 
-- Using the attendance table, find the longest CONSECUTIVE streak of PRESENT days for employee_id 4 (Sneha 
-- Iyer). Return the streak's start date, end date, and length in days.
 
WITH days as (
    SELECT 
        employee_id,
        attendance_date::date as attendance_date
    FROM attendance
    WHERE employee_id = 4
        AND status = 'PRESENT'
),
with_previous as (
    SELECT
        employee_id,
        attendance_date,
        lag(attendance_date) OVER 
        (PARTITION BY employee_id ORDER BY attendance_date) as previous_date
    FROM days
),
marked as (
    SELECT
        employee_id,
        attendance_date,
        previous_date,
        CASE 
            WHEN previous_date is null or attendance_date - previous_date > 1 THEN 1 
            ELSE 0
        END as new_island
    FROM with_previous
),
islands as (
    SELECT
        employee_id,
        attendance_date,
        previous_date,
        sum(new_island) over 
        (PARTITION BY employee_id ORDER BY attendance_date) as island_id
    FROM marked
),
streaks AS (
    SELECT
        employee_id,
        MIN(attendance_date) AS start_date,
        MAX(attendance_date) AS end_date,
        COUNT(*) AS streak_length
    FROM islands
    GROUP BY employee_id, island_id
)
SELECT
    start_date,
    end_date,
    streak_length
FROM streaks
ORDER BY streak_length DESC
LIMIT 1;

-- --- Question 85 ---
-- [Tables: attendance] 
-- Using the attendance table, find every consecutive streak (of any status, not just PRESENT) of 2 or more days for 
-- ALL employees, returning employee_id, status, streak_start, streak_end, streak_length. This generalizes 
-- Question 84 — think about what needs to change in your PARTITION BY to also separate by status, not just 
-- employee.
 
WITH numbered as (
    SELECT
        employee_id,
        attendance_date,
        status,
        ROW_NUMBER() over 
        (PARTITION BY employee_id,status ORDER BY attendance_date) as rn 
    FROM attendance
),
islands as (
    SELECT
        employee_id,
        attendance_date,
        status,
        (attendance_date - (rn * INTERVAL '1 day')) as island_grp
    FROM numbered
)
SELECT
    employee_id,
    status,
    min(attendance_date) as streak_start,
    max(attendance_date) as streak_end,
    count(attendance_date) as streak_length
FROM islands
GROUP BY employee_id,status,island_grp
HAVING count(*) >= 2

-- --- Question 86 ---
-- [Tables: orders] 
-- Using orders, find each customer's longest streak of CONSECUTIVE MONTHS (not necessarily consecutive 
-- calendar days — think in terms of year-month buckets) in which they placed at least one COMPLETED order. 
-- Return customer_id, streak_start_month, streak_end_month, streak_length_months.
 
WITH distinct_months AS (
  SELECT DISTINCT customer_id, DATE_TRUNC('month', order_date) AS order_month
  FROM orders WHERE order_status = 'COMPLETED'
), numbered AS (
  SELECT customer_id, order_month,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_month ASC) AS rn
  FROM distinct_months
), islands AS (
  SELECT customer_id, order_month,
         (order_month - (rn * INTERVAL '1 month')) AS island_group
  FROM numbered
)
SELECT customer_id, MIN(order_month) AS streak_start_month, MAX(order_month) AS streak_end_month, COUNT(*) AS streak_length_months
FROM islands
GROUP BY customer_id, island_group
ORDER BY streak_length_months DESC;


-- --- Question 87 ---
-- [Tables: orders] 
-- Using orders, identify GAPS of more than 60 days between a customer's consecutive COMPLETED orders (a 
-- simpler LAG-based flag, not a full island summary). Return customer_id, order_date, previous_order_date, 
-- days_since_previous, flagged as 'LONG GAP' where the gap exceeds 60 days.
 
WITH numbered as (
    SELECT
        customer_id,
        order_date,
        lag(order_date) OVER
        (PARTITION BY customer_id ORDER BY order_date) as previous_date 
    FROM orders
    WHERE order_status = 'COMPLETED'
),
gap as (
    SELECT 
        customer_id,
        order_date,
        CASE 
            WHEN (order_date - previous_date) > 60 THEN 'LONG GAP'  
            ELSE 'NO GAP'
        END as flag,
        COALESCE((order_date - previous_date),0) as days_since_previous
    FROM numbered
)
SELECT * FROM gap

-- ============================================================================
-- 16. Top-N-Per-Group and Latest-Record Problems
-- ============================================================================

-- --- Question 88 ---
-- [Tables: employees] 
-- For each department, find the top 2 highest-paid ACTIVE employees. Handle ties deliberately: decide whether 
-- you want EXACTLY 2 rows per department or ALL employees tied for the 2nd spot, implement one approach, 
-- and explain your choice in a comment.
 
WITH numbered as (
    SELECT 
        employee_id,
        concat(first_name,' ',last_name) as full_name,
        department_id,
        salary,
        rank() OVER 
        (PARTITION BY department_id ORDER BY salary DESC) as rn
    FROM employees
    WHERE status = 'ACTIVE'
)
SELECT *
FROM numbered
WHERE rn <= 2
-- COMMENT: I chose RANK() because if two employees are tied for the 2nd highest salary, it's usually fairer to show both in a compensation report rather than arbitrarily cutting one off with ROW_NUMBER().



-- --- Question 89 ---
-- [Tables: customers, orders] 
-- For each customer, find their single MOST RECENT order (regardless of status). Return customer_id, 
-- customer_name, order_id, order_date, order_status, total_amount.
 
with recent_order as (
    SELECT 
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.order_status,
    ROW_NUMBER() over 
    (PARTITION BY c.customer_id ORDER BY o.order_date desc) as rn
FROM customers c
INNER JOIN orders o on c.customer_id = o.customer_id 
)
SELECT * FROM recent_order
WHERE rn = 1
 
-- --- Question 90 ---
-- [Tables: products, order_items] 
-- For each product category, find the single best-selling product by total quantity sold (across order_items, 
-- regardless of order status). Return category, product_id, product_name, total_quantity_sold.

WITH product_sales AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(o.quantity) AS total_quantity_sold
    FROM products p
    JOIN order_items o
        USING (product_id)
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_name,
        total_quantity_sold,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY total_quantity_sold DESC
        ) AS rn
    FROM product_sales
)
SELECT
    category,
    product_id,
    product_name,
    total_quantity_sold
FROM ranked_products
WHERE rn = 1
ORDER BY category;

-- --- Question 91 ---
-- [Tables: product_prices_history] 
-- Using product_prices_history, find the CURRENT price (i.e., the applicable price as of today) for every product, 
-- using a general 'latest row per group' technique rather than relying solely on effective_to IS NULL (write it so it 
-- would still work correctly even if effective_to were poorly maintained).
 
WITH ranked_prices AS (
  SELECT product_id, price, effective_from, effective_to,
         ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY effective_from DESC) AS rn
  FROM product_prices_history
)
SELECT product_id, price AS current_price FROM ranked_prices WHERE rn = 1;


-- --- Question 92 ---
-- [Tables: orders] 
-- For each ship_country, find the top 3 orders by total_amount (COMPLETED only). If there's a tie for 3rd place, 
-- decide and justify (in a comment) whether your query returns exactly 3 rows per country or all ties — implement 
-- your chosen approach.
 
WITH ranked_orders AS (
  SELECT order_id, ship_country, total_amount,
         DENSE_RANK() OVER (PARTITION BY ship_country ORDER BY total_amount DESC) AS rnk
  FROM orders WHERE order_status = 'COMPLETED'
)
SELECT order_id, ship_country, total_amount FROM ranked_orders WHERE rnk <= 3;
-- COMMENT: DENSE_RANK() ensures that if there's a tie for 1st or 2nd, the next value isn't skipped, meaning we get exactly 3 distinct monetary levels per country, which might include more than 3 rows if ties exist.

-- ============================================================================
-- 17. Multi-CTE Analytical Problems and Real Business Scenarios
-- ============================================================================

-- --- Question 93 ---
-- [Tables: customers, orders] 
-- Business question: 'Which customers are at risk of churn?' Define an at-risk customer as: someone whose most 
-- recent COMPLETED order was more than 120 days before their OWN most recent order date in the dataset (i.e., 
-- relative to their personal last-order date, not today's date) OR someone who has had at least one CANCELLED or 
-- RETURNED order with no COMPLETED order afterward. Build this using CTEs. Return customer_id, 
-- customer_name, last_order_date, risk_reason.
 
WITH customer_orders AS (
  SELECT customer_id,
         MAX(CASE WHEN order_status = 'COMPLETED' THEN order_date END) AS last_completed_date,
         MAX(order_date) AS last_overall_date
  FROM orders GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name, co.last_completed_date AS last_order_date,
       CASE
         WHEN (co.last_overall_date - co.last_completed_date) > 120 THEN 'No completed orders in >120 days from last activity'
         WHEN co.last_completed_date IS NULL THEN 'Only Cancelled/Returned orders exist'
       END AS risk_reason
FROM customers c JOIN customer_orders co ON c.customer_id = co.customer_id
WHERE (co.last_overall_date - co.last_completed_date) > 120 OR co.last_completed_date IS NULL;

-- --- Question 94 ---
-- [Tables: customers, orders] 
-- Business question: 'Build a customer lifetime value (LTV) leaderboard with segment context.' For each customer, 
-- calculate: total COMPLETED order value, total number of COMPLETED orders, average order value, and their 
-- revenue_quartile (via NTILE(4)) — then flag Enterprise-segment customers who are NOT in the top quartile as 
-- 'Enterprise Underperformer, Review' for account management follow-up.
 
with customer_summary as (
    SELECT  DISTINCT
        c.customer_id,
        c.customer_name,
        customer_segment,
        count(*) OVER (PARTITION BY c.customer_id) as total_completed_orders,
        sum(o.total_amount) over (PARTITION BY c.customer_id) as customer_total_order_value,
        round(avg(o.total_amount) over (PARTITION BY c.customer_id),2) as customer_avg_order_value
    FROM customers c 
    JOIN orders o USING (customer_id)
    WHERE o.order_status = 'COMPLETED'
),
customer_quartile AS (
    SELECT *,
        NTILE(4) OVER (
            ORDER BY customer_total_order_value DESC
        ) AS revenue_quartile
    FROM customer_summary
)
SELECT *,
    CASE WHEN customer_segment = 'Enterprise' AND revenue_quartile > 1 THEN 'Enterprise Underperformer, Review' END AS flag
FROM customer_quartile

-- --- Question 95 ---
-- [Tables: employees] 
-- Business question: 'Show department-level headcount and cost trends over time.' For each department and 
-- each hire_date year, show the number of employees hired that year, the running cumulative headcount through 
-- that year, and the running cumulative salary cost through that year (active employees only). This requires 
-- combining a yearly GROUP BY aggregation with a running-total window function on top of it — plan your CTE 
-- structure before writing the query.
 
with eyear as (
    SELECT 
        department_id,
        salary,
        extract(YEAR FROM hire_date) as emp_year
    FROM employees
    WHERE status = 'ACTIVE'
),
head_salary_count as (
    SELECT  
        department_id,
        emp_year,
        count(*) over (PARTITION BY department_id,emp_year) as emp_count,
        sum(salary) OVER (PARTITION BY department_id,emp_year) as emp_salary
    FROM eyear
    
),
cummulative as (
    SELECT department_id,
        emp_year,
        sum(emp_count) OVER (PARTITION BY department_id ORDER BY emp_year) as emp_count,
        sum(emp_salary) OVER (PARTITION BY department_id ORDER BY emp_year) as emp_salary
    FROM head_salary_count
)
SELECT * FROM cummulative

-- --- Question 96 ---
-- [Tables: products, order_items] 
-- Business question: 'Which products are underperforming relative to their category?' For each product, compare 
-- its total revenue (via order_items, all order statuses) to the AVERAGE total revenue of products in the same 
-- category. Flag any product below 50% of its category average as 'Underperforming'. Handle products that have 
-- NEVER been ordered (they should count as 0 revenue, not be excluded from the analysis, and should very likely 
-- be flagged as underperforming).
 
WITH prod_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        COALESCE(
            SUM(
                o.unit_price * o.quantity * (1 - o.discount_pct)
            ),
            0
        ) AS product_revenue

    FROM products p
    LEFT JOIN order_items o USING (product_id)

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

category_avg AS (
    SELECT
        *,
        ROUND(
            AVG(product_revenue) OVER (
                PARTITION BY category
            ),
            2
        ) AS avg_prod_revenue
    FROM prod_revenue
)

SELECT
    product_id,
    product_name,
    category,
    product_revenue,
    avg_prod_revenue,

    CASE
        WHEN product_revenue < 0.5 * avg_prod_revenue
             OR avg_prod_revenue = 0
        THEN 'Underperforming'
        ELSE 'better'
    END AS performance

FROM category_avg;

WITH prod_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        COALESCE(
            SUM(
                o.unit_price * o.quantity * (1 - o.discount_pct)
            ),
            0
        ) AS product_revenue

    FROM products p
    LEFT JOIN order_items o USING (product_id)

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

category_avg AS (
    SELECT
        *,
        ROUND(
            AVG(product_revenue) OVER (
                PARTITION BY category
            ),
            2
        ) AS avg_prod_revenue
    FROM prod_revenue
)

SELECT
    product_id,
    product_name,
    category,
    product_revenue,
    avg_prod_revenue,

    CASE
        WHEN product_revenue < 0.5 * avg_prod_revenue
             OR avg_prod_revenue = 0
        THEN 'Underperforming'
        ELSE 'better'
    END AS performance

FROM category_avg;

-- --- Question 97 ---
-- [Tables: customers, orders] 
-- Business question: 'Build a cohort retention view.' Group customers into signup cohorts by the YEAR-MONTH of 
-- their signup_date. For each cohort, calculate: cohort size (number of customers), and how many of those 
-- customers placed at least one COMPLETED order in each of the 3 months following their signup month. This is a 
-- simplified monthly cohort retention analysis — think carefully about how you define 'month 1 / month 2 / 
-- month 3 after signup' for customers with different signup dates.
 
WITH cohorts AS (
  SELECT customer_id, DATE_TRUNC('month', signup_date) AS cohort_month FROM customers
), active_months AS (
  SELECT DISTINCT customer_id, DATE_TRUNC('month', order_date) AS active_month FROM orders WHERE order_status = 'COMPLETED'
)
SELECT c.cohort_month::date, COUNT(DISTINCT c.customer_id) AS cohort_size,
       COUNT(DISTINCT CASE WHEN a.active_month = c.cohort_month + INTERVAL '1 month' THEN c.customer_id END) AS month_1_active,
       COUNT(DISTINCT CASE WHEN a.active_month = c.cohort_month + INTERVAL '2 month' THEN c.customer_id END) AS month_2_active,
       COUNT(DISTINCT CASE WHEN a.active_month = c.cohort_month + INTERVAL '3 month' THEN c.customer_id END) AS month_3_active
FROM cohorts c LEFT JOIN active_months a ON c.customer_id = a.customer_id
GROUP BY c.cohort_month ORDER BY c.cohort_month;

-- --- Question 98 ---
-- [Tables: orders, payments] 
-- Business question: 'Reconcile orders against payments for the finance team, the way you already do for VIVE AP 
-- statements.' Build a single query that classifies every order into exactly one of: 'FULLY PAID' (SUCCESS payment 
-- amount equals total_amount), 'PARTIALLY PAID' (SUCCESS payment amount less than total_amount), 
-- 'OVERPAID' (SUCCESS payment amount exceeds total_amount — a data quality flag), 'UNPAID / NO PAYMENT 
-- FOUND', or 'PAYMENT FAILED ONLY' (a payment exists but all attempts failed). Return order_id, customer_id, 
-- total_amount, total_success_paid, reconciliation_status.
 
WITH amount AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.total_amount,
        COUNT(p.payment_id) AS attempts,
        COALESCE(SUM(p.amount_paid), 0) AS total_paid,
        COALESCE(SUM(CASE WHEN p.payment_status = 'SUCCESS' THEN p.amount_paid ELSE 0 END), 0) AS total_success_paid
    FROM orders o
    LEFT JOIN payments p USING (order_id)
    GROUP BY o.order_id, o.customer_id, o.total_amount
)
SELECT
    order_id,
    customer_id,
    total_amount,
    total_paid,
    total_success_paid,
    CASE 
        WHEN total_success_paid = 0 AND attempts > 0 THEN 'PAYMENT FAILED ONLY'
        WHEN total_success_paid = 0 THEN 'UNPAID / NO PAYMENT FOUND'
        WHEN total_success_paid = total_amount THEN 'FULLY PAID'
        WHEN total_success_paid < total_amount THEN 'PARTIALLY PAID'
        WHEN total_success_paid > total_amount THEN 'OVERPAID'
    END AS reconciliation_status
FROM amount;

-- --- Question 99 ---
-- [Tables: projects, departments, employee_projects, employees] 
-- Business question: 'Give engineering leadership a project staffing and utilization report.' For each ACTIVE 
-- project, show: project_name, department_name, number of distinct employees staffed, total hours_logged 
-- across all staffed employees, and the name + hours of whoever is logging the MOST hours on that project (the 
-- de facto lead by effort, which may or may not match their assigned role of 'Lead'). Flag any case where the top
-- hours person's role is NOT 'Lead' as 'ROLE MISMATCH — REVIEW'.

WITH project_summary AS (
    SELECT
        p.project_id,
        p.project_name,
        d.department_name,
        COUNT(DISTINCT ep.employee_id) AS employee_count,
        SUM(ep.hours_logged) AS total_hours_logged
    FROM projects p
    JOIN departments d USING (department_id)
    JOIN employee_projects ep USING (project_id)
    WHERE p.status = 'ACTIVE'
    GROUP BY p.project_id, p.project_name, d.department_name
),
top_employee AS (
    SELECT
        ep.project_id,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        ep.hours_logged,
        ep.role,
        ROW_NUMBER() OVER (
            PARTITION BY ep.project_id
            ORDER BY ep.hours_logged DESC
        ) AS rn
    FROM employee_projects ep
    JOIN employees e USING (employee_id)
)
SELECT
    ps.project_name,
    ps.department_name,
    ps.employee_count,
    ps.total_hours_logged,
    te.employee_name AS top_hours_person,
    te.hours_logged AS top_hours,
    CASE
        WHEN te.role <> 'Lead'
        THEN 'ROLE MISMATCH — REVIEW'
        ELSE NULL
    END AS flag
FROM project_summary ps
JOIN top_employee te
    ON ps.project_id = te.project_id
WHERE te.rn = 1;

-- --- Question 100 ---
-- [Tables: orders] 
-- Business question: 'Build a full revenue waterfall by month, with month-over-month growth, a 3-month moving 
-- average, and a flag for any month that declined more than 15% from the prior month.' This should combine: a 
-- monthly aggregation CTE, a LAG-based month-over-month comparison, a moving-average window function, and 
-- a CASE-based flag — all in one coherent multi-CTE query. Return order_month, monthly_revenue, 
-- mom_growth_pct, moving_avg_3mo, decline_flag.

WITH monthly_rev AS (
  SELECT DATE_TRUNC('month', order_date) AS order_month, SUM(total_amount) AS monthly_revenue
  FROM orders WHERE order_status = 'COMPLETED' GROUP BY order_month
)
SELECT order_month, monthly_revenue,
       (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month)) / LAG(monthly_revenue) OVER (ORDER BY order_month) AS mom_growth_pct,
       AVG(monthly_revenue) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3mo,
       CASE WHEN (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month)) / LAG(monthly_revenue) OVER (ORDER BY order_month) < -0.15 THEN 'DECLINE FLAG' END AS decline_flag
FROM monthly_rev;

-- --- Question 101 ---
-- [Tables: customers] 
-- Business question: 'Identify potential duplicate customer records for data cleanup' — a real, messy problem. 
-- Using customers, find any pairs of customers that share the same email domain AND signed up within 7 days of 
-- each other AND are in the same country, as CANDIDATE duplicates for a human to review (this is intentionally a 
-- heuristic, not a guarantee of an actual duplicate — real fuzzy-matching problems like this always need human 
-- review, which is worth stating explicitly in your answer). Return both customer_ids, both names, and the specific 
-- matching criteria that triggered the flag.

SELECT c1.customer_id AS id_1,
       c1.customer_name AS name_1,
       c2.customer_id AS id_2,
       c2.customer_name AS name_2,
       'Same Country, Same Email Domain, Signup within 7 days' AS reason
FROM customers c1
JOIN customers c2
  ON c1.country = c2.country
  AND SUBSTRING(c1.email FROM POSITION('@' IN c1.email))
      = SUBSTRING(c2.email FROM POSITION('@' IN c2.email))
  AND c1.customer_id < c2.customer_id
WHERE ABS(c1.signup_date - c2.signup_date) <= 7;

-- --- Question 102 ---
-- [Tables: employees, projects, departments] 
-- Business question: 'Executive summary: one row per department with a full scorecard.' For each department, in 
-- a single row, return: current active headcount, average tenure in years, average salary, total salary cost, number 
-- of active projects, total project budget, and a computed 'cost per active project dollar' ratio (department total 
-- salary cost / total active project budget, handled safely if a department has zero active project budget). This 
-- requires joining and aggregating from THREE different tables at three different grains (employees, projects, 
-- departments) without incorrectly inflating any of the sums — think carefully about join order and where you 
-- need to pre-aggregate BEFORE joining, to avoid fan-out/duplication errors.

WITH dept_emps AS (
  SELECT department_id, COUNT(*) AS active_headcount, AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))) AS avg_tenure, AVG(salary) AS avg_salary, SUM(salary) AS total_salary
  FROM employees WHERE status = 'ACTIVE' GROUP BY department_id
), dept_projs AS (
  SELECT department_id, COUNT(*) AS active_projects, SUM(budget) AS total_proj_budget
  FROM projects WHERE status = 'ACTIVE' GROUP BY department_id
)
SELECT d.department_name, e.active_headcount, e.avg_tenure, e.avg_salary, e.total_salary, p.active_projects, p.total_proj_budget,
       e.total_salary / NULLIF(p.total_proj_budget, 0) AS cost_per_active_project_dollar
FROM departments d
LEFT JOIN dept_emps e ON d.department_id = e.department_id
LEFT JOIN dept_projs p ON d.department_id = p.department_id;

-- ============================================================================
-- 18. Query Optimization and Indexing Basics
-- ============================================================================



-- --- Question 103 ---
-- [Tables: orders] 
-- Given a hypothetical orders table with 50 million rows, propose which column(s) you would index to speed up a 
-- dashboard query that filters WHERE customer_id = ? AND order_status = 'COMPLETED' ORDER BY order_date 
-- DESC. Explain your reasoning, including whether a single composite index or multiple single-column indexes 
-- would be more appropriate, and why column ORDER within a composite index matters.

-- For `WHERE customer_id = ? AND order_status = 'COMPLETED' ORDER BY order_date DESC`:
-- I would use a composite index on `(customer_id, order_status, order_date)`.
-- Order matters: equality filters (`customer_id`, `order_status`) must come first so the index can efficiently jump to the exact subset of records. `order_date` comes last because it handles the sorting. If `order_date` came first, the engine couldnt use the index to filter on `customer_id` efficiently.



-- --- Question 104 ---
-- [Tables: orders] 
-- Rewrite this poorly-performing hypothetical query to be index-friendly, and explain what specifically was 
-- preventing efficient index use: SELECT * FROM orders WHERE YEAR(order_date) = 2024 AND 
-- MONTH(order_date) = 6;

SELECT * FROM orders
WHERE order_date >= '2024-06-01' AND order_date < '2024-07-01';
-- EXPLANATION: Wrapping the column in functions like `YEAR()` or `MONTH()` prevents the query optimizer from using an index on `order_date` (a concept known as breaking sargability). By using a bounding date range, the B-tree index can be efficiently traversed.


-- --- Question 105 ---
-- [Tables: orders, order_items] 
-- You inherit a query that joins orders to order_items and then does SUM(orders.total_amount) grouped by 
-- customer_id, and the numbers come out far too high compared to what finance expects. Diagnose (in writing) 
-- what's most likely wrong, and propose the corrected query structure.

-- DIAGNOSIS: If you JOIN `orders` to `order_items` before taking `SUM(orders.total_amount)`, the join creates a Cartesian explosion for the order. An order with 5 items will repeat the `total_amount` 5 times in the intermediate result set, inflating the sum 5x.
-- CORRECTED STRUCTURE: Aggregate `order_items` in a CTE first before joining to `orders`, OR don't join `order_items` at all if you only need order-level totals.

-- ============================================================================
-- 19. Transactions and Data Integrity Basics
-- ============================================================================



-- --- Question 106 ---
-- [Tables: departments] 
-- Write a transaction (BEGIN/COMMIT/ROLLBACK syntax) that would safely move 5000 in budget from the 
-- Marketing department to the Engineering department in the departments table, ensuring both the deduction 
-- and the addition either both succeed or neither does. Include a comment explaining what you'd check before 
-- committing versus rolling back.

BEGIN TRANSACTION;
  UPDATE departments SET budget = budget - 5000 WHERE department_name = 'Marketing';
  UPDATE departments SET budget = budget + 5000 WHERE department_name = 'Engineering';
-- COMMENT: Before committing, I would check if Marketing's budget dropped below 0 (if negative balances aren't allowed) or check `@@ERROR` / row counts to ensure both queries affected exactly 1 row. If an error occurred, I would ROLLBACK.
COMMIT;

-- --- Question 107 ---
-- [Tables: departments] 
-- Explain, in writing (no query needed): why running two separate, un-transacted UPDATE statements to 
-- accomplish Question 106 (one at a time, each auto-committed) would be unsafe, and describe a realistic failure 
-- scenario where this causes a real data integrity problem.

-- If you execute two separate UPDATEs (auto-committed), and the system crashes or loses network connection immediately after the first query (deducting $5000 from Marketing), the second query never runs. You have now destroyed $5000 of budget. It vanished from Marketing but was never credited to Engineering, violating the Consistency and Atomicity of your data.


-- --- Question 108 ---
-- Explain, in writing: what a deadlock is, why it can happen even when every individual transaction is logically 
-- correct, and one concrete practice you could adopt in application/ETL code to reduce the chance of deadlocks 
-- occurring.

-- A deadlock is when Transaction A holds a lock on Row 1 and waits for Row 2, while Transaction B holds a lock on Row 2 and waits for Row 1. Neither can proceed. This happens even if both queries are logically perfectly sound.
-- -- MITIGATION: The most standard practice is to always access/update tables and rows in the EXACT SAME consistent order across all application code (e.g., always update Marketing before Engineering, or always lock alphabetical by table name). Keeping transactions as short as possible also limits the window for deadlocks.