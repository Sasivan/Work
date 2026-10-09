-- ============================================================================
-- SQL MASTERY ASSIGNMENT — TEST QUESTIONS, SET 3 (Revised)
-- One unified scenario, two clean sections. No shuffling this time.
--
-- SECTION 1 — 10 standalone DDL/DML questions. Each one exercises a
-- different combination of SQL concepts; no topic repeats across the 10.
-- Ordered loosely fundamental -> advanced. Solve in any order.
--
-- SECTION 2 — 10-step ETL pipeline. These ARE dependent on each other —
-- each step builds on the table(s)/objects created or loaded by the
-- step(s) before it. Must be solved in Step order.
--
-- Same 12-table dataset as the main assignment, plus the new objects this
-- scenario asks you to create. Full PostgreSQL answers are at the end.
-- ============================================================================


-- ============================================================================
-- SCENARIO
-- ============================================================================
-- DataGrokr Retail is opening a new regional distribution center and needs
-- the schema extended and cleaned up to support it (Section 1), plus a
-- proper nightly ETL pipeline that incrementally pulls new/changed orders,
-- validates and cleans them, deduplicates same-batch resends, loads them
-- into production, and tracks exactly how far it has loaded so it never
-- re-processes the same data twice (Section 2).
-- ============================================================================


-- ============================================================================
-- SECTION 1 — DDL / DML (10 independent questions, mixed difficulty)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- S1-Q1 [Easy] [Topic: CREATE TABLE + PRIMARY KEY + UNIQUE + CHECK]
-- Create a new table `warehouses` with: warehouse_id as the primary key,
-- warehouse_name that must be unique and not null, region, location, and
-- capacity_units that must always be greater than 0.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q2 [Medium] [Topic: ALTER TABLE — add column, default, foreign key, NOT NULL]
-- Add a warehouse_id column to orders. Give every existing row a default
-- value of 1 so the ALTER doesn't fail on current data, make it a foreign
-- key referencing warehouses(warehouse_id), then make the column NOT NULL
-- now that every row has a value.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q3 [Medium] [Topic: CREATE VIEW over a join + aggregation]
-- Create a view vw_department_headcount that, for each department, shows
-- department_name, active employee count, and average active salary —
-- so this logic can be queried as a simple SELECT from the view going
-- forward instead of re-written every time.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q4 [Easy] [Topic: CREATE TABLE with an identity column + INSERT]
-- Create a table customer_loyalty_tiers with an auto-generated primary key
-- (tier_id), tier_name, min_points, and a notes column, using a GENERATED
-- ALWAYS AS IDENTITY column rather than a manually-assigned key. Then
-- insert 3 rows: Silver (0 pts), Gold (5000 pts), Platinum (20000 pts).
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q5 [Medium] [Topic: INSERT ... SELECT with a subquery filter]
-- Create a table high_value_customers (customer_id, customer_name,
-- lifetime_value), then populate it in one statement by selecting every
-- customer whose total COMPLETED order value exceeds 10000.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q6 [Medium] [Topic: UPDATE driven by a subquery]
-- Give every employee who has ever held a 'Lead' role in employee_projects
-- a 3% salary increase, using a subquery against employee_projects inside
-- the UPDATE's WHERE clause (not a join).
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q7 [Hard] [Topic: DELETE ... USING (join-based delete)]
-- Using PostgreSQL's DELETE ... USING syntax (a join inside the DELETE
-- itself, not a subquery), remove every order_items row that belongs to
-- a CANCELLED order.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q8 [Hard] [Topic: partial / conditional index]
-- Create a partial index on orders(customer_id) that only indexes rows
-- where order_status = 'PENDING' — smaller and faster than indexing every
-- row, since dashboards only ever filter pending orders by customer.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q9 [Hard] [Topic: trigger function + trigger]
-- Create a trigger function and an AFTER UPDATE trigger on products so
-- that any time list_price changes, a row is automatically inserted into
-- price_change_log capturing product_id, old_price, and new_price —
-- without relying on the application to remember to log it.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S1-Q10 [Medium] [Topic: RENAME COLUMN + DROP COLUMN + ADD CONSTRAINT]
-- On customer_loyalty_tiers (from S1-Q4): rename tier_name to
-- loyalty_tier, drop the now-unused notes column, and add a CHECK
-- constraint ensuring min_points is never negative.
-- ----------------------------------------------------------------------------


-- ============================================================================
-- SECTION 2 — ETL PIPELINE (10 sequential steps — solve in order)
-- Pipeline: incrementally load new/changed orders since the last
-- successful run, validate and clean them, deduplicate same-batch
-- resends, load into production, and advance a watermark so the next
-- run never reprocesses the same rows.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- S2-Step 1 [Medium] [Topic: watermark / control table]
-- Create an etl_watermark table (pipeline_name as primary key,
-- last_loaded_at timestamp), then insert a starting row for a pipeline
-- named 'orders_incremental_load' with a deliberately old timestamp
-- (e.g. year 2000) so the very first run picks up all historical orders.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 2 [Medium] [Topic: staging table design]
-- Create an unconstrained staging table stg_orders_incremental mirroring
-- orders' columns, plus order_size, load_batch_id, and loaded_at. No
-- primary key, foreign key, or NOT NULL constraints.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 3 [Medium] [Topic: incremental extraction using the watermark]
-- Extract only orders with an order_date AFTER the current watermark
-- value for 'orders_incremental_load' into stg_orders_incremental,
-- stamping each row with a generated load_batch_id. In a comment, note
-- that in a real pipeline this SELECT would read from an external source
-- system rather than from orders itself.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 4 [Medium] [Topic: multi-rule validation / quarantine]
-- Create stg_orders_incremental_rejects (staging shape + rejection_reason)
-- and quarantine every staged row that has ANY of: a NULL customer_id, a
-- customer_id with no match in customers, or a negative total_amount —
-- tagging each row with which specific rule it failed.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 5 [Medium] [Topic: transformation — cleanse and derive]
-- Remove the now-quarantined rows from staging. On the remaining valid
-- rows, standardize ship_country (trim + uppercase) and populate the
-- order_size column ('Small' < 1000, 'Medium' 1000-5000, 'Large' > 5000)
-- based on total_amount.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 6 [Hard] [Topic: deduplication within a batch]
-- If the same order_id appears more than once in stg_orders_incremental
-- (e.g. a same-day correction resend), keep only the most recently loaded
-- version (by loaded_at) and delete the rest.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 7 [Hard] [Topic: stored procedure + exception handling]
-- Create a pipeline_error_log table, then wrap Steps 4-6 (quarantine,
-- cleanse, deduplicate) into a single stored PROCEDURE
-- extract_and_transform_orders(), with an EXCEPTION WHEN OTHERS block
-- that logs the error message into pipeline_error_log and re-raises it
-- rather than silently swallowing the failure.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 8 [Hard] [Topic: upsert load + watermark advancement]
-- Upsert every remaining staged row into the real orders table (insert
-- new order_ids, update existing ones). Then advance etl_watermark's
-- last_loaded_at to the MAX(order_date) found in this batch — but only if
-- the batch actually had rows, so an empty run never corrupts the
-- watermark.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 9 [Medium] [Topic: audit logging + reset]
-- Create pipeline_run_log (if it doesn't exist) and insert one row for
-- this run recording rows extracted, rows rejected, rows loaded, and a
-- status of 'SUCCESS'. Then TRUNCATE stg_orders_incremental, leaving
-- stg_orders_incremental_rejects untouched for manual review.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- S2-Step 10 [Hard] [Topic: orchestration wrapper + idempotency guarantee]
-- Create a master stored PROCEDURE run_orders_etl_pipeline() that performs
-- the full nightly run end to end: extract (Step 3 logic), CALL
-- extract_and_transform_orders() (Step 7), upsert + advance the watermark
-- (Step 8), log the run (Step 9), and truncate staging — with its own
-- EXCEPTION handler that logs a FAILED run without advancing the
-- watermark. In a comment, explain exactly what makes a failed run safe
-- to retry the next night without reprocessing or duplicating data. Show
-- the one-line CALL a nightly scheduler would use to invoke it.
-- ----------------------------------------------------------------------------


-- ============================================================================
-- END OF QUESTIONS
-- ============================================================================



-- ============================================================================
-- ============================================================================
--                          ANSWER KEY — POSTGRESQL
-- ============================================================================
-- ============================================================================


-- ===================== SECTION 1 =====================

-- S1-Q1
CREATE TABLE warehouses (
    warehouse_id   INT PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL UNIQUE,
    region         VARCHAR(50),
    location       VARCHAR(100),
    capacity_units INT CHECK (capacity_units > 0)
);

-- S1-Q2
ALTER TABLE orders ADD COLUMN warehouse_id INT DEFAULT 1;

ALTER TABLE orders
ADD CONSTRAINT fk_orders_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);

ALTER TABLE orders ALTER COLUMN warehouse_id SET NOT NULL;

-- S1-Q3
CREATE VIEW vw_department_headcount AS
SELECT d.department_name,
       COUNT(e.employee_id) AS active_headcount,
       ROUND(AVG(e.salary), 2) AS avg_active_salary
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id AND e.status = 'ACTIVE'
GROUP BY d.department_name;

-- S1-Q4
CREATE TABLE customer_loyalty_tiers (
    tier_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tier_name  VARCHAR(50) NOT NULL,
    min_points INT,
    notes      VARCHAR(200)
);

INSERT INTO customer_loyalty_tiers (tier_name, min_points, notes) VALUES
    ('Silver',   0,     'Default tier'),
    ('Gold',     5000,  'Mid tier'),
    ('Platinum', 20000, 'Top tier');

-- S1-Q5
CREATE TABLE high_value_customers (
    customer_id    INT,
    customer_name  VARCHAR(100),
    lifetime_value DECIMAL
);

INSERT INTO high_value_customers (customer_id, customer_name, lifetime_value)
SELECT c.customer_id, c.customer_name, SUM(o.total_amount)
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'COMPLETED'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 10000;

-- S1-Q6
UPDATE employees
SET salary = salary * 1.03
WHERE employee_id IN (
    SELECT employee_id FROM employee_projects WHERE role = 'Lead'
);

-- S1-Q7
DELETE FROM order_items oi
USING orders o
WHERE oi.order_id = o.order_id
  AND o.order_status = 'CANCELLED';

-- S1-Q8
CREATE INDEX idx_orders_pending_customer
ON orders (customer_id)
WHERE order_status = 'PENDING';

-- S1-Q9
CREATE OR REPLACE FUNCTION log_price_change() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.list_price IS DISTINCT FROM OLD.list_price THEN
        INSERT INTO price_change_log (product_id, old_price, new_price, changed_by)
        VALUES (NEW.product_id, OLD.list_price, NEW.list_price, CURRENT_USER);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_price_change
AFTER UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION log_price_change();

-- S1-Q10
ALTER TABLE customer_loyalty_tiers RENAME COLUMN tier_name TO loyalty_tier;
ALTER TABLE customer_loyalty_tiers DROP COLUMN notes;
ALTER TABLE customer_loyalty_tiers
ADD CONSTRAINT chk_min_points_nonneg CHECK (min_points >= 0);


-- ===================== SECTION 2 — ETL PIPELINE =====================

-- S2-Step 1
CREATE TABLE etl_watermark (
    pipeline_name  VARCHAR(100) PRIMARY KEY,
    last_loaded_at TIMESTAMP NOT NULL
);

INSERT INTO etl_watermark (pipeline_name, last_loaded_at)
VALUES ('orders_incremental_load', '2000-01-01 00:00:00');

-- S2-Step 2
CREATE TABLE stg_orders_incremental (
    order_id      INT,
    customer_id   INT,
    order_date    DATE,
    order_status  VARCHAR(20),
    total_amount  DECIMAL,
    ship_country  VARCHAR(100),
    order_size    VARCHAR(20),
    load_batch_id VARCHAR(50),
    loaded_at     TIMESTAMP DEFAULT NOW()
);

-- S2-Step 3
-- In a real pipeline this SELECT would read from an external source system
-- (an API, a landing bucket, a source database) — here it's simulated
-- against `orders` itself since this dataset has no separate source table.
INSERT INTO stg_orders_incremental (order_id, customer_id, order_date, order_status, total_amount, ship_country, load_batch_id)
SELECT order_id, customer_id, order_date, order_status, total_amount, ship_country,
       'BATCH_' || TO_CHAR(NOW(), 'YYYYMMDD_HH24MISS')
FROM orders
WHERE order_date > (
    SELECT last_loaded_at FROM etl_watermark WHERE pipeline_name = 'orders_incremental_load'
);

-- S2-Step 4
CREATE TABLE stg_orders_incremental_rejects (
    order_id         INT,
    customer_id      INT,
    order_date       DATE,
    order_status     VARCHAR(20),
    total_amount     DECIMAL,
    ship_country     VARCHAR(100),
    load_batch_id    VARCHAR(50),
    rejection_reason VARCHAR(200)
);

INSERT INTO stg_orders_incremental_rejects
    (order_id, customer_id, order_date, order_status, total_amount, ship_country, load_batch_id, rejection_reason)
SELECT s.order_id, s.customer_id, s.order_date, s.order_status, s.total_amount, s.ship_country, s.load_batch_id,
    CASE
        WHEN s.customer_id IS NULL THEN 'missing customer_id'
        WHEN c.customer_id IS NULL THEN 'customer_id not found in customers'
        WHEN s.total_amount < 0 THEN 'negative total_amount'
    END
FROM stg_orders_incremental s
LEFT JOIN customers c ON s.customer_id = c.customer_id
WHERE s.customer_id IS NULL
   OR c.customer_id IS NULL
   OR s.total_amount < 0;

-- S2-Step 5
DELETE FROM stg_orders_incremental s
WHERE EXISTS (
    SELECT 1 FROM stg_orders_incremental_rejects r WHERE r.order_id = s.order_id
);

UPDATE stg_orders_incremental
SET ship_country = TRIM(UPPER(ship_country)),
    order_size = CASE
        WHEN total_amount < 1000 THEN 'Small'
        WHEN total_amount <= 5000 THEN 'Medium'
        ELSE 'Large'
    END;

-- S2-Step 6
DELETE FROM stg_orders_incremental s
USING (
    SELECT ctid, order_id,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY loaded_at DESC) AS rn
    FROM stg_orders_incremental
) r
WHERE s.ctid = r.ctid AND r.rn > 1;

-- S2-Step 7
CREATE TABLE IF NOT EXISTS pipeline_error_log (
    error_id      SERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100),
    error_message TEXT,
    occurred_at   TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE extract_and_transform_orders()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Quarantine invalid rows (multi-rule validation)
    INSERT INTO stg_orders_incremental_rejects
        (order_id, customer_id, order_date, order_status, total_amount, ship_country, load_batch_id, rejection_reason)
    SELECT s.order_id, s.customer_id, s.order_date, s.order_status, s.total_amount, s.ship_country, s.load_batch_id,
        CASE
            WHEN s.customer_id IS NULL THEN 'missing customer_id'
            WHEN c.customer_id IS NULL THEN 'customer_id not found in customers'
            WHEN s.total_amount < 0 THEN 'negative total_amount'
        END
    FROM stg_orders_incremental s
    LEFT JOIN customers c ON s.customer_id = c.customer_id
    WHERE s.customer_id IS NULL OR c.customer_id IS NULL OR s.total_amount < 0;

    -- Remove quarantined rows from staging
    DELETE FROM stg_orders_incremental s
    WHERE EXISTS (SELECT 1 FROM stg_orders_incremental_rejects r WHERE r.order_id = s.order_id);

    -- Cleanse and derive on remaining valid rows
    UPDATE stg_orders_incremental
    SET ship_country = TRIM(UPPER(ship_country)),
        order_size = CASE
            WHEN total_amount < 1000 THEN 'Small'
            WHEN total_amount <= 5000 THEN 'Medium'
            ELSE 'Large'
        END;

    -- Deduplicate within the batch, keeping the latest-loaded version per order_id
    DELETE FROM stg_orders_incremental s
    USING (
        SELECT ctid, order_id,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY loaded_at DESC) AS rn
        FROM stg_orders_incremental
    ) r
    WHERE s.ctid = r.ctid AND r.rn > 1;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO pipeline_error_log (pipeline_name, error_message)
        VALUES ('orders_incremental_load', SQLERRM);
        RAISE;
END;
$$;

-- S2-Step 8
INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount, ship_country)
SELECT order_id, customer_id, order_date, order_status, total_amount, ship_country
FROM stg_orders_incremental
ON CONFLICT (order_id)
DO UPDATE SET
    order_status = EXCLUDED.order_status,
    total_amount = EXCLUDED.total_amount,
    ship_country = EXCLUDED.ship_country;

UPDATE etl_watermark
SET last_loaded_at = (SELECT MAX(order_date) FROM stg_orders_incremental)
WHERE pipeline_name = 'orders_incremental_load'
  AND EXISTS (SELECT 1 FROM stg_orders_incremental);
-- The EXISTS guard means an empty batch (nothing new since last run) never
-- overwrites the watermark with a NULL MAX(order_date).

-- S2-Step 9
CREATE TABLE IF NOT EXISTS pipeline_run_log (
    run_id         SERIAL PRIMARY KEY,
    pipeline_name  VARCHAR(100),
    batch_id       VARCHAR(50),
    rows_extracted INT,
    rows_rejected  INT,
    rows_loaded    INT,
    run_timestamp  TIMESTAMP DEFAULT NOW(),
    status         VARCHAR(20)
);

INSERT INTO pipeline_run_log (pipeline_name, batch_id, rows_extracted, rows_rejected, rows_loaded, status)
SELECT
    'orders_incremental_load',
    (SELECT load_batch_id FROM stg_orders_incremental LIMIT 1),
    (SELECT COUNT(*) FROM stg_orders_incremental) + (SELECT COUNT(*) FROM stg_orders_incremental_rejects),
    (SELECT COUNT(*) FROM stg_orders_incremental_rejects),
    (SELECT COUNT(*) FROM stg_orders_incremental),
    'SUCCESS';

TRUNCATE TABLE stg_orders_incremental;
-- stg_orders_incremental_rejects is deliberately left alone for manual review.

-- S2-Step 10
CREATE OR REPLACE PROCEDURE run_orders_etl_pipeline()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_extracted INT;
    v_rows_rejected  INT;
    v_rows_loaded    INT;
    v_batch_id       VARCHAR(50);
BEGIN
    v_batch_id := 'BATCH_' || TO_CHAR(NOW(), 'YYYYMMDD_HH24MISS');

    -- Extract (incremental, watermark-driven)
    INSERT INTO stg_orders_incremental (order_id, customer_id, order_date, order_status, total_amount, ship_country, load_batch_id)
    SELECT order_id, customer_id, order_date, order_status, total_amount, ship_country, v_batch_id
    FROM orders
    WHERE order_date > (SELECT last_loaded_at FROM etl_watermark WHERE pipeline_name = 'orders_incremental_load');

    -- Validate, cleanse, deduplicate
    CALL extract_and_transform_orders();

    -- Load + advance watermark
    INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount, ship_country)
    SELECT order_id, customer_id, order_date, order_status, total_amount, ship_country
    FROM stg_orders_incremental
    ON CONFLICT (order_id) DO UPDATE SET
        order_status = EXCLUDED.order_status,
        total_amount = EXCLUDED.total_amount,
        ship_country = EXCLUDED.ship_country;

    UPDATE etl_watermark
    SET last_loaded_at = (SELECT MAX(order_date) FROM stg_orders_incremental)
    WHERE pipeline_name = 'orders_incremental_load'
      AND EXISTS (SELECT 1 FROM stg_orders_incremental);

    -- Log the run
    SELECT COUNT(*) INTO v_rows_loaded FROM stg_orders_incremental;
    SELECT COUNT(*) INTO v_rows_rejected FROM stg_orders_incremental_rejects WHERE load_batch_id = v_batch_id;
    v_rows_extracted := v_rows_loaded + v_rows_rejected;

    INSERT INTO pipeline_run_log (pipeline_name, batch_id, rows_extracted, rows_rejected, rows_loaded, status)
    VALUES ('orders_incremental_load', v_batch_id, v_rows_extracted, v_rows_rejected, v_rows_loaded, 'SUCCESS');

    -- Reset staging for the next run
    TRUNCATE TABLE stg_orders_incremental;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO pipeline_error_log (pipeline_name, error_message)
        VALUES ('orders_incremental_load', SQLERRM);

        INSERT INTO pipeline_run_log (pipeline_name, batch_id, status)
        VALUES ('orders_incremental_load', v_batch_id, 'FAILED');

        RAISE;
END;
$$;

-- Nightly invocation (what a scheduler such as pg_cron or an external
-- orchestrator would call):
CALL run_orders_etl_pipeline();

-- Why a failed run is safe to retry: the watermark is only advanced INSIDE
-- this same procedure, AFTER the upsert succeeds — and staging is only
-- truncated at the very end, also after a successful upsert. If any step
-- raises an error, the EXCEPTION block fires, logs the failure, and the
-- watermark is left exactly where it was before this run started. The next
-- invocation will simply re-extract the same date window from `orders` and
-- try again — nothing was lost, and because the load step is an upsert
-- (ON CONFLICT), even partially-loaded rows from a prior failed attempt
-- are safely overwritten with the same values rather than duplicated.


-- ============================================================================
-- END OF ANSWER KEY
-- ============================================================================
