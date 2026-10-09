-- ============================================================================
-- SQL TEST 1 — FULL QUESTION BANK
-- Each of the 17 original Test 1 questions is treated as its own TOPIC.
-- Every topic has 10 question variants, all against the same 12-table
-- dataset (employees, departments, customers, orders, order_items,
-- products, payments, projects, employee_projects, employee_org_chart,
-- attendance, product_prices_history), plus warehouses/price_change_log
-- where a topic's variants need them (noted inline).
-- PostgreSQL code is placed directly below each question — no separate
-- answer key this time.
-- ============================================================================


-- ============================================================================
-- TOPIC 1 — SCHEMA DESIGN (Primary Keys + Foreign Keys)
-- ============================================================================

-- 1.1 Design customers -> orders -> order_items as a connected chain.
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE,
    signup_date   DATE,
    country       VARCHAR(100),
    customer_segment VARCHAR(20),
    referred_by   INT REFERENCES customers(customer_id)
);
CREATE TABLE orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT NOT NULL REFERENCES customers(customer_id),
    order_date   DATE,
    order_status VARCHAR(20),
    total_amount DECIMAL,
    ship_country VARCHAR(100)
);
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders(order_id),
    product_id    INT NOT NULL REFERENCES products(product_id),
    quantity      INT,
    unit_price    DECIMAL,
    discount_pct  DECIMAL
);

-- 1.2 Design employees with a self-referencing manager relationship.
CREATE TABLE employees (
    employee_id   INT PRIMARY KEY,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    manager_id    INT REFERENCES employees(employee_id),
    department_id INT,
    salary        DECIMAL
);

-- 1.3 Design departments and link employees to it with a foreign key.
CREATE TABLE departments (
    department_id   INT PRIMARY KEY,
    department_name VARCHAR(100),
    budget          DECIMAL
);
ALTER TABLE employees
ADD CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- 1.4 Design products + order_items with a foreign key and a quantity CHECK.
CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    product_name VARCHAR(100),
    list_price   DECIMAL
);
ALTER TABLE order_items
ADD CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE order_items
ADD CONSTRAINT chk_qty_positive CHECK (quantity > 0);

-- 1.5 Design payments so each order can have AT MOST one payment row.
CREATE TABLE payments (
    payment_id     INT PRIMARY KEY,
    order_id       INT NOT NULL UNIQUE REFERENCES orders(order_id),
    amount_paid    DECIMAL,
    payment_status VARCHAR(20)
);

-- 1.6 Design projects + employee_projects as a many-to-many bridge table.
CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(100),
    department_id INT REFERENCES departments(department_id)
);
CREATE TABLE employee_projects (
    employee_id  INT REFERENCES employees(employee_id),
    project_id   INT REFERENCES projects(project_id),
    role         VARCHAR(20),
    hours_logged INT,
    PRIMARY KEY (employee_id, project_id)
);

-- 1.7 Add a self-referencing "referred_by" relationship to customers.
ALTER TABLE customers ADD COLUMN referred_by INT REFERENCES customers(customer_id);

-- 1.8 Design product_prices_history with a surrogate key and a date-logic CHECK.
CREATE TABLE product_prices_history (
    price_id       SERIAL PRIMARY KEY,
    product_id     INT NOT NULL REFERENCES products(product_id),
    price          DECIMAL NOT NULL,
    effective_from DATE NOT NULL,
    effective_to   DATE,
    CHECK (effective_to IS NULL OR effective_to > effective_from)
);

-- 1.9 Design attendance with a composite primary key.
CREATE TABLE attendance (
    employee_id      INT REFERENCES employees(employee_id),
    attendance_date  DATE,
    status           VARCHAR(20),
    PRIMARY KEY (employee_id, attendance_date)
);

-- 1.10 Schema evolution: add a warehouses table and link orders to it.
CREATE TABLE warehouses (
    warehouse_id   INT PRIMARY KEY,
    warehouse_name VARCHAR(100)
);
ALTER TABLE orders ADD COLUMN warehouse_id INT REFERENCES warehouses(warehouse_id);


-- ============================================================================
-- TOPIC 2 — INSERT RECORDS
-- ============================================================================

-- 2.1 Insert a new customer, their order, and a matching order_item.
INSERT INTO customers (customer_id, customer_name, email, signup_date, country, customer_segment)
VALUES (116, 'Arun Nair', 'arun.nair@mail.com', '2024-06-01', 'India', 'Retail');
INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount, ship_country)
VALUES (5035, 116, '2024-06-05', 'COMPLETED', 1450.00, 'India');
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_pct)
VALUES (9021, 5035, 204, 1, 950.00, 0.00);

-- 2.2 Insert several new products in a single multi-row INSERT.
INSERT INTO products (product_id, product_name, category, unit_cost, list_price, launch_date, is_active)
VALUES
    (211, 'Wireless Earbuds', 'Electronics', 300.00, 600.00, '2024-01-01', TRUE),
    (212, 'Laptop Stand',     'Accessories', 150.00, 350.00, '2024-02-01', TRUE),
    (213, 'Desk Lamp',        'Furniture',   200.00, 450.00, '2024-03-01', TRUE);

-- 2.3 Insert a product and let it fall back to its column default.
INSERT INTO products (product_id, product_name, category, unit_cost, list_price, launch_date)
VALUES (214, 'USB Cable', 'Accessories', 20.00, 50.00, '2024-04-01');
-- is_active is omitted and picks up its DEFAULT TRUE automatically.

-- 2.4 Populate a new table from an existing one with INSERT ... SELECT.
CREATE TABLE archived_cancelled_orders AS TABLE orders WITH NO DATA;  --<<<-------------------------------
INSERT INTO archived_cancelled_orders
SELECT * FROM orders WHERE order_status = 'CANCELLED';

-- 2.5 Insert a customer and capture the inserted row with RETURNING.
INSERT INTO customers (customer_id, customer_name, email, signup_date, country, customer_segment)
VALUES (117, 'Meera Iyer', 'meera.iyer@mail.com', '2024-07-01', 'India', 'Retail')
RETURNING customer_id, signup_date;

-- 2.6 Insert a customer that might already exist, silently skipping conflicts.
INSERT INTO customers (customer_id, customer_name, email, signup_date, country, customer_segment)
VALUES (101, 'Rajesh Kumar', 'rajesh.k@mail.com', '2021-01-15', 'India', 'Retail')
ON CONFLICT (customer_id) DO NOTHING;

-- 2.7 Insert a new employee reporting to an existing manager.
INSERT INTO employees (employee_id, first_name, last_name, manager_id, department_id, salary)
VALUES (19, 'Tara', 'Singh', 2, 1, 105000);

-- 2.8 Insert a new department.
INSERT INTO departments (department_id, department_name, location, budget)
VALUES (6, 'Customer Success', 'Bengaluru', 700000);

-- 2.9 Insert a payment row linked to an existing order.
INSERT INTO payments (payment_id, order_id, payment_date, payment_method, amount_paid, payment_status)
VALUES (7021, 5034, '2024-06-04', 'CARD', 3050.00, 'SUCCESS');

-- 2.10 Insert a top-level employee with an explicit NULL manager.
INSERT INTO employees (employee_id, first_name, last_name, manager_id, department_id, salary)
VALUES (20, 'Imran', 'Shaikh', NULL, 1, 285000);
-- NULL manager_id signals this employee is top-level (e.g. a new VP).


-- ============================================================================
-- TOPIC 3 — ALTER TABLE
-- ============================================================================

-- 3.1 Add a nullable column.
ALTER TABLE employees ADD COLUMN linkedin_url VARCHAR(255);

-- 3.2 Add a NOT NULL column with a default so existing rows don't break.
ALTER TABLE products ADD COLUMN is_discontinued BOOLEAN DEFAULT FALSE NOT NULL;

-- 3.3 Drop a column.
ALTER TABLE customers DROP COLUMN IF EXISTS phone_number;

-- 3.4 Rename a column.
ALTER TABLE departments RENAME COLUMN budget TO annual_budget;

-- 3.5 Rename a table.
ALTER TABLE warehouses RENAME TO distribution_centers;

-- 3.6 Widen a column's data type.
ALTER TABLE products ALTER COLUMN product_name TYPE VARCHAR(200);

-- 3.7 Add a CHECK constraint.
ALTER TABLE employees ADD CONSTRAINT chk_salary_positive CHECK (salary > 0);

-- 3.8 Add a FOREIGN KEY constraint to an already-existing table.
ALTER TABLE projects
ADD CONSTRAINT fk_projects_department FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- 3.9 Add a UNIQUE constraint.
ALTER TABLE employees ADD CONSTRAINT uq_employee_email UNIQUE (email);

-- 3.10 Drop a constraint.
ALTER TABLE employees DROP CONSTRAINT chk_salary_positive;


-- ============================================================================
-- TOPIC 4 — UPDATE ... WHERE
-- ============================================================================

-- 4.1 Simple single-row update.
UPDATE employees SET job_title = 'Senior Engineer' WHERE employee_id = 5;

-- 4.2 Update using a CASE expression.
UPDATE products
SET category = CASE
    WHEN category = 'Electronics'  THEN 'Tech - Electronics'
    WHEN category = 'Accessories'  THEN 'Tech - Accessories'
    ELSE category
END;

-- 4.3 Update rows selected via a subquery.
UPDATE orders
SET order_status = 'COMPLETED'
WHERE order_id IN (SELECT order_id FROM payments WHERE payment_status = 'SUCCESS')
  AND order_status = 'PENDING';

-- 4.4 Update using a correlated scalar subquery as the new value.
UPDATE employees e
SET salary = (SELECT AVG(salary) FROM employees WHERE department_id = e.department_id)
WHERE employee_id = 6;

-- 4.5 Update multiple columns in one statement.
UPDATE customers SET customer_segment = 'Enterprise', referred_by = NULL WHERE customer_id = 111;

-- 4.6 Update driven by a join (Postgres UPDATE ... FROM).
UPDATE orders o
SET total_amount = oi.line_total
FROM (
    SELECT order_id, SUM(quantity * unit_price * (1 - discount_pct)) AS line_total
    FROM order_items GROUP BY order_id
) oi
WHERE o.order_id = oi.order_id;

-- 4.7 Update with arithmetic (a department-wide raise).
UPDATE employees SET salary = salary * 1.05 WHERE department_id = 1 AND status = 'ACTIVE';

-- 4.8 Update gated by EXISTS.
UPDATE customers c
SET customer_segment = 'Enterprise'
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id AND o.total_amount > 15000
);

-- 4.9 Update restricted to a date range.
UPDATE orders SET order_status = 'ARCHIVED' WHERE order_date < '2022-01-01';

-- 4.10 Conditionally clear a column to NULL.
UPDATE employees SET manager_id = NULL WHERE job_title LIKE 'VP%';


-- ============================================================================
-- TOPIC 5 — DELETE ... WHERE
-- ============================================================================

-- 5.1 Simple delete.
DELETE FROM payments WHERE payment_status = 'FAILED';

-- 5.2 Delete rows matched via a subquery.
DELETE FROM order_items WHERE order_id IN (SELECT order_id FROM orders WHERE order_status = 'CANCELLED');

-- 5.3 Delete using NOT EXISTS.
DELETE FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
  AND c.signup_date < '2021-06-01';

-- 5.4 Delete using a join inside the DELETE itself (DELETE ... USING).
DELETE FROM order_items oi
USING orders o
WHERE oi.order_id = o.order_id AND o.order_status = 'RETURNED';

-- 5.5 Delete with multiple AND conditions.
DELETE FROM employee_projects WHERE role = 'Reviewer' AND hours_logged < 50;

-- 5.6 Delete rows older than a cutoff date.
DELETE FROM attendance WHERE attendance_date < '2024-01-01';

-- 5.7 Delete exact-duplicate rows, keeping one copy of each.
DELETE FROM products a
USING products b
WHERE a.ctid < b.ctid AND a.product_name = b.product_name;

-- 5.8 Batched delete (bounded by LIMIT, meant to be re-run until empty).
DELETE FROM orders WHERE order_id IN (
    SELECT order_id FROM orders WHERE order_status = 'CANCELLED' LIMIT 100
);

-- 5.9 Delete child rows whose parent order was cancelled.
DELETE FROM order_items WHERE order_id IN (SELECT order_id FROM orders WHERE order_status = 'CANCELLED');

-- 5.10 Delete and capture what was removed with RETURNING.
DELETE FROM payments WHERE payment_status = 'FAILED' RETURNING payment_id, order_id;


-- ============================================================================
-- TOPIC 6 — WHERE / ORDER BY / LIMIT
-- ============================================================================

-- 6.1 Basic filter, sort, and limit.
SELECT * FROM orders WHERE order_status = 'COMPLETED' ORDER BY order_date DESC LIMIT 10;

-- 6.2 Mixed AND/OR, explicitly parenthesized.
SELECT * FROM employees WHERE (department_id = 1 OR department_id = 2) AND status = 'ACTIVE';

-- 6.3 Date range with BETWEEN.
SELECT * FROM orders WHERE order_date BETWEEN '2023-01-01' AND '2023-03-31' ORDER BY order_date;

-- 6.4 IN list filter with a LIMIT.
SELECT * FROM customers WHERE country IN ('India', 'UAE', 'USA') ORDER BY signup_date LIMIT 5;

-- 6.5 Pattern matching with LIKE.
SELECT * FROM employees WHERE email LIKE '%.gupta@%' ORDER BY last_name;

-- 6.6 Sort on multiple columns with mixed direction.
SELECT * FROM products ORDER BY category ASC, list_price DESC;

-- 6.7 Pagination with LIMIT + OFFSET.
SELECT * FROM orders ORDER BY order_date DESC LIMIT 10 OFFSET 20;

-- 6.8 Control where NULLs land in the sort order.
SELECT employee_id, manager_id FROM employees ORDER BY manager_id NULLS LAST;

-- 6.9 Sort by a computed expression.
SELECT product_name, list_price, unit_cost, (list_price - unit_cost) AS margin
FROM products ORDER BY margin DESC;

-- 6.10 Negated condition with NOT.
SELECT * FROM orders WHERE NOT order_status = 'CANCELLED' ORDER BY order_date;


-- ============================================================================
-- TOPIC 7 — INNER JOIN + AGGREGATION (plus PK/FK/UNIQUE theory)
-- ============================================================================

-- 7.1 Customers + orders: order count and completed revenue per customer.
SELECT c.customer_id, c.customer_name,
       COUNT(o.order_id) AS order_count,
       SUM(CASE WHEN o.order_status = 'COMPLETED' THEN o.total_amount ELSE 0 END) AS completed_revenue
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name;

-- 7.2 Employees + departments: active headcount and avg salary per department.
SELECT d.department_name, COUNT(*) AS headcount, ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
INNER JOIN departments d ON d.department_id = e.department_id
WHERE e.status = 'ACTIVE'
GROUP BY d.department_name;

-- 7.3 Products + order_items: total revenue per product.
SELECT p.product_id, p.product_name,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_revenue
FROM products p
INNER JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- 7.4 Orders + payments: total successfully paid, by order status.
SELECT o.order_status, SUM(p.amount_paid) AS total_paid
FROM orders o
INNER JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_status = 'SUCCESS'
GROUP BY o.order_status;

-- 7.5 Employees + employee_projects: total hours logged per employee.
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name, SUM(ep.hours_logged) AS total_hours
FROM employees e
INNER JOIN employee_projects ep ON ep.employee_id = e.employee_id
GROUP BY e.employee_id, full_name
ORDER BY total_hours DESC;

-- 7.6 Three-table chain: customers -> orders -> order_items revenue.
SELECT c.customer_id, c.customer_name,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS revenue
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY revenue DESC;

-- 7.7 Departments + projects: total project budget per department.
SELECT d.department_name, SUM(pr.budget) AS total_project_budget
FROM departments d
INNER JOIN projects pr ON pr.department_id = d.department_id
GROUP BY d.department_name;

-- 7.8 Self INNER JOIN: direct-report count per manager.
SELECT m.employee_id, m.first_name || ' ' || m.last_name AS manager_name, COUNT(e.employee_id) AS report_count
FROM employees m
INNER JOIN employees e ON e.manager_id = m.employee_id
GROUP BY m.employee_id, manager_name;

-- 7.9 Three-table chain filtered to COMPLETED orders: quantity sold per product.
SELECT p.product_id, p.product_name, SUM(oi.quantity) AS qty_sold
FROM products p
INNER JOIN order_items oi ON oi.product_id = p.product_id
INNER JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'COMPLETED'
GROUP BY p.product_id, p.product_name
ORDER BY qty_sold DESC;

-- 7.10 Written answer + composite-key illustration.
-- INNER JOIN vs NATURAL JOIN: NATURAL JOIN auto-joins on every identically
-- named column in both tables (implicit, risky if a column name coincides
-- by accident); INNER JOIN requires an explicit ON condition, so the join
-- key is always unambiguous. Composite key vs surrogate key: a composite
-- key uses two or more existing columns together as the primary key (e.g.
-- employee_projects' (employee_id, project_id)); a surrogate key is an
-- artificial auto-generated id (e.g. SERIAL) with no business meaning.
SELECT employee_id, project_id, role FROM employee_projects WHERE role = 'Lead';
-- (employee_id, project_id) together are this table's composite primary key.


-- ============================================================================
-- TOPIC 8 — SELF-JOIN WITHIN A HIERARCHY
-- ============================================================================

-- 8.1 Managers (employee_org_chart) with at least 2 direct reports.
SELECT m.emp_id, m.emp_name, COUNT(r.emp_id) AS direct_report_count
FROM employee_org_chart m
JOIN employee_org_chart r ON r.manager_id = m.emp_id
GROUP BY m.emp_id, m.emp_name
HAVING COUNT(r.emp_id) >= 2;

-- 8.2 Same pattern on the employees table, threshold of 3.
SELECT m.employee_id, m.first_name || ' ' || m.last_name AS manager_name, COUNT(e.employee_id) AS direct_reports
FROM employees m
JOIN employees e ON e.manager_id = m.employee_id
GROUP BY m.employee_id, manager_name
HAVING COUNT(e.employee_id) >= 3;

-- 8.3 Basic self-join: every employee alongside their manager's name.
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       m.first_name || ' ' || m.last_name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- 8.4 Employees who out-earn their own manager.
SELECT e.employee_id, e.first_name, e.salary AS emp_salary, m.salary AS manager_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- 8.5 Pairs of employees who share the same manager ("siblings").
SELECT e1.employee_id AS emp1, e2.employee_id AS emp2, e1.manager_id
FROM employees e1
JOIN employees e2 ON e1.manager_id = e2.manager_id AND e1.employee_id < e2.employee_id
WHERE e1.manager_id IS NOT NULL;

-- 8.6 Managers with ZERO direct reports.
SELECT m.employee_id, m.first_name
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.employee_id
WHERE m.job_title LIKE '%Manager%'
GROUP BY m.employee_id, m.first_name
HAVING COUNT(e.employee_id) = 0;

-- 8.7 Two-level self-join: employee, manager, and grand-manager.
SELECT e.employee_id, e.first_name, m.first_name AS manager, gm.first_name AS grand_manager
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
JOIN employees gm ON m.manager_id = gm.employee_id;

-- 8.8 Two-level self-join on customers' referral chain.
SELECT c1.customer_id AS referred, c2.customer_id AS referred_by, c3.customer_id AS original_referrer
FROM customers c1
JOIN customers c2 ON c1.referred_by = c2.customer_id
JOIN customers c3 ON c2.referred_by = c3.customer_id;

-- 8.9 Pairs of same-category products with a large price gap.
SELECT p1.product_name AS product_a, p2.product_name AS product_b, p1.category,
       ABS(p1.list_price - p2.list_price) AS price_diff
FROM products p1
JOIN products p2 ON p1.category = p2.category AND p1.product_id < p2.product_id
WHERE ABS(p1.list_price - p2.list_price) > 1000;

-- 8.10 Managers whose reports collectively log under 500 hours (self-join + more).
SELECT m.employee_id, m.first_name, SUM(ep.hours_logged) AS total_report_hours
FROM employees m
JOIN employees e ON e.manager_id = m.employee_id
JOIN employee_projects ep ON ep.employee_id = e.employee_id
GROUP BY m.employee_id, m.first_name
HAVING SUM(ep.hours_logged) < 500;


-- ============================================================================
-- TOPIC 9 — Nth-RANKED VALUE
-- ============================================================================

-- 9.1 3rd highest DISTINCT list_price.
SELECT DISTINCT list_price FROM products ORDER BY list_price DESC OFFSET 2 LIMIT 1;

-- 9.2 2nd highest salary.
SELECT DISTINCT salary FROM employees ORDER BY salary DESC OFFSET 1 LIMIT 1;

-- 9.3 5th highest order total_amount.
SELECT DISTINCT total_amount FROM orders ORDER BY total_amount DESC OFFSET 4 LIMIT 1;

-- 9.4 Generalized Nth value via CTE + DENSE_RANK (change the filter for any N).
WITH ranked AS (
    SELECT DISTINCT total_amount, DENSE_RANK() OVER (ORDER BY total_amount DESC) AS rnk
    FROM orders
)
SELECT total_amount FROM ranked WHERE rnk = 5;

-- 9.5 2nd LOWEST list_price within each category.
WITH ranked AS (
    SELECT product_id, product_name, category, list_price,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY list_price ASC) AS rnk
    FROM products
)
SELECT * FROM ranked WHERE rnk = 2;

-- 9.6 3rd highest average department salary.
WITH dept_avg AS (
    SELECT department_id, AVG(salary) AS avg_salary FROM employees WHERE status = 'ACTIVE' GROUP BY department_id
)
SELECT DISTINCT avg_salary FROM dept_avg ORDER BY avg_salary DESC OFFSET 2 LIMIT 1;

-- 9.7 Each customer's 4th most recent order.
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
SELECT * FROM ranked WHERE rn = 4;

-- 9.8 2nd highest total hours logged by any single employee.
WITH emp_hours AS (
    SELECT employee_id, SUM(hours_logged) AS total_hours FROM employee_projects GROUP BY employee_id
)
SELECT DISTINCT total_hours FROM emp_hours ORDER BY total_hours DESC OFFSET 1 LIMIT 1;

-- 9.9 Each customer's 3rd highest COMPLETED order value (Nth-per-group).
WITH ranked AS (
    SELECT customer_id, order_id, total_amount,
           DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY total_amount DESC) AS rnk
    FROM orders WHERE order_status = 'COMPLETED'
)
SELECT * FROM ranked WHERE rnk = 3;

-- 9.10 Same answer, two techniques compared side by side.
-- Technique A: OFFSET/LIMIT
SELECT DISTINCT list_price FROM products ORDER BY list_price DESC OFFSET 2 LIMIT 1;
-- Technique B: DENSE_RANK (safer when the value needs to be reused/joined later)
SELECT list_price FROM (
    SELECT DISTINCT list_price, DENSE_RANK() OVER (ORDER BY list_price DESC) AS rnk FROM products
) t WHERE rnk = 3;


-- ============================================================================
-- TOPIC 10 — TWO-WAY RELATIONSHIPS (most collaborators)
-- ============================================================================

-- 10.1 Each employee's count of distinct collaborators (shared-project self-join).
SELECT ep1.employee_id, COUNT(DISTINCT ep2.employee_id) AS collaborator_count
FROM employee_projects ep1
JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id <> ep2.employee_id
GROUP BY ep1.employee_id
ORDER BY collaborator_count DESC;

-- 10.2 The single pair of employees who've shared the most projects together.
SELECT ep1.employee_id AS emp_a, ep2.employee_id AS emp_b, COUNT(*) AS shared_projects
FROM employee_projects ep1
JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id < ep2.employee_id
GROUP BY ep1.employee_id, ep2.employee_id
ORDER BY shared_projects DESC
LIMIT 1;

-- 10.3 Employees who have never collaborated with anyone.
SELECT employee_id FROM employee_projects
GROUP BY employee_id
HAVING COUNT(DISTINCT project_id) > 0
EXCEPT
SELECT ep1.employee_id FROM employee_projects ep1
JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id <> ep2.employee_id;

-- 10.4 The project with the most staff assigned to it.
SELECT project_id, COUNT(*) AS staff_count
FROM employee_projects
GROUP BY project_id
ORDER BY staff_count DESC
LIMIT 1;

-- 10.5 Customer pairs that refer each other (mutual referral check).
SELECT c1.customer_id, c2.customer_id
FROM customers c1
JOIN customers c2 ON c1.referred_by = c2.customer_id AND c2.referred_by = c1.customer_id;

-- 10.6 Products frequently bought together in the same order.
SELECT oi1.product_id AS product_a, oi2.product_id AS product_b,
       COUNT(DISTINCT oi1.order_id) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
GROUP BY oi1.product_id, oi2.product_id
ORDER BY times_bought_together DESC;

-- 10.7 Cross-department collaboration count per employee.
SELECT e1.employee_id, COUNT(DISTINCT e2.employee_id) AS cross_dept_collaborators
FROM employee_projects ep1
JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id <> ep2.employee_id
JOIN employees e1 ON e1.employee_id = ep1.employee_id
JOIN employees e2 ON e2.employee_id = ep2.employee_id AND e2.department_id <> e1.department_id
GROUP BY e1.employee_id;

-- 10.8 Pairs of employees who are BOTH "Lead" on the same shared project.
SELECT ep1.employee_id AS emp_a, ep2.employee_id AS emp_b, ep1.project_id
FROM employee_projects ep1
JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id < ep2.employee_id
WHERE ep1.role = 'Lead' AND ep2.role = 'Lead';

-- 10.9 The least collaborative employee (minimum non-zero collaborator count).
WITH collab AS (
    SELECT ep1.employee_id, COUNT(DISTINCT ep2.employee_id) AS collaborator_count
    FROM employee_projects ep1
    JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id <> ep2.employee_id
    GROUP BY ep1.employee_id
)
SELECT * FROM collab ORDER BY collaborator_count ASC LIMIT 1;

-- 10.10 A per-employee collaboration list as a single comma-separated string.
SELECT ep1.employee_id, STRING_AGG(DISTINCT ep2.employee_id::TEXT, ', ') AS collaborators
FROM employee_projects ep1
JOIN employee_projects ep2 ON ep1.project_id = ep2.project_id AND ep1.employee_id <> ep2.employee_id
GROUP BY ep1.employee_id;


-- ============================================================================
-- TOPIC 11 — WINDOW FUNCTIONS: SWAPPING ADJACENT LABELS
-- ============================================================================

-- 11.1 Swap salary-rank labels in pairs within each department.
WITH ranked AS (
    SELECT employee_id, first_name || ' ' || last_name AS full_name, department_id, salary,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees WHERE status = 'ACTIVE'
)
SELECT employee_id, full_name, department_id, rn AS original_rank,
    COALESCE(
        CASE WHEN rn % 2 = 1 THEN LEAD(rn) OVER (PARTITION BY department_id ORDER BY rn)
             ELSE LAG(rn) OVER (PARTITION BY department_id ORDER BY rn) END,
        rn
    ) AS swapped_rank
FROM ranked;

-- 11.2 Swap price-tier rank labels in pairs within each product category.
WITH ranked AS (
    SELECT product_id, product_name, category, list_price,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY list_price DESC) AS rn
    FROM products
)
SELECT product_id, product_name, category, rn AS original_rank,
    COALESCE(
        CASE WHEN rn % 2 = 1 THEN LEAD(rn) OVER (PARTITION BY category ORDER BY rn)
             ELSE LAG(rn) OVER (PARTITION BY category ORDER BY rn) END,
        rn
    ) AS swapped_rank
FROM ranked;

-- 11.3 Swap recency-rank labels in pairs within each customer's order history.
WITH ranked AS (
    SELECT order_id, customer_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
SELECT order_id, customer_id, rn AS original_rank,
    COALESCE(
        CASE WHEN rn % 2 = 1 THEN LEAD(rn) OVER (PARTITION BY customer_id ORDER BY rn)
             ELSE LAG(rn) OVER (PARTITION BY customer_id ORDER BY rn) END,
        rn
    ) AS swapped_rank
FROM ranked;

-- 11.4 Swap the actual NAME values (not just the rank number) between pairs.
WITH ranked AS (
    SELECT employee_id, first_name || ' ' || last_name AS full_name, department_id,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees WHERE status = 'ACTIVE'
)
SELECT department_id, rn,
    COALESCE(
        CASE WHEN rn % 2 = 1 THEN LEAD(full_name) OVER (PARTITION BY department_id ORDER BY rn)
             ELSE LAG(full_name) OVER (PARTITION BY department_id ORDER BY rn) END,
        full_name
    ) AS swapped_name
FROM ranked;

-- 11.5 Use LEAD to flag adjacent pairs that are "out of order" by hire date.
WITH ranked AS (
    SELECT employee_id, department_id, hire_date, salary,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees WHERE status = 'ACTIVE'
)
SELECT *,
    CASE WHEN hire_date > LEAD(hire_date) OVER (PARTITION BY department_id ORDER BY rn)
         THEN 'OUT OF ORDER' ELSE 'OK' END AS order_flag
FROM ranked;

-- 11.6 Adjacent-pair aggregation (2-row moving sum) instead of a label swap.
SELECT order_month, monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY order_month ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS pair_sum
FROM (
    SELECT DATE_TRUNC('month', order_date) AS order_month, SUM(total_amount) AS monthly_revenue
    FROM orders WHERE order_status = 'COMPLETED'
    GROUP BY DATE_TRUNC('month', order_date)
) m;

-- 11.7 Swap adjacent months' revenue figures in a monthly time series.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date) AS order_month, SUM(total_amount) AS monthly_revenue,
           ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', order_date)) AS rn
    FROM orders WHERE order_status = 'COMPLETED'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT order_month, monthly_revenue, rn,
    COALESCE(
        CASE WHEN rn % 2 = 1 THEN LEAD(monthly_revenue) OVER (ORDER BY rn)
             ELSE LAG(monthly_revenue) OVER (ORDER BY rn) END,
        monthly_revenue
    ) AS swapped_revenue
FROM monthly;

-- 11.8 Swap adjacent NTILE quartile labels for customers by total revenue.
WITH quartiles AS (
    SELECT c.customer_id, SUM(o.total_amount) AS total_value,
           NTILE(4) OVER (ORDER BY SUM(o.total_amount)) AS quartile
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'COMPLETED'
    GROUP BY c.customer_id
)
SELECT customer_id, quartile,
    CASE WHEN quartile % 2 = 1 THEN quartile + 1 ELSE quartile - 1 END AS swapped_quartile
FROM quartiles;

-- 11.9 Swap adjacent attendance status labels per employee, ordered by date.
WITH ranked AS (
    SELECT employee_id, attendance_date, status,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY attendance_date) AS rn
    FROM attendance
)
SELECT employee_id, attendance_date, status,
    COALESCE(
        CASE WHEN rn % 2 = 1 THEN LEAD(status) OVER (PARTITION BY employee_id ORDER BY rn)
             ELSE LAG(status) OVER (PARTITION BY employee_id ORDER BY rn) END,
        status
    ) AS swapped_status
FROM ranked;

-- 11.10 Harder variant: rotate ranks in groups of 3 instead of swapping pairs.
WITH ranked AS (
    SELECT employee_id, department_id,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees WHERE status = 'ACTIVE'
)
SELECT employee_id, department_id, rn,
    CASE
        WHEN rn % 3 = 1 THEN LEAD(rn, 2) OVER (PARTITION BY department_id ORDER BY rn)
        WHEN rn % 3 = 2 THEN LEAD(rn, 1) OVER (PARTITION BY department_id ORDER BY rn)
        WHEN rn % 3 = 0 THEN LAG(rn, 2) OVER (PARTITION BY department_id ORDER BY rn)
    END AS rotated_rank
FROM ranked;


-- ============================================================================
-- TOPIC 12 — RELATIONAL DIVISION
-- ============================================================================

-- 12.1 Employees assigned to EVERY currently ACTIVE project.
WITH active_projects AS (
    SELECT project_id FROM projects WHERE status = 'ACTIVE'
),
emp_active_assignments AS (
    SELECT ep.employee_id, COUNT(DISTINCT ep.project_id) AS assigned_count
    FROM employee_projects ep
    JOIN active_projects ap ON ap.project_id = ep.project_id
    GROUP BY ep.employee_id
)
SELECT eaa.employee_id, e.first_name || ' ' || e.last_name AS full_name
FROM emp_active_assignments eaa
JOIN employees e ON e.employee_id = eaa.employee_id
WHERE eaa.assigned_count = (SELECT COUNT(*) FROM active_projects);

-- 12.2 Customers who have ordered EVERY product in a specific category.
WITH category_products AS (
    SELECT product_id FROM products WHERE category = 'Accessories'
),
customer_coverage AS (
    SELECT o.customer_id, COUNT(DISTINCT oi.product_id) AS products_bought
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE oi.product_id IN (SELECT product_id FROM category_products)
    GROUP BY o.customer_id
)
SELECT customer_id FROM customer_coverage WHERE products_bought = (SELECT COUNT(*) FROM category_products);

-- 12.3 Employees who've logged hours on EVERY project in their own department.
WITH dept_projects AS (
    SELECT e.employee_id, pr.project_id
    FROM employees e
    JOIN projects pr ON pr.department_id = e.department_id
),
emp_coverage AS (
    SELECT dp.employee_id,
           COUNT(DISTINCT dp.project_id) AS dept_project_count,
           COUNT(DISTINCT ep.project_id) AS assigned_count
    FROM dept_projects dp
    LEFT JOIN employee_projects ep ON ep.employee_id = dp.employee_id AND ep.project_id = dp.project_id
    GROUP BY dp.employee_id
)
SELECT employee_id FROM emp_coverage WHERE assigned_count = dept_project_count;

-- 12.4 Customers with a COMPLETED order in EVERY year from 2021 to 2024.
WITH years AS (SELECT generate_series(2021, 2024) AS yr),
customer_years AS (
    SELECT customer_id, EXTRACT(YEAR FROM order_date) AS yr
    FROM orders WHERE order_status = 'COMPLETED'
    GROUP BY customer_id, EXTRACT(YEAR FROM order_date)
)
SELECT customer_id FROM customer_years
GROUP BY customer_id
HAVING COUNT(DISTINCT yr) = (SELECT COUNT(*) FROM years);

-- 12.5 Products that appear in EVERY order a specific customer has placed.
WITH cust_orders AS (
    SELECT order_id FROM orders WHERE customer_id = 101
),
product_coverage AS (
    SELECT oi.product_id, COUNT(DISTINCT oi.order_id) AS order_count
    FROM order_items oi
    WHERE oi.order_id IN (SELECT order_id FROM cust_orders)
    GROUP BY oi.product_id
)
SELECT product_id FROM product_coverage WHERE order_count = (SELECT COUNT(*) FROM cust_orders);

-- 12.6 Employees who hold the 'Lead' role on EVERY project they're assigned to.
SELECT employee_id FROM employee_projects
GROUP BY employee_id
HAVING COUNT(*) = SUM(CASE WHEN role = 'Lead' THEN 1 ELSE 0 END);

-- 12.7 Departments where EVERY active employee earns above 100000.
SELECT department_id FROM employees
WHERE status = 'ACTIVE' AND department_id IS NOT NULL
GROUP BY department_id
HAVING MIN(salary) > 100000;

-- 12.8 Customers who've used EVERY available payment_method at least once.
WITH methods AS (SELECT DISTINCT payment_method FROM payments),
cust_methods AS (
    SELECT o.customer_id, p.payment_method
    FROM orders o
    JOIN payments p ON p.order_id = o.order_id
    WHERE p.payment_status = 'SUCCESS'
    GROUP BY o.customer_id, p.payment_method
)
SELECT customer_id FROM cust_methods
GROUP BY customer_id
HAVING COUNT(DISTINCT payment_method) = (SELECT COUNT(*) FROM methods);

-- 12.9 ship_countries with a COMPLETED order in EVERY quarter of 2023.
WITH quarters AS (SELECT generate_series(1, 4) AS q),
country_quarters AS (
    SELECT ship_country, EXTRACT(QUARTER FROM order_date) AS q
    FROM orders
    WHERE order_status = 'COMPLETED' AND EXTRACT(YEAR FROM order_date) = 2023
    GROUP BY ship_country, EXTRACT(QUARTER FROM order_date)
)
SELECT ship_country FROM country_quarters
GROUP BY ship_country
HAVING COUNT(DISTINCT q) = (SELECT COUNT(*) FROM quarters);

-- 12.10 Employees assigned to projects spanning EVERY department with an active project.
WITH active_depts AS (
    SELECT DISTINCT department_id FROM projects WHERE status = 'ACTIVE'
),
emp_dept_coverage AS (
    SELECT ep.employee_id, COUNT(DISTINCT pr.department_id) AS depts_covered
    FROM employee_projects ep
    JOIN projects pr ON pr.project_id = ep.project_id
    WHERE pr.department_id IN (SELECT department_id FROM active_depts)
    GROUP BY ep.employee_id
)
SELECT employee_id FROM emp_dept_coverage WHERE depts_covered = (SELECT COUNT(*) FROM active_depts);


-- ============================================================================
-- TOPIC 13 — LEFT JOIN: KEEP ALL ROWS, INCLUDING ZERO MATCHES
-- ============================================================================

-- 13.1 Every customer's order count, including customers with zero orders.
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name;

-- 13.2 Every department's active headcount, including HR's zero.
SELECT d.department_id, d.department_name, COUNT(e.employee_id) AS headcount
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id AND e.status = 'ACTIVE'
GROUP BY d.department_id, d.department_name;

-- 13.3 Every product's total quantity ordered, including never-ordered products.
SELECT p.product_id, p.product_name, COALESCE(SUM(oi.quantity), 0) AS total_qty
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

-- 13.4 Every employee's total hours logged, including those with zero project assignments.
SELECT e.employee_id, e.first_name, COALESCE(SUM(ep.hours_logged), 0) AS total_hours
FROM employees e
LEFT JOIN employee_projects ep ON ep.employee_id = e.employee_id
GROUP BY e.employee_id, e.first_name;

-- 13.5 Every customer's total successful payments, including those with none.
SELECT c.customer_id, c.customer_name, COALESCE(SUM(p.amount_paid), 0) AS total_paid
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN payments p ON p.order_id = o.order_id AND p.payment_status = 'SUCCESS'
GROUP BY c.customer_id, c.customer_name;

-- 13.6 Every project's distinct contributor count, including unstaffed projects.
SELECT pr.project_id, pr.project_name, COUNT(DISTINCT ep.employee_id) AS contributor_count
FROM projects pr
LEFT JOIN employee_projects ep ON ep.project_id = pr.project_id
GROUP BY pr.project_id, pr.project_name;

-- 13.7 Every warehouse's order count, including warehouses with zero orders.
SELECT w.warehouse_id, w.warehouse_name, COUNT(o.order_id) AS order_count
FROM warehouses w
LEFT JOIN orders o ON o.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name;

-- 13.8 Every manager's direct-report count, including managers with zero (self LEFT JOIN).
SELECT m.employee_id, m.first_name, COUNT(e.employee_id) AS direct_reports
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.employee_id
GROUP BY m.employee_id, m.first_name;

-- 13.9 Every product's price-history entry count, including products with none.
SELECT p.product_id, p.product_name, COUNT(pph.product_id) AS price_history_entries
FROM products p
LEFT JOIN product_prices_history pph ON pph.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

-- 13.10 Every customer's distinct purchased-category count, including zero purchases.
SELECT c.customer_id, c.customer_name, COUNT(DISTINCT p.category) AS categories_purchased
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products p ON p.product_id = oi.product_id
GROUP BY c.customer_id, c.customer_name;


-- ============================================================================
-- TOPIC 14 — FIRST OCCURRENCE + DATE-RANGE FILTER
-- ============================================================================

-- 14.1 Each customer's first order placed within 2023.
WITH y2023_orders AS (
    SELECT order_id, customer_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rn
    FROM orders
    WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01'
)
SELECT customer_id, order_id, order_date FROM y2023_orders WHERE rn = 1;

-- 14.2 Each employee's first PRESENT day within June 2024.
WITH ranked AS (
    SELECT employee_id, attendance_date,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY attendance_date) AS rn
    FROM attendance
    WHERE status = 'PRESENT' AND attendance_date BETWEEN '2024-06-01' AND '2024-06-30'
)
SELECT employee_id, attendance_date FROM ranked WHERE rn = 1;

-- 14.3 Each customer's first COMPLETED order, across all years.
WITH ranked AS (
    SELECT customer_id, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn
    FROM orders WHERE order_status = 'COMPLETED'
)
SELECT customer_id, order_id, order_date FROM ranked WHERE rn = 1;

-- 14.4 Each product's first logged price change within 2022-2023.
WITH ranked AS (
    SELECT product_id, price, effective_from,
           ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY effective_from) AS rn
    FROM product_prices_history
    WHERE effective_from BETWEEN '2022-01-01' AND '2023-12-31'
)
SELECT * FROM ranked WHERE rn = 1;

-- 14.5 Each employee's first project, by that project's own start_date.
WITH ranked AS (
    SELECT ep.employee_id, pr.project_id, pr.start_date,
           ROW_NUMBER() OVER (PARTITION BY ep.employee_id ORDER BY pr.start_date) AS rn
    FROM employee_projects ep
    JOIN projects pr ON pr.project_id = ep.project_id
)
SELECT employee_id, project_id, start_date FROM ranked WHERE rn = 1;

-- 14.6 Each customer's first RETURNED order within 2023-2024.
WITH ranked AS (
    SELECT customer_id, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn
    FROM orders
    WHERE order_status = 'RETURNED' AND order_date BETWEEN '2023-01-01' AND '2024-12-31'
)
SELECT * FROM ranked WHERE rn = 1;

-- 14.7 Each department's first-ever hire.
WITH ranked AS (
    SELECT department_id, employee_id, hire_date,
           ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY hire_date) AS rn
    FROM employees WHERE department_id IS NOT NULL
)
SELECT * FROM ranked WHERE rn = 1;

-- 14.8 Each country's first customer signup.
WITH ranked AS (
    SELECT country, customer_id, signup_date,
           ROW_NUMBER() OVER (PARTITION BY country ORDER BY signup_date) AS rn
    FROM customers
)
SELECT * FROM ranked WHERE rn = 1;

-- 14.9 Each ship_country's first CANCELLED order within a date range.
WITH ranked AS (
    SELECT ship_country, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY ship_country ORDER BY order_date) AS rn
    FROM orders
    WHERE order_status = 'CANCELLED' AND order_date BETWEEN '2023-01-01' AND '2024-06-30'
)
SELECT * FROM ranked WHERE rn = 1;

-- 14.10 Each 2023 new customer's first order within 90 days of signup.
WITH new_customers AS (
    SELECT customer_id, signup_date FROM customers WHERE signup_date BETWEEN '2023-01-01' AND '2023-12-31'
),
ranked AS (
    SELECT o.customer_id, o.order_id, o.order_date, nc.signup_date,
           ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS rn
    FROM orders o
    JOIN new_customers nc ON nc.customer_id = o.customer_id
    WHERE o.order_date <= nc.signup_date + INTERVAL '90 days'
)
SELECT * FROM ranked WHERE rn = 1;


-- ============================================================================
-- TOPIC 15 — POINT-IN-TIME LOOKUP (value as of a given date)
-- ============================================================================

-- 15.1 Price of product 205 as of 2022-01-01.
SELECT price FROM product_prices_history
WHERE product_id = 205
  AND DATE '2022-01-01' >= effective_from
  AND DATE '2022-01-01' < COALESCE(effective_to, DATE '9999-12-31');

-- 15.2 Price of product 201 as of 2023-12-31 (boundary date).
SELECT price FROM product_prices_history
WHERE product_id = 201
  AND DATE '2023-12-31' >= effective_from
  AND DATE '2023-12-31' < COALESCE(effective_to, DATE '9999-12-31');

-- 15.3 Current price for EVERY product, via a general latest-row-per-group pattern.
WITH ranked AS (
    SELECT product_id, price, effective_from,
           ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY effective_from DESC) AS rn
    FROM product_prices_history
)
SELECT product_id, price FROM ranked WHERE rn = 1;

-- 15.4 Price lookup for a date BEFORE any history exists (edge case).
SELECT price FROM product_prices_history
WHERE product_id = 203
  AND DATE '2015-01-01' >= effective_from
  AND DATE '2015-01-01' < COALESCE(effective_to, DATE '9999-12-31');
-- Returns no rows: 2015-01-01 predates product 203's earliest effective_from
-- (2019-11-20), so correctly there is no "price as of" that date.

-- 15.5 Price actually in effect on the order date, per order_item.
SELECT oi.order_item_id, oi.unit_price,
    (SELECT price FROM product_prices_history pph
     WHERE pph.product_id = oi.product_id
       AND o.order_date >= pph.effective_from
       AND o.order_date < COALESCE(pph.effective_to, DATE '9999-12-31')) AS price_as_of_order
FROM order_items oi JOIN orders o ON o.order_id = oi.order_id;

-- 15.6 Products that had a price change during Q1 2023.
SELECT DISTINCT product_id FROM product_prices_history
WHERE effective_from BETWEEN '2023-01-01' AND '2023-03-31';

-- 15.7 Price on the exact day a new price took effect (boundary inclusivity).
SELECT product_id, price FROM product_prices_history
WHERE product_id = 206 AND effective_from = DATE '2022-01-15';

-- 15.8 The generic reusable template for any Type-2 SCD "as of date" lookup.
-- SELECT <cols> FROM <history_table>
-- WHERE <entity_id> = :id
--   AND :as_of_date >= effective_from
--   AND :as_of_date <  COALESCE(effective_to, DATE '9999-12-31');
SELECT price FROM product_prices_history
WHERE product_id = 201
  AND DATE '2023-06-01' >= effective_from
  AND DATE '2023-06-01' < COALESCE(effective_to, DATE '9999-12-31');

-- 15.9 Compare a product's price on two different dates, side by side.
SELECT
    (SELECT price FROM product_prices_history WHERE product_id = 201
       AND DATE '2021-01-01' >= effective_from AND DATE '2021-01-01' < COALESCE(effective_to, DATE '9999-12-31')) AS price_2021_01_01,
    (SELECT price FROM product_prices_history WHERE product_id = 201
       AND DATE '2023-06-01' >= effective_from AND DATE '2023-06-01' < COALESCE(effective_to, DATE '9999-12-31')) AS price_2023_06_01;

-- 15.10 Every product whose price differs between two given dates.
WITH price_compare AS (
    SELECT p.product_id,
        (SELECT price FROM product_prices_history pph WHERE pph.product_id = p.product_id
           AND DATE '2023-01-01' >= pph.effective_from AND DATE '2023-01-01' < COALESCE(pph.effective_to, DATE '9999-12-31')) AS price_2023,
        (SELECT price FROM product_prices_history pph WHERE pph.product_id = p.product_id
           AND DATE '2024-01-01' >= pph.effective_from AND DATE '2024-01-01' < COALESCE(pph.effective_to, DATE '9999-12-31')) AS price_2024
    FROM products p
)
SELECT *, (price_2024 - price_2023) AS price_change
FROM price_compare
WHERE price_2023 IS DISTINCT FROM price_2024;


-- ============================================================================
-- TOPIC 16 — DATABASE VIEWS FOR REUSABLE LOGIC
-- ============================================================================

-- 16.1 A customer order summary view.
CREATE VIEW vw_customer_order_summary AS
SELECT c.customer_id, c.customer_name,
       COUNT(o.order_id) AS total_orders,
       SUM(CASE WHEN o.order_status = 'COMPLETED' THEN o.total_amount ELSE 0 END) AS completed_revenue,
       MAX(o.order_date) AS most_recent_order_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name;

-- 16.2 An active-employees view with department context.
CREATE VIEW vw_active_employees AS
SELECT e.employee_id, e.first_name, e.last_name, e.job_title, d.department_name, e.salary
FROM employees e
LEFT JOIN departments d ON d.department_id = e.department_id
WHERE e.status = 'ACTIVE';

-- 16.3 A per-product revenue view.
CREATE VIEW vw_product_revenue AS
SELECT p.product_id, p.product_name,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

-- 16.4 A monthly revenue view.
CREATE VIEW vw_monthly_revenue AS
SELECT DATE_TRUNC('month', order_date) AS order_month, SUM(total_amount) AS monthly_revenue
FROM orders WHERE order_status = 'COMPLETED'
GROUP BY DATE_TRUNC('month', order_date);

-- 16.5 A department vs. project budget rollup view.
CREATE VIEW vw_department_project_budget AS
SELECT d.department_id, d.department_name, d.budget AS department_budget, SUM(pr.budget) AS total_project_budget
FROM departments d
LEFT JOIN projects pr ON pr.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget;

-- 16.6 A view with a filter baked in (pending orders only).
CREATE VIEW vw_pending_orders AS
SELECT o.order_id, o.order_date, c.customer_name, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'PENDING';

-- 16.7 A simple, directly-updatable view, plus an UPDATE through it.
CREATE VIEW vw_active_products AS
SELECT product_id, product_name, list_price, is_active FROM products WHERE is_active = TRUE;

UPDATE vw_active_products SET list_price = 1300.00 WHERE product_id = 201;
-- This works because the view is a plain single-table SELECT with no
-- aggregation or joins — Postgres allows direct updates through views like it.

-- 16.8 A view that exposes a window-function ranking.
CREATE VIEW vw_employee_salary_rank AS
SELECT employee_id, first_name, last_name, department_id, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank
FROM employees WHERE status = 'ACTIVE';

-- 16.9 Drop and recreate a view with an extra column.
DROP VIEW IF EXISTS vw_pending_orders;
CREATE OR REPLACE VIEW vw_pending_orders AS
SELECT o.order_id, o.order_date, c.customer_name, o.total_amount, o.ship_country
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'PENDING';

-- 16.10 A view layered on top of another view.
CREATE VIEW vw_top_customers AS
SELECT customer_id, customer_name, completed_revenue
FROM vw_customer_order_summary
ORDER BY completed_revenue DESC
LIMIT 10;


-- ============================================================================
-- TOPIC 17 — RECONCILING TWO FACT TABLES WITHOUT LOSING UNMATCHED ROWS
-- ============================================================================

-- 17.1 RETURNED orders vs REFUNDED payments, both directions of mismatch.
SELECT
    COALESCE(o.order_id, p.order_id) AS order_id,
    o.order_status,
    p.payment_status,
    CASE
        WHEN o.order_id IS NULL THEN 'REFUND WITH NO RETURNED ORDER'
        WHEN p.order_id IS NULL THEN 'RETURNED ORDER WITH NO REFUND'
    END AS reconciliation_flag
FROM (SELECT * FROM orders WHERE order_status = 'RETURNED') o
FULL JOIN (SELECT * FROM payments WHERE payment_status = 'REFUNDED') p
    ON o.order_id = p.order_id
WHERE o.order_id IS NULL OR p.order_id IS NULL;

-- 17.2 Full orders-vs-payments reconciliation status for every order.
SELECT o.order_id, o.total_amount, COALESCE(SUM(p.amount_paid), 0) AS total_paid,
    CASE
        WHEN COALESCE(SUM(p.amount_paid), 0) = 0 THEN 'UNPAID / NO PAYMENT FOUND'
        WHEN SUM(p.amount_paid) < o.total_amount THEN 'PARTIALLY PAID'
        WHEN SUM(p.amount_paid) = o.total_amount THEN 'FULLY PAID'
        ELSE 'OVERPAID'
    END AS reconciliation_status
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id AND p.payment_status = 'SUCCESS'
GROUP BY o.order_id, o.total_amount;

-- 17.3 employee_projects vs projects: unstaffed projects + orphaned assignments.
SELECT pr.project_id, pr.project_name FROM projects pr
LEFT JOIN employee_projects ep ON ep.project_id = pr.project_id
WHERE ep.project_id IS NULL
UNION ALL
SELECT ep.project_id, 'ORPHANED ASSIGNMENT - no matching project' FROM employee_projects ep
LEFT JOIN projects pr ON pr.project_id = ep.project_id
WHERE pr.project_id IS NULL;

-- 17.4 order_items vs orders: orphaned line items + orders with no line items.
SELECT oi.order_item_id, 'ORPHAN ORDER_ITEM' AS issue FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT o.order_id, 'ORDER WITH NO LINE ITEMS' AS issue FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE oi.order_item_id IS NULL;

-- 17.5 customers self-referential integrity + never-ordered customers.
SELECT c.customer_id, 'REFERRED_BY NOT FOUND' AS issue FROM customers c
LEFT JOIN customers r ON r.customer_id = c.referred_by
WHERE c.referred_by IS NOT NULL AND r.customer_id IS NULL
UNION ALL
SELECT c.customer_id, 'NEVER ORDERED' AS issue FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- 17.6 products vs product_prices_history integrity check, both directions.
SELECT p.product_id, 'NO PRICE HISTORY' AS issue FROM products p
LEFT JOIN product_prices_history pph ON pph.product_id = p.product_id
WHERE pph.product_id IS NULL
UNION ALL
SELECT pph.product_id, 'PRICE HISTORY REFERENCES UNKNOWN PRODUCT' AS issue FROM product_prices_history pph
LEFT JOIN products p ON p.product_id = pph.product_id
WHERE p.product_id IS NULL;

-- 17.7 employees vs employee_org_chart: two parallel hierarchies, consistency check.
SELECT e.employee_id, 'IN employees NOT IN employee_org_chart' AS issue FROM employees e
LEFT JOIN employee_org_chart eoc ON eoc.emp_id = e.employee_id
WHERE eoc.emp_id IS NULL
UNION ALL
SELECT eoc.emp_id, 'IN employee_org_chart NOT IN employees' AS issue FROM employee_org_chart eoc
LEFT JOIN employees e ON e.employee_id = eoc.emp_id
WHERE e.employee_id IS NULL;

-- 17.8 departments vs employees: empty departments + orphaned department_id.
SELECT d.department_id, 'DEPARTMENT WITH NO ACTIVE EMPLOYEES' AS issue FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id AND e.status = 'ACTIVE'
WHERE e.employee_id IS NULL
UNION ALL
SELECT e.department_id, 'EMPLOYEE DEPARTMENT_ID NOT IN departments' AS issue FROM employees e
LEFT JOIN departments d ON d.department_id = e.department_id
WHERE e.department_id IS NOT NULL AND d.department_id IS NULL;

-- 17.9 payments vs orders by VALUE (amount mismatch, not just presence/absence).
SELECT o.order_id, o.total_amount, p.amount_paid, (p.amount_paid - o.total_amount) AS difference
FROM orders o
JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_status = 'SUCCESS' AND p.amount_paid <> o.total_amount;

-- 17.10 attendance vs employees: employees with no attendance + orphaned attendance rows.
SELECT e.employee_id, 'NO ATTENDANCE RECORDS' AS issue FROM employees e
LEFT JOIN attendance a ON a.employee_id = e.employee_id
WHERE a.employee_id IS NULL
UNION ALL
SELECT a.employee_id, 'ATTENDANCE ROW FOR UNKNOWN EMPLOYEE' AS issue FROM attendance a
LEFT JOIN employees e ON e.employee_id = a.employee_id
WHERE e.employee_id IS NULL
GROUP BY a.employee_id;


-- ============================================================================
-- END OF QUESTION BANK — 17 topics x 10 variants = 170 questions
-- ============================================================================
