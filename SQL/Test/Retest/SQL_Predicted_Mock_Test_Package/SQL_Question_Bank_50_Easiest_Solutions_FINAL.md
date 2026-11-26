# SQL Question Bank — 50 Questions with the Easiest MySQL Solutions

**Database:** MySQL 8.0  
**Structure:** 10 topics × 5 questions = 50 questions  
**Goal:** Learn one short, repeatable SQL pattern for each question. The examples favour easy-to-remember code over production-level complexity.

> These are practice variations based on the concepts in SQL Test 1 and SQL Test 2. They are not official questions. Table and column names are assumed to match the question. Run each question against the matching tables in your practice database.

## How to study this bank

1. Read the question and try to identify the SQL pattern.
2. Type the solution without copying it.
3. Remember the short pattern under **Remember**.
4. Pay attention to the note where a shorter method has a limitation.

---

# Topic 1 — Table Design, DDL and Constraints

## Q1. Create a parent and child table

Create departments and employees. Every employee must belong to a department.

```sql
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL,
    employee_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
```

**Remember:** Create the parent (`departments`) first, then the child (`employees`).

## Q2. Add a unique constraint to employee email

Assume the `email` column already exists.

```sql
ALTER TABLE employees
ADD UNIQUE (email);
```

**Remember:** `ALTER TABLE` changes an existing table; `UNIQUE` prevents duplicate values.

## Q3. Require product stock to be zero or more

```sql
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock INT NOT NULL DEFAULT 0,
    CHECK (stock >= 0)
);
```

**Remember:** `NOT NULL` blocks missing values; `CHECK` blocks negative stock.

## Q4. Create a composite primary key

A student can enrol in a course only once.

```sql
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    enrolled_on DATE,
    PRIMARY KEY (student_id, course_id)
);
```

**Remember:** Put both columns inside `PRIMARY KEY (col1, col2)`.

## Q5. Add a required status column with a default

```sql
ALTER TABLE orders
ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending';
```

**Remember:** `NOT NULL DEFAULT 'pending'` makes the column required and supplies a default.

---

# Topic 2 — INSERT, UPDATE, DELETE, Filtering and Sorting

## Q1. Insert multiple rows in one query

```sql
INSERT INTO departments (department_name)
VALUES ('Engineering'), ('Finance'), ('Operations');
```

**Remember:** Write one `INSERT`, then separate rows with commas.

## Q2. Increase prices in one category by 5%

```sql
UPDATE products
SET price = price * 1.05
WHERE category_id = 3;
```

**Remember:** Increase by 5% = multiply by `1.05`. Always check the `WHERE` clause.

## Q3. Delete one cancelled order

```sql
DELETE FROM orders
WHERE order_id = 105
  AND status = 'cancelled';
```

**Remember:** `DELETE FROM table WHERE condition`. Do not omit `WHERE` unless every row should be deleted.

## Q4. Find the five newest paid orders

```sql
SELECT order_id, customer_id, order_date
FROM orders
WHERE status = 'paid'
ORDER BY order_date DESC
LIMIT 5;
```

**Remember:** Newest first = `ORDER BY date DESC`; first five = `LIMIT 5`.

## Q5. Insert a user or update their existing email

Assume `user_id` is a primary key or unique key.

```sql
INSERT INTO users (user_id, name, email)
VALUES (10, 'Asha', 'asha@example.com')
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    email = VALUES(email);
```

**Remember:** `ON DUPLICATE KEY UPDATE` handles an existing primary/unique key. `VALUES(column)` is supported in MySQL 8, though newer MySQL versions mark this form as deprecated.

---

# Topic 3 — JOINs and Grouped Aggregation

## Q1. Calculate total revenue per customer

Tables: `customers`, `orders`, `order_items`.

```sql
SELECT
    c.customer_id,
    c.first_name,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.first_name;
```

**Remember:** Join the related tables, calculate `quantity * price`, then `SUM()` by customer.

## Q2. Show every customer, even customers with zero orders

```sql
SELECT
    c.customer_id,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id;
```

**Remember:** `LEFT JOIN` keeps all customers. Count a right-table ID so customers with no match get `0`.

## Q3. Find departments with at least five employees

```sql
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 5;
```

**Remember:** `WHERE` filters rows before grouping; `HAVING` filters after grouping.

## Q4. Calculate the total value of each order

```sql
SELECT
    order_id,
    SUM(quantity * unit_price) AS order_total
FROM order_items
GROUP BY order_id;
```

**Remember:** Group line items by order and sum `quantity * unit_price`.

## Q5. Find orders whose customer does not exist

```sql
SELECT o.*
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
```

**Remember:** `LEFT JOIN` plus `WHERE right_table.id IS NULL` finds unmatched rows.

---

# Topic 4 — Self-Joins, Relationships and Relational Division

## Q1. Show each employee and their manager

Assume `employees.manager_id` points to `employees.employee_id`.

```sql
SELECT
    e.employee_name,
    m.employee_name AS manager_name
FROM employees e
LEFT JOIN employees m ON m.employee_id = e.manager_id;
```

**Remember:** A self-join uses the same table twice with different aliases.

## Q2. Find categories with at least three direct children

```sql
SELECT p.id, p.name, COUNT(c.id) AS child_count
FROM categories p
JOIN categories c ON c.parent_id = p.id
GROUP BY p.id, p.name
HAVING COUNT(c.id) >= 3;
```

**Remember:** Parent alias + child alias, then `GROUP BY` the parent.

## Q3. Count friendships from both directions

A request from A to B also counts as a connection for B.

```sql
SELECT person_id, COUNT(DISTINCT friend_id) AS friend_count
FROM (
    SELECT sender_id AS person_id, receiver_id AS friend_id
    FROM friend_requests
    UNION ALL
    SELECT receiver_id, sender_id
    FROM friend_requests
) x
GROUP BY person_id;
```

**Remember:** `UNION ALL` stacks the original direction and the reversed direction.

## Q4. Find students who completed every required course

```sql
SELECT student_id
FROM completions
WHERE course_id IN (SELECT course_id FROM required_courses)
GROUP BY student_id
HAVING COUNT(DISTINCT course_id) = (
    SELECT COUNT(*) FROM required_courses
);
```

**Remember:** Count distinct completed required courses and compare with the total required courses.

**Note:** This is the easiest count-based version when the required-course table contains at least one course. For a completely general “every row” rule, including an empty required-course set, use double `NOT EXISTS`.

## Q5. Find products that have never been ordered

```sql
SELECT p.product_id, p.product_name
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
);
```

**Remember:** `NOT EXISTS` means no matching row was found.

---

# Topic 5 — Window Functions and Ranking

## Q1. Find the third-highest distinct salary

```sql
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 2;
```

**Remember:** Remove duplicates, sort high to low, skip two rows. This returns no row if fewer than three distinct salaries exist.

## Q2. Find the latest order for each customer

```sql
SELECT customer_id, order_id, order_date
FROM (
    SELECT
        customer_id,
        order_id,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC, order_id DESC
        ) AS rn
    FROM orders
) x
WHERE rn = 1;
```

**Remember:** `PARTITION BY customer_id` restarts numbering for each customer; `rn = 1` keeps the latest order.

## Q3. Find the top two products by revenue in each category

```sql
WITH totals AS (
    SELECT
        p.category_id,
        p.product_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY p.category_id, p.product_id
), ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY category_id
               ORDER BY revenue DESC
           ) AS rn
    FROM totals
)
SELECT category_id, product_id, revenue
FROM ranked
WHERE rn <= 2;
```

**Remember:** First calculate totals; then number products inside each category; finally keep `rn <= 2`.

**Note:** `ROW_NUMBER()` returns at most two products per category. Use `DENSE_RANK()` instead when the question says to include ties.

## Q4. Calculate a running total per account

```sql
SELECT
    account_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date, transaction_id
    ) AS running_total
FROM transactions;
```

**Remember:** `SUM() OVER (PARTITION BY ... ORDER BY ...)` makes a running total.

## Q5. Swap adjacent labels based on row position

```sql
WITH x AS (
    SELECT id, label,
           ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM bins
)
SELECT
    id,
    CASE
        WHEN MOD(rn, 2) = 1
            THEN COALESCE(LEAD(label) OVER (ORDER BY rn), label)
        ELSE LAG(label) OVER (ORDER BY rn)
    END AS swapped_label
FROM x
ORDER BY id;
```

**Remember:** Odd row takes the next label (`LEAD`); even row takes the previous label (`LAG`). The last unpaired row keeps its own label.

---

# Topic 6 — Dates, First Occurrence and As-Of Queries

## Q1. Count first-ever purchases per day, including zero days

Example range: 1 January through 7 January 2026.

```sql
WITH RECURSIVE dates AS (
    SELECT DATE('2026-01-01') AS d
    UNION ALL
    SELECT d + INTERVAL 1 DAY
    FROM dates
    WHERE d < '2026-01-07'
), first_buy AS (
    SELECT customer_id, MIN(purchase_date) AS first_date
    FROM purchases
    GROUP BY customer_id
)
SELECT d.d, COUNT(f.customer_id) AS new_customers
FROM dates d
LEFT JOIN first_buy f ON f.first_date = d.d
GROUP BY d.d
ORDER BY d.d;
```

**Remember:** Generate every date, find each customer's `MIN(date)`, then `LEFT JOIN` so zero days remain.

## Q2. Find each employee's salary as of a selected date

If the employee has no salary history by that date, use 40,000.

```sql
SELECT
    e.employee_id,
    COALESCE((
        SELECT s.salary
        FROM salary_changes s
        WHERE s.employee_id = e.employee_id
          AND s.change_date <= '2026-03-01'
        ORDER BY s.change_date DESC, s.id DESC
        LIMIT 1
    ), 40000) AS salary_as_of
FROM employees e;
```

**Remember:** Choose the latest change that is on or before the requested date.

## Q3. Count each subscriber's renewals in 2025, including zero

```sql
SELECT s.subscriber_id, COUNT(r.renewal_id) AS renewals
FROM subscribers s
LEFT JOIN renewals r
    ON r.subscriber_id = s.subscriber_id
   AND r.renewal_date >= '2025-01-01'
   AND r.renewal_date < '2026-01-01'
GROUP BY s.subscriber_id;
```

**Remember:** Put the year filter in the `ON` clause so subscribers with no renewals remain.

## Q4. Find the first order date for each customer

```sql
SELECT customer_id, MIN(order_date) AS first_order_date
FROM orders
GROUP BY customer_id;
```

**Remember:** First date = `MIN(date)` grouped by customer.

## Q5. Find orders from the last 30 days

For a `DATE` column, including today:

```sql
SELECT *
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL 29 DAY
  AND order_date <= CURRENT_DATE
ORDER BY order_date DESC;
```

**Remember:** Compare the date with a range. For an exam with a fixed reference date, use the date given in the question instead of `CURRENT_DATE`.

---

# Topic 7 — CTEs, Views and Reconciliation

## Q1. Calculate total spend per customer using a CTE

```sql
WITH spend AS (
    SELECT customer_id, SUM(amount) AS total_spend
    FROM payments
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.name,
    COALESCE(s.total_spend, 0) AS total_spend
FROM customers c
LEFT JOIN spend s ON s.customer_id = c.customer_id;
```

**Remember:** Aggregate first in the CTE; join it to customers; use `COALESCE` for zero.

## Q2. Create a view for customer order totals

```sql
CREATE OR REPLACE VIEW vw_customer_totals AS
SELECT
    c.customer_id,
    c.name,
    COALESCE(SUM(o.total_amount), 0) AS total_amount
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;
```

**Remember:** A view is a saved `SELECT` query.

## Q3. Reconcile monthly sales and refunds, keeping unmatched groups

```sql
WITH sales AS (
    SELECT DATE_FORMAT(sale_date, '%Y-%m') AS month,
           region, SUM(amount) AS sales_amount
    FROM payments
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m'), region
), refunds AS (
    SELECT DATE_FORMAT(refund_date, '%Y-%m') AS month,
           region, SUM(amount) AS refund_amount
    FROM refunds_table
    GROUP BY DATE_FORMAT(refund_date, '%Y-%m'), region
), all_keys AS (
    SELECT month, region FROM sales
    UNION
    SELECT month, region FROM refunds
)
SELECT
    k.month,
    k.region,
    COALESCE(s.sales_amount, 0) AS sales_amount,
    COALESCE(r.refund_amount, 0) AS refund_amount
FROM all_keys k
LEFT JOIN sales s ON s.month = k.month AND s.region = k.region
LEFT JOIN refunds r ON r.month = k.month AND r.region = k.region;
```

**Remember:** Make one list of every month/region key, then left join both summaries to it.

## Q4. Find source rows that are missing from the target

```sql
SELECT s.id
FROM source_table s
WHERE NOT EXISTS (
    SELECT 1
    FROM target_table t
    WHERE t.id = s.id
);
```

**Remember:** `NOT EXISTS` finds source IDs with no target match.

## Q5. Combine current and archived events

```sql
WITH all_events AS (
    SELECT customer_id, event_date, event_type FROM current_events
    UNION ALL
    SELECT customer_id, event_date, event_type FROM archived_events
)
SELECT customer_id, COUNT(*) AS event_count
FROM all_events
GROUP BY customer_id;
```

**Remember:** `UNION ALL` stacks rows; it does not remove duplicates.

---

# Topic 8 — Staging Cleanup and ETL Data Quality

## Q1. Copy rows into a clean table, removing exact duplicates

```sql
INSERT INTO clean_customers (customer_id, name, email)
SELECT DISTINCT customer_id, name, email
FROM raw_customers;
```

**Remember:** `SELECT DISTINCT` removes identical selected rows.

## Q2. Keep only the first row for each customer ID

Assume `source_row_id` determines which row arrived first.

```sql
INSERT INTO clean_customers (customer_id, name, email)
SELECT customer_id, name, email
FROM (
    SELECT r.*,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY loaded_at, source_row_id
           ) AS rn
    FROM raw_customers r
) x
WHERE rn = 1;
```

**Remember:** `PARTITION BY` the duplicate key, sort oldest first, keep `rn = 1`.

## Q3. Drop orders whose customer is missing

```sql
INSERT INTO clean_orders (order_id, customer_id, order_date)
SELECT r.order_id, r.customer_id, r.order_date
FROM raw_orders r
JOIN clean_customers c ON c.customer_id = r.customer_id;
```

**Remember:** An `INNER JOIN` keeps only orders with a valid customer.

## Q4. Keep order items only when their parent order survived cleaning

```sql
INSERT INTO clean_order_items (item_id, order_id, product_id, quantity)
SELECT i.item_id, i.order_id, i.product_id, i.quantity
FROM raw_order_items i
JOIN clean_orders o ON o.order_id = i.order_id;
```

**Remember:** Load child rows by joining to the cleaned parent table.

## Q5. Keep valid non-negative decimal amounts

```sql
INSERT INTO clean_payments (payment_id, amount)
SELECT payment_id, CAST(amount_text AS DECIMAL(10,2))
FROM raw_payments
WHERE amount_text REGEXP '^[0-9]+([.][0-9]{1,2})?$'
  AND CAST(amount_text AS DECIMAL(10,2)) >= 0;
```

**Remember:** `REGEXP` checks the numeric format; `CAST` converts the text to a number.

---

# Topic 9 — Stored Procedures, Cursors, Repeat-Safe Loads and SCD2

## Q1. Create a procedure that refreshes a target table

This version uses `DELETE`, which is easy to remember and works with foreign keys when child tables are cleared first.

```sql
CREATE PROCEDURE refresh_customers()
BEGIN
    DELETE FROM clean_customers;

    INSERT INTO clean_customers (customer_id, name)
    SELECT DISTINCT customer_id, name
    FROM raw_customers;
END;
```

**Remember:** Clear the target, then insert the source again. This is a full-refresh pattern.

## Q2. Create a procedure with an input parameter

```sql
CREATE PROCEDURE get_customer_orders(IN p_customer_id INT)
BEGIN
    SELECT order_id, order_date, status
    FROM orders
    WHERE customer_id = p_customer_id
    ORDER BY order_date;
END;
```

Call it with:

```sql
CALL get_customer_orders(10);
```

**Remember:** `IN` receives a value; use the parameter in the `WHERE` condition.

## Q3. Use a cursor to read active employees one row at a time

```sql
CREATE PROCEDURE list_active_employees()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE v_name VARCHAR(100);

    DECLARE cur CURSOR FOR
        SELECT name FROM employees WHERE active = 1;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_name;
        IF finished = 1 THEN
            LEAVE read_loop;
        END IF;
        SELECT v_name AS employee_name;
    END LOOP;

    CLOSE cur;
END;
```

**Remember:** Declare → open → fetch in a loop → leave at NOT FOUND → close.

## Q4. Compare nullable values safely in MySQL

```sql
IF NOT (old_email <=> new_email) THEN
    -- values are different
END IF;
```

**Remember:** MySQL `<=>` compares `NULL` safely. `NOT (a <=> b)` means the values differ, including `NULL` versus a value.

## Q5. Expire an old dimension row and insert a new version

Example for customer 10, whose email or city has changed:

```sql
UPDATE dim_customer
SET expiry_date = CURRENT_DATE,
    is_current = FALSE
WHERE customer_id = 10
  AND is_current = TRUE
  AND (
      NOT (email <=> 'new@example.com')
      OR NOT (city <=> 'Pune')
  );

INSERT INTO dim_customer (
    customer_id, email, city, effective_date, expiry_date, is_current
)
SELECT 10, 'new@example.com', 'Pune', CURRENT_DATE, NULL, TRUE
WHERE NOT EXISTS (
    SELECT 1
    FROM dim_customer
    WHERE customer_id = 10 AND is_current = TRUE
);
```

**Remember:** SCD2 = expire the old current row, then insert a new current row. Do not overwrite the old history.

---

# Topic 10 — Star Schema, Fact Tables and Indexing

## Q1. Create a customer dimension with a surrogate key

```sql
CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);
```

**Remember:** `customer_key` is the warehouse key; `customer_id` is the original business key.

## Q2. Create an order fact table

```sql
CREATE TABLE fact_orders (
    order_id INT PRIMARY KEY,
    customer_key INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key)
);
```

**Remember:** A fact row stores measures and foreign keys to dimensions.

## Q3. Load total order value into the fact table

```sql
INSERT INTO fact_orders (order_id, customer_key, order_date, total_amount)
SELECT
    o.order_id,
    d.customer_key,
    o.order_date,
    SUM(i.quantity * i.unit_price)
FROM orders o
JOIN dim_customer d
    ON d.customer_id = o.customer_id AND d.is_current = TRUE
JOIN order_items i ON i.order_id = o.order_id
GROUP BY o.order_id, d.customer_key, o.order_date;
```

**Remember:** Join the order to its current dimension row, join line items, multiply, then sum.

## Q4. Show current customers and their sales, including zero

```sql
SELECT
    d.customer_id,
    d.customer_name,
    COALESCE(SUM(f.total_amount), 0) AS total_sales
FROM dim_customer d
LEFT JOIN fact_orders f ON f.customer_key = d.customer_key
WHERE d.is_current = TRUE
GROUP BY d.customer_key, d.customer_id, d.customer_name;
```

**Remember:** `LEFT JOIN` keeps customers with no facts; `COALESCE` changes `NULL` to zero.

## Q5. Create two useful reporting indexes

```sql
CREATE INDEX idx_customer_current
ON dim_customer (customer_id, is_current);

CREATE INDEX idx_fact_order_date
ON fact_orders (order_date);
```

**Remember:** Index columns used often for joins and filters. Do not index every column.

---

# Fast Recognition Sheet

| Question wording | Easiest SQL pattern |
|---|---|
| “at least N” after grouping | `GROUP BY` + `HAVING COUNT(*) >= N` |
| “include zero” | `LEFT JOIN` + `COUNT(right.id)` or `COALESCE` |
| “no matching row” | `NOT EXISTS` or `LEFT JOIN ... IS NULL` |
| “Nth distinct value” | `DISTINCT` + `ORDER BY` + `LIMIT/OFFSET` |
| “latest row per group” | `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY date DESC)` |
| “running total” | `SUM() OVER (PARTITION BY ... ORDER BY ...)` |
| “first-ever date” | `MIN(date)` per person before joining to date range |
| “every required item” | Count distinct matches and compare with total, or double `NOT EXISTS` |
| “keep first duplicate” | `ROW_NUMBER()` and `rn = 1` |
| “drop orphan rows” | `INNER JOIN` to the valid parent table |
| “safe full refresh” | Delete old target rows, then insert again |
| “track history” | SCD Type 2: expire old version + insert new version |
| “NULL-safe compare” | MySQL `<=>` |
| “reporting model” | Dimension tables + fact table + aggregate measures |

## Final memory advice

Do not try to memorize every full query as a separate item. Memorize the small patterns in the recognition sheet, then change only the table names, column names and filter values to match the exam question.
