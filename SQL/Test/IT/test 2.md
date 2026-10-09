# PostgreSQL Test 2 – ETL Layers
## Mock Test with Questions and Solutions

**Database:** PostgreSQL  
**Questions:** 8  
**Topics:** ETL Layers, Stored Procedures, Control Flow, Star Schema, SCD Type 2, Views, Indexing, Idempotency

---

## Q1. Intermediate Layer – Denormalization

You are given the following staging table:

```sql
CREATE TABLE stg_orders (
    order_id INT,
    customer_id INT,
    customer_name VARCHAR(100),
    customer_email VARCHAR(150),
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    quantity INT,
    unit_price NUMERIC(10,2),
    order_date DATE,
    order_status VARCHAR(30)
);
```

The same customer and product information may appear in multiple orders.

### Question

1. Explain why this staging structure may not be ideal for reporting.
2. Create an intermediate table called `int_orders`.
3. Add a calculated `total_amount` column.
4. Store the cleaned order status in uppercase.

### Solution

The staging layer generally stores raw/source data.

Repeated customer and product information can make reporting queries larger and can result in unnecessary repeated data.

The intermediate layer can clean and transform the staging data.

```sql
CREATE TABLE int_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(100),
    customer_email VARCHAR(150),
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    quantity INT,
    unit_price NUMERIC(10,2),
    order_date DATE,
    order_status VARCHAR(30),
    total_amount NUMERIC(12,2)
);
```

Load the intermediate table:

```sql
INSERT INTO int_orders (
    order_id,
    customer_id,
    customer_name,
    customer_email,
    product_id,
    product_name,
    category,
    quantity,
    unit_price,
    order_date,
    order_status,
    total_amount
)
SELECT
    order_id,
    customer_id,
    customer_name,
    customer_email,
    product_id,
    product_name,
    category,
    quantity,
    unit_price,
    order_date,
    UPPER(order_status),
    quantity * unit_price
FROM stg_orders;
```

---

## Q2. Stored Procedure – Staging to Intermediate

Create a PostgreSQL stored procedure called:

```text
load_int_orders()
```

The procedure must:

- Read data from `stg_orders`.
- Ignore rows where `order_id` is NULL.
- Ignore rows where `quantity <= 0`.
- Ignore rows where `unit_price < 0`.
- Convert `order_status` to uppercase.
- Calculate `total_amount`.
- Insert valid records into `int_orders`.

### Solution

PostgreSQL uses `PL/pgSQL` for procedural logic.

```sql
CREATE OR REPLACE PROCEDURE load_int_orders()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO int_orders (
        order_id,
        customer_id,
        customer_name,
        customer_email,
        product_id,
        product_name,
        category,
        quantity,
        unit_price,
        order_date,
        order_status,
        total_amount
    )
    SELECT
        order_id,
        customer_id,
        customer_name,
        customer_email,
        product_id,
        product_name,
        category,
        quantity,
        unit_price,
        order_date,
        UPPER(order_status),
        quantity * unit_price
    FROM stg_orders
    WHERE order_id IS NOT NULL
      AND quantity > 0
      AND unit_price >= 0;

END;
$$;
```

Execute the procedure:

```sql
CALL load_int_orders();
```

---

## Q3. Stored Procedure – Order Status History

Create the following table:

```sql
CREATE TABLE order_status_history (
    history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT,
    old_status VARCHAR(30),
    new_status VARCHAR(30),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Question

Create a PostgreSQL procedure called `update_order_status()`.

The procedure should accept:

```text
order_id
new_status
```

It must:

1. Find the current status.
2. Compare the old and new status.
3. If they are different, insert a record into `order_status_history`.
4. Update the current order status.
5. Use `IF` control flow.

### Solution

```sql
CREATE OR REPLACE PROCEDURE update_order_status(
    IN p_order_id INT,
    IN p_new_status VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR(30);
BEGIN

    SELECT order_status
    INTO v_old_status
    FROM int_orders
    WHERE order_id = p_order_id;

    IF v_old_status IS DISTINCT FROM p_new_status THEN

        INSERT INTO order_status_history (
            order_id,
            old_status,
            new_status,
            changed_at
        )
        VALUES (
            p_order_id,
            v_old_status,
            p_new_status,
            CURRENT_TIMESTAMP
        );

        UPDATE int_orders
        SET order_status = p_new_status
        WHERE order_id = p_order_id;

    END IF;

END;
$$;
```

Execute:

```sql
CALL update_order_status(101, 'SHIPPED');
```

### Important PostgreSQL Concept

```sql
IS DISTINCT FROM
```

is useful when comparing values that may contain `NULL`.

---

## Q4. Star Schema – Fact and Dimension Tables

You have the following intermediate data:

```text
order_id
customer_id
customer_name
customer_email
product_id
product_name
category
order_date
quantity
unit_price
total_amount
```

### Question

Create a PostgreSQL reporting star schema containing:

```text
dim_customer
dim_product
dim_date
fact_sales
```

Also identify which columns should be dimensions and which should be facts.

### Solution

The star schema is:

```text
                    dim_customer
                         |
                         |
dim_product -------- fact_sales -------- dim_date
```

### Customer Dimension

```sql
CREATE TABLE dim_customer (
    customer_key INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    customer_email VARCHAR(150)
);
```

### Product Dimension

```sql
CREATE TABLE dim_product (
    product_key INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(100),
    category VARCHAR(100)
);
```

### Date Dimension

```sql
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    month INT,
    day INT
);
```

### Fact Table

```sql
CREATE TABLE fact_sales (
    sales_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT NOT NULL,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    date_key INT NOT NULL,
    quantity INT,
    unit_price NUMERIC(10,2),
    total_amount NUMERIC(12,2),

    FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key),

    FOREIGN KEY (product_key)
        REFERENCES dim_product(product_key),

    FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key)
);
```

### Dimensions

```text
customer_id
customer_name
customer_email
product_id
product_name
category
order_date
```

### Measures / Facts

```text
quantity
unit_price
total_amount
```

---

## Q5. Slowly Changing Dimension Type 2

Create a PostgreSQL `dim_customer` table that supports SCD Type 2.

Required columns:

```text
customer_key
customer_id
customer_name
city
valid_from
valid_to
is_current
```

Initially:

```text
customer_id = 101
customer_name = Alice
city = Chennai
```

Later the customer moves to Bangalore.

### Question

Implement SCD Type 2 so that:

1. The old Chennai record remains.
2. The old record becomes inactive.
3. A new Bangalore record is created.
4. The new record becomes current.

### Solution

Create the table:

```sql
CREATE TABLE dim_customer (
    customer_key INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    city VARCHAR(100),
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);
```

Insert the initial version:

```sql
INSERT INTO dim_customer (
    customer_id,
    customer_name,
    city,
    valid_from,
    valid_to,
    is_current
)
VALUES (
    101,
    'Alice',
    'Chennai',
    DATE '2026-01-01',
    NULL,
    TRUE
);
```

Close the old version:

```sql
UPDATE dim_customer
SET
    valid_to = CURRENT_DATE,
    is_current = FALSE
WHERE customer_id = 101
  AND is_current = TRUE;
```

Insert the new version:

```sql
INSERT INTO dim_customer (
    customer_id,
    customer_name,
    city,
    valid_from,
    valid_to,
    is_current
)
VALUES (
    101,
    'Alice',
    'Bangalore',
    CURRENT_DATE,
    NULL,
    TRUE
);
```

Result:

```text
customer_id | city      | valid_from | valid_to   | is_current
------------+-----------+------------+------------+-----------
101         | Chennai   | 2026-01-01 | 2026-10-06 | false
101         | Bangalore | 2026-10-06 | NULL       | true
```

The old record is preserved.

---

## Q5 – SCD Type 2 Procedure

### Question

Create a stored procedure that:

1. Inserts a customer if the customer does not exist.
2. Does nothing if the customer's tracked attribute has not changed.
3. Closes the old record if the customer's city changes.
4. Inserts a new current version.

### Solution

```sql
CREATE OR REPLACE PROCEDURE update_customer_scd2(
    IN p_customer_id INT,
    IN p_customer_name VARCHAR(100),
    IN p_city VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_city VARCHAR(100);
BEGIN

    SELECT city
    INTO v_old_city
    FROM dim_customer
    WHERE customer_id = p_customer_id
      AND is_current = TRUE;

    IF NOT FOUND THEN

        INSERT INTO dim_customer (
            customer_id,
            customer_name,
            city,
            valid_from,
            valid_to,
            is_current
        )
        VALUES (
            p_customer_id,
            p_customer_name,
            p_city,
            CURRENT_DATE,
            NULL,
            TRUE
        );

    ELSIF v_old_city IS DISTINCT FROM p_city THEN

        UPDATE dim_customer
        SET
            valid_to = CURRENT_DATE,
            is_current = FALSE
        WHERE customer_id = p_customer_id
          AND is_current = TRUE;

        INSERT INTO dim_customer (
            customer_id,
            customer_name,
            city,
            valid_from,
            valid_to,
            is_current
        )
        VALUES (
            p_customer_id,
            p_customer_name,
            p_city,
            CURRENT_DATE,
            NULL,
            TRUE
        );

    END IF;

END;
$$;
```

Execute:

```sql
CALL update_customer_scd2(
    101,
    'Alice',
    'Bangalore'
);
```

---

## Q6. View – Current Customer Order Activity

Create a PostgreSQL view called:

```text
customer_order_summary
```

The view must show:

```text
customer_id
customer_name
total_orders
total_quantity
total_sales
last_order_date
```

Only the current customer version should be included.

Use:

```text
dim_customer
fact_sales
dim_date
```

### Solution

```sql
CREATE OR REPLACE VIEW customer_order_summary AS
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(f.order_id) AS total_orders,
    SUM(f.quantity) AS total_quantity,
    SUM(f.total_amount) AS total_sales,
    MAX(d.full_date) AS last_order_date
FROM dim_customer AS c
JOIN fact_sales AS f
    ON c.customer_key = f.customer_key
JOIN dim_date AS d
    ON f.date_key = d.date_key
WHERE c.is_current = TRUE
GROUP BY
    c.customer_id,
    c.customer_name;
```

View the result:

```sql
SELECT *
FROM customer_order_summary;
```

The important condition is:

```sql
WHERE c.is_current = TRUE
```

This ensures that historical SCD Type 2 versions are not treated as current customers.

---

## Q7. Query Performance and Indexing

The following query is slow:

```sql
SELECT
    c.customer_name,
    SUM(f.total_amount) AS total_sales
FROM fact_sales AS f
JOIN dim_customer AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_id = 101
GROUP BY c.customer_name;
```

The tables contain millions of rows.

### Question

1. Identify suitable columns for indexing.
2. Create the indexes.
3. Explain why the indexes help.
4. Explain one disadvantage of excessive indexing.
5. Show how to inspect the query plan.

### Solution

Create an index on `customer_id`:

```sql
CREATE INDEX idx_dim_customer_customer_id
ON dim_customer(customer_id);
```

Create an index on the fact-table join column:

```sql
CREATE INDEX idx_fact_sales_customer_key
ON fact_sales(customer_key);
```

The first index helps with:

```sql
WHERE c.customer_id = 101
```

The second index can help with:

```sql
f.customer_key = c.customer_key
```

### Check the Query Plan

```sql
EXPLAIN
SELECT
    c.customer_name,
    SUM(f.total_amount) AS total_sales
FROM fact_sales AS f
JOIN dim_customer AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_id = 101
GROUP BY c.customer_name;
```

For actual execution statistics:

```sql
EXPLAIN ANALYZE
SELECT
    c.customer_name,
    SUM(f.total_amount) AS total_sales
FROM fact_sales AS f
JOIN dim_customer AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_id = 101
GROUP BY c.customer_name;
```

### Disadvantage of Excessive Indexes

Indexes require storage and can slow down:

```text
INSERT
UPDATE
DELETE
```

because the indexes also need to be maintained.

---

## Q8. Idempotency – Can Q2 Be Run Twice?

Consider the procedure from Q2:

```sql
CALL load_int_orders();
```

Suppose:

```text
stg_orders = 100 valid rows
```

You execute:

```sql
CALL load_int_orders();
CALL load_int_orders();
```

### Question

1. How many rows may exist after the first execution?
2. How many may exist after the second execution?
3. Is the procedure idempotent?
4. How can you make the ETL procedure safe to rerun?

### Solution

After the first execution:

```text
100 rows
```

If the procedure simply performs:

```sql
INSERT INTO int_orders
SELECT ...
FROM stg_orders;
```

then the second execution attempts to insert the same rows again.

Therefore:

```text
First execution  → 100 rows
Second execution → 200 rows
```

if duplicate prevention is not implemented.

The procedure is therefore **not idempotent**.

An idempotent ETL operation can be executed multiple times without incorrectly accumulating duplicate data.

---

## PostgreSQL Solution – DELETE and Reload

If `int_orders` is a full-refresh intermediate table:

```sql
CREATE OR REPLACE PROCEDURE load_int_orders()
LANGUAGE plpgsql
AS $$
BEGIN

    DELETE FROM int_orders;

    INSERT INTO int_orders (
        order_id,
        customer_id,
        customer_name,
        customer_email,
        product_id,
        product_name,
        category,
        quantity,
        unit_price,
        order_date,
        order_status,
        total_amount
    )
    SELECT
        order_id,
        customer_id,
        customer_name,
        customer_email,
        product_id,
        product_name,
        category,
        quantity,
        unit_price,
        order_date,
        UPPER(order_status),
        quantity * unit_price
    FROM stg_orders
    WHERE order_id IS NOT NULL
      AND quantity > 0
      AND unit_price >= 0;

END;
$$;
```

Now:

```sql
CALL load_int_orders();
CALL load_int_orders();
```

does not accumulate duplicate rows.

---

## PostgreSQL Solution – ON CONFLICT

Because `order_id` is the primary key:

```sql
order_id INT PRIMARY KEY
```

PostgreSQL can use `ON CONFLICT`.

```sql
INSERT INTO int_orders (
    order_id,
    customer_id,
    customer_name,
    customer_email,
    product_id,
    product_name,
    category,
    quantity,
    unit_price,
    order_date,
    order_status,
    total_amount
)
SELECT
    order_id,
    customer_id,
    customer_name,
    customer_email,
    product_id,
    product_name,
    category,
    quantity,
    unit_price,
    order_date,
    UPPER(order_status),
    quantity * unit_price
FROM stg_orders
WHERE order_id IS NOT NULL
  AND quantity > 0
  AND unit_price >= 0
ON CONFLICT (order_id)
DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    customer_name = EXCLUDED.customer_name,
    customer_email = EXCLUDED.customer_email,
    product_id = EXCLUDED.product_id,
    product_name = EXCLUDED.product_name,
    category = EXCLUDED.category,
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price,
    order_date = EXCLUDED.order_date,
    order_status = EXCLUDED.order_status,
    total_amount = EXCLUDED.total_amount;
```

`EXCLUDED` represents the values from the attempted insert.

---

# Bonus Questions

## Q9. Find Duplicate Orders

Find duplicate `order_id` values in the staging table.

### Solution

```sql
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
```

---

## Q10. Find Invalid Orders

Find records where:

- `order_id` is NULL
- `quantity <= 0`
- `unit_price < 0`

### Solution

```sql
SELECT *
FROM stg_orders
WHERE order_id IS NULL
   OR quantity <= 0
   OR unit_price < 0;
```

---

## Q11. Find Current Customers

Return only the current version of customers.

### Solution

```sql
SELECT *
FROM dim_customer
WHERE is_current = TRUE;
```

---

## Q12. Find Customers with Multiple SCD Versions

Find customers who have more than one historical version.

### Solution

```sql
SELECT
    customer_id,
    COUNT(*) AS version_count
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

---

## Q13. Total Sales by Current Customer

Calculate total sales for every current customer.

### Solution

```sql
SELECT
    c.customer_id,
    c.customer_name,
    SUM(f.total_amount) AS total_sales
FROM dim_customer AS c
JOIN fact_sales AS f
    ON c.customer_key = f.customer_key
WHERE c.is_current = TRUE
GROUP BY
    c.customer_id,
    c.customer_name;
```

---

## Q14. Customers with Sales Greater Than 10,000

### Solution

```sql
SELECT
    c.customer_id,
    c.customer_name,
    SUM(f.total_amount) AS total_sales
FROM dim_customer AS c
JOIN fact_sales AS f
    ON c.customer_key = f.customer_key
WHERE c.is_current = TRUE
GROUP BY
    c.customer_id,
    c.customer_name
HAVING SUM(f.total_amount) > 10000;
```

---

# PostgreSQL Syntax to Remember

## Auto-Generated ID

```sql
id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

Example:

```sql
customer_key INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

---

## Stored Procedure

```sql
CREATE OR REPLACE PROCEDURE procedure_name()
LANGUAGE plpgsql
AS $$
BEGIN

    -- SQL statements

END;
$$;
```

Execute:

```sql
CALL procedure_name();
```

---

## Variables

```sql
DECLARE
    v_status VARCHAR(30);
```

---

## SELECT INTO

```sql
SELECT order_status
INTO v_status
FROM int_orders
WHERE order_id = 101;
```

---

## IF / ELSIF / ELSE

```sql
IF condition THEN

    -- statements

ELSIF another_condition THEN

    -- statements

ELSE

    -- statements

END IF;
```

---

## NULL-Safe Comparison

```sql
value1 IS DISTINCT FROM value2
```

---

## Upsert

```sql
INSERT INTO table_name (...)
VALUES (...)
ON CONFLICT (column_name)
DO UPDATE SET
    column_name = EXCLUDED.column_name;
```

---

## Boolean

```sql
TRUE
FALSE
```

Example:

```sql
WHERE is_current = TRUE;
```

---

## Current Date and Time

```sql
CURRENT_DATE
```

```sql
CURRENT_TIMESTAMP
```

---

## Query Performance

```sql
EXPLAIN
SELECT ...;
```

```sql
EXPLAIN ANALYZE
SELECT ...;
```

---

# Final Revision Priority

If you have limited preparation time, practice in this order:

```text
1. Q2 → Stored Procedure
2. Q3 → Procedure + IF/ELSE + Status History
3. Q5 → SCD Type 2
4. Q4 → Star Schema
5. Q8 → Idempotency + ON CONFLICT
6. Q6 → View + JOIN + GROUP BY
7. Q7 → Index + EXPLAIN
8. Q1 → Intermediate Layer
```

## Most Important PostgreSQL Patterns

You should be able to write these without looking at your notes:

```sql
CREATE TABLE
```

```sql
GENERATED ALWAYS AS IDENTITY
```

```sql
INSERT INTO ... SELECT
```

```sql
CREATE OR REPLACE PROCEDURE
```

```sql
LANGUAGE plpgsql
```

```sql
DECLARE
```

```sql
SELECT ... INTO
```

```sql
IF / ELSIF / ELSE
```

```sql
UPDATE
```

```sql
CREATE VIEW
```

```sql
CREATE INDEX
```

```sql
EXPLAIN ANALYZE
```

```sql
ON CONFLICT (...) DO UPDATE
```

```sql
JOIN
```

```sql
GROUP BY
```

```sql
HAVING
```

```sql
COUNT()
SUM()
MAX()
```

---

# ETL Architecture to Remember

```text
SOURCE
   ↓
STAGING
   ↓
INTERMEDIATE
   ↓
REPORTING
   ↓
FACT + DIMENSIONS
   ↓
VIEWS / BI
```

## Core Concepts

```text
Staging
    ↓
Raw/source data

Intermediate
    ↓
Clean + validate + transform

Reporting
    ↓
Star schema + facts + dimensions

SCD Type 2
    ↓
Preserve historical changes

Views
    ↓
Reusable reporting queries

Indexes
    ↓
Improve query performance

Idempotency
    ↓
Safe ETL reruns
```
