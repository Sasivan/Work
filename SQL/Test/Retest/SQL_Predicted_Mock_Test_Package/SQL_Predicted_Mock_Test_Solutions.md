# SQL Predicted Mock Assessment — Complete Solutions

**Database:** MySQL 8.0  
**Questions:** 11  
**Total:** 100 points  
**Purpose:** Worked answer key for `SQL_Predicted_Mock_Test_Package/questions.ipynb`.

> This answer key matches the questions and seed data in the supplied mock-test ZIP. It is a practice solution, not an official assessment answer sheet. Run the mock package first and keep the blank `questions.ipynb` unchanged for exam practice.

## Before using these solutions

1. Start the MySQL container using the package `README.md`.
2. Run `python seed/seed_mysql.py` from the package root.
3. Open `questions.ipynb` and complete the setup cell.
4. Attempt a question first, then compare your work with the corresponding solution below.

**Important:** The seed script drops and recreates all five mock databases. Run it only against the disposable local mock container on port `3308`, never against a real database.

### Database map

| Database | Purpose | Initial state |
|---|---|---|
| `sql_mock_core` | Questions 1–3 | Empty; create your tables |
| `sql_mock_select` | Questions 4–8 | Pre-seeded question tables |
| `sql_mock_staging` | Question 9 source | Pre-seeded raw data |
| `sql_mock_intermediate` | Questions 9–10 | Empty; create clean tables |
| `sql_mock_reporting` | Questions 10–11 | Empty; create dimensions and facts |

---

# Part A — Core SQL

## Question 1 — Design a Small Sales Schema (8 points)

**Concepts:** DDL, primary keys, foreign keys, `UNIQUE`, `DEFAULT`, and `CHECK`.

Create parent tables before child tables: `customers` → `orders` → `order_items`.

```sql
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    signup_date DATE NOT NULL
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    sku VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);
```

**Why this works:**

- `PRIMARY KEY` uniquely identifies each row.
- `AUTO_INCREMENT` creates the next integer ID automatically.
- `NOT NULL` requires a value.
- `UNIQUE` prevents duplicate customer emails.
- `DEFAULT 'pending'` supplies a status when the insert omits it.
- The foreign keys enforce the parent-child relationships.
- The `CHECK` constraint rejects zero or negative quantities in supported MySQL 8.0 versions (8.0.16 and later).

**Common mistake:** Creating `orders` before `customers`, or `order_items` before `orders`, causes the referenced parent table not to exist.

---

## Question 2 — Insert Data and Make Targeted Changes (8 points)

The tables are empty immediately after the mock seed script is run. The inserts below create customer IDs 1–4 and order IDs 1–4 in the stated order.

### 2.1 Insert the customers

```sql
INSERT INTO customers (full_name, email, signup_date)
VALUES
    ('Asha Rao',  'asha@example.com', '2024-01-10'),
    ('Ben Kumar', 'ben@example.com',  '2024-02-15'),
    ('Cara Das',  'cara@example.com', '2024-03-20'),
    ('Dev Mehta', 'dev@example.com',  '2024-04-25');

SELECT * FROM customers ORDER BY customer_id;
```

### 2.2 Insert the orders

```sql
INSERT INTO orders (customer_id, order_date)
VALUES
    (1, '2026-01-05'),
    (1, '2026-02-10'),
    (2, '2026-02-15'),
    (3, '2026-03-01');

SELECT * FROM orders ORDER BY order_id;
```

`status` is omitted, so every new order receives the default value `pending`.

### 2.3 Insert the order items

Because this is a freshly seeded, empty `sql_mock_core` database, the four inserted orders have IDs 1–4.

```sql
INSERT INTO order_items (order_id, sku, quantity, unit_price)
VALUES
    (1, 'SKU-A', 2,  25.00),
    (1, 'SKU-B', 1,  75.00),
    (2, 'SKU-C', 3, 150.00),
    (2, 'SKU-A', 1,  25.00),
    (3, 'SKU-A', 2,  25.00),
    (4, 'SKU-B', 1,  75.00);

SELECT * FROM order_items ORDER BY item_id;
```

### 2.4 Update all orders belonging to customer 1

```sql
UPDATE orders
SET status = 'shipped'
WHERE customer_id = 1;

SELECT *
FROM orders
WHERE customer_id = 1;
```

### 2.5 Delete only the SKU-B line from order 4

```sql
DELETE FROM order_items
WHERE order_id = 4
  AND sku = 'SKU-B';

SELECT *
FROM order_items
WHERE order_id = 4;
```

The order itself remains in `orders`. It now has no order-item rows.

**Final expected state:** 4 customers, 4 orders, and 5 order items. Orders 1 and 2 are `shipped`; orders 3 and 4 remain `pending`.

**Common mistake:** Omitting the `WHERE` clause from `UPDATE` or `DELETE` changes or deletes every row. Also, do not assume the IDs above if you have inserted other data already; reset the mock database before attempting the question again.

---

## Question 3 — Revenue per Customer, Including Customers with No Orders (8 points)

**Concepts:** `LEFT JOIN`, aggregation, `COUNT(DISTINCT ...)`, and `COALESCE`.

```sql
SELECT
    c.customer_id,
    c.full_name,
    CAST(COALESCE(SUM(oi.quantity * oi.unit_price), 0.00) AS DECIMAL(10,2)) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.customer_id
LEFT JOIN order_items AS oi
    ON oi.order_id = o.order_id
GROUP BY
    c.customer_id,
    c.full_name
ORDER BY
    total_revenue DESC,
    c.customer_id;
```

**Expected result after Question 2:**

| customer_id | full_name | total_revenue | order_count |
|---:|---|---:|---:|
| 1 | Asha Rao | 600.00 | 2 |
| 2 | Ben Kumar | 50.00 | 1 |
| 3 | Cara Das | 0.00 | 1 |
| 4 | Dev Mehta | 0.00 | 0 |

**Why `COUNT(DISTINCT o.order_id)` matters:** Joining an order to multiple order items repeats the order row. A simple `COUNT(o.order_id)` would count an order more than once. `COUNT(DISTINCT ...)` counts each order once.

**Why `LEFT JOIN` matters:** It preserves customers who have no orders. `COALESCE` changes the resulting `NULL` revenue to zero.

---

## Question 4 — Keep the First Sign-up for Each Normalized Email (8 points)

**Concepts:** CTE, email normalization, and `ROW_NUMBER()`.

```sql
WITH ranked_signups AS (
    SELECT
        signup_id,
        LOWER(TRIM(email)) AS normalized_email,
        source_name,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(email))
            ORDER BY signup_id
        ) AS rn
    FROM q1_email_signups
)
SELECT
    signup_id,
    normalized_email,
    source_name
FROM ranked_signups
WHERE rn = 1
ORDER BY signup_id;
```

**Expected result:**

| signup_id | normalized_email | source_name |
|---:|---|---|
| 1 | asha@example.com | web |
| 2 | ben@example.com | mobile |
| 4 | cara@example.com | web |
| 6 | dev@example.com | mobile |

**Remember:** `LOWER(TRIM(email))` forms the duplicate key. `ROW_NUMBER()` assigns 1 to the smallest `signup_id` within each normalized email group. The source table is not changed.

---

# Part B — Advanced SQL

## Question 5 — Categories with at Least Five Direct Subcategories (8 points)

**Concepts:** Self-join, `GROUP BY`, and `HAVING`.

```sql
SELECT
    parent.id,
    parent.name,
    COUNT(child.id) AS direct_child_count
FROM q2_categories AS parent
JOIN q2_categories AS child
    ON child.parent_id = parent.id
GROUP BY
    parent.id,
    parent.name
HAVING COUNT(child.id) >= 5
ORDER BY parent.id;
```

**Expected result:**

| id | name | direct_child_count |
|---:|---|---:|
| 1 | Electronics | 6 |

**Why this counts direct children only:** The join checks `child.parent_id = parent.id`. It does not recursively follow descendants, so grandchildren are not included.

**Common mistake:** Using `WHERE COUNT(...) >= 5`. Aggregate conditions belong in `HAVING`, after grouping.

---

## Question 6 — Third-Highest Distinct Product Price (8 points)

**Concepts:** `DISTINCT`, sorting, `LIMIT`, and scalar subqueries.

```sql
SELECT (
    SELECT DISTINCT price
    FROM q3_prices
    ORDER BY price DESC
    LIMIT 1 OFFSET 2
) AS third_highest_distinct_price;
```

**Expected result:**

| third_highest_distinct_price |
|---:|
| 600.00 |

**Why it works:** `DISTINCT` removes repeated prices first. `ORDER BY price DESC` ranks the unique prices from highest to lowest. `OFFSET 2` skips the first two. If fewer than three distinct prices exist, the scalar subquery returns no row and the outer query returns one row containing `NULL`.

---

## Question 7 — Members Who Attended Every Workshop (8 points)

**Concept:** Relational division using nested `NOT EXISTS`.

```sql
SELECT m.member_id
FROM q4_members AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM q4_workshops AS w
    WHERE NOT EXISTS (
        SELECT 1
        FROM q4_attendance AS a
        WHERE a.member_id = m.member_id
          AND a.workshop_id = w.workshop_id
    )
)
ORDER BY m.member_id;
```

**Expected result:**

| member_id |
|---:|
| 1 |
| 3 |

**Read the query in plain English:** Return a member for whom there does not exist a workshop that they did not attend. This means they attended every workshop at least once.

**Why duplicate attendance does not matter:** The inner condition uses `EXISTS`; one matching attendance is enough. Extra duplicate attendance rows do not change the answer.

---

## Question 8 — First-Ever Purchases by Day, Including Zero Days (8 points)

**Concepts:** Recursive CTE date spine, `MIN()`, and `LEFT JOIN`.

```sql
WITH RECURSIVE date_spine AS (
    SELECT DATE('2026-03-27') AS purchase_day

    UNION ALL

    SELECT DATE_ADD(purchase_day, INTERVAL 1 DAY)
    FROM date_spine
    WHERE purchase_day < DATE('2026-04-01')
),
first_purchase AS (
    SELECT
        customer_id,
        MIN(purchase_date) AS first_purchase_date
    FROM q5_purchases
    GROUP BY customer_id
)
SELECT
    d.purchase_day,
    COUNT(fp.customer_id) AS new_customers
FROM date_spine AS d
LEFT JOIN first_purchase AS fp
    ON fp.first_purchase_date = d.purchase_day
GROUP BY d.purchase_day
ORDER BY d.purchase_day;
```

**Expected result:**

| purchase_day | new_customers |
|---|---:|
| 2026-03-27 | 1 |
| 2026-03-28 | 1 |
| 2026-03-29 | 1 |
| 2026-03-30 | 0 |
| 2026-03-31 | 0 |
| 2026-04-01 | 1 |

**Important:** Calculate the first purchase from the entire `q5_purchases` table before joining to the requested date range. Customer 3 first purchased on 2026-03-25, so the purchase on 2026-03-31 is not a new customer.

**Why `LEFT JOIN` matters:** It preserves every generated calendar date, including dates where no customer has their first purchase.

---

# Part C — ETL and Reporting

## Question 9 — Staging to Intermediate: Clean and Reload Safely (12 points)

**Concepts:** ETL layers, exact duplicate removal, normalization, referential integrity, stored procedures, and idempotency.

The staging tables are already seeded. Create clean tables in `sql_mock_intermediate`, then create a procedure that performs a full refresh.

### 9.1 Inspect the staging source tables

Run this in a normal Python cell:

```python
from sqlalchemy import text
import pandas as pd

for table_name in ["raw_customers", "raw_orders", "raw_order_items"]:
    print(f"\n--- {table_name} ---")
    display(pd.read_sql(text(f"SELECT * FROM {table_name}"), staging_engine))
```

The provided seed data has:

- 6 raw customer rows, including one exact duplicate customer row;
- 7 raw orders, including order `299` for missing customer `99`;
- 9 raw order-item rows, including an item for orphan order `299`.

### 9.2 Create the intermediate tables

```python
intermediate_ddl = [
    """
    CREATE TABLE IF NOT EXISTS customers (
        customer_id INT PRIMARY KEY,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(100) NULL,
        city VARCHAR(50) NULL,
        signup_date DATE NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS orders (
        order_id INT PRIMARY KEY,
        customer_id INT NOT NULL,
        order_date DATE NOT NULL,
        status VARCHAR(20) NOT NULL,
        CONSTRAINT fk_intermediate_orders_customer
            FOREIGN KEY (customer_id)
            REFERENCES customers(customer_id)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS order_items (
        order_item_id INT PRIMARY KEY,
        order_id INT NOT NULL,
        product_name VARCHAR(100) NOT NULL,
        quantity INT NOT NULL,
        unit_price DECIMAL(10,2) NOT NULL,
        CONSTRAINT fk_intermediate_items_order
            FOREIGN KEY (order_id)
            REFERENCES orders(order_id)
    )
    """
]

with intermediate_engine.begin() as conn:
    for statement in intermediate_ddl:
        conn.exec_driver_sql(statement)
```

### 9.3 Create the full-refresh procedure

Use `exec_driver_sql()` for the whole `CREATE PROCEDURE` statement. Do not add the MySQL command-line `DELIMITER` directive; `DELIMITER` is a client command, not part of the SQL sent by SQLAlchemy.

```python
procedure_sql = """
CREATE PROCEDURE sp_load_mock_intermediate()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET FOREIGN_KEY_CHECKS = 1;
        RESIGNAL;
    END;

    -- Clear child tables before parent tables.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE order_items;
    TRUNCATE TABLE orders;
    TRUNCATE TABLE customers;
    SET FOREIGN_KEY_CHECKS = 1;

    -- Customers: remove exact duplicate source rows and normalize names.
    INSERT INTO customers (
        customer_id, first_name, last_name, email, city, signup_date
    )
    SELECT DISTINCT
        customer_id,
        CONCAT(
            UPPER(LEFT(TRIM(first_name), 1)),
            LOWER(SUBSTRING(TRIM(first_name), 2))
        ),
        CONCAT(
            UPPER(LEFT(TRIM(last_name), 1)),
            LOWER(SUBSTRING(TRIM(last_name), 2))
        ),
        email,
        city,
        signup_date
    FROM sql_mock_staging.raw_customers;

    -- Orders: the INNER JOIN drops orders with no cleaned customer.
    INSERT INTO orders (order_id, customer_id, order_date, status)
    SELECT DISTINCT
        ro.order_id,
        ro.customer_id,
        ro.order_date,
        ro.status
    FROM sql_mock_staging.raw_orders AS ro
    INNER JOIN customers AS c
        ON c.customer_id = ro.customer_id;

    -- Order items: the INNER JOIN drops items for orders that did not survive.
    INSERT INTO order_items (
        order_item_id, order_id, product_name, quantity, unit_price
    )
    SELECT DISTINCT
        ri.order_item_id,
        ri.order_id,
        ri.product_name,
        ri.quantity,
        ri.unit_price
    FROM sql_mock_staging.raw_order_items AS ri
    INNER JOIN orders AS o
        ON o.order_id = ri.order_id;
END
"""

with intermediate_engine.connect() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_load_mock_intermediate")
    conn.exec_driver_sql(procedure_sql)
    conn.commit()
```

### 9.4 Call the procedure twice and compare row counts

```python
def get_intermediate_counts(conn):
    counts = {}
    for table_name in ["customers", "orders", "order_items"]:
        counts[table_name] = conn.exec_driver_sql(
            f"SELECT COUNT(*) FROM {table_name}"
        ).scalar_one()
    return counts

with intermediate_engine.connect() as conn:
    conn.exec_driver_sql("CALL sp_load_mock_intermediate()")
    conn.commit()
    first_run = get_intermediate_counts(conn)
    print("After first run:", first_run)

    conn.exec_driver_sql("CALL sp_load_mock_intermediate()")
    conn.commit()
    second_run = get_intermediate_counts(conn)
    print("After second run:", second_run)

assert first_run == second_run
```

**Expected counts after both runs:**

| Table | Expected rows | Reason |
|---|---:|---|
| `customers` | 5 | 6 raw rows minus one exact duplicate |
| `orders` | 6 | 7 raw rows minus orphan order 299 |
| `order_items` | 8 | 9 raw rows minus the item belonging to orphan order 299 |

**What makes this idempotent:** The procedure clears the target tables and reloads them from the unchanged source. The second run produces the same contents and row counts rather than appending duplicates.

**Normalization examples:** `ASHA` → `Asha`, `SHARMA` → `Sharma`, `ben` → `Ben`, and `kumar` → `Kumar`. The `NULL` email for customer 3 remains `NULL` because the query inserts the source value directly.

**Common mistakes:**

- Loading `raw_orders` without joining to cleaned customers leaves an orphan order.
- Loading all raw order items without joining to the cleaned orders leaves an orphan item.
- Using `SELECT DISTINCT` only on the ID would not mean exact source-row deduplication; the solution applies it to the selected source fields.
- Truncating a parent before its child can fail with foreign-key checks enabled.

---

## Question 10 — Build and Load the Reporting Star Schema (12 points)

**Concepts:** Dimension and fact tables, surrogate keys, aggregation, and safe reload.

### 10.1 Create the dimension and fact tables

```python
reporting_ddl = [
    """
    CREATE TABLE IF NOT EXISTS dim_customer (
        customer_key INT AUTO_INCREMENT PRIMARY KEY,
        customer_id INT NOT NULL,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(100) NULL,
        city VARCHAR(50) NULL,
        effective_date DATE NOT NULL,
        expiry_date DATE NULL,
        is_current BOOLEAN NOT NULL DEFAULT TRUE,
        INDEX idx_dim_customer_current (customer_id, is_current)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS fact_orders (
        order_id INT PRIMARY KEY,
        customer_key INT NOT NULL,
        customer_id INT NOT NULL,
        order_date DATE NOT NULL,
        status VARCHAR(20) NOT NULL,
        total_amount DECIMAL(10,2) NOT NULL,
        item_count INT NOT NULL,
        CONSTRAINT fk_fact_orders_customer
            FOREIGN KEY (customer_key)
            REFERENCES dim_customer(customer_key)
    )
    """
]

with reporting_engine.begin() as conn:
    for statement in reporting_ddl:
        conn.exec_driver_sql(statement)
```

### 10.2 Reset and load the dimension first, then the fact

The following uses the requested full-refresh strategy. It temporarily disables foreign-key checks for the truncate operations, clears the fact child table before the dimension parent table, then restores checks.

```python
with reporting_engine.connect() as conn:
    try:
        conn.exec_driver_sql("SET FOREIGN_KEY_CHECKS = 0")
        conn.commit()

        conn.exec_driver_sql("TRUNCATE TABLE fact_orders")
        conn.commit()

        conn.exec_driver_sql("TRUNCATE TABLE dim_customer")
        conn.commit()
    finally:
        conn.exec_driver_sql("SET FOREIGN_KEY_CHECKS = 1")
        conn.commit()

    # Dimension: one current row per intermediate customer.
    conn.exec_driver_sql("""
        INSERT INTO dim_customer (
            customer_id, first_name, last_name, email, city,
            effective_date, expiry_date, is_current
        )
        SELECT
            customer_id,
            first_name,
            last_name,
            email,
            city,
            COALESCE(signup_date, CURDATE()),
            NULL,
            TRUE
        FROM sql_mock_intermediate.customers
    """)
    conn.commit()

    # Fact: one row per intermediate order.
    conn.exec_driver_sql("""
        INSERT INTO fact_orders (
            order_id, customer_key, customer_id, order_date,
            status, total_amount, item_count
        )
        SELECT
            o.order_id,
            d.customer_key,
            o.customer_id,
            o.order_date,
            o.status,
            COALESCE(SUM(oi.quantity * oi.unit_price), 0.00),
            COUNT(oi.order_item_id)
        FROM sql_mock_intermediate.orders AS o
        INNER JOIN dim_customer AS d
            ON d.customer_id = o.customer_id
           AND d.is_current = TRUE
        LEFT JOIN sql_mock_intermediate.order_items AS oi
            ON oi.order_id = o.order_id
        GROUP BY
            o.order_id,
            d.customer_key,
            o.customer_id,
            o.order_date,
            o.status
    """)
    conn.commit()
```

### 10.3 Verify the row counts and inspect the fact rows

```python
with reporting_engine.connect() as conn:
    dimension_count = conn.exec_driver_sql(
        "SELECT COUNT(*) FROM dim_customer"
    ).scalar_one()
    fact_count = conn.exec_driver_sql(
        "SELECT COUNT(*) FROM fact_orders"
    ).scalar_one()

    print("Dimension rows:", dimension_count)
    print("Fact rows:", fact_count)

    display(pd.read_sql(
        text("SELECT * FROM fact_orders ORDER BY order_id"), conn
    ))

assert dimension_count == 5
assert fact_count == 6
```

**Expected counts:** 5 dimension rows and 6 fact rows.

**Expected fact values:**

| order_id | customer_id | total_amount | item_count |
|---:|---:|---:|---:|
| 201 | 1 | 125.00 | 2 |
| 202 | 1 | 475.00 | 2 |
| 203 | 2 | 50.00 | 1 |
| 204 | 3 | 75.00 | 1 |
| 205 | 4 | 300.00 | 1 |
| 206 | 5 | 25.00 | 1 |

**Why `LEFT JOIN` is used for the order items:** An order with no item rows must still produce a fact row. `COALESCE` sets its total to zero, and `COUNT(oi.order_item_id)` sets the item count to zero.

**Why the dimension is loaded first:** Each fact row stores a `customer_key` that must already exist in `dim_customer`.

---

## Question 11 — SCD Type 2 and Current-Customer Activity View (12 points)

**Concepts:** Historical dimension versions, NULL-safe comparison, surrogate-key joins, and views.

### 11.1 Create the SCD Type 2 procedure

The tracked attributes are `email` and `city`. The MySQL `<=>` operator compares nullable values safely: it returns true when both sides are `NULL`.

```python
scd_procedure_sql = """
CREATE PROCEDURE sp_apply_mock_customer_scd()
BEGIN
    -- Expire the current version when email or city changed.
    UPDATE dim_customer AS d
    INNER JOIN sql_mock_intermediate.customers AS c
        ON c.customer_id = d.customer_id
    SET
        d.expiry_date = CURDATE(),
        d.is_current = FALSE
    WHERE d.is_current = TRUE
      AND (
          NOT (d.email <=> c.email)
          OR NOT (d.city <=> c.city)
      );

    -- Insert a new current version when there is no current row.
    -- This includes customers whose old version was just expired above.
    INSERT INTO dim_customer (
        customer_id, first_name, last_name, email, city,
        effective_date, expiry_date, is_current
    )
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.city,
        CURDATE(),
        NULL,
        TRUE
    FROM sql_mock_intermediate.customers AS c
    LEFT JOIN dim_customer AS d
        ON d.customer_id = c.customer_id
       AND d.is_current = TRUE
    WHERE d.customer_key IS NULL;
END
"""

with reporting_engine.connect() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_apply_mock_customer_scd")
    conn.exec_driver_sql(scd_procedure_sql)
    conn.commit()
```

### 11.2 Change customer 2's city and call the procedure

The question does not prescribe the new city. Use `Noida` as the example value; any different city value demonstrates the same change-detection behavior.

```python
with intermediate_engine.begin() as conn:
    conn.execute(
        text("""
            UPDATE customers
            SET city = :new_city
            WHERE customer_id = :customer_id
        """),
        {"new_city": "Noida", "customer_id": 2}
    )

with reporting_engine.connect() as conn:
    conn.exec_driver_sql("CALL sp_apply_mock_customer_scd()")
    conn.commit()
```

### 11.3 Verify the two versions for customer 2

```sql
SELECT
    customer_key,
    customer_id,
    city,
    effective_date,
    expiry_date,
    is_current
FROM dim_customer
WHERE customer_id = 2
ORDER BY customer_key;
```

Expected shape (the generated surrogate key and run date depend on the database run):

| customer_id | city | expiry_date | is_current |
|---:|---|---|---|
| 2 | Delhi | today's date | 0 |
| 2 | Noida | NULL | 1 |

The former row is retained as history and marked not current. A new row is inserted for the changed city.

**Common mistake:** Using `d.email <> c.email` does not correctly detect all changes involving `NULL`. Use `NOT (d.email <=> c.email)` and the same check for `city`.

### 11.4 Create the current-customer activity view

```sql
CREATE OR REPLACE VIEW vw_mock_customer_activity AS
SELECT
    d.customer_key,
    d.customer_id,
    d.first_name,
    d.last_name,
    d.email,
    d.city,
    COALESCE(SUM(f.total_amount), 0.00) AS total_order_amount,
    COUNT(f.order_id) AS order_count
FROM dim_customer AS d
LEFT JOIN fact_orders AS f
    ON f.customer_key = d.customer_key
WHERE d.is_current = TRUE
GROUP BY
    d.customer_key,
    d.customer_id,
    d.first_name,
    d.last_name,
    d.email,
    d.city;
```

Create it in Python if you prefer:

```python
with reporting_engine.begin() as conn:
    conn.exec_driver_sql("""
        CREATE OR REPLACE VIEW vw_mock_customer_activity AS
        SELECT
            d.customer_key,
            d.customer_id,
            d.first_name,
            d.last_name,
            d.email,
            d.city,
            COALESCE(SUM(f.total_amount), 0.00) AS total_order_amount,
            COUNT(f.order_id) AS order_count
        FROM dim_customer AS d
        LEFT JOIN fact_orders AS f
            ON f.customer_key = d.customer_key
        WHERE d.is_current = TRUE
        GROUP BY
            d.customer_key,
            d.customer_id,
            d.first_name,
            d.last_name,
            d.email,
            d.city
    """)
```

### 11.5 Query the view

```sql
SELECT *
FROM vw_mock_customer_activity
ORDER BY total_order_amount DESC, customer_id;
```

**Expected behavior:** The view returns one row for each of the five current customers. It includes zero-order current customers because the fact join is a `LEFT JOIN`.

**Important surrogate-key detail:** Customer 2's existing order fact still references the old, expired `customer_key`. The new current customer version has a new key, so its current-row activity is zero until new facts are loaded against that new key. This is expected when the view joins on `customer_key`, as the question requires. Do not join only on `customer_id` to make the historical fact appear under the new dimension version.

---

# Final expected-results checklist

| Question | Main check | Expected result |
|---|---|---|
| 1 | Tables created | 3 tables, parent-first foreign keys |
| 2 | DML complete | 4 customers, 4 orders, 5 order-item rows |
| 3 | Revenue aggregation | Asha 600; Ben 50; Cara 0; Dev 0 |
| 4 | Earliest normalized email | Signup IDs 1, 2, 4, 6 |
| 5 | Five or more direct children | Electronics, count 6 |
| 6 | Third-highest distinct price | 600.00 |
| 7 | Attended every workshop | Member IDs 1 and 3 |
| 8 | New customers by date | 1, 1, 1, 0, 0, 1 |
| 9 | Clean full refresh | Customers 5, orders 6, items 8 after each run |
| 10 | Star schema | Dimension 5, fact 6 |
| 11 | SCD2 and view | Customer 2 has one expired and one current version; view contains five current customers |

## Patterns worth memorizing

| Pattern | Reusable SQL shape |
|---|---|
| Keep unmatched parent rows | `LEFT JOIN` from the parent table |
| Turn missing aggregates into zero | `COALESCE(SUM(...), 0)` |
| Count orders after joining order items | `COUNT(DISTINCT order_id)` |
| Keep first duplicate | `ROW_NUMBER() OVER (PARTITION BY key ORDER BY id)` then `WHERE rn = 1` |
| Filter grouped results | `HAVING`, not `WHERE` |
| Return third distinct value | `SELECT DISTINCT ... ORDER BY ... LIMIT 1 OFFSET 2` |
| Find rows matching every required row | Double `NOT EXISTS` |
| Include dates with no activity | Recursive date CTE + `LEFT JOIN` |
| Remove orphan child rows | `INSERT ... SELECT` with an `INNER JOIN` to valid parent rows |
| Make a full refresh repeat-safe | Clear targets in child-first order, then reload |
| Preserve historical dimension changes | Expire old SCD2 row and insert a new current row |
| Compare nullable columns | MySQL NULL-safe equality: `<=>` |
| Join facts to a dimension version | Use the surrogate key (`customer_key`) |

---

**End of solution guide.**
