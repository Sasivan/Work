# SQL Test 1 + SQL Test 2 — Easiest Combined Solutions

**Purpose:** A beginner-friendly answer guide for the two original SQL assessments supplied in the ZIP files. The answers use **MySQL 8** and focus on the shortest clear solution that still satisfies the question.

- **SQL Test 1:** 17 questions, 170 marks.
  - Part A: DDL and DML (Q1–Q7).
  - Part B: Complex SELECT (Q8–Q17).
- **SQL Test 2:** 8 questions, 80 marks.
  - Staging → Intermediate → Reporting ETL.
- **Total:** 25 questions, 250 marks.

> These are model solutions, not official answer keys. Use the exact databases and table names from the assessment. Test 1 Part A and Part B use different databases. Test 2 uses three databases. The connection details in the notebooks are for a disposable local test database only.

---

# How to remember the main SQL patterns

| What the question asks | Pattern to remember |
|---|---|
| Create related tables | Parent table first, child table second, foreign key |
| Insert many rows | One `INSERT ... VALUES (...), (...);` |
| Change selected rows | `UPDATE ... SET ... WHERE ...` |
| Remove selected rows | `DELETE ... WHERE ...` |
| Get newest rows | `WHERE` → `ORDER BY ... DESC` → `LIMIT` |
| Calculate totals | `JOIN` → `GROUP BY` → `SUM` |
| Find parent with many children | Self-join → `GROUP BY` → `HAVING` |
| Find Nth distinct value | `DISTINCT` → sort descending → `LIMIT 1 OFFSET` |
| Treat two columns as one relationship | `UNION` the two directions → `GROUP BY` |
| Keep zero-match parents | `LEFT JOIN` and count a child key |
| Find first-ever date | `MIN(date)` per person, then join to dates |
| Find value as of a date | Latest row where `date <= target_date` |
| Keep rows from either side | Aggregate both sides, then `LEFT JOIN` + `UNION ALL` |
| Clean staging data | `DISTINCT` + `TRIM` + joins to remove orphans |
| Track history | Expire old version, insert new version |

# Part 1 — SQL Test 1: Fundamentals (17 questions)

## Part A — DDL and DML fundamentals

### Q1. Build the schema: `customers`, `orders`, `order_items`

Create the parent table first. The child table's foreign key must point to a table that already exists.

```sql
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    signup_date DATE NOT NULL
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
```

**Remember:** `PRIMARY KEY` identifies a row; `FOREIGN KEY` connects tables; `UNIQUE` prevents duplicates; `NOT NULL` requires a value; `CHECK` validates a rule.

### Q2. Insert customers, orders and order items

The assessment starts with an empty database, so the generated IDs are 1–5 for customers and 1–6 for orders when you insert in the requested order.

```sql
INSERT INTO customers (first_name, last_name, email, signup_date)
VALUES
('Alice', 'Johnson', 'alice.johnson@example.com', '2024-01-15'),
('Bob', 'Smith', 'bob.smith@example.com', '2024-02-20'),
('Carla', 'Diaz', 'carla.diaz@example.com', '2024-03-05'),
('David', 'Lee', 'david.lee@example.com', '2024-04-10'),
('Emma', 'Wilson', 'emma.wilson@example.com', '2024-05-22');

INSERT INTO orders (customer_id, order_date)
VALUES
(1, '2024-06-01'),
(1, '2024-06-15'),
(2, '2024-06-03'),
(3, '2024-06-10'),
(4, '2024-06-20'),
(5, '2024-06-25');

INSERT INTO order_items (order_id, product_name, quantity, unit_price)
VALUES
(1, 'Widget A', 2, 9.99),
(1, 'Widget B', 1, 19.99),
(2, 'Widget A', 3, 9.99),
(3, 'Gadget X', 1, 49.99),
(4, 'Widget B', 5, 19.99),
(4, 'Gadget X', 2, 49.99),
(5, 'Widget A', 4, 9.99),
(6, 'Gadget X', 1, 49.99),
(6, 'Widget B', 2, 19.99);
```

**Remember:** Insert parent rows first (`customers`), then orders, then order items. The child rows need valid parent IDs.

### Q3. Add a `status` column to `orders`

```sql
ALTER TABLE orders
ADD status VARCHAR(20) NOT NULL DEFAULT 'pending';
```

`DEFAULT 'pending'` gives existing rows a value when the new column is added.

### Q4. Update Alice's order statuses

```sql
UPDATE orders
SET status = 'shipped'
WHERE customer_id = 1;
```

**Remember:** `UPDATE` always needs the correct `WHERE` clause. Without it, every order would be updated.

### Q5. Delete Carla's incorrect Gadget X line

```sql
DELETE FROM order_items
WHERE order_id = 4
  AND product_name = 'Gadget X';
```

Both conditions identify the requested line. Without `WHERE`, every order item would be deleted.

### Q6. Find the three newest pending orders

```sql
SELECT order_id, customer_id, order_date, status
FROM orders
WHERE status = 'pending'
ORDER BY order_date DESC
LIMIT 3;
```

**Remember:** Filter first, sort newest first, keep three rows.

### Q7. Total spend per customer; explain PK vs FK vs UNIQUE

**Part A — query**

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spend DESC;
```

**Remember:** `JOIN` the three tables → multiply quantity by price → `SUM` per customer → sort highest first.

**Part B — written answer**

- **Primary key:** uniquely identifies each row; it cannot be `NULL`.
- **Foreign key:** makes sure a child row refers to an existing parent row. It prevents an order from referring to a customer that does not exist.
- **Unique constraint:** prevents duplicate values in the chosen column or column combination. A table can have several `UNIQUE` constraints.

---

## Part B — Complex SELECT

### Q8. Categories with at least four direct subcategories

```sql
SELECT
    p.id,
    p.name
FROM q1_categories p
JOIN q1_categories c ON c.parent_id = p.id
GROUP BY p.id, p.name
HAVING COUNT(*) >= 4;
```

**Remember:** Join the category table to itself. `c.parent_id = p.id` finds the immediate children. `HAVING` filters groups after counting.

### Q9. Third-highest distinct price; return NULL if missing

```sql
SELECT (
    SELECT DISTINCT price
    FROM q2_products
    ORDER BY price DESC
    LIMIT 1 OFFSET 2
) AS third_highest_price;
```

**Remember:** `DISTINCT` removes ties, descending order puts the largest first, and `OFFSET 2` skips the first two values. The outer `SELECT` returns `NULL` if there is no third value.

For the supplied seed data, the answer is **400**.

### Q10. User with the most collaborators

Each accepted pair is stored in only one direction. Add the reverse direction so both people get counted.

```sql
SELECT
    user_id,
    COUNT(*) AS collaborator_count
FROM (
    SELECT requester_id AS user_id, accepter_id AS collaborator_id
    FROM q3_collaboration_requests

    UNION

    SELECT accepter_id AS user_id, requester_id AS collaborator_id
    FROM q3_collaboration_requests
) AS pairs
GROUP BY user_id
ORDER BY collaborator_count DESC
LIMIT 1;
```

**Remember:** `UNION` makes both sides of each collaboration visible. Then count collaborators per user. The supplied seed data has a unique highest user.

### Q11. Swap adjacent warehouse bin labels

```sql
WITH numbered AS (
    SELECT
        id,
        label,
        ROW_NUMBER() OVER (ORDER BY id) AS rn
    FROM q4_bins
)
SELECT
    id,
    CASE
        WHEN MOD(rn, 2) = 1
            THEN COALESCE(LEAD(label) OVER (ORDER BY rn), label)
        ELSE LAG(label) OVER (ORDER BY rn)
    END AS new_label
FROM numbered
ORDER BY id;
```

**Remember:** `ROW_NUMBER()` numbers rows. Odd positions take the next label (`LEAD`); even positions take the previous label (`LAG`). `COALESCE` keeps the final odd label unchanged when there is no next row.

For the supplied five rows, the labels become: `Bravo`, `Alpha`, `Delta`, `Charlie`, `Echo`.

### Q12. Members who attended every workshop

```sql
SELECT member_id
FROM q5_attendance
GROUP BY member_id
HAVING COUNT(DISTINCT workshop_id) = (
    SELECT COUNT(*) FROM q5_workshops
);
```

**Remember:** Count each workshop only once per member. Keep members whose number of different attended workshops equals the total number of workshops.

For the supplied seed data, the members are **1 and 3**.

### Q13. Signup date and 2024 renewal count, including zero

```sql
SELECT
    s.id AS subscriber_id,
    s.signup_date,
    COUNT(r.id) AS renewals_2024
FROM q6_subscribers s
LEFT JOIN q6_renewals r
    ON r.subscriber_id = s.id
   AND r.renewal_date >= '2024-01-01'
   AND r.renewal_date < '2025-01-01'
GROUP BY s.id, s.signup_date
ORDER BY s.id;
```

**Remember:** Use `LEFT JOIN` to keep every subscriber. Put the year condition in `ON`, not `WHERE`. Count `r.id`, not `COUNT(*)`, so a subscriber with no matching renewal gets zero.

### Q14. First-time purchases by date, including dates with zero

```sql
WITH RECURSIVE dates AS (
    SELECT DATE('2026-01-31') AS day_date
    UNION ALL
    SELECT day_date + INTERVAL 1 DAY
    FROM dates
    WHERE day_date < '2026-04-01'
), first_purchase AS (
    SELECT customer_id, MIN(purchase_date) AS first_date
    FROM q7_purchases
    GROUP BY customer_id
)
SELECT
    d.day_date,
    COUNT(f.customer_id) AS first_time_customers
FROM dates d
LEFT JOIN first_purchase f
    ON f.first_date = d.day_date
GROUP BY d.day_date
ORDER BY d.day_date;
```

**Remember:** First find each customer's earliest purchase over the whole table. Then create all requested dates and `LEFT JOIN` those first dates. This keeps dates with zero customers.

**Important trap:** Do not filter purchases to the date range before finding `MIN(purchase_date)`. A customer's earlier purchase may be outside the range.

### Q15. Employee salary as of 2026-03-01

```sql
WITH RankedSalaries AS (
    SELECT 
        employee_id,
        salary,
        effective_date,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id 
            ORDER BY effective_date DESC
        ) AS rn
    FROM SalaryHistory
    WHERE effective_date <= '2026-03-01'
)
SELECT 
    employee_id,
    salary AS salary_as_of_date,
    effective_date
FROM RankedSalaries
WHERE rn = 1;

```

**Remember:** Find the newest salary change on or before the target date. If there is none, use the default `40000` with `COALESCE`.

### Q16. Total donation per donor, as a view

```sql
CREATE OR REPLACE VIEW vw_donor_totals AS
WITH totals AS (
    SELECT donor_id, SUM(amount) AS total_amount
    FROM q9_donations
    GROUP BY donor_id
)
SELECT
    d.id AS donor_id,
    d.name,
    COALESCE(t.total_amount, 0.00) AS total_donations
FROM q9_donors d
LEFT JOIN totals t ON t.donor_id = d.id;
```

Query the view:

```sql
SELECT *
FROM vw_donor_totals
ORDER BY donor_id;
```

**Remember:** The CTE calculates each donor's total. `LEFT JOIN` keeps donors with no donations. `COALESCE` changes their missing total to `0.00`.

### Q17. Reconcile payments and refunds without losing unmatched months

MySQL does not have `FULL OUTER JOIN`. First total each table by month and region. Then use a left join for payment rows and a second left join to collect refund-only rows.

```sql
WITH payments AS (
    SELECT
        DATE_FORMAT(pay_date, '%Y-%m') AS month,
        region,
        COUNT(*) AS pay_count,
        SUM(amount) AS pay_amount
    FROM q10_payments
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(pay_date, '%Y-%m'), region
), refunds AS (
    SELECT
        DATE_FORMAT(refund_date, '%Y-%m') AS month,
        region,
        COUNT(*) AS refund_count,
        SUM(amount) AS refund_amount
    FROM q10_refunds
    GROUP BY DATE_FORMAT(refund_date, '%Y-%m'), region
)

-- All payment groups, with matching refunds when they exist
SELECT
    p.month,
    p.region,
    p.pay_count,
    p.pay_amount,
    COALESCE(r.refund_count, 0) AS refund_count,
    COALESCE(r.refund_amount, 0.00) AS refund_amount
FROM payments p
LEFT JOIN refunds r
    ON r.month = p.month AND r.region = p.region

UNION ALL

-- Refund groups that had no matching payment group
SELECT
    r.month,
    r.region,
    0 AS pay_count,
    0.00 AS pay_amount,
    r.refund_count,
    r.refund_amount
FROM refunds r
LEFT JOIN payments p
    ON p.month = r.month AND p.region = r.region
WHERE p.month IS NULL

ORDER BY month, region;
```

**Remember:** A normal join loses rows that exist on only one side. `LEFT JOIN` gets all payment groups; the second half adds only refund groups missing from payments. `UNION ALL` combines the results.

---

# Part 2 — SQL Test 2: ETL Layers (8 questions)

This test has three databases:

- `sql_test3_staging`: raw data, already created and seeded.
- `sql_test3_intermediate`: cleaned relational tables you create.
- `sql_test3_reporting`: reporting dimension, fact table, and view you create.

The notebook uses SQLAlchemy for stored procedures because procedure bodies contain internal semicolons. Send the complete `CREATE PROCEDURE ... BEGIN ... END` text as **one statement** using `conn.exec_driver_sql(...)`.

## Q1. Staging inspection + intermediate DDL

### Step 1 — inspect each raw table

Run each query separately so each result is visible:

```sql
SELECT * FROM sql_test3_staging.raw_customers;
SELECT * FROM sql_test3_staging.raw_orders;
SELECT * FROM sql_test3_staging.raw_order_items;
```

Look for the exact duplicate customer row, inconsistent name casing, the `NULL` email, and orders that refer to missing customers.

### Step 2 — create the intermediate tables

Run this using the `intermediate_engine` connection:

```sql
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
```

**Remember:** Create `customers` first, then `orders`, then `order_items`. The target schemas deliberately allow `email` to be `NULL`.

## Q2. Stored procedure: staging to intermediate cleanup

The procedure must:

1. Remove the old intermediate rows so a rerun does not append duplicates.
2. Remove exact duplicate source rows using `DISTINCT`.
3. Clean names using `TRIM`, `UPPER`, and `LOWER`.
4. Keep `NULL` emails as `NULL`.
5. Drop orphan orders using an `INNER JOIN` to cleaned customers.
6. Drop order items for orders that were not loaded.

### Python + SQLAlchemy solution

Assume the notebook setup has already created `intermediate_engine`.

```python
procedure_sql = """
CREATE PROCEDURE sp_load_intermediate_from_staging()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET FOREIGN_KEY_CHECKS = 1;
        RESIGNAL;
    END;

    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE order_items;
    TRUNCATE TABLE orders;
    TRUNCATE TABLE customers;
    SET FOREIGN_KEY_CHECKS = 1;

    INSERT INTO customers
        (customer_id, first_name, last_name, email, city, signup_date)
    SELECT DISTINCT
        customer_id,
        CONCAT(UPPER(LEFT(TRIM(first_name), 1)), LOWER(SUBSTRING(TRIM(first_name), 2))),
        CONCAT(UPPER(LEFT(TRIM(last_name), 1)), LOWER(SUBSTRING(TRIM(last_name), 2))),
        email,
        city,
        signup_date
    FROM sql_test3_staging.raw_customers;

    INSERT INTO orders (order_id, customer_id, order_date, status)
    SELECT DISTINCT
        r.order_id, r.customer_id, r.order_date, r.status
    FROM sql_test3_staging.raw_orders r
    JOIN customers c ON c.customer_id = r.customer_id;

    INSERT INTO order_items
        (order_item_id, order_id, product_name, quantity, unit_price)
    SELECT DISTINCT
        i.order_item_id, i.order_id, i.product_name, i.quantity, i.unit_price
    FROM sql_test3_staging.raw_order_items i
    JOIN orders o ON o.order_id = i.order_id;
END
"""

with intermediate_engine.begin() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_load_intermediate_from_staging")
    conn.exec_driver_sql(procedure_sql)
    conn.exec_driver_sql("CALL sp_load_intermediate_from_staging()")
```

### Verify the results

```sql
SELECT COUNT(*) AS customer_count FROM customers;     -- 5
SELECT COUNT(*) AS order_count FROM orders;            -- 6
SELECT COUNT(*) AS order_item_count FROM order_items;  -- 8
```

**Why the joins work:** the customer `INNER JOIN` removes the two orders with missing customer IDs. The order-item `INNER JOIN` then removes the items belonging to those dropped orders. `DISTINCT` removes the exact duplicate customer row. The missing email remains `NULL` because the query copies it without replacing it.

**Remember:** `DISTINCT` removes duplicates; `TRIM` cleans spaces; `INNER JOIN` removes orphans; load customers → orders → items.

## Q3. Cursor procedure: customer order status history

This question specifically requires a cursor and an `IF/ELSE`, so keep the cursor pattern. The cursor reads one order at a time. The temporary table stores the rows that the procedure will return.

```python
procedure_sql = """
CREATE PROCEDURE sp_customer_order_status_history(IN p_customer_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_order_id INT;
    DECLARE v_order_date DATE;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_flag VARCHAR(20);

    DECLARE order_cursor CURSOR FOR
        SELECT
            o.order_id,
            o.order_date,
            COALESCE(SUM(i.quantity * i.unit_price), 0)
        FROM orders o
        LEFT JOIN order_items i ON i.order_id = o.order_id
        WHERE o.customer_id = p_customer_id
        GROUP BY o.order_id, o.order_date
        ORDER BY o.order_date;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_order_history;
    CREATE TEMPORARY TABLE tmp_order_history (
        order_id INT,
        order_date DATE,
        total_value DECIMAL(12,2),
        value_flag VARCHAR(20)
    );

    OPEN order_cursor;

    read_loop: LOOP
        FETCH order_cursor INTO v_order_id, v_order_date, v_total;

        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        IF v_total > 400 THEN
            SET v_flag = 'HIGH_VALUE';
        ELSE
            SET v_flag = 'STANDARD';
        END IF;

        INSERT INTO tmp_order_history
        VALUES (v_order_id, v_order_date, v_total, v_flag);
    END LOOP;

    CLOSE order_cursor;

    SELECT * FROM tmp_order_history ORDER BY order_date;
END
"""

with intermediate_engine.begin() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_customer_order_status_history")
    conn.exec_driver_sql(procedure_sql)
    conn.exec_driver_sql("CALL sp_customer_order_status_history(1)")
```

**Remember the cursor order:** declare variables → declare cursor → declare handler → open → fetch → check `done` → `IF/ELSE` → insert → close.

For customer 1 in the supplied seed data:

- Order 101 total = `125.00` → `STANDARD`.
- Order 102 total = `475.00` → `HIGH_VALUE`.

## Q4. Intermediate to reporting: star schema

### Step 1 — create the dimension and fact tables

Run using `reporting_engine`:

```sql
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    city VARCHAR(50),
    effective_date DATE NOT NULL,
    expiry_date DATE NULL,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS fact_orders (
    order_id INT PRIMARY KEY,
    customer_key INT NOT NULL,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    item_count INT NOT NULL,
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key)
);
```

### Step 2 — clear old rows before reloading

Delete child rows first, then parent rows. This respects the foreign key.

```sql
DELETE FROM fact_orders;
DELETE FROM dim_customer;
```

### Step 3 — load the customer dimension

```sql
INSERT INTO dim_customer
    (customer_id, first_name, last_name, email, city,
     effective_date, expiry_date, is_current)
SELECT
    customer_id, first_name, last_name, email, city,
    CURDATE(), NULL, TRUE
FROM sql_test3_intermediate.customers;
```

### Step 4 — load the order fact table

```sql
INSERT INTO fact_orders
    (order_id, customer_key, customer_id, order_date, status,
     total_amount, item_count)
SELECT
    o.order_id,
    d.customer_key,
    o.customer_id,
    o.order_date,
    o.status,
    COALESCE(SUM(i.quantity * i.unit_price), 0),
    COUNT(i.order_item_id)
FROM sql_test3_intermediate.orders o
JOIN dim_customer d
    ON d.customer_id = o.customer_id
   AND d.is_current = TRUE
LEFT JOIN sql_test3_intermediate.order_items i
    ON i.order_id = o.order_id
GROUP BY
    o.order_id, d.customer_key, o.customer_id,
    o.order_date, o.status;
```

**Remember:** Dimension first, fact second. The dimension stores customer details. The fact stores order measures (`total_amount`, `item_count`). The `LEFT JOIN` keeps an order even if it has no items.

**Why pre-calculate total and count?** Reports can read the order totals directly instead of joining every order to its individual line items and calculating them repeatedly.

## Q5. SCD Type 2 procedure: version customer details

This is easier with two set-based statements inside a procedure. A cursor is **not** required by this question.

- First, expire the current version if `email` or `city` changed.
- Then insert a new current version for customers who do not currently have one.
- Unchanged customers keep their current row.

```python
procedure_sql = """
CREATE PROCEDURE sp_apply_customer_scd()
BEGIN
    -- 1. Expire current rows whose email or city changed
    UPDATE dim_customer d
    JOIN sql_test3_intermediate.customers c
        ON c.customer_id = d.customer_id
    SET
        d.expiry_date = CURDATE(),
        d.is_current = FALSE
    WHERE d.is_current = TRUE
      AND (
          NOT (d.email <=> c.email)
          OR NOT (d.city <=> c.city)
      );

    -- 2. Insert customers that do not have a current version
    INSERT INTO dim_customer
        (customer_id, first_name, last_name, email, city,
         effective_date, expiry_date, is_current)
    SELECT
        c.customer_id, c.first_name, c.last_name, c.email, c.city,
        CURDATE(), NULL, TRUE
    FROM sql_test3_intermediate.customers c
    LEFT JOIN dim_customer d
        ON d.customer_id = c.customer_id
       AND d.is_current = TRUE
    WHERE d.customer_key IS NULL;
END
"""

with reporting_engine.begin() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_apply_customer_scd")
    conn.exec_driver_sql(procedure_sql)

    # Simulate the requested change for customer 2
    conn.exec_driver_sql("""
        UPDATE sql_test3_intermediate.customers
        SET city = 'Phoenix'
        WHERE customer_id = 2
    """)

    conn.exec_driver_sql("CALL sp_apply_customer_scd()")
```

Check customer 2:

```sql
SELECT
    customer_id, city, effective_date, expiry_date, is_current
FROM dim_customer
WHERE customer_id = 2
ORDER BY customer_key;
```

You should see two versions: the old city row is expired (`is_current = 0`) and the new city row is current (`is_current = 1`).

**Remember:** `UPDATE` old row → `INSERT` new row. `<=>` is MySQL's NULL-safe equality operator, so `NULL` versus a real value is detected as a change.

## Q6. View: activity for each current customer, including zero orders

```sql
CREATE OR REPLACE VIEW vw_customer_activity_summary AS
SELECT
    d.customer_id,
    CONCAT(d.first_name, ' ', d.last_name) AS customer_name,
    d.city,
    COALESCE(SUM(f.total_amount), 0.00) AS total_order_value,
    COUNT(f.order_id) AS order_count
FROM dim_customer d
LEFT JOIN fact_orders f
    ON f.customer_key = d.customer_key
WHERE d.is_current = TRUE
GROUP BY
    d.customer_key, d.customer_id,
    d.first_name, d.last_name, d.city;
```

Query the view:

```sql
SELECT *
FROM vw_customer_activity_summary
ORDER BY total_order_value DESC;
```

**Remember:** `LEFT JOIN` keeps customers with zero orders. `COALESCE` changes a missing sum to zero. Join by `customer_key` because the fact row points to a specific customer version.

## Q7. Written: which reporting indexes should be added?

A simple answer:

1. `dim_customer(customer_id, is_current)` — helps find the current version of a customer.
2. `fact_orders(order_date)` — helps reports that filter or sort by order date.
3. `fact_orders(customer_key)` — helps joins to the customer dimension. MySQL normally creates an index to support a foreign key if a suitable one does not already exist, so check before adding another one.
4. `dim_customer.customer_key` and `fact_orders.order_id` are already indexed because they are primary keys.

**Tradeoff:** Indexes make reads faster but use storage and make inserts/updates/deletes slower. Add indexes for columns used in real joins, filters, and sorting; do not index every column.

## Q8. Is Question 2 safe to run twice?

**Yes.** The procedure clears the intermediate tables and reloads them from the staging tables every time. If the same staging data is loaded twice, the second run rebuilds the same clean result instead of appending another copy.

It is called a **full refresh**. If the procedure only inserted rows without clearing or updating existing rows, a second run could create duplicates or fail on primary-key conflicts.

---

# Final revision sheet — patterns worth memorizing

## Basic query patterns

```sql
-- Filter and sort
SELECT * FROM table_name
WHERE condition
ORDER BY date_column DESC
LIMIT 3;

-- Join and total
SELECT key_column, SUM(amount)
FROM table_a a
JOIN table_b b ON b.id = a.id
GROUP BY key_column;

-- Keep unmatched parent rows
SELECT p.id, COUNT(c.id)
FROM parent p
LEFT JOIN child c ON c.parent_id = p.id
GROUP BY p.id;
```

## Advanced SELECT patterns

```sql
-- Nth distinct highest value (3rd highest)
SELECT (
    SELECT DISTINCT value_column
    FROM table_name
    ORDER BY value_column DESC
    LIMIT 1 OFFSET 2
);

-- Find members who attended every workshop
SELECT member_id
FROM attendance
GROUP BY member_id
HAVING COUNT(DISTINCT workshop_id) =
       (SELECT COUNT(*) FROM workshops);

-- Latest value as of a date
SELECT value_column
FROM history_table
WHERE person_id = wanted_id
  AND change_date <= '2026-03-01'
ORDER BY change_date DESC
LIMIT 1;
```

## ETL order

```text
STAGING (raw source)
       ↓
EXTRACT (read the source)
       ↓
TRANSFORM (dedupe, clean, remove orphans)
       ↓
INTERMEDIATE (clean relational tables)
       ↓
REPORTING (dimension + fact + views)
```

## Common mistakes to avoid

- Create parent tables before child tables.
- Never omit the `WHERE` clause from a targeted `UPDATE` or `DELETE`.
- Use `DISTINCT` when the question says distinct.
- Use `COUNT(DISTINCT ...)` when duplicate attendance rows are possible.
- Use `LEFT JOIN` when the question says include everyone, including zero matches.
- Put filters for the right-hand table in the `ON` clause when preserving unmatched left rows.
- Find first-ever dates before applying the final date range.
- For an as-of query, use the latest date `<=` the requested date.
- Aggregate each side before reconciling payment/refund tables, or multiple rows can multiply totals.
- MySQL has no `FULL OUTER JOIN`; use left join plus right-only rows with `UNION ALL`.
- Send a stored procedure as one SQLAlchemy statement; do not split its body at semicolons.
- Load parent rows before child rows when inserting into foreign-key tables.
- SCD Type 2 means expire the old version and insert the new version; never overwrite the historical row.
- Use `<=>` for NULL-safe comparisons in MySQL.
- A full-refresh ETL procedure should produce the same final tables when run twice with unchanged source data.
