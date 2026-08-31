-- --- Question 62 ---
-- [Tables: employees] 
-- Using a CTE, calculate the average salary per department (active employees only), then return only employees 
-- who earn MORE than their department's average. Return employee_id, full name, department_id, salary, 
-- dept_avg_salary.

WITH avg_salary_per_dep as (
    SELECT 
        department_id,
        round(avg(salary),1) as avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT 
    e.employee_id,
    concat(e.first_name,' ',e.last_name) as full_name,
    e.department_id,
    e.salary,
    d.avg_salary
FROM employees e
INNER JOIN avg_salary_per_dep d 
on e.department_id = d.department_id 
AND e.status = 'ACTIVE'
AND e.salary > d.avg_salary

-- --- Question 63 ---
-- [Tables: orders, customers] 
-- Using two chained CTEs, first calculate each customer's total COMPLETED order value (lifetime_value), then rank 
-- customers by lifetime_value and return only the top 10.

WITH order_totals as (
    SELECT
        customer_id,
        sum(total_amount) as lifetime_value
    FROM orders
    WHERE order_status = 'COMPLETED'
    GROUP BY customer_id
), ranked_customers as (
    SELECT 
        customer_id,lifetime_value,
        rank() over (order by lifetime_value desc) as value_rank
    FROM order_totals
)
SELECT * FROM ranked_customers 
WHERE value_rank <= 10

-- --- Question 64 ---
-- [Tables: orders] 
-- Using a CTE, build a monthly revenue summary (COMPLETED orders only) with year, month, total_revenue, and 
-- order_count, sorted chronologically. Then, in a second query building on the first CTE's logic, identify which 
-- month had the highest total_revenue.

WITH monthly_summary as (
    SELECT
        extract(year from order_date) as order_year,
        to_char(order_date,'Mon') as order_month,
        sum(total_amount) as total_value,
        count(*) as order_count
    FROM orders
    WHERE order_status = 'COMPLETED'
    GROUP BY order_year,order_month
)
SELECT * from monthly_summary
ORDER BY total_value DESC
limit 1

-- --- Question 65 ---
-- [Tables: employee_org_chart] 
-- Write a RECURSIVE CTE over employee_org_chart that returns the full management chain for Vikram Joshi 
-- (emp_id 9) — i.e., Vikram, then his manager, then that manager's manager, all the way up to the CEO. Return 
-- emp_id, emp_name, and a level number where Vikram is level 1.

WITH RECURSIVE manager_chain as (
    SELECT 
        emp_id,
        emp_name,
        manager_id,
        1 as level_depth
    FROM employee_org_chart
    WHERE emp_id = 9

    UNION ALL

    SELECT 
        m.emp_id,m.emp_name,m.manager_id,mc.level_depth + 1
    FROM employee_org_chart m 
    INNER JOIN manager_chain mc 
    on m.emp_id = mc.manager_id

)

SELECT emp_id, emp_name, level_depth
FROM manager_chain
ORDER BY level_depth;

-- --- Question 66 ---
-- [Tables: employee_org_chart] 
-- Write a RECURSIVE CTE over employee_org_chart that, for a given manager (e.g., emp_id 8, Anita Desai), returns 
-- EVERY person in her reporting chain at any depth (direct and indirect reports). Return emp_id, emp_name, and 
-- depth relative to Anita (her direct reports = depth 1, their reports = depth 2, etc.).

WITH RECURSIVE reporting_chain as (
    SELECT 
        emp_id,emp_name,manager_id,1 as level_depth
    FROM employee_org_chart
    WHERE manager_id = 8

    UNION ALL

    SELECT 
        m.emp_id,m.emp_name,m.manager_id,mc.level_depth + 1
    FROM employee_org_chart m 
    INNER JOIN reporting_chain mc 
    on m.manager_id = mc.emp_id
)
SELECT emp_id, emp_name, level_depth
FROM reporting_chain
ORDER BY level_depth;

-- --- Question 67 ---
-- [Tables: projects, departments] 
-- Using a CTE, calculate for each department the total budget from projects (grouped by department_id) 
-- alongside the department's own budget from the departments table (joined in), and flag any department where 
-- project spending exceeds the department's stated budget.

WITH project_spending AS (
    SELECT
        department_id,
        sum(budget) as project_value
    FROM projects
    GROUP BY department_id
)
SELECT
    d.department_id,
    d.department_name,
    d.budget as department_value,
    coalesce(p.project_value,0),
    CASE 
        WHEN d.budget < coalesce(p.project_value,0) THEN 'OVER BUDGET' 
        ELSE 'OK'
    END as budget_status
FROM departments d 
left JOIN project_spending p 
on d.department_id = p.department_id

-- ============================================================================
-- 13. Window Functions — The Complete Guide
-- ============================================================================

-- --- Question 68 ---
-- [Tables: employees] 
-- Using ROW_NUMBER(), assign a rank to each employee's salary WITHIN their own department (highest salary = 
-- 1), for active employees only. Return employee_id, full name, department_id, salary, salary_rank_in_dept.

SELECT
    concat(first_name,' ',last_name) as full_name,
    salary,
    ROW_NUMBER() over (PARTITION BY department_id ORDER BY salary) as salary_rank_in_dept
FROM employees
WHERE status = 'ACTIVE'
--ORDER BY salary_rank_in_dept

-- --- Question 69 ---
-- [Tables: employees] 
-- Repeat Question 68 but use RANK() instead of ROW_NUMBER(). Then, using the same data, explain (as a written 
-- comment) a realistic scenario in this dataset (or a hypothetical tie you construct) where RANK() and 
-- ROW_NUMBER() would produce genuinely different results.

SELECT
    concat(first_name,' ',last_name) as full_name,
    salary,
    rank() over (PARTITION BY department_id ORDER BY salary) as salary_rank_in_dept
FROM employees
WHERE status = 'ACTIVE'
/*
COMMENT: If Alice and Bob both make $150,000 as the top earners in HR, RANK() assigns them both rank 1, and the next person (Charlie) gets rank 3. ROW_NUMBER() would arbitrarily assign Alice rank 1 and Bob rank 2. RANK is better when ties genuinely matter (e.g., "bonus goes to top 2 salaries").
*/

-- --- Question 70 ---
-- [Tables: products] 
-- Using DENSE_RANK(), find the top 3 DISTINCT list_price levels among products (i.e., if two products share the 
-- same list_price, they count as the SAME price level) and return every product at those top 3 price levels.

WITH ranked_products AS (
    SELECT
        product_id, product_name, list_price,
        DENSE_RANK() OVER (ORDER BY list_price DESC) AS price_rank
    FROM products
)
SELECT
    *
FROM ranked_products
WHERE price_rank <= 3;

-- --- Question 71 ---
-- [Tables: customers, orders] 
-- Using NTILE(4), divide all customers into revenue quartiles based on their total COMPLETED order value 
-- (customers with zero orders should be treated as having 0 total value and still included). Return customer_id, 
-- customer_name, total_value, revenue_quartile.

WITH customer_totals as (
    SELECT
        c.customer_id,
        c.customer_name,
        sum(o.total_amount) as total_value
    FROM customers c 
    LEFT JOIN orders o 
    on c.customer_id = o.customer_id
    WHERE o.order_status = 'COMPLETED'
    GROUP BY c.customer_id
)
SELECT 
    *,
    ntile(4) OVER (order BY total_value desc) AS revenue_quartile
FROM customer_totals

-- --- Question 72 ---
-- [Tables: orders] 
-- Using LAG(), for each customer, calculate the number of days between their current order and their PREVIOUS 
-- order (order_date difference), ordered chronologically per customer. The very first order for each customer 
-- should show NULL for this gap.

SELECT
    customer_id,
    order_date,
    --lag(order_date) OVER (PARTITION BY customer_id order by order_date asc) as prev_order_date
    (order_date - lag(order_date) OVER (PARTITION BY customer_id order by order_date asc)) as days_diff
FROM orders

-- --- Question 73 ---
-- [Tables: orders] 
-- Using LEAD(), for each customer's order history, show the date of their NEXT order alongside the current one, 
-- and flag (with a CASE expression) any gap longer than 90 days between consecutive orders as 'AT RISK GAP'.

SELECT
    customer_id,
    order_id,
    order_date,
    lead(order_date) over (PARTITION BY customer_id ORDER BY order_date ASC) as next_order_date,
    --(lead(order_date) over (PARTITION BY customer_id ORDER BY order_date ASC) - order_date) as gap,
    CASE 
        WHEN (lead(order_date) over (PARTITION BY customer_id ORDER BY order_date ASC) - order_date)>90 THEN 'AT RISK GAP'
        ELSE 'NO RISK'
    END as gap_status
FROM orders

-- --- Question 74 ---
-- [Tables: orders] 
-- Build a monthly revenue running total (cumulative sum) across all COMPLETED orders, ordered chronologically 
-- by month. Return order_month, monthly_revenue, running_total_revenue.

WITH monthly_totals as (
    SELECT
        date_trunc('month',order_date) as order_month,
        --to_char(order_date,'Mon') as order_month,
        sum(total_amount) as monthly_revenue
    FROM orders
    WHERE order_status = 'COMPLETED'
    GROUP BY order_month
)
SELECT 
    *,
    sum(monthly_revenue) OVER (ORDER BY order_month asc) as cum_monthly_revenue
FROM monthly_totals


-- --- Question 75 ---
-- [Tables: orders] 
-- Build a 3-month moving average of monthly revenue (COMPLETED orders only) using an explicit ROWS 
-- BETWEEN frame clause. Return order_month, monthly_revenue, moving_avg_3mo.

WITH monthly_totals as (
    SELECT
        date_trunc('month',order_date) as order_month,
        sum(total_amount) as monthly_revenue
    FROM orders
    WHERE order_status = 'COMPLETED'
    GROUP BY order_month
)
SELECT
    TO_CHAR(order_month, 'Month YYYY') AS order_month,
    monthly_revenue,
    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3mo
FROM monthly_totals;

-- --- Question 76 ---
-- [Tables: employees] 
-- For each employee, show their salary alongside their DEPARTMENT's total active-employee salary (using SUM() 
-- OVER(PARTITION BY...) with NO ORDER BY — the partition-total pattern, not a running total) and calculate what 
-- percentage of the department total each employee represents.

SELECT
    employee_id,
    salary,
    department_id,
    COALESCE(sum(salary) over (PARTITION BY department_id),0) dept_total_salary,
    round((salary*100)/sum(salary) OVER (PARTITION BY department_id),2) pct_of_dept
FROM employees
WHERE status = 'ACTIVE'
    --and not COALESCE(department_id,0) = 0;

-- --- Question 77 ---
-- [Tables: employees] 
-- Combine PARTITION BY and ORDER BY in the SAME aggregate window function: for each department, calculate 
-- a running total of salary ordered by hire_date (i.e., cumulative salary cost as people were hired over time, reset 
-- per department). Return employee_id, full name, department_id, hire_date, salary, running_dept_salary_cost.

SELECT
    employee_id,
    concat(first_name,' ',last_name) as full_name,
    department_id,
    hire_date,
    salary,
    sum(salary) OVER (PARTITION BY department_id ORDER BY hire_date) as running_dept_salary_cost
FROM employees
WHERE status = 'ACTIVE';

-- --- Question 78 ---
-- [Tables: employees] 
-- Write a query that would ATTEMPT to filter directly on a window function's result using WHERE in the same 
-- SELECT (e.g., trying to filter WHERE salary_rank_in_dept = 1 in the same query where you defined it). Explain in a 
-- comment why this fails, then provide the corrected version using a CTE or subquery.

/*
SELECT 
    employee_id,
    rank() over (ORDER BY salary desc) as rnk
FROM employees
WHERE rnk = 1;
*/
-- where executes before window function

with ranked_emps as (
    SELECT 
        employee_id,
        rank() over (ORDER BY salary desc) as rnk
    FROM employees
)
SELECT * FROM ranked_emps WHERE rnk = 1;

-- --- Question 79 ---
-- [Tables: employees] 
-- Using FIRST_VALUE() and LAST_VALUE() as window functions (research these if you haven't encountered them 
-- — they return the first/last value in the window frame), find each department's highest-paid and lowest-paid 
-- active employee's salary, shown alongside every employee row in that department. Be careful with the default 
-- frame for LAST_VALUE() — research why the naive version often returns an unexpected result and correct for it 
-- using an explicit frame clause.

SELECT
  employee_id, department_id, salary,
  FIRST_VALUE(salary) OVER (PARTITION BY department_id ORDER BY salary DESC) AS highest_paid,
  LAST_VALUE(salary) OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS lowest_paid
FROM employees
WHERE status = 'ACTIVE';


-- ============================================================================
-- 14. Pivoting and Unpivoting Concepts
-- ============================================================================

-- --- Question 80 ---
-- [Tables: employees] 
-- Using conditional aggregation, pivot the employees table so each row is a department_id, with separate 
-- columns for count of Male and Female active employees, plus a total_active column.

SELECT 
    department_id,
    sum(case when gender = 'M' then 1 else 0 end) male_count,
    sum(case when gender = 'F' then 1 else 0 end) female_count,
    count(*) total_count
FROM employees
WHERE status = 'ACTIVE'
GROUP BY department_id

-- --- Question 81 ---
-- [Tables: orders] 
-- Using conditional aggregation, pivot orders so each row is a customer_id, with separate columns for total 
-- COMPLETED amount, total CANCELLED amount, and total RETURNED amount.

SELECT
    customer_id,
    sum(case when order_status = 'COMPLETED' then 1 else 0 end) completed_count,
    sum(case when order_status = 'CANCELLED' then 1 else 0 end) cancelled_count,
    sum(case when order_status = 'RETEURNED' then 1 else 0 end) returned_count
FROM orders
GROUP BY customer_id

-- --- Question 82 ---
-- [Tables: orders] 
-- Using conditional aggregation, build a year-over-year comparison: one row per ship_country, with separate 
-- columns for total 2023 COMPLETED revenue and total 2024 COMPLETED revenue, plus a computed year-over
-- year growth percentage.

with ship_country_comp as (
    SELECT
        ship_country,
        sum(CASE 
            WHEN to_char(order_date,'YYYY') = '2023' THEN total_amount
            ELSE  0
        END) rev_2023,
        sum(CASE 
            WHEN to_char(order_date,'YYYY') = '2024' THEN total_amount  
            ELSE  0
        END) rev_2024
    FROM orders
    WHERE order_status = 'COMPLETED'
    GROUP BY ship_country
)

SELECT *,
    COALESCE(round((rev_2024-rev_2023)*100/nullif(rev_2023,0),2),0) yoy_growth_pct
FROM ship_country_comp

-- --- Question 83 ---
-- [Tables: departments] 
-- Write an unpivot-style query using UNION ALL that takes the departments table's location and budget as two 
-- separate 'attribute rows' per department (i.e., output columns department_id, attribute_name, attribute_value, 
-- where attribute_name is either 'location' or 'budget'). Note budget is numeric and location is text — think about 
-- how you'd need to cast budget to text to make this work in a single unioned column.

SELECT department_id,'location' attribute_name,location attribute_value
FROM departments
UNION ALL
SELECT department_id,'budget' attribute_name,budget::VARCHAR attribute_value
FROM departments