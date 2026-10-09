-- ============================================================================
-- SQL TEST 2 — ETL LAYERS: FULL QUESTION BANK
-- A fresh, standalone scenario and schema — not reused from Test 1.
-- Each of the 8 real Test 2 questions (Q1-Q8) is treated as its own TOPIC.
-- Every topic has 10 question variants. PostgreSQL code is placed directly
-- below each question.
-- ============================================================================


-- ============================================================================
-- SCENARIO & SCHEMA
-- ============================================================================
-- An online retail company exports a nightly raw orders file into a single
-- denormalized staging table. The ETL pipeline has three layers:
--
--   STAGING     — stg_orders_raw: one row per order line item, raw/text
--                 columns, customer and product details repeated on every
--                 row (classic flat-file export).
--
--   INTERMEDIATE — int_customers, int_products, int_orders, int_order_items,
--                 order_status_history: cleaned, typed, normalized entity
--                 tables with proper foreign keys.
--
--   REPORTING   — dim_customer (SCD Type 2), dim_product, dim_date,
--                 fact_orders: a star schema built FROM the intermediate
--                 layer, purposely re-denormalized for fast BI queries.
--
-- Base DDL (assume these exist before working through the topics below;
-- Topic 1 and Topic 4 walk through designing them):
--
-- CREATE TABLE stg_orders_raw (
--     row_id               SERIAL PRIMARY KEY,
--     order_ref            VARCHAR(50),
--     customer_full_name   VARCHAR(150),
--     customer_email_raw   VARCHAR(150),
--     customer_country_raw VARCHAR(100),
--     product_sku          VARCHAR(50),
--     product_name_raw     VARCHAR(150),
--     product_category_raw VARCHAR(100),
--     qty_raw               VARCHAR(20),
--     unit_price_raw         VARCHAR(20),
--     order_date_raw         VARCHAR(20),
--     order_status_raw       VARCHAR(30),
--     load_ts                TIMESTAMP DEFAULT NOW()
-- );
-- ============================================================================


-- ============================================================================
-- TOPIC 1 — DENORMALIZING FOR REPORTING: INSPECT STAGING, WRITE INTERMEDIATE DDL (Q1)
-- ============================================================================

-- 1.1 Write the full intermediate-layer DDL (customers, products, orders, order_items).
CREATE TABLE int_customers (
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(150) NOT NULL,
    email       VARCHAR(150) UNIQUE,
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
);

CREATE TABLE int_order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT REFERENCES int_orders(order_id),
    product_id    INT REFERENCES int_products(product_id),
    quantity      INT,
    unit_price    DECIMAL
);

-- 1.2 Profile the raw status values before deciding how to standardize them.
SELECT DISTINCT order_status_raw, COUNT(*) AS occurrence_count
FROM stg_orders_raw
GROUP BY order_status_raw
ORDER BY occurrence_count DESC;

-- 1.3 Write int_customers with a NOT NULL + UNIQUE email to prevent duplicates.
CREATE TABLE int_customers (
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(150) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    country     VARCHAR(100),
    created_at  TIMESTAMP DEFAULT NOW()
);

-- 1.4 Profile rows where quantity/price can't be safely cast to a number.
SELECT row_id, qty_raw, unit_price_raw
FROM stg_orders_raw
WHERE qty_raw !~ '^[0-9]+$' OR unit_price_raw !~ '^[0-9]+(\.[0-9]+)?$';

-- 1.5 Write int_orders with a CHECK constraint on the standardized status set.
CREATE TABLE int_orders (
    order_id     SERIAL PRIMARY KEY,
    order_ref    VARCHAR(50) UNIQUE,
    customer_id  INT REFERENCES int_customers(customer_id),
    order_date   DATE,
    order_status VARCHAR(20) CHECK (order_status IN ('PENDING','COMPLETED','CANCELLED','RETURNED','EXPIRED'))
);

-- 1.6 Profile stg_orders_raw for duplicate order_ref values.
SELECT order_ref, COUNT(*) AS occurrence_count
FROM stg_orders_raw
GROUP BY order_ref
HAVING COUNT(*) > 1;

-- 1.7 Write int_order_items, and explain how its grain relates to the raw staging row.
-- stg_orders_raw is one row per order LINE ITEM, with customer and product
-- details repeated on every line (fully denormalized). int_order_items
-- keeps that same one-row-per-line grain, but normalizes it to just
-- (order_id, product_id, quantity, unit_price) — descriptive attributes
-- move out into int_customers / int_products, referenced by foreign key.
CREATE TABLE int_order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT REFERENCES int_orders(order_id),
    product_id    INT REFERENCES int_products(product_id),
    quantity      INT,
    unit_price    DECIMAL
);

-- 1.8 Profile rows with a missing or blank customer email.
SELECT row_id, order_ref, customer_email_raw
FROM stg_orders_raw
WHERE customer_email_raw IS NULL OR TRIM(customer_email_raw) = '';

-- 1.9 Add a lineage-tracking batch id column to every intermediate table.
ALTER TABLE int_customers ADD COLUMN loaded_batch_id VARCHAR(50);
ALTER TABLE int_products ADD COLUMN loaded_batch_id VARCHAR(50);
ALTER TABLE int_orders ADD COLUMN loaded_batch_id VARCHAR(50);
ALTER TABLE int_order_items ADD COLUMN loaded_batch_id VARCHAR(50);

-- 1.10 Written: why does the intermediate layer split the flat staging row into 4 tables?
-- stg_orders_raw repeats customer and product details on every line-item
-- row, which is fine for a raw export but wastes space and risks
-- inconsistency (the same customer's name could be spelled differently
-- across rows). Splitting into int_customers, int_products, int_orders,
-- and int_order_items gives each entity a single authoritative row,
-- enforces referential integrity via foreign keys, and makes the data
-- reusable beyond just this one report — before the reporting layer
-- deliberately re-denormalizes it again (for query speed) in Topic 4.


-- ============================================================================
-- TOPIC 2 — STORED PROCEDURE: CLEANUP FROM STAGING TO INTERMEDIATE (Q2)
-- ============================================================================

-- 2.1 The full staging-to-intermediate load procedure.
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

-- 2.2 A narrower procedure that only dedupes and loads customers.
CREATE OR REPLACE PROCEDURE load_distinct_customers()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO int_customers (full_name, email, country)
    SELECT DISTINCT ON (LOWER(TRIM(customer_email_raw)))
           customer_full_name, LOWER(TRIM(customer_email_raw)), customer_country_raw
    FROM stg_orders_raw
    WHERE customer_email_raw IS NOT NULL
    ON CONFLICT (email) DO NOTHING;
END;
$$;

-- 2.3 A procedure that standardizes inconsistent status casing before load.
CREATE OR REPLACE PROCEDURE standardize_order_status()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE stg_orders_raw
    SET order_status_raw = UPPER(TRIM(order_status_raw));
    -- int_orders' CHECK constraint (Topic 1.5) will reject anything
    -- outside the allowed set at insert time.
END;
$$;

-- 2.4 A procedure that parses a known inconsistent raw date format.
CREATE OR REPLACE PROCEDURE clean_order_dates()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE stg_orders_raw
    SET order_date_raw = TO_CHAR(TO_DATE(order_date_raw, 'DD-MM-YYYY'), 'YYYY-MM-DD')
    WHERE order_date_raw ~ '^\d{2}-\d{2}-\d{4}$';
END;
$$;

-- 2.5 Make the customer-load step safely re-runnable with ON CONFLICT.
INSERT INTO int_customers (full_name, email, country)
SELECT DISTINCT customer_full_name, LOWER(TRIM(customer_email_raw)), customer_country_raw
FROM stg_orders_raw
ON CONFLICT (email) DO NOTHING;

-- 2.6 A procedure that quarantines bad rows instead of aborting the whole load.
CREATE TABLE stg_orders_rejects (
    row_id            INT,
    rejection_reason  VARCHAR(200),
    rejected_at       TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE load_order_items_safely()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT * FROM stg_orders_raw LOOP
        BEGIN
            INSERT INTO int_order_items (order_id, product_id, quantity, unit_price)
            SELECT o.order_id, p.product_id, rec.qty_raw::INT, rec.unit_price_raw::DECIMAL
            FROM int_orders o JOIN int_products p ON p.sku = rec.product_sku
            WHERE o.order_ref = rec.order_ref;
        EXCEPTION WHEN OTHERS THEN
            INSERT INTO stg_orders_rejects (row_id, rejection_reason)
            VALUES (rec.row_id, SQLERRM);
        END;
    END LOOP;
END;
$$;

-- 2.7 An incremental version that only processes rows newer than the last run.
CREATE OR REPLACE PROCEDURE incremental_cleanup(p_since TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO int_customers (full_name, email, country)
    SELECT DISTINCT customer_full_name, LOWER(TRIM(customer_email_raw)), customer_country_raw
    FROM stg_orders_raw
    WHERE load_ts > p_since
    ON CONFLICT (email) DO NOTHING;
END;
$$;

-- 2.8 A post-load validation query flagging broken foreign keys.
SELECT oi.order_item_id, oi.order_id, oi.product_id
FROM int_order_items oi
LEFT JOIN int_orders o ON o.order_id = oi.order_id
LEFT JOIN int_products p ON p.product_id = oi.product_id
WHERE o.order_id IS NULL OR p.product_id IS NULL;

-- 2.9 Reset staging after a successful run.
TRUNCATE TABLE stg_orders_raw;
-- Run only after stage_to_intermediate_load() has completed successfully.

-- 2.10 Wrap the full cleanup in a single all-or-nothing procedure.
CREATE OR REPLACE PROCEDURE stage_to_intermediate_load_safe()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO int_customers (full_name, email, country)
    SELECT DISTINCT customer_full_name, LOWER(TRIM(customer_email_raw)), customer_country_raw
    FROM stg_orders_raw
    ON CONFLICT (email) DO NOTHING;

    INSERT INTO int_products (sku, product_name, category)
    SELECT DISTINCT product_sku, product_name_raw, product_category_raw
    FROM stg_orders_raw
    ON CONFLICT (sku) DO NOTHING;

    INSERT INTO int_orders (order_ref, customer_id, order_date, order_status)
    SELECT DISTINCT s.order_ref, c.customer_id, s.order_date_raw::DATE, UPPER(TRIM(s.order_status_raw))
    FROM stg_orders_raw s JOIN int_customers c ON c.email = LOWER(TRIM(s.customer_email_raw))
    ON CONFLICT (order_ref) DO NOTHING;

    INSERT INTO int_order_items (order_id, product_id, quantity, unit_price)
    SELECT o.order_id, p.product_id, s.qty_raw::INT, s.unit_price_raw::DECIMAL
    FROM stg_orders_raw s
    JOIN int_orders o ON o.order_ref = s.order_ref
    JOIN int_products p ON p.sku = s.product_sku;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Load failed, rolling back: %', SQLERRM;
        RAISE;
END;
$$;
-- A PROCEDURE body called without internal COMMITs runs as one implicit
-- transaction — a failure partway through rolls back everything it inserted.


-- ============================================================================
-- TOPIC 3 — STORED PROCEDURE: ORDER STATUS HISTORY WITH CONTROL FLOW (Q3)
-- ============================================================================

-- 3.1 The core procedure: log a status change only if it actually changed.
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

-- 3.2 Reject a status change that would move the order backward in its lifecycle.
CREATE OR REPLACE PROCEDURE log_order_status_change_guarded(p_order_id INT, p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR;
    v_lifecycle TEXT[] := ARRAY['PENDING','COMPLETED','RETURNED'];
BEGIN
    SELECT status INTO v_current_status FROM order_status_history
    WHERE order_id = p_order_id ORDER BY changed_at DESC LIMIT 1;

    IF v_current_status IS NOT NULL
       AND array_position(v_lifecycle, p_new_status) < array_position(v_lifecycle, v_current_status) THEN
        RAISE EXCEPTION 'Cannot move order % backward from % to %', p_order_id, v_current_status, p_new_status;
    END IF;

    IF v_current_status IS DISTINCT FROM p_new_status THEN
        INSERT INTO order_status_history (order_id, status) VALUES (p_order_id, p_new_status);
    END IF;
END;
$$;

-- 3.3 Process a whole batch of pending status changes in a loop.
CREATE OR REPLACE PROCEDURE process_status_batch()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT * FROM pending_status_changes LOOP
        CALL log_order_status_change(rec.order_id, rec.new_status);
    END LOOP;
END;
$$;
-- Assumes a temp/staging table pending_status_changes(order_id, new_status).

-- 3.4 Map a raw incoming status code to a standardized status with CASE.
CREATE OR REPLACE PROCEDURE log_status_from_raw_code(p_order_id INT, p_raw_code VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR;
BEGIN
    v_status := CASE p_raw_code
        WHEN 'C' THEN 'COMPLETED'
        WHEN 'P' THEN 'PENDING'
        WHEN 'X' THEN 'CANCELLED'
        WHEN 'R' THEN 'RETURNED'
        ELSE 'UNKNOWN'
    END;
    CALL log_order_status_change(p_order_id, v_status);
END;
$$;

-- 3.5 Cascade a CANCELLED status to the order's line items as well.
CREATE OR REPLACE PROCEDURE log_order_status_change_cascading(p_order_id INT, p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    CALL log_order_status_change(p_order_id, p_new_status);

    IF p_new_status = 'CANCELLED' THEN
        UPDATE int_order_items SET order_id = order_id -- placeholder for an item_status column
        WHERE order_id = p_order_id;
    END IF;
END;
$$;

-- 3.6 Use a loop (WHILE/FOR) to auto-expire stale PENDING orders.
CREATE OR REPLACE PROCEDURE expire_stale_pending_orders(p_days_threshold INT)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT order_id FROM int_orders
        WHERE order_status = 'PENDING' AND order_date < CURRENT_DATE - p_days_threshold
    LOOP
        CALL log_order_status_change(rec.order_id, 'EXPIRED');
        UPDATE int_orders SET order_status = 'EXPIRED' WHERE order_id = rec.order_id;
    END LOOP;
END;
$$;

-- 3.7 A helper FUNCTION that returns an order's current status.
CREATE OR REPLACE FUNCTION get_current_order_status(p_order_id INT) RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR;
BEGIN
    SELECT status INTO v_status FROM order_status_history
    WHERE order_id = p_order_id ORDER BY changed_at DESC LIMIT 1;
    RETURN v_status;
END;
$$;

-- 3.8 Log both old and new status plus who made the change.
ALTER TABLE order_status_history ADD COLUMN old_status VARCHAR(20);

CREATE OR REPLACE PROCEDURE log_order_status_change_audited(p_order_id INT, p_new_status VARCHAR, p_changed_by VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    v_current_status := get_current_order_status(p_order_id);

    IF v_current_status IS DISTINCT FROM p_new_status THEN
        INSERT INTO order_status_history (order_id, status, old_status, changed_by)
        VALUES (p_order_id, p_new_status, v_current_status, p_changed_by);
    END IF;
END;
$$;

-- 3.9 Handle the very first status row differently from subsequent changes.
CREATE OR REPLACE PROCEDURE initialize_order_status(p_order_id INT, p_status VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM order_status_history WHERE order_id = p_order_id) THEN
        INSERT INTO order_status_history (order_id, status) VALUES (p_order_id, p_status);
    ELSE
        CALL log_order_status_change(p_order_id, p_status);
    END IF;
END;
$$;

-- 3.10 Raise a custom exception for an invalid status value.
CREATE OR REPLACE PROCEDURE log_order_status_change_strict(p_order_id INT, p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_allowed TEXT[] := ARRAY['PENDING','COMPLETED','CANCELLED','RETURNED','EXPIRED'];
BEGIN
    IF NOT (p_new_status = ANY(v_allowed)) THEN
        RAISE EXCEPTION 'Invalid order status: %. Allowed values: %', p_new_status, v_allowed;
    END IF;
    CALL log_order_status_change(p_order_id, p_new_status);
END;
$$;


-- ============================================================================
-- TOPIC 4 — STAR SCHEMA: FACT & DIMENSION TABLES FROM INTERMEDIATE TO REPORTING (Q4)
-- ============================================================================

-- 4.1 Full star schema DDL.
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

-- 4.2 Load dim_product from int_products (a simple Type 1 dimension).
INSERT INTO dim_product (product_id, product_name, category)
SELECT product_id, product_name, category FROM int_products;

-- 4.3 Generate dim_date, one row per calendar day across a range.
INSERT INTO dim_date (date_key, full_date, year, month, day, quarter)
SELECT TO_CHAR(d, 'YYYYMMDD')::INT, d,
       EXTRACT(YEAR FROM d)::INT, EXTRACT(MONTH FROM d)::INT,
       EXTRACT(DAY FROM d)::INT, EXTRACT(QUARTER FROM d)::INT
FROM generate_series('2021-01-01'::DATE, '2025-12-31'::DATE, '1 day') AS d;

-- 4.4 Load fact_orders from int_orders + int_order_items, resolving dimension keys.
INSERT INTO fact_orders (order_id, order_ref, customer_key, product_key, date_key, quantity, unit_price, revenue)
SELECT o.order_id, o.order_ref, dc.customer_key, dp.product_key,
       TO_CHAR(o.order_date, 'YYYYMMDD')::INT,
       oi.quantity, oi.unit_price, oi.quantity * oi.unit_price
FROM int_orders o
JOIN int_order_items oi ON oi.order_id = o.order_id
JOIN dim_customer dc ON dc.customer_id = o.customer_id AND dc.is_current = TRUE
JOIN dim_product dp ON dp.product_id = oi.product_id;

-- 4.5 A report that shows why the star schema simplifies querying.
SELECT dc.full_name, dp.category, dd.year, dd.quarter,
       SUM(f.revenue) AS total_revenue
FROM fact_orders f
JOIN dim_customer dc ON dc.customer_key = f.customer_key
JOIN dim_product dp ON dp.product_key = f.product_key
JOIN dim_date dd ON dd.date_key = f.date_key
GROUP BY dc.full_name, dp.category, dd.year, dd.quarter;
-- One join per dimension — no need to know the normalized intermediate
-- layer's full foreign-key chain to write this report.

-- 4.6 A degenerate dimension: keep order_ref directly on the fact table.
ALTER TABLE fact_orders ADD COLUMN IF NOT EXISTS order_ref VARCHAR(50);
-- order_ref has no descriptive attributes of its own worth modeling as a
-- separate dimension — it only exists for traceability back to the source
-- order, so it stays a plain "degenerate dimension" column on the fact row.

-- 4.7 Add a brand-new dimension (warehouse) and wire it into the fact table.
CREATE TABLE dim_warehouse (
    warehouse_key  SERIAL PRIMARY KEY,
    warehouse_id   INT NOT NULL,
    warehouse_name VARCHAR(100),
    region         VARCHAR(50)
);
ALTER TABLE fact_orders ADD COLUMN warehouse_key INT REFERENCES dim_warehouse(warehouse_key);

-- 4.8 A typical BI slice: revenue by quarter and product category.
SELECT dd.quarter, dp.category, SUM(f.revenue) AS total_revenue
FROM fact_orders f
JOIN dim_date dd ON dd.date_key = f.date_key
JOIN dim_product dp ON dp.product_key = f.product_key
GROUP BY dd.quarter, dp.category
ORDER BY dd.quarter, total_revenue DESC;

-- 4.9 Written: what changes if the fact grain moves from line-item to order-level?
-- fact_orders currently has a grain of "one row per order line item". If
-- the grain changed to "one row per order", quantity/unit_price/revenue
-- would need to become order-level totals, and product_key would no
-- longer fit on the fact row at all (an order can have many products) —
-- it would need a bridge table or be dropped entirely, breaking any
-- existing "revenue by product" query built against the line-item grain.

-- 4.10 A pre-aggregated fact table for faster daily reporting.
CREATE TABLE fact_daily_revenue (
    date_key      INT REFERENCES dim_date(date_key) PRIMARY KEY,
    total_revenue DECIMAL,
    order_count   INT
);

INSERT INTO fact_daily_revenue (date_key, total_revenue, order_count)
SELECT date_key, SUM(revenue), COUNT(DISTINCT order_id)
FROM fact_orders
GROUP BY date_key;


-- ============================================================================
-- TOPIC 5 — SLOWLY CHANGING DIMENSION TYPE 2: VERSIONING dim_customer (Q5)
-- ============================================================================

-- 5.1 The core SCD Type 2 procedure.
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
        INSERT INTO dim_customer (customer_id, full_name, email, country, effective_from, is_current)
        VALUES (p_customer_id, p_full_name, p_email, p_country, CURRENT_DATE, TRUE);
    ELSIF v_current.full_name <> p_full_name OR v_current.email <> p_email OR v_current.country <> p_country THEN
        UPDATE dim_customer
        SET effective_to = CURRENT_DATE - 1, is_current = FALSE
        WHERE customer_key = v_current.customer_key;

        INSERT INTO dim_customer (customer_id, full_name, email, country, effective_from, is_current)
        VALUES (p_customer_id, p_full_name, p_email, p_country, CURRENT_DATE, TRUE);
    END IF;
END;
$$;

-- 5.2 Confirm no spurious version is created when nothing changed.
-- Already guaranteed by apply_customer_scd2's ELSIF: if full_name/email/
-- country all match the current row, neither the UPDATE nor INSERT runs.
CALL apply_customer_scd2(101, 'Rajesh Kumar', 'rajesh.k@mail.com', 'India');

-- 5.3 Process every customer from int_customers in one batch call.
CREATE OR REPLACE PROCEDURE apply_customer_scd2_batch()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT * FROM int_customers LOOP
        CALL apply_customer_scd2(rec.customer_id, rec.full_name, rec.email, rec.country);
    END LOOP;
END;
$$;

-- 5.4 Point-in-time lookup: a customer's attributes as of a past date.
SELECT * FROM dim_customer
WHERE customer_id = 101
  AND DATE '2023-06-01' >= effective_from
  AND DATE '2023-06-01' < COALESCE(effective_to, DATE '9999-12-31');

-- 5.5 Find customers who've changed 3 or more times (frequent changers).
SELECT customer_id, COUNT(*) AS version_count
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) >= 3;

-- 5.6 Track specifically WHICH column changed on each new version.
ALTER TABLE dim_customer ADD COLUMN changed_fields VARCHAR(200);

CREATE OR REPLACE PROCEDURE apply_customer_scd2_tracked(
    p_customer_id INT, p_full_name VARCHAR, p_email VARCHAR, p_country VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current RECORD;
    v_changes VARCHAR := '';
BEGIN
    SELECT * INTO v_current FROM dim_customer WHERE customer_id = p_customer_id AND is_current = TRUE;

    IF v_current IS NOT NULL THEN
        IF v_current.full_name <> p_full_name THEN v_changes := v_changes || 'full_name,'; END IF;
        IF v_current.email <> p_email THEN v_changes := v_changes || 'email,'; END IF;
        IF v_current.country <> p_country THEN v_changes := v_changes || 'country,'; END IF;

        IF v_changes <> '' THEN
            UPDATE dim_customer SET effective_to = CURRENT_DATE - 1, is_current = FALSE
            WHERE customer_key = v_current.customer_key;

            INSERT INTO dim_customer (customer_id, full_name, email, country, effective_from, is_current, changed_fields)
            VALUES (p_customer_id, p_full_name, p_email, p_country, CURRENT_DATE, TRUE, v_changes);
        END IF;
    END IF;
END;
$$;

-- 5.7 Reconstruct a customer's full version history with days-per-version.
SELECT customer_id, full_name, effective_from, effective_to,
       COALESCE(effective_to, CURRENT_DATE) - effective_from AS days_as_this_version
FROM dim_customer
WHERE customer_id = 101
ORDER BY effective_from;

-- 5.8 Soft-delete a customer (close their current row, no new version).
CREATE OR REPLACE PROCEDURE soft_delete_customer(p_customer_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE dim_customer
    SET effective_to = CURRENT_DATE, is_current = FALSE
    WHERE customer_id = p_customer_id AND is_current = TRUE;
END;
$$;

-- 5.9 Written: why does dim_customer need a surrogate key for SCD Type 2 to work?
-- customer_id is the NATURAL key and repeats across every historical
-- version of that customer in dim_customer, so it can't be used by
-- fact_orders — doing so would make it ambiguous which version a fact row
-- points to. customer_key is a SURROGATE key, unique per VERSION, so
-- fact_orders can reference the exact version of the customer that was
-- current at the time of that order — the entire point of SCD Type 2.

-- 5.10 Wrap the close-out and new-version insert in an explicit transaction.
CREATE OR REPLACE PROCEDURE apply_customer_scd2_txn(
    p_customer_id INT, p_full_name VARCHAR, p_email VARCHAR, p_country VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current RECORD;
BEGIN
    SELECT * INTO v_current FROM dim_customer WHERE customer_id = p_customer_id AND is_current = TRUE;

    IF v_current IS NOT NULL AND
       (v_current.full_name <> p_full_name OR v_current.email <> p_email OR v_current.country <> p_country) THEN
        UPDATE dim_customer SET effective_to = CURRENT_DATE - 1, is_current = FALSE
        WHERE customer_key = v_current.customer_key;

        INSERT INTO dim_customer (customer_id, full_name, email, country, effective_from, is_current)
        VALUES (p_customer_id, p_full_name, p_email, p_country, CURRENT_DATE, TRUE);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'SCD2 update failed for customer %, rolling back: %', p_customer_id, SQLERRM;
        RAISE;
END;
$$;
-- As a single procedure body, the close-out UPDATE and the new-version
-- INSERT succeed or fail together.


-- ============================================================================
-- TOPIC 6 — VIEW: ORDER ACTIVITY SUMMARY PER CURRENT CUSTOMER (Q6)
-- ============================================================================

-- 6.1 The core view.
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

-- 6.2 Add average order value.
CREATE OR REPLACE VIEW vw_customer_order_activity AS
SELECT dc.customer_id, dc.full_name,
       COUNT(f.order_key) AS total_orders,
       SUM(f.revenue) AS total_revenue,
       ROUND(AVG(f.revenue), 2) AS avg_order_value,
       MAX(dd.full_date) AS most_recent_order_date
FROM dim_customer dc
LEFT JOIN fact_orders f ON f.customer_key = dc.customer_key
LEFT JOIN dim_date dd ON dd.date_key = f.date_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name;

-- 6.3 A rolling 12-month version of the view.
CREATE VIEW vw_customer_activity_last_12mo AS
SELECT dc.customer_id, dc.full_name,
       COUNT(f.order_key) AS orders_last_12mo,
       SUM(f.revenue) AS revenue_last_12mo
FROM dim_customer dc
LEFT JOIN fact_orders f ON f.customer_key = dc.customer_key
LEFT JOIN dim_date dd ON dd.date_key = f.date_key AND dd.full_date >= CURRENT_DATE - INTERVAL '12 months'
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name;

-- 6.4 Break activity down per product category.
CREATE VIEW vw_customer_activity_by_category AS
SELECT dc.customer_id, dc.full_name, dp.category,
       COUNT(f.order_key) AS orders_in_category,
       SUM(f.revenue) AS revenue_in_category
FROM dim_customer dc
JOIN fact_orders f ON f.customer_key = dc.customer_key
JOIN dim_product dp ON dp.product_key = f.product_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name, dp.category;

-- 6.5 Flag customers as ACTIVE / LAPSING / CHURNED by recency.
CREATE VIEW vw_customer_activity_flag AS
SELECT dc.customer_id, dc.full_name,
       MAX(dd.full_date) AS most_recent_order_date,
       CASE
           WHEN MAX(dd.full_date) IS NULL THEN 'NO ORDERS'
           WHEN MAX(dd.full_date) >= CURRENT_DATE - INTERVAL '90 days' THEN 'ACTIVE'
           WHEN MAX(dd.full_date) >= CURRENT_DATE - INTERVAL '180 days' THEN 'LAPSING'
           ELSE 'CHURNED'
       END AS activity_status
FROM dim_customer dc
LEFT JOIN fact_orders f ON f.customer_key = dc.customer_key
LEFT JOIN dim_date dd ON dd.date_key = f.date_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name;

-- 6.6 First and most recent order date per customer.
CREATE VIEW vw_customer_first_last_order AS
SELECT dc.customer_id, dc.full_name,
       MIN(dd.full_date) AS first_order_date,
       MAX(dd.full_date) AS most_recent_order_date
FROM dim_customer dc
JOIN fact_orders f ON f.customer_key = dc.customer_key
JOIN dim_date dd ON dd.date_key = f.date_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name;

-- 6.7 Query the view to find high-value current customers.
SELECT * FROM vw_customer_order_activity
WHERE total_revenue > 10000
ORDER BY total_revenue DESC;

-- 6.8 A layered view ranking customers by revenue.
CREATE VIEW vw_customer_revenue_rank AS
SELECT customer_id, full_name, total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM vw_customer_order_activity;

-- 6.9 Written: why filter to is_current = TRUE instead of joining on customer_id directly?
-- dim_customer holds one row PER VERSION under SCD Type 2, so joining by
-- the natural customer_id without the is_current filter would match
-- MULTIPLE rows per customer — every historical version — fanning out
-- fact_orders' revenue and inflating totals. Filtering to is_current =
-- TRUE guarantees exactly one dim_customer row per customer.

-- 6.10 Rewrite as a materialized view, with reasoning.
CREATE MATERIALIZED VIEW mv_customer_order_activity AS
SELECT dc.customer_id, dc.full_name,
       COUNT(f.order_key) AS total_orders,
       SUM(f.revenue) AS total_revenue,
       MAX(dd.full_date) AS most_recent_order_date
FROM dim_customer dc
LEFT JOIN fact_orders f ON f.customer_key = dc.customer_key
LEFT JOIN dim_date dd ON dd.date_key = f.date_key
WHERE dc.is_current = TRUE
GROUP BY dc.customer_id, dc.full_name;
-- A materialized view makes sense if this report is hit constantly (e.g.
-- a dashboard) but fact_orders is too large to recompute live every time —
-- the tradeoff is staleness between REFRESH MATERIALIZED VIEW runs.


-- ============================================================================
-- TOPIC 7 — QUERY PERFORMANCE AND INDEXING (Q7)
-- ============================================================================

-- 7.1 Index to speed up filtering fact_orders by customer + date range.
CREATE INDEX idx_fact_orders_customer_date ON fact_orders(customer_key, date_key);
-- customer_key first: it's the equality filter and higher-selectivity
-- column; date_key second supports the range filter within that customer.

-- 7.2 Written + index: why customer_id alone isn't enough for SCD2 point-in-time lookups.
-- An index on dim_customer(customer_id) alone doesn't help, because MANY
-- rows share the same customer_id under SCD Type 2 — the engine still has
-- to scan all of a customer's versions to find the one whose date range
-- covers the requested date.
CREATE INDEX idx_dim_customer_id_range ON dim_customer(customer_id, effective_from, effective_to);

-- 7.3 A covering index for "latest status per order" instead of a partial index.
-- A partial index on "most recent status" doesn't directly help, since
-- MAX(changed_at) per order still scans every row for that order. A
-- covering index that enables an index-only scan helps more:
CREATE INDEX idx_order_status_history_covering
ON order_status_history (order_id, changed_at DESC) INCLUDE (status);

-- 7.4 Rewrite a function-wrapped date filter to be index-friendly.
-- Original (not index-friendly): WHERE EXTRACT(YEAR FROM full_date) = 2023
SELECT * FROM dim_date WHERE full_date >= '2023-01-01' AND full_date < '2024-01-01';

-- 7.5 Written: why staging tables are usually left unindexed.
-- Staging tables are typically truncated and fully reloaded every run, and
-- every index must be rebuilt/updated on every bulk load — for a table
-- that's only ever fully scanned (never queried selectively), an index
-- adds pure write overhead with zero read benefit.

-- 7.6 Indexes to speed up the current-customer view's underlying join.
CREATE INDEX idx_dim_customer_current ON dim_customer(customer_key) WHERE is_current = TRUE;
CREATE INDEX idx_fact_orders_customer_key ON fact_orders(customer_key);

-- 7.7 A covering index that enables an index-only scan for a specific report.
CREATE INDEX idx_fact_orders_covering
ON fact_orders(customer_key, date_key) INCLUDE (revenue, quantity);
-- With revenue and quantity included, a query needing only those four
-- columns can be answered entirely from the index — no heap lookup needed.

-- 7.8 Written: why too many indexes hurt the nightly ETL load.
-- Every index on fact_orders must be updated on every row the nightly ETL
-- inserts, so a heavily-indexed fact table pays that cost on every load —
-- a common compromise is dropping/disabling non-essential indexes before a
-- large load and rebuilding them afterward.

-- 7.9 Diagnose a sequential scan despite a WHERE filter.
-- Likely causes: (a) no index exists on the filtered column, (b) an index
-- exists but the filter wraps the column in a function, preventing its
-- use, or (c) the filter matches such a large fraction of rows that a
-- sequential scan is genuinely cheaper. Fix for (a)/(b):
CREATE INDEX idx_fact_orders_date_key ON fact_orders(date_key);

-- 7.10 Written: B-tree vs BRIN for a large append-only fact table.
-- A B-tree is the general-purpose default, efficient for exact-match and
-- range queries, but grows with the table and is costly to maintain on
-- very high insert-volume tables. A BRIN index is far smaller and cheaper
-- to maintain, and works well when a column is naturally correlated with
-- physical row order — e.g. date_key on an append-only fact table, where
-- new rows arrive in roughly increasing date order. Choose BRIN for large,
-- append-only, naturally-ordered columns; choose B-tree for precise point
-- lookups or columns with no natural physical ordering.
CREATE INDEX idx_fact_orders_date_brin ON fact_orders USING BRIN (date_key);


-- ============================================================================
-- TOPIC 8 — WRITTEN: IS THE STAGING-TO-INTERMEDIATE PROCEDURE IDEMPOTENT? (Q8)
-- ============================================================================

-- 8.1 Written: is stage_to_intermediate_load() from Topic 2.1 safe to run twice?
-- Mostly yes, because every INSERT in it uses ON CONFLICT DO NOTHING
-- against a UNIQUE constraint (email, sku, order_ref) — running it again
-- against the same staging batch inserts nothing new the second time.
-- int_order_items is the exception: it has no uniqueness constraint of its
-- own, so re-running the procedure against the SAME staged rows would
-- insert duplicate order_item rows every time.

-- 8.2 Fix: add a uniqueness constraint so int_order_items becomes idempotent too.
ALTER TABLE int_order_items
ADD CONSTRAINT uq_order_product UNIQUE (order_id, product_id);
-- (Then the INSERT in 2.1 would also need an ON CONFLICT (order_id, product_id) DO NOTHING clause.)

-- 8.3 Written: what does "idempotent" mean in this specific ETL context?
-- Running the same procedure call twice against the same input produces
-- the SAME end state as running it once — no duplicate rows, no doubled
-- totals — which matters because a nightly job can fail partway through
-- and simply be re-run from the start without manual cleanup first.

-- 8.4 Demonstrate the non-idempotent behavior directly.
-- Before the fix in 8.2, calling stage_to_intermediate_load() twice in a
-- row against the same stg_orders_raw batch doubles int_order_items:
SELECT order_id, product_id, COUNT(*) AS row_count
FROM int_order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- 8.5 Written: does TRUNCATEing staging after a successful run (Topic 2.9) affect idempotency?
-- It changes WHEN re-running matters, not whether the procedure itself is
-- idempotent: if staging is truncated after every successful run, a
-- second CALL with nothing left in stg_orders_raw is a safe no-op
-- regardless. Idempotency of the procedure's own logic only matters when
-- staging DOES still contain the same rows — e.g. after a failed run that
-- didn't reach the truncate step, which is exactly the retry scenario this
-- property needs to handle.

-- 8.6 Compare to the incremental procedure (Topic 2.7) — is it idempotent?
-- incremental_cleanup(p_since) re-runs against WHATEVER is newer than
-- p_since, so calling it twice with the SAME p_since inserts the same
-- customers again — not idempotent on its own either, unless its INSERT
-- also uses ON CONFLICT DO NOTHING (which, in 2.7, it does for int_customers
-- specifically, so that part is safe; a fuller version touching
-- int_order_items would need the same 8.2 fix).

-- 8.7 Written: does the SCD Type 2 procedure (Topic 5.1) need the same scrutiny?
-- Yes, and it already passes: apply_customer_scd2's ELSIF guard means
-- calling it twice with identical inputs creates no second version the
-- second time — it IS idempotent by design, which is exactly what
-- Topic 5.2 demonstrates.

-- 8.8 Written: is log_order_status_change (Topic 3.1) idempotent?
-- Yes — it only inserts when the new status differs from the last
-- recorded one, so calling it twice in a row with the same p_new_status
-- inserts nothing the second time.

-- 8.9 A general test query to verify idempotency after any procedure run.
-- Run the procedure, note the row counts, run it again, and confirm the
-- counts are unchanged:
SELECT 'int_customers' AS tbl, COUNT(*) FROM int_customers
UNION ALL
SELECT 'int_orders', COUNT(*) FROM int_orders
UNION ALL
SELECT 'int_order_items', COUNT(*) FROM int_order_items;

-- 8.10 Written: the general rule of thumb for writing idempotent ETL procedures.
-- Every INSERT that could run against the same source data twice needs a
-- uniqueness constraint to anchor an ON CONFLICT clause against (or an
-- equivalent "does this already exist" check before inserting). Every
-- UPDATE should be written so applying it again produces the same result
-- (e.g. SET status = 'X', not SET counter = counter + 1). A procedure is
-- only as idempotent as its least-guarded statement.


-- ============================================================================
-- END OF QUESTION BANK — 8 topics x 10 variants = 80 questions
-- ============================================================================
