# Test 2: ETL Layers — Practice Exam

A single realistic mock version of Test 2, built to match the actual 8-question pattern (Q1–Q8) as closely as possible. Same staging → intermediate → reporting scenario throughout. Full solutions are in the Answer Key at the end.

---

## Dataset Reference — Read This First

A retail company exports a raw nightly orders file into one denormalized staging table. Your job across this test is to build the intermediate and reporting layers on top of it.

```sql
CREATE TABLE stg_orders_raw (
    row_id               SERIAL PRIMARY KEY,
    order_ref            VARCHAR(50),
    customer_full_name   VARCHAR(150),
    customer_email_raw   VARCHAR(150),
    customer_country_raw VARCHAR(100),
    product_sku          VARCHAR(50),
    product_name_raw     VARCHAR(150),
    product_category_raw VARCHAR(100),
    qty_raw               VARCHAR(20),
    unit_price_raw         VARCHAR(20),
    order_date_raw         VARCHAR(20),
    order_status_raw       VARCHAR(30),
    load_ts                TIMESTAMP DEFAULT NOW()
);
```

One row per order line item. Customer and product details are repeated on every row (a typical flat-file export). Numbers and dates arrive as raw text, and `order_status_raw` has inconsistent casing (`'completed'`, `'Completed'`, `'COMPLETED'`).

---

## Part 1 — Denormalizing for Reporting Performance (Q1)

**Question 1.** Inspect `stg_orders_raw`'s structure above and write the full DDL for the **intermediate layer**: `int_customers`, `int_products`, `int_orders`, and `int_order_items`. Choose primary keys, foreign keys, and any constraints you think the raw data quality issues justify (e.g. preventing duplicate customers or orders once cleaned).

---

## Part 2 — Stored Procedures for Business Logic (Q2, Q3, Q8 — 30 points)

**Question 2 (12 points).** Write a stored procedure `stage_to_intermediate_load()` that reads from `stg_orders_raw` and loads the intermediate tables from Q1: dedupe and insert customers, dedupe and insert products, standardize `order_status_raw` to uppercase before inserting into `int_orders`, and populate `int_order_items` with properly cast numeric values.

**Question 3 (12 points).** Write a stored procedure `log_order_status_change(p_order_id INT, p_new_status VARCHAR)` that inserts a new row into an `order_status_history` table **only if** the order's status has actually changed from its most recently recorded status. Use explicit control flow (`IF`/`ELSE`) rather than a constraint to enforce this.

**Question 8 — written (6 points).** Is the procedure you wrote for Q2 still correct if it is run twice in a row against the **same** staging batch — i.e., is it idempotent? Justify your answer. If it is not fully idempotent, explain exactly what you would change to make it so.

---

## Part 3 — Star Schema: Fact and Dimension Tables (Q4)

**Question 4.** Using the intermediate layer from Q1/Q2, design the reporting layer as a star schema: `dim_customer`, `dim_product`, `dim_date`, and `fact_orders`. Write the DDL for all four tables, then write the `INSERT` statements that populate `dim_product` and `fact_orders` from the intermediate tables.

---

## Part 4 — Slowly Changing Dimension Type 2 (Q5)

**Question 5.** Write a stored procedure `apply_customer_scd2(p_customer_id INT, p_full_name VARCHAR, p_email VARCHAR, p_country VARCHAR)` that correctly versions `dim_customer` using SCD Type 2 logic:
- If the customer doesn't exist yet in `dim_customer`, insert their first version.
- If any tracked attribute (`full_name`, `email`, `country`) has changed from the current version, close out the current row and insert a new one.
- If nothing has changed, do nothing.

---

## Part 5 — Views for Reusable Query Logic (Q6)

**Question 6.** Create a view `vw_customer_order_activity` showing, for each **current** customer, their total number of orders, total revenue, and most recent order date. In one sentence, explain why the view must filter on `is_current = TRUE` rather than joining on `customer_id` directly.

---

## Part 6 — Query Performance and Indexing (Q7 — written)

**Question 7.** A dashboard query filters `fact_orders` by a specific `customer_key` and a date range (via `date_key`), and it's currently slow. Propose an index to speed it up, write the `CREATE INDEX` statement, and justify your choice of column order.

---
---

# ANSWER KEY

## Q1 — Intermediate Layer DDL

```sql
CREATE TABLE int_customers (
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(150) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    country     VARCHAR(100),
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE int_products (
    product_id   SERIAL PRIMARY KEY,
    sku          VARCHAR(50) UNIQUE,
    product_name VARCHAR(150),
    category     VARCHAR(100)
);

CREATE TABLE int_orders (
    order_id     SERIAL PRIMARY KEY,
    order_ref    VARCHAR(50) UNIQUE,
    customer_id  INT REFERENCES int_customers(customer_id),
    order_date   DATE,
    order_status VARCHAR(20)
        CHECK (order_status IN ('PENDING','COMPLETED','CANCELLED','RETURNED','EXPIRED'))
);

CREATE TABLE int_order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT REFERENCES int_orders(order_id),
    product_id    INT REFERENCES int_products(product_id),
    quantity      INT,
    unit_price    DECIMAL
);
```

`email` and `sku` get `UNIQUE` constraints because the staging data will contain the same customer/product repeated across many line-item rows — these constraints are what let the Q2 load use `ON CONFLICT DO NOTHING` to dedupe safely. `order_ref` is `UNIQUE` for the same reason on the order side. The `CHECK` on `order_status` enforces that only standardized values land here, after Q2's cleanup step runs.

## Q2 — Staging-to-Intermediate Load Procedure

```sql
CREATE OR REPLACE PROCEDURE stage_to_intermediate_load()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO int_customers (full_name, email, country)
    SELECT DISTINCT customer_full_name, LOWER(TRIM(customer_email_raw)), customer_country_raw
    FROM stg_orders_raw
    WHERE customer_email_raw IS NOT NULL
    ON CONFLICT (email) DO NOTHING;

    INSERT INTO int_products (sku, product_name, category)
    SELECT DISTINCT product_sku, product_name_raw, product_category_raw
    FROM stg_orders_raw
    ON CONFLICT (sku) DO NOTHING;

    INSERT INTO int_orders (order_ref, customer_id, order_date, order_status)
    SELECT DISTINCT s.order_ref, c.customer_id, s.order_date_raw::DATE, UPPER(TRIM(s.order_status_raw))
    FROM stg_orders_raw s
    JOIN int_customers c ON c.email = LOWER(TRIM(s.customer_email_raw))
    ON CONFLICT (order_ref) DO NOTHING;

    INSERT INTO int_order_items (order_id, product_id, quantity, unit_price)
    SELECT o.order_id, p.product_id, s.qty_raw::INT, s.unit_price_raw::DECIMAL
    FROM stg_orders_raw s
    JOIN int_orders o ON o.order_ref = s.order_ref
    JOIN int_products p ON p.sku = s.product_sku;
END;
$$;
```

## Q3 — Order Status History Procedure (Control Flow)

```sql
CREATE OR REPLACE PROCEDURE log_order_status_change(p_order_id INT, p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    SELECT status INTO v_current_status
    FROM order_status_history
    WHERE order_id = p_order_id
    ORDER BY changed_at DESC
    LIMIT 1;

    IF v_current_status IS DISTINCT FROM p_new_status THEN
        INSERT INTO order_status_history (order_id, status)
        VALUES (p_order_id, p_new_status);
    END IF;
END;
$$;
```

`IS DISTINCT FROM` is used instead of `<>` so that an order with no history yet (`v_current_status` is `NULL`) still correctly triggers the first insert — a plain `<>` comparison against `NULL` would evaluate to `UNKNOWN` and silently skip it.

## Q4 — Star Schema DDL + Load

```sql
CREATE TABLE dim_customer (
    customer_key   SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL,
    full_name      VARCHAR(150),
    email          VARCHAR(150),
    country        VARCHAR(100),
    effective_from DATE NOT NULL,
    effective_to   DATE,
    is_current     BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_product (
    product_key  SERIAL PRIMARY KEY,
    product_id   INT NOT NULL,
    product_name VARCHAR(150),
    category     VARCHAR(100)
);

CREATE TABLE dim_date (
    date_key  INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year      INT,
    month     INT,
    day       INT,
    quarter   INT
);

CREATE TABLE fact_orders (
    order_key    SERIAL PRIMARY KEY,
    order_id     INT,
    order_ref    VARCHAR(50),
    customer_key INT REFERENCES dim_customer(customer_key),
    product_key  INT REFERENCES dim_product(product_key),
    date_key     INT REFERENCES dim_date(date_key),
    quantity     INT,
    unit_price   DECIMAL,
    revenue      DECIMAL
);
```

```sql
-- Populate dim_product (Type 1 — simple load, no history tracking needed here)
INSERT INTO dim_product (product_id, product_name, category)
SELECT product_id, product_name, category FROM int_products;

-- Populate fact_orders from the intermediate layer, resolving dimension keys
INSERT INTO fact_orders (order_id, order_ref, customer_key, product_key, date_key, quantity, unit_price, revenue)
SELECT o.order_id, o.order_ref, dc.customer_key, dp.product_key,
       TO_CHAR(o.order_date, 'YYYYMMDD')::INT,
       oi.quantity, oi.unit_price, oi.quantity * oi.unit_price
FROM int_orders o
JOIN int_order_items oi ON oi.order_id = o.order_id
JOIN dim_customer dc ON dc.customer_id = o.customer_id AND dc.is_current = TRUE
JOIN dim_product dp ON dp.product_id = oi.product_id;
```

`fact_orders` joins to `dim_customer` with `is_current = TRUE` specifically so each order line links to whichever customer version was current *at load time* — see Q5 for why that matters once a customer's details change.

## Q5 — SCD Type 2 Procedure for `dim_customer`

```sql
CREATE OR REPLACE PROCEDURE apply_customer_scd2(
    p_customer_id INT, p_full_name VARCHAR, p_email VARCHAR, p_country VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current RECORD;
BEGIN
    SELECT * INTO v_current FROM dim_customer
    WHERE customer_id = p_customer_id AND is_current = TRUE;

    IF v_current IS NULL THEN
        -- Brand-new customer: first version
        INSERT INTO dim_customer (customer_id, full_name, email, country, effective_from, is_current)
        VALUES (p_customer_id, p_full_name, p_email, p_country, CURRENT_DATE, TRUE);

    ELSIF v_current.full_name <> p_full_name
       OR v_current.email <> p_email
       OR v_current.country <> p_country THEN
        -- Something changed: close out the old version, insert the new one
        UPDATE dim_customer
        SET effective_to = CURRENT_DATE - 1, is_current = FALSE
        WHERE customer_key = v_current.customer_key;

        INSERT INTO dim_customer (customer_id, full_name, email, country, effective_from, is_current)
        VALUES (p_customer_id, p_full_name, p_email, p_country, CURRENT_DATE, TRUE);
    END IF;
    -- ELSE: nothing changed — no action, no spurious new version
END;
$$;
```

## Q6 — Customer Order Activity View

```sql
CREATE VIEW vw_customer_order_activity AS
SELECT dc.customer_id, dc.full_name,
       COUNT(f.order_key) AS total_orders,
       SUM(f.revenue) AS total_revenue,
       MAX(dd.full_date) AS most_recent_order_date
FROM dim_customer dc
LEFT JOIN fact_orders f ON f.customer_key = dc.customer_key
LEFT JOIN dim_date dd ON dd.date_key = f.date_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name;
```

**Why `is_current = TRUE` is required:** `dim_customer` holds one row *per version* under SCD Type 2, so joining on `customer_id` without that filter would match every historical version of a customer at once, fanning out `fact_orders` and inflating `total_orders`/`total_revenue`.

## Q7 — Indexing for the Dashboard Query

```sql
CREATE INDEX idx_fact_orders_customer_date ON fact_orders(customer_key, date_key);
```

**Reasoning:** `customer_key` goes first because it's the equality filter (`WHERE customer_key = ?`) and the higher-selectivity column — it narrows the search down to one customer's rows immediately. `date_key` goes second to support the range filter (`BETWEEN` / `>=` / `<`) *within* that customer's already-narrowed set of rows. Reversing the order would mean the index couldn't be used efficiently for the equality filter at all, since a range condition can't narrow a leading index column the way an equality condition can.

## Q8 — Written: Is Q2's Procedure Idempotent?

**Mostly yes, but not completely.** Every `INSERT` into `int_customers`, `int_products`, and `int_orders` uses `ON CONFLICT DO NOTHING` against a `UNIQUE` constraint (`email`, `sku`, `order_ref` respectively) — re-running the procedure against the same staging batch inserts nothing new into those three tables the second time.

**`int_order_items` is the exception.** It has no uniqueness constraint of its own, so running the procedure twice against the same staged rows inserts the same line items a second time, silently doubling quantities and revenue in any downstream report.

**The fix:**

```sql
ALTER TABLE int_order_items
ADD CONSTRAINT uq_order_product UNIQUE (order_id, product_id);
```

And update the final `INSERT` in Q2 to guard against re-insertion the same way the others do:

```sql
INSERT INTO int_order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, s.qty_raw::INT, s.unit_price_raw::DECIMAL
FROM stg_orders_raw s
JOIN int_orders o ON o.order_ref = s.order_ref
JOIN int_products p ON p.sku = s.product_sku
ON CONFLICT (order_id, product_id) DO NOTHING;
```

With that change, every statement in the procedure is anchored to a uniqueness constraint, and the whole procedure becomes genuinely idempotent — safe to re-run after a failed or partial load without manual cleanup first.
