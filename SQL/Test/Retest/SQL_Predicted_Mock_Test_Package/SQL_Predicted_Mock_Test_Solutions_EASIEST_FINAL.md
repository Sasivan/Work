# SQL Predicted Mock Test — Easiest Solutions (Final)

**Database:** MySQL 8.0  
**Questions:** 11  
**Marks:** 100  
**Matches:** `SQL_Predicted_Mock_Test_Package/questions.ipynb`

This version has been simplified for exam preparation. It uses the shortest clear solution that still meets each question's requirements. Longer production-style error handlers and unnecessary helper code have been removed. The required SQL patterns—deduplication, self-joins, date spines, ETL, stored procedures, star schema and SCD Type 2—are retained.

> Run the mock package's seed script before practising. It resets the five disposable databases, so use it only with the local mock MySQL container on port 3308. The notebook setup cell creates `staging_engine`, `intermediate_engine`, and `reporting_engine` for the examples below.

## Database map

| Database | Used by | Starting state |
|---|---|---|
| `sql_mock_core` | Questions 1–3 | Empty; create your own tables |
| `sql_mock_select` | Questions 4–8 | Pre-seeded question data |
| `sql_mock_staging` | Question 9 source | Pre-seeded raw data |
| `sql_mock_intermediate` | Questions 9–10 | Empty; create clean tables |
| `sql_mock_reporting` | Questions 10–11 | Empty; create dimension and fact tables |

---

# Part A — Core SQL

## Question 1 — Design a Small Sales Schema (8 points)

**Pattern:** Create parent tables before child tables; use primary keys, foreign keys, `UNIQUE`, `DEFAULT` and `CHECK`.

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
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    sku VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
```

**Easy way to remember:**

1. Create `customers` first.
2. Create `orders` because it references customers.
3. Create `order_items` because it references orders.

`PRIMARY KEY` identifies a row; `FOREIGN KEY` connects tables; `UNIQUE` prevents duplicates; `DEFAULT` supplies a value; `CHECK` validates a value.

---

## Question 2 — Insert Data and Make Targeted Changes (8 points)

Use the tables from Question 1. Run these as separate cells, as requested in the notebook.

### 2.1 Insert customers

```sql
INSERT INTO customers (full_name, email, signup_date)
VALUES
    ('Asha Rao',  'asha@example.com', '2024-01-10'),
    ('Ben Kumar', 'ben@example.com',  '2024-02-15'),
    ('Cara Das',  'cara@example.com', '2024-03-20'),
    ('Dev Mehta', 'dev@example.com', '2024-04-25');
```

### 2.2 Insert orders

```sql
INSERT INTO orders (customer_id, order_date)
VALUES
    (1, '2026-01-05'),
    (1, '2026-02-10'),
    (2, '2026-02-15'),
    (3, '2026-03-01');
```

`status` is not supplied, so MySQL uses its default value, `pending`.

### 2.3 Insert order items

```sql
INSERT INTO order_items (order_id, sku, quantity, unit_price)
VALUES
    (1, 'SKU-A', 2,  25.00),
    (1, 'SKU-B', 1,  75.00),
    (2, 'SKU-C', 3, 150.00),
    (2, 'SKU-A', 1,  25.00),
    (3, 'SKU-A', 2,  25.00),
    (4, 'SKU-B', 1,  75.00);
```

### 2.4 Mark customer 1's orders as shipped

```sql
UPDATE orders
SET status = 'shipped'
WHERE customer_id = 1;
```

### 2.5 Delete only the SKU-B item from order 4

```sql
DELETE FROM order_items
WHERE order_id = 4 AND sku = 'SKU-B';
```

### 2.6 Check the final data

```sql
SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM order_items;
```

**Expected final row counts:** 4 customers, 4 orders and 5 order items. Orders 1 and 2 are `shipped`; orders 3 and 4 remain `pending`.

**Remember:** `INSERT` adds rows, `UPDATE` changes matching rows, and `DELETE` removes matching rows. Always check the `WHERE` condition before running an update or delete.

---

## Question 3 — Revenue per Customer, Including Customers with No Orders (8 points)

**Pattern:** `LEFT JOIN` + `SUM` + `COUNT(DISTINCT)` + `COALESCE`.

```sql
SELECT
    c.customer_id,
    c.full_name,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0.00) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_revenue DESC, c.customer_id;
```

**Expected result after Question 2:**

| customer_id | full_name | total_revenue | order_count |
|---:|---|---:|---:|
| 1 | Asha Rao | 600.00 | 2 |
| 2 | Ben Kumar | 50.00 | 1 |
| 3 | Cara Das | 0.00 | 1 |
| 4 | Dev Mehta | 0.00 | 0 |

**Why these three expressions matter:**

- `LEFT JOIN` keeps customers with no orders.
- `COALESCE(..., 0)` displays zero instead of `NULL` revenue.
- `COUNT(DISTINCT o.order_id)` counts an order once even when it has several item rows.

**Remember:** When a question says “include zero,” start by thinking `LEFT JOIN`.

---

# Part B — Advanced SQL

## Question 4 — Keep the First Sign-up for Each Normalized Email (8 points)

**Pattern:** Normalize the email, number duplicates, keep row number 1.

```sql
WITH ranked AS (
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
SELECT signup_id, normalized_email, source_name
FROM ranked
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

**Remember:** `LOWER(TRIM(email))` makes the duplicate key; `ROW_NUMBER()` gives the first row number 1; `WHERE rn = 1` keeps it. The original table is unchanged.

---

## Question 5 — Categories with at Least Five Direct Subcategories (8 points)

**Pattern:** Self-join + `GROUP BY` + `HAVING`.

```sql
SELECT
    p.id,
    p.name,
    COUNT(c.id) AS direct_child_count
FROM q2_categories p
JOIN q2_categories c ON c.parent_id = p.id
GROUP BY p.id, p.name
HAVING COUNT(c.id) >= 5
ORDER BY p.id;
```

**Expected result:**

| id | name | direct_child_count |
|---:|---|---:|
| 1 | Electronics | 6 |

**Why it counts direct children only:** The join uses `c.parent_id = p.id`. It does not travel down to grandchildren.

**Remember:** Join the table to itself, count child IDs, then filter the count using `HAVING`.

---

## Question 6 — Third-Highest Distinct Product Price (8 points)

**Simplest pattern:** `DISTINCT` + descending sort + `LIMIT/OFFSET`.

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

**Why it works:** `DISTINCT` removes repeated prices. `DESC` puts the highest first. `OFFSET 2` skips the first two distinct prices.

**Important:** The outer `SELECT` ensures exactly one result row. If there are fewer than three distinct prices, the value is `NULL`.

---

## Question 7 — Members Who Attended Every Workshop (8 points)

**Easier pattern:** Count each member's distinct workshops and compare with the total number of workshops.

```sql
SELECT member_id
FROM q4_attendance
GROUP BY member_id
HAVING COUNT(DISTINCT workshop_id) = (
    SELECT COUNT(*) FROM q4_workshops
)
ORDER BY member_id;
```

**Expected result:**

| member_id |
|---:|
| 1 |
| 3 |

**Why it works:** A member qualifies when their number of distinct attended workshops equals the total number of workshops. `DISTINCT` prevents duplicate attendance from increasing the count.

**Remember:** “Attended every workshop” → count distinct attended workshops = count of all workshops.

**If the assessment explicitly requires `NOT EXISTS`:** use the equivalent relational-division pattern below.

```sql
SELECT m.member_id
FROM q4_members m
WHERE NOT EXISTS (
    SELECT 1
    FROM q4_workshops w
    WHERE NOT EXISTS (
        SELECT 1
        FROM q4_attendance a
        WHERE a.member_id = m.member_id
          AND a.workshop_id = w.workshop_id
    )
)
ORDER BY m.member_id;
```

Read it as: “There is no workshop that this member did not attend.”

---

## Question 8 — First-Ever Purchases by Day, Including Zero Days (8 points)

The reporting range is 27 March 2026 through 1 April 2026.

**Pattern:** Generate dates, find first purchase per customer, then `LEFT JOIN`.

```sql
WITH RECURSIVE dates AS (
    SELECT DATE('2026-03-27') AS d
    UNION ALL
    SELECT d + INTERVAL 1 DAY
    FROM dates
    WHERE d < '2026-04-01'
), first_purchase AS (
    SELECT customer_id, MIN(purchase_date) AS first_date
    FROM q5_purchases
    GROUP BY customer_id
)
SELECT
    dates.d AS purchase_day,
    COUNT(first_purchase.customer_id) AS new_customers
FROM dates
LEFT JOIN first_purchase
    ON first_purchase.first_date = dates.d
GROUP BY dates.d
ORDER BY dates.d;
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

**Important:** Calculate `MIN(purchase_date)` from the entire purchases table before joining to the reporting dates. Customer 3 first purchased on 25 March, so their purchase on 31 March is not a new customer.

**Remember:** First purchase = `MIN(date)`; include empty days = date list + `LEFT JOIN`.

---

# Part C — ETL and Reporting

## Question 9 — Staging to Intermediate: Clean and Reload Safely (12 points)

**Pattern:** Create clean tables → full refresh → remove duplicates → normalize → drop orphans → run twice.

The source tables are already seeded in `sql_mock_staging`. First inspect them:

```python
from sqlalchemy import text
import pandas as pd

for table in ["raw_customers", "raw_orders", "raw_order_items"]:
    print("---", table, "---")
    display(pd.read_sql(text(f"SELECT * FROM {table}"), staging_engine))
```

The seed contains 6 customer rows (one exact duplicate), 7 orders (one orphan order 299), and 9 order items (one item belongs to orphan order 299).

### 9.1 Create the three intermediate tables

```python
ddl = [
    """CREATE TABLE IF NOT EXISTS customers (
        customer_id INT PRIMARY KEY,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(100), city VARCHAR(50), signup_date DATE
    )""",
    """CREATE TABLE IF NOT EXISTS orders (
        order_id INT PRIMARY KEY,
        customer_id INT NOT NULL,
        order_date DATE NOT NULL,
        status VARCHAR(20) NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    )""",
    """CREATE TABLE IF NOT EXISTS order_items (
        order_item_id INT PRIMARY KEY,
        order_id INT NOT NULL,
        product_name VARCHAR(100) NOT NULL,
        quantity INT NOT NULL,
        unit_price DECIMAL(10,2) NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
    )"""
]

with intermediate_engine.begin() as conn:
    for sql in ddl:
        conn.exec_driver_sql(sql)
```

### 9.2 Create the full-refresh procedure

**Important MySQL 8 correction:** The notebook's instruction to disable `FOREIGN_KEY_CHECKS` and then `TRUNCATE` these linked InnoDB tables is not valid. MySQL still rejects `TRUNCATE` on a table referenced by another table's foreign key, even when checks are disabled. The easiest working full refresh is `DELETE` in child-first order. See the [MySQL 8 TRUNCATE documentation](https://dev.mysql.com/doc/refman/8.0/en/truncate-table.html).

**Easy-to-remember procedure:** delete child rows → delete parent rows → load customers → load orders → load items.

```python
procedure_sql = """
CREATE PROCEDURE sp_load_mock_intermediate()
BEGIN
    DELETE FROM order_items;
    DELETE FROM orders;
    DELETE FROM customers;

    INSERT INTO customers
        (customer_id, first_name, last_name, email, city, signup_date)
    SELECT DISTINCT
        customer_id,
        CONCAT(UPPER(LEFT(TRIM(first_name), 1)),
               LOWER(SUBSTRING(TRIM(first_name), 2))),
        CONCAT(UPPER(LEFT(TRIM(last_name), 1)),
               LOWER(SUBSTRING(TRIM(last_name), 2))),
        email, city, signup_date
    FROM sql_mock_staging.raw_customers;

    INSERT INTO orders (order_id, customer_id, order_date, status)
    SELECT DISTINCT r.order_id, r.customer_id, r.order_date, r.status
    FROM sql_mock_staging.raw_orders r
    JOIN customers c ON c.customer_id = r.customer_id;

    INSERT INTO order_items
        (order_item_id, order_id, product_name, quantity, unit_price)
    SELECT DISTINCT
        i.order_item_id, i.order_id, i.product_name, i.quantity, i.unit_price
    FROM sql_mock_staging.raw_order_items i
    JOIN orders o ON o.order_id = i.order_id;
END
"""

with intermediate_engine.connect() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_load_mock_intermediate")
    conn.exec_driver_sql(procedure_sql)
    conn.commit()
```

**Why this is the correct working alternative:** `DELETE` follows the foreign-key relationships and succeeds when child rows are removed first. Disabling `FOREIGN_KEY_CHECKS` does not remove the referenced-table restriction on `TRUNCATE`. If an examiner insists on `TRUNCATE`, the foreign-key constraints must be dropped and recreated; that is longer and unnecessary for this practice test.

### 9.3 Call the procedure twice and check the counts

```python
with intermediate_engine.connect() as conn:
    conn.exec_driver_sql("CALL sp_load_mock_intermediate()")
    conn.commit()

    first = [
        conn.exec_driver_sql(f"SELECT COUNT(*) FROM {t}").scalar_one()
        for t in ["customers", "orders", "order_items"]
    ]
    print("First run:", first)

    conn.exec_driver_sql("CALL sp_load_mock_intermediate()")
    conn.commit()

    second = [
        conn.exec_driver_sql(f"SELECT COUNT(*) FROM {t}").scalar_one()
        for t in ["customers", "orders", "order_items"]
    ]
    print("Second run:", second)

assert first == second
```

**Expected counts on both runs:**

| Table | Rows | Reason |
|---|---:|---|
| customers | 5 | 6 source rows minus one exact duplicate |
| orders | 6 | 7 source rows minus orphan order 299 |
| order_items | 8 | 9 source rows minus item belonging to orphan order 299 |

**Remember the order:** Customers first, then orders that have a customer, then items that have an order.

---

## Question 10 — Build and Load the Reporting Star Schema (12 points)

**Pattern:** Create dimension → create fact → reset both → insert dimension → aggregate orders into fact.

### 10.1 Create the dimension and fact tables

```python
with reporting_engine.begin() as conn:
    conn.exec_driver_sql("""
        CREATE TABLE IF NOT EXISTS dim_customer (
            customer_key INT AUTO_INCREMENT PRIMARY KEY,
            customer_id INT NOT NULL,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            email VARCHAR(100),
            city VARCHAR(50),
            effective_date DATE NOT NULL,
            expiry_date DATE NULL,
            is_current BOOLEAN NOT NULL DEFAULT TRUE,
            INDEX idx_dim_customer_current (customer_id, is_current)
        )
    """)

    conn.exec_driver_sql("""
        CREATE TABLE IF NOT EXISTS fact_orders (
            order_id INT PRIMARY KEY,
            customer_key INT NOT NULL,
            customer_id INT NOT NULL,
            order_date DATE NOT NULL,
            status VARCHAR(20) NOT NULL,
            total_amount DECIMAL(10,2) NOT NULL,
            item_count INT NOT NULL,
            FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key)
        )
    """)
```

### 10.2 Reset both tables and load the dimension first

The question calls out MySQL's `TRUNCATE` foreign-key restriction. The simplest safe reset is to use `DELETE` on the child (`fact_orders`) first and then the parent (`dim_customer`). MySQL 8 does not allow truncating a referenced InnoDB parent table merely by setting `FOREIGN_KEY_CHECKS = 0`; see the [official MySQL 8 documentation](https://dev.mysql.com/doc/refman/8.0/en/truncate-table.html).

```python
with reporting_engine.connect() as conn:
    conn.exec_driver_sql("DELETE FROM fact_orders")
    conn.exec_driver_sql("DELETE FROM dim_customer")
    conn.commit()

    # Load one current dimension row for each intermediate customer.
    conn.exec_driver_sql("""
        INSERT INTO dim_customer (
            customer_id, first_name, last_name, email, city,
            effective_date, expiry_date, is_current
        )
        SELECT
            customer_id, first_name, last_name, email, city,
            COALESCE(signup_date, CURDATE()), NULL, TRUE
        FROM sql_mock_intermediate.customers
    """)
    conn.commit()

    # Load one fact row per order.
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
            COALESCE(SUM(i.quantity * i.unit_price), 0.00),
            COUNT(i.order_item_id)
        FROM sql_mock_intermediate.orders o
        JOIN dim_customer d
            ON d.customer_id = o.customer_id AND d.is_current = TRUE
        LEFT JOIN sql_mock_intermediate.order_items i
            ON i.order_id = o.order_id
        GROUP BY
            o.order_id, d.customer_key, o.customer_id,
            o.order_date, o.status
    """)
    conn.commit()
```

### 10.3 Check the row counts and fact rows

```python
with reporting_engine.connect() as conn:
    dim_count = conn.exec_driver_sql(
        "SELECT COUNT(*) FROM dim_customer"
    ).scalar_one()
    fact_count = conn.exec_driver_sql(
        "SELECT COUNT(*) FROM fact_orders"
    ).scalar_one()

    print("Dimension rows:", dim_count)
    print("Fact rows:", fact_count)
    display(pd.read_sql(text("SELECT * FROM fact_orders ORDER BY order_id"), conn))

assert dim_count == 5
assert fact_count == 6
```

**Expected counts:** 5 dimension rows and 6 fact rows.

**Expected fact totals:**

| order_id | customer_id | total_amount | item_count |
|---:|---:|---:|---:|
| 201 | 1 | 125.00 | 2 |
| 202 | 1 | 475.00 | 2 |
| 203 | 2 | 50.00 | 1 |
| 204 | 3 | 75.00 | 1 |
| 205 | 4 | 300.00 | 1 |
| 206 | 5 | 25.00 | 1 |

**Remember:** Dimension first, fact second. A fact row stores the dimension's `customer_key`. Use `LEFT JOIN` to items so an order with no items can still appear with zero total and zero count.

---

## Question 11 — SCD Type 2 and Current-Customer Activity View (12 points)

**Pattern:** Compare current rows → expire changed rows → insert missing current versions → create view.

The tracked columns are `email` and `city`. MySQL's `<=>` operator safely compares values when either side may be `NULL`.

### 11.1 Create the SCD Type 2 procedure

```python
scd_sql = """
CREATE PROCEDURE sp_apply_mock_customer_scd()
BEGIN
    -- Expire the old current row when email or city changes.
    UPDATE dim_customer d
    JOIN sql_mock_intermediate.customers c
        ON c.customer_id = d.customer_id
    SET d.expiry_date = CURDATE(),
        d.is_current = FALSE
    WHERE d.is_current = TRUE
      AND (
          NOT (d.email <=> c.email)
          OR NOT (d.city <=> c.city)
      );

    -- Insert a new row if the customer has no current version.
    INSERT INTO dim_customer (
        customer_id, first_name, last_name, email, city,
        effective_date, expiry_date, is_current
    )
    SELECT
        c.customer_id, c.first_name, c.last_name, c.email, c.city,
        CURDATE(), NULL, TRUE
    FROM sql_mock_intermediate.customers c
    LEFT JOIN dim_customer d
        ON d.customer_id = c.customer_id AND d.is_current = TRUE
    WHERE d.customer_key IS NULL;
END
"""

with reporting_engine.connect() as conn:
    conn.exec_driver_sql("DROP PROCEDURE IF EXISTS sp_apply_mock_customer_scd")
    conn.exec_driver_sql(scd_sql)
    conn.commit()
```

**Why two statements are enough:** The `UPDATE` expires only rows whose tracked values changed. The `INSERT` adds a row only when no current row remains. If nothing changed, a current row still exists, so nothing is inserted.

### 11.2 Change customer 2's city and call the procedure

```python
with intermediate_engine.begin() as conn:
    conn.execute(
        text("UPDATE customers SET city = :city WHERE customer_id = :id"),
        {"city": "Noida", "id": 2}
    )

with reporting_engine.connect() as conn:
    conn.exec_driver_sql("CALL sp_apply_mock_customer_scd()")
    conn.commit()
```

### 11.3 Confirm the old and new versions

```sql
SELECT customer_key, customer_id, city,
       effective_date, expiry_date, is_current
FROM dim_customer
WHERE customer_id = 2
ORDER BY customer_key;
```

**Expected shape:**

| customer_id | city | expiry_date | is_current |
|---:|---|---|---:|
| 2 | Delhi | current run date | 0 |
| 2 | Noida | NULL | 1 |

The exact date and generated surrogate keys depend on the run.

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
    COALESCE(SUM(f.total_amount), 0) AS total_order_amount,
    COUNT(f.order_id) AS order_count
FROM dim_customer d
LEFT JOIN fact_orders f ON f.customer_key = d.customer_key
WHERE d.is_current = TRUE
GROUP BY
    d.customer_key, d.customer_id, d.first_name,
    d.last_name, d.email, d.city;
```

Or create it from the notebook using SQLAlchemy:

```python
with reporting_engine.begin() as conn:
    conn.exec_driver_sql("""CREATE OR REPLACE VIEW vw_mock_customer_activity AS
        SELECT d.customer_key, d.customer_id, d.first_name, d.last_name,
               d.email, d.city,
               COALESCE(SUM(f.total_amount), 0) AS total_order_amount,
               COUNT(f.order_id) AS order_count
        FROM dim_customer d
        LEFT JOIN fact_orders f ON f.customer_key = d.customer_key
        WHERE d.is_current = TRUE
        GROUP BY d.customer_key, d.customer_id, d.first_name,
                 d.last_name, d.email, d.city
    """)
```

### 11.5 Query the view

```sql
SELECT *
FROM vw_mock_customer_activity
ORDER BY total_order_amount DESC, customer_id;
```

**Important:** Join the fact table using `customer_key`, not only `customer_id`. Customer 2's old fact rows still reference the old dimension key. The new current version therefore has zero historical fact rows until new facts are loaded against its new key. This is the expected SCD2 behaviour for the question.

---

# Final Expected-Results Checklist

| Question | What to check | Expected result |
|---|---|---|
| 1 | Tables created | 3 tables, parent-first foreign keys |
| 2 | DML complete | 4 customers, 4 orders, 5 order items |
| 3 | Revenue report | Asha 600; Ben 50; Cara 0; Dev 0 |
| 4 | First normalized emails | Signup IDs 1, 2, 4, 6 |
| 5 | Five or more direct children | Electronics, count 6 |
| 6 | Third-highest distinct price | 600.00 |
| 7 | Attended every workshop | Members 1 and 3 |
| 8 | First purchases by date | 1, 1, 1, 0, 0, 1 |
| 9 | Intermediate full refresh | Customers 5, orders 6, items 8 after both runs |
| 10 | Star schema | 5 dimension rows, 6 fact rows |
| 11 | SCD2 | Customer 2 has one expired and one current row; view has current customers |

# 12 Patterns to Memorize

| If the question says… | Remember this |
|---|---|
| Include customers with zero orders | `LEFT JOIN` |
| Show zero instead of NULL | `COALESCE(value, 0)` |
| Count an order after joining its items | `COUNT(DISTINCT order_id)` |
| Keep first duplicate | `ROW_NUMBER()` and `rn = 1` |
| Count direct children | Self-join + `GROUP BY` + `HAVING` |
| Third-highest distinct value | `DISTINCT` + `ORDER BY DESC` + `LIMIT 1 OFFSET 2` |
| Attended every workshop | Count distinct attendance = total workshops; or double `NOT EXISTS` |
| First-ever date | `MIN(date)` per customer |
| Include zero-activity dates | Recursive date CTE + `LEFT JOIN` |
| Remove orphan rows | `INNER JOIN` to the cleaned parent |
| Run ETL again safely | Clear target, then reload in parent-child order |
| Keep historical changes | Expire old SCD2 row + insert new current row |

**Final advice:** Learn the pattern, not every line. In the exam, keep the structure and replace only the table names, column names and values given in the question.
