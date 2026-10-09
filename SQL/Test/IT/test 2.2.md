# SQL Test 2 — ETL Layers — Mock Exam

Mirrors your stated structure exactly: Q1 (intermediate DDL), Q2/Q3/Q8 (stored procedures, 30
points), Q4 (star schema), Q5 (SCD Type 2), Q6 (view), Q7 (indexing, written).
Given scenario + schema below, answer each question as you would in the real test, then check
against the answer underneath.

---

## Given: Staging Schema

```sql
CREATE TABLE stg_customers (
    customer_id INT,
    name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE stg_products (
    product_id INT,
    name VARCHAR(100),
    category VARCHAR(50)
);

CREATE TABLE stg_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20)
);

CREATE TABLE stg_order_items (
    item_id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2)
);
```

Sample staging data (what you'd "inspect" before answering Q1):

```
stg_orders:        1, 101, 2025-09-01, 'completed'
                    2, 102, 2025-09-03, 'pending'
                    3, 101, 2025-09-10, 'completed'

stg_order_items:    1, 1, 501, 2, 250.00
                    2, 1, 502, 1, 100.00
                    3, 2, 501, 3, 250.00

stg_customers:      101, 'Arjun Mehta', 'arjun@mail.com', 'Pune'
                    102, 'Neha Rao', 'neha@mail.com', 'Mumbai'

stg_products:       501, 'Desk Lamp', 'Home'
                    502, 'Notebook', 'Stationery'
```

---

## Q1. Intermediate-Layer DDL (Denormalization)

**Question:** Based on the staging schema above, design and write the DDL for an intermediate
table `int_order_details` that denormalizes orders, customers, products, and order items into
one wide, reporting-ready table.

**Answer:**
```sql
CREATE TABLE int_order_details (
    order_id INT,
    order_date DATE,
    order_status VARCHAR(20),
    customer_id INT,
    customer_name VARCHAR(100),
    customer_city VARCHAR(50),
    product_id INT,
    product_name VARCHAR(100),
    product_category VARCHAR(50),
    quantity INT,
    unit_price DECIMAL(10,2),
    line_total DECIMAL(10,2),
    PRIMARY KEY (order_id, product_id)
);
```
**Reasoning to write alongside it:** each row represents one order line with every attribute a
report might need already flattened in — no joins required at query time. `line_total` is
precomputed rather than left for downstream queries to recalculate repeatedly.

---

## Q2. Stored Procedure — Staging → Intermediate Cleanup (15 pts)

**Question:** Write a stored procedure `load_intermediate_orders()` that populates
`int_order_details` from the staging tables, trimming customer names and computing `line_total`.

**Answer:**
```sql
DELIMITER $$

CREATE PROCEDURE load_intermediate_orders()
BEGIN
    TRUNCATE TABLE int_order_details;

    INSERT INTO int_order_details (
        order_id, order_date, order_status, customer_id, customer_name, customer_city,
        product_id, product_name, product_category, quantity, unit_price, line_total
    )
    SELECT
        o.order_id,
        o.order_date,
        o.status,
        c.customer_id,
        TRIM(c.name),
        COALESCE(c.city, 'Unknown'),
        p.product_id,
        p.name,
        p.category,
        oi.quantity,
        oi.unit_price,
        oi.quantity * oi.unit_price
    FROM stg_orders o
    JOIN stg_customers c ON o.customer_id = c.customer_id
    JOIN stg_order_items oi ON o.order_id = oi.order_id
    JOIN stg_products p ON oi.product_id = p.product_id;
END $$

DELIMITER ;

CALL load_intermediate_orders();
```
**Expected resulting rows (against the sample data above):**
```
order_id=1, product_id=501, quantity=2, unit_price=250.00, line_total=500.00
order_id=1, product_id=502, quantity=1, unit_price=100.00, line_total=100.00
order_id=2, product_id=501, quantity=3, unit_price=250.00, line_total=750.00
```
(order_id=3 has no matching `stg_order_items` row in the sample, so it's correctly excluded by the `JOIN`.)

---

## Q3. Stored Procedure — Order Status History with Control Flow (15 pts)

**Question:** Write a procedure `log_order_status_change(p_order_id, p_new_status)` that: looks
up the order's current status, does nothing if it's unchanged, logs the transition to
`order_status_history` if it has changed, and updates the order — using `IF/ELSEIF/ELSE`.

**Answer:**
```sql
CREATE TABLE order_status_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at DATETIME
);

DELIMITER $$

CREATE PROCEDURE log_order_status_change(
    IN p_order_id INT,
    IN p_new_status VARCHAR(20)
)
BEGIN
    DECLARE v_old_status VARCHAR(20);

    SELECT status INTO v_old_status FROM stg_orders WHERE order_id = p_order_id;

    IF v_old_status IS NULL THEN
        SELECT CONCAT('Order ', p_order_id, ' not found') AS message;

    ELSEIF v_old_status = p_new_status THEN
        SELECT 'No status change needed' AS message;

    ELSE
        INSERT INTO order_status_history (order_id, old_status, new_status, changed_at)
        VALUES (p_order_id, v_old_status, p_new_status, NOW());

        UPDATE stg_orders SET status = p_new_status WHERE order_id = p_order_id;

        SELECT CONCAT('Status changed from ', v_old_status, ' to ', p_new_status) AS message;
    END IF;
END $$

DELIMITER ;

CALL log_order_status_change(2, 'completed');
-- Expected: 'Status changed from pending to completed', one row logged in order_status_history
```

---

## Q4. Star Schema — Fact & Dimension Tables (20 pts)

**Question:** Build the reporting-layer star schema from `int_order_details`: one fact table
`fact_order_line`, with dimension tables `dim_customer`, `dim_product`, `dim_date`. Write both the
DDL and the load statements.

**Answer:**
```sql
CREATE TABLE dim_customer (
    customer_key INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    customer_name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE dim_product (
    product_key INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50)
);

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    day INT
);

CREATE TABLE fact_order_line (
    order_id INT,
    customer_key INT REFERENCES dim_customer(customer_key),
    product_key INT REFERENCES dim_product(product_key),
    date_key INT REFERENCES dim_date(date_key),
    quantity INT,
    unit_price DECIMAL(10,2),
    line_total DECIMAL(10,2)
);

-- Load dims first
INSERT INTO dim_customer (customer_id, customer_name, city)
SELECT DISTINCT customer_id, customer_name, customer_city FROM int_order_details;

INSERT INTO dim_product (product_id, product_name, category)
SELECT DISTINCT product_id, product_name, product_category FROM int_order_details;

INSERT INTO dim_date (date_key, full_date, year, month, day)
SELECT DISTINCT
    CAST(DATE_FORMAT(order_date, '%Y%m%d') AS UNSIGNED),
    order_date,
    YEAR(order_date), MONTH(order_date), DAY(order_date)
FROM int_order_details;

-- Load fact last (depends on dim surrogate keys)
INSERT INTO fact_order_line (order_id, customer_key, product_key, date_key, quantity, unit_price, line_total)
SELECT
    i.order_id, dc.customer_key, dp.product_key,
    CAST(DATE_FORMAT(i.order_date, '%Y%m%d') AS UNSIGNED),
    i.quantity, i.unit_price, i.line_total
FROM int_order_details i
JOIN dim_customer dc ON i.customer_id = dc.customer_id
JOIN dim_product dp ON i.product_id = dp.product_id;
```
**Why dims load before fact:** the fact table's foreign keys (`customer_key`, `product_key`) are
surrogate keys generated by the dimension tables' `AUTO_INCREMENT` — they must exist before the
fact rows that reference them can be inserted.

---

## Q5. Slowly Changing Dimension Type 2 — Versioning `dim_customer` (20 pts)

**Question:** Convert `dim_customer` to SCD Type 2 and write a procedure
`update_dim_customer_scd2(p_customer_id, p_new_name, p_new_city)` that versions it correctly —
new customer, changed attribute, and no-change cases.

**Answer:**
```sql
CREATE TABLE dim_customer_scd2 (
    customer_key INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    effective_date DATE,
    expiry_date DATE,
    is_current BOOLEAN DEFAULT TRUE
);

DELIMITER $$

CREATE PROCEDURE update_dim_customer_scd2(
    IN p_customer_id INT,
    IN p_new_name VARCHAR(100),
    IN p_new_city VARCHAR(50)
)
BEGIN
    DECLARE v_current_city VARCHAR(50);

    SELECT city INTO v_current_city
    FROM dim_customer_scd2
    WHERE customer_id = p_customer_id AND is_current = TRUE;

    IF v_current_city IS NULL THEN
        INSERT INTO dim_customer_scd2 (customer_id, customer_name, city, effective_date, expiry_date, is_current)
        VALUES (p_customer_id, p_new_name, p_new_city, CURDATE(), NULL, TRUE);

    ELSEIF v_current_city <> p_new_city THEN
        UPDATE dim_customer_scd2
        SET expiry_date = CURDATE() - INTERVAL 1 DAY, is_current = FALSE
        WHERE customer_id = p_customer_id AND is_current = TRUE;

        INSERT INTO dim_customer_scd2 (customer_id, customer_name, city, effective_date, expiry_date, is_current)
        VALUES (p_customer_id, p_new_name, p_new_city, CURDATE(), NULL, TRUE);

    ELSE
        SELECT 'No change in tracked attributes' AS message;
    END IF;
END $$

DELIMITER ;

-- Trace through the sample data:
CALL update_dim_customer_scd2(101, 'Arjun Mehta', 'Pune');     -- new row, is_current=TRUE
CALL update_dim_customer_scd2(101, 'Arjun Mehta', 'Bangalore'); -- Pune row expired, new Bangalore row inserted
CALL update_dim_customer_scd2(101, 'Arjun Mehta', 'Bangalore'); -- no change, message only
```
**Resulting table after all three calls:**
```
customer_key | customer_id | city      | effective_date | expiry_date | is_current
1            | 101          | Pune      | <call1 date>    | <call2-1day> | FALSE
2            | 101          | Bangalore | <call2 date>    | NULL         | TRUE
```

---

## Q6. View — Order Activity Summary per Current Customer (15 pts)

**Question:** Create a view `order_activity_summary` showing, for each **current** version of
each customer (per `dim_customer_scd2`), their total orders, total spent, and most recent order
date.

**Answer:**
```sql
CREATE VIEW order_activity_summary AS
SELECT
    dc.customer_id,
    dc.customer_name,
    dc.city,
    COUNT(f.order_id) AS total_orders,
    SUM(f.line_total) AS total_spent,
    MAX(dd.full_date) AS last_order_date
FROM dim_customer_scd2 dc
JOIN fact_order_line f ON dc.customer_key = f.customer_key
JOIN dim_date dd ON f.date_key = dd.date_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.customer_name, dc.city;

SELECT * FROM order_activity_summary;
```
**Why `is_current = TRUE` is essential here:** without it, a customer who changed cities (and
therefore has multiple `dim_customer_scd2` rows) would appear multiple times — once per historical
version — splitting their order totals across stale rows instead of showing one accurate,
up-to-date summary row per real-world customer.

---

## Q7. Query Performance & Indexing (Written, 10 pts)

**Question:** You've noticed `SELECT * FROM fact_order_line WHERE customer_key = 5` is slow on a
large fact table. What would you do, and what's the tradeoff?

**Answer:**
> Add an index on `fact_order_line.customer_key`:
> ```sql
> CREATE INDEX idx_fact_customer_key ON fact_order_line(customer_key);
> ```
> This lets MySQL use an index lookup (`ref` access in `EXPLAIN`) instead of scanning every row in
> the fact table (`ALL`/full scan) to find matches. Since `customer_key` is a foreign key used in
> joins and filters constantly in reporting queries, it's a natural indexing candidate.
>
> **Tradeoff:** every `INSERT` into `fact_order_line` now also has to update this index, slightly
> slowing down the ETL load step. For a fact table that's bulk-loaded in batches (not
> row-by-row transactional writes), this cost is small and well worth the read-speed gain — but if
> this table were being written to constantly in real time, over-indexing could become a
> meaningful write bottleneck. A reasonable middle ground for large bulk loads: drop the index
> before the load, run the `INSERT`, then recreate the index once afterward.

---

## Q8. Written — Is Q2's Procedure Idempotent? (included in the 30-point group with Q2/Q3)

**Question:** If `load_intermediate_orders()` (Q2) is called twice in a row with no changes to
staging data in between, is the result still correct? Explain why or why not.

**Answer:**
> Yes, it's idempotent. The procedure begins with `TRUNCATE TABLE int_order_details`, which wipes
> the table completely before every reload. Running it once or running it five times in a row
> produces the identical end state each time — whatever is currently in staging, fully reloaded
> with no accumulation.
>
> This would **not** hold if the `TRUNCATE` were removed and replaced with a bare
> `INSERT INTO int_order_details SELECT ...` — every repeated call would re-insert the same rows
> again, duplicating every row in the table on each run. The `TRUNCATE`-first pattern is exactly
> what makes a full-refresh load idempotent; an incremental/append-only load without a
> corresponding dedup or upsert step (e.g. `INSERT ... ON DUPLICATE KEY UPDATE`) would not be.

---

## Self-Check Before Submitting

- [ ] Q1: Does your DDL include every attribute a downstream report would need, with no further joins required?
- [ ] Q2: Did you `TRUNCATE` before `INSERT` (or otherwise guarantee idempotency)?
- [ ] Q3: Did you cover all three branches — not found, unchanged, changed — with `IF/ELSEIF/ELSE`?
- [ ] Q4: Did dimension tables load **before** the fact table (surrogate key dependency)?
- [ ] Q5: Did you handle all three SCD2 cases — new customer, changed attribute, no change?
- [ ] Q6: Did you filter to `is_current = TRUE` before aggregating?
- [ ] Q7: Did you name both the fix (index) **and** its tradeoff (write cost)?
- [ ] Q8: Did you explicitly name *what* makes it idempotent (`TRUNCATE` first) and what would break it?
