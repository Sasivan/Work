# ETL Pipeline — PostgreSQL SQL Notes

## 1. What is ETL?

**ETL = Extract → Transform → Load**

```text
SOURCE
   ↓
EXTRACT
   ↓
STAGING
   ↓
VALIDATE
   ↓
TRANSFORM
   ↓
LOAD
   ↓
TARGET
   ↓
AUDIT / CLEANUP
```

A typical SQL ETL pipeline:

```text
Source
  ↓
Staging
  ↓
Validation
  ↓
Transformation
  ↓
Target
  ↓
Audit
  ↓
Cleanup
```

The main idea:

> Do not directly trust raw source data. Load it into staging first, validate and transform it, then load clean data into the target.

---

## 2. ETL Layers

A common data-engineering design is:

```text
SOURCE
   ↓
BRONZE / STAGING
   ↓
SILVER / CLEANED
   ↓
GOLD / BUSINESS
```

For a SQL practical test, this can be simplified to:

```text
Source
  ↓
Staging
  ↓
Validation
  ↓
Transformation
  ↓
Target
  ↓
Audit
  ↓
Cleanup
```

---

## 3. EXTRACT

Extraction means obtaining data from a source.

Common sources:

```text
CSV
API
Excel
Another database
JSON
Application database
Cloud storage
```

In SQL practice, extraction can be simulated by inserting source data into a staging table.

### Example

```sql
CREATE TABLE stg_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    order_status TEXT,
    total_amount NUMERIC(12,2),
    batch_id TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Load source data:

```sql
INSERT INTO stg_orders
    (order_id, customer_id, order_date, order_status, total_amount, batch_id)
VALUES
    (1001, 1, '2026-09-01', 'completed', 2500, 'B001'),
    (1002, 2, '2026-09-01', 'completed', 1800, 'B001'),
    (1003, 3, 'cancelled', 700, 'B001');
```

---

## 4. STAGING TABLE

A staging table is an intermediate area where raw source data is loaded before processing.

### Why use staging?

It allows you to:

- inspect raw data
- validate records
- identify bad records
- transform data
- track batches
- retry processing
- separate source data from production tables

### Example

```sql
CREATE TABLE stg_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    order_status TEXT,
    total_amount NUMERIC(12,2),
    batch_id TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Staging tables often have fewer strict constraints because source data may be dirty.

For example:

```text
order_id    amount
1001        500
1002        -200
1003        NULL
```

The staging table can accept these values so that the ETL process can identify and reject them later.

---

## 5. BATCH ID

A batch ID identifies one ETL run.

Examples:

```text
BATCH_20261001
BATCH_20261002
BATCH_20261003
```

Example:

```sql
INSERT INTO stg_orders
    (order_id, customer_id, order_status, total_amount, batch_id)
VALUES
    (1001, 1, 'COMPLETED', 2500, 'BATCH_20261001');
```

Process one batch:

```sql
SELECT *
FROM stg_orders
WHERE batch_id = 'BATCH_20261001';
```

### Why batch IDs matter

They help with:

- incremental ETL
- auditing
- troubleshooting
- retrying failed batches
- selective staging cleanup

---

## 6. VALIDATION

Validation checks whether source records are acceptable.

Typical validation rules:

```text
amount > 0
customer exists
valid status
date is not NULL
required fields exist
duplicate detection
valid foreign key
```

### Validate amount

```sql
SELECT *
FROM stg_orders
WHERE total_amount <= 0;
```

### Validate customer

```sql
SELECT s.*
FROM stg_orders s
LEFT JOIN customers c
    ON c.customer_id = s.customer_id
WHERE c.customer_id IS NULL;
```

### Validate status

```sql
SELECT *
FROM stg_orders
WHERE UPPER(TRIM(order_status))
      NOT IN ('COMPLETED', 'CANCELLED', 'PENDING');
```

---

## 7. REJECTED RECORDS

ETL systems often store invalid records separately instead of simply deleting them.

### Reject table

```sql
CREATE TABLE etl_rejects (
    reject_id BIGSERIAL PRIMARY KEY,
    order_id INT,
    batch_id TEXT,
    reject_reason TEXT,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Insert rejected records

```sql
INSERT INTO etl_rejects
    (order_id, batch_id, reject_reason)
SELECT
    s.order_id,
    s.batch_id,
    CASE
        WHEN s.total_amount <= 0
            THEN 'INVALID AMOUNT'
        WHEN c.customer_id IS NULL
            THEN 'CUSTOMER NOT FOUND'
        WHEN UPPER(TRIM(s.order_status))
             NOT IN ('COMPLETED', 'CANCELLED', 'PENDING')
            THEN 'INVALID STATUS'
    END
FROM stg_orders s
LEFT JOIN customers c
    ON c.customer_id = s.customer_id
WHERE s.total_amount <= 0
   OR c.customer_id IS NULL
   OR UPPER(TRIM(s.order_status))
      NOT IN ('COMPLETED', 'CANCELLED', 'PENDING');
```

Concept:

```text
Valid records
     ↓
Target

Invalid records
     ↓
Reject table
```

---

## 8. TRANSFORMATION

Transformation converts raw data into the format required by the target.

Common transformations include:

### TRIM

```sql
TRIM(order_status)
```

Example:

```text
' COMPLETED ' → 'COMPLETED'
```

### UPPER

```sql
UPPER(order_status)
```

Example:

```text
'completed' → 'COMPLETED'
```

### COALESCE

```sql
COALESCE(total_amount, 0)
```

### CASE

```sql
CASE
    WHEN total_amount >= 5000 THEN 'HIGH'
    WHEN total_amount >= 1000 THEN 'MEDIUM'
    ELSE 'LOW'
END
```

### CAST

```sql
total_amount::NUMERIC(12,2)
```

or:

```sql
CAST(total_amount AS NUMERIC(12,2))
```

---

## 9. TRANSFORM + LOAD

One of the most important ETL patterns is:

```sql
INSERT INTO target
SELECT transformed_data
FROM staging;
```

### Example

```sql
INSERT INTO etl_orders
    (
        order_id,
        customer_id,
        order_date,
        order_status,
        total_amount,
        batch_id
    )
SELECT
    order_id,
    customer_id,
    order_date,
    UPPER(TRIM(order_status)),
    total_amount,
    batch_id
FROM stg_orders
WHERE total_amount > 0;
```

---

## 10. TARGET TABLE

The target table normally contains clean and validated data.

```sql
CREATE TABLE etl_orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,

    order_status TEXT NOT NULL
        CHECK (
            order_status IN
            ('COMPLETED', 'CANCELLED', 'PENDING')
        ),

    total_amount NUMERIC(12,2) NOT NULL
        CHECK (total_amount > 0),

    batch_id TEXT NOT NULL,

    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Staging vs Target

Staging:

```sql
total_amount NUMERIC
```

Target:

```sql
total_amount NUMERIC NOT NULL
CHECK (total_amount > 0)
```

The target is normally stricter.

---

## 11. INSERT ... SELECT

One of the most important ETL SQL patterns.

### Syntax

```sql
INSERT INTO target_table
    (column1, column2, column3)
SELECT
    column1,
    column2,
    column3
FROM source_table
WHERE condition;
```

### Example

```sql
INSERT INTO etl_orders
    (order_id, customer_id, total_amount)
SELECT
    order_id,
    customer_id,
    total_amount
FROM stg_orders
WHERE total_amount > 0;
```

---

## 12. JOIN DURING ETL

ETL often needs data from multiple tables.

```sql
INSERT INTO etl_orders
    (order_id, customer_id, customer_name, total_amount)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_name,
    o.total_amount
FROM stg_orders o
JOIN customers c
    ON c.customer_id = o.customer_id;
```

Concept:

```text
stg_orders
     +
customers
     ↓
transformed dataset
     ↓
etl_orders
```

---

## 13. FILTERING DURING ETL

Example:

```sql
SELECT *
FROM stg_orders
WHERE batch_id = 'B001'
  AND total_amount > 0
  AND UPPER(TRIM(order_status))
      IN ('COMPLETED', 'CANCELLED', 'PENDING');
```

Only valid records are passed to the next stage.

---

## 14. DUPLICATE DETECTION

ETL frequently needs to find duplicate records.

### GROUP BY method

```sql
SELECT
    order_id,
    COUNT(*) AS cnt
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
```

### Window function method

```sql
SELECT *,
       COUNT(*) OVER (
           PARTITION BY order_id
       ) AS duplicate_count
FROM stg_orders;
```

Only duplicates:

```sql
WITH x AS (
    SELECT *,
           COUNT(*) OVER (
               PARTITION BY order_id
           ) AS duplicate_count
    FROM stg_orders
)
SELECT *
FROM x
WHERE duplicate_count > 1;
```

---

## 15. UPSERT

An ETL pipeline may receive the same order more than once.

Instead of getting a duplicate-key error, use `ON CONFLICT`.

### Syntax

```sql
INSERT INTO target (...)
VALUES (...)
ON CONFLICT (primary_key)
DO UPDATE SET
    column1 = EXCLUDED.column1;
```

### Example

```sql
INSERT INTO etl_orders
    (order_id, customer_id, total_amount)
VALUES
    (1001, 10, 3000)
ON CONFLICT (order_id)
DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    total_amount = EXCLUDED.total_amount;
```

`EXCLUDED` represents the incoming row.

---

## 16. Idempotent ETL

An ETL operation is **idempotent** when running it again does not incorrectly duplicate the data.

Example:

```sql
INSERT INTO etl_orders (...)
SELECT ...
FROM stg_orders
ON CONFLICT (order_id)
DO UPDATE SET
    total_amount = EXCLUDED.total_amount;
```

If the same batch is processed twice, existing records can be updated instead of duplicated.

---

## 17. MERGE

PostgreSQL also supports `MERGE`.

### Syntax

```sql
MERGE INTO target t
USING source s
ON t.order_id = s.order_id

WHEN MATCHED THEN
    UPDATE SET
        total_amount = s.total_amount

WHEN NOT MATCHED THEN
    INSERT (order_id, total_amount)
    VALUES (s.order_id, s.total_amount);
```

Concept:

```text
Does target row exist?
       |
   ┌───┴───┐
  YES      NO
   ↓        ↓
UPDATE    INSERT
```

---

## 18. AUDIT TABLE

An ETL pipeline should record what happened.

### Create audit table

```sql
CREATE TABLE etl_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    batch_id TEXT,
    source_rows INT,
    loaded_rows INT,
    rejected_rows INT,
    status TEXT,
    load_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Insert audit record

```sql
INSERT INTO etl_audit
    (batch_id, source_rows, loaded_rows, rejected_rows, status)
VALUES
    ('B001', 1000, 970, 30, 'PARTIAL');
```

Typical statuses:

```text
SUCCESS
PARTIAL
FAILED
```

---

## 19. SOURCE vs LOADED vs REJECTED

A common ETL reconciliation:

```text
SOURCE ROWS = 1000
LOADED      = 970
REJECTED    = 30
```

Check:

```text
1000 = 970 + 30
```

SQL:

```sql
SELECT
    source_rows,
    loaded_rows,
    rejected_rows,
    loaded_rows + rejected_rows AS reconciled_rows
FROM etl_audit;
```

---

## 20. STORED PROCEDURE

Instead of manually executing many ETL commands, put them into a procedure.

### Syntax

```sql
CREATE OR REPLACE PROCEDURE procedure_name(
    p_batch_id TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- ETL operations

END;
$$;
```

Execute:

```sql
CALL procedure_name('B001');
```

### Example

```sql
CREATE OR REPLACE PROCEDURE load_orders(
    p_batch_id TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO etl_orders (...)
    SELECT ...
    FROM stg_orders
    WHERE batch_id = p_batch_id;

END;
$$;
```

Run:

```sql
CALL load_orders('B001');
```

---

## 21. Function vs Procedure

### Function

Normally returns a value.

```sql
CREATE FUNCTION add_tax(amount NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN amount * 0.10;
END;
$$;
```

Call:

```sql
SELECT add_tax(1000);
```

### Procedure

Used to perform operations.

```sql
CREATE PROCEDURE load_orders(...)
...
```

Call:

```sql
CALL load_orders('B001');
```

For ETL orchestration, procedures are particularly useful because they can execute multiple database operations.

---

## 22. TRANSACTION IN ETL

Suppose an ETL process performs:

```text
INSERT target
UPDATE target
INSERT audit
DELETE staging
```

You do not want only some operations to succeed.

Use a transaction:

```sql
BEGIN;

-- ETL operation 1
-- ETL operation 2
-- ETL operation 3

COMMIT;
```

If something fails:

```sql
ROLLBACK;
```

### Example

```sql
BEGIN;

INSERT INTO etl_orders
SELECT ...
FROM stg_orders;

INSERT INTO etl_audit
VALUES (...);

COMMIT;
```

---

## 23. SAVEPOINT

A savepoint allows partial rollback inside a transaction.

```sql
BEGIN;

INSERT INTO etl_orders
SELECT ...;

SAVEPOINT after_load;

UPDATE etl_orders
SET total_amount = total_amount * 1.10;

ROLLBACK TO SAVEPOINT after_load;

COMMIT;
```

Result:

```text
INSERT remains
UPDATE is undone
```

---

## 24. Exception Handling

PL/pgSQL procedures can handle errors.

### Basic syntax

```sql
BEGIN

    -- ETL operations

EXCEPTION
    WHEN OTHERS THEN

        -- error handling

END;
```

### Example

```sql
CREATE OR REPLACE PROCEDURE test_etl()
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO etl_orders
    SELECT ...
    FROM stg_orders;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ETL failed: %', SQLERRM;
        RAISE;

END;
$$;
```

`SQLERRM` contains the error message.

---

## 25. TRUNCATE

After successful processing, staging may need to be emptied.

```sql
TRUNCATE TABLE stg_orders;
```

Important:

`TRUNCATE` removes **all rows**.

It cannot be used like:

```sql
TRUNCATE TABLE stg_orders
WHERE batch_id = 'B001';
```

That is invalid.

If you need selective cleanup:

```sql
DELETE FROM stg_orders
WHERE batch_id = 'B001';
```

### DELETE vs TRUNCATE

| DELETE | TRUNCATE |
|---|---|
| Can use `WHERE` | Removes all rows |
| Good for selective cleanup | Good for clearing a staging table |
| Row-level deletion | Table-level operation |
| `DELETE FROM table WHERE ...` | `TRUNCATE TABLE table` |

---

## 26. ETL Cleanup

After successful processing:

```sql
DELETE FROM stg_orders
WHERE batch_id = 'B001';
```

Or, if the entire staging table is disposable:

```sql
TRUNCATE TABLE stg_orders;
```

Do not blindly clean staging before successful processing.

Recommended sequence:

```text
Load staging
     ↓
Validate
     ↓
Transform
     ↓
Load target
     ↓
Audit
     ↓
Cleanup staging
```

---

## 27. Incremental ETL

Instead of processing the complete source every time, process only new or changed records.

Example:

```sql
SELECT *
FROM source_orders
WHERE updated_at > :last_successful_load;
```

Using a batch:

```sql
SELECT *
FROM stg_orders
WHERE batch_id = 'B002';
```

Incremental ETL reduces unnecessary processing.

---

## 28. Slowly Changing Dimensions

Sometimes customer information changes.

Example:

```text
Customer 10
Old city = Bangalore
New city = Hyderabad
```

ETL must decide whether to:

```text
UPDATE existing value
```

or preserve history.

Common types:

```text
SCD Type 1 → overwrite old value
SCD Type 2 → preserve history
```

---

## 29. SCD Type 1

Overwrite the old value.

```sql
UPDATE customer_dimension
SET city = 'Hyderabad'
WHERE customer_id = 10;
```

The old Bangalore value is not preserved.

---

## 30. SCD Type 2

Maintain historical records.

Typical columns:

```text
customer_id
city
valid_from
valid_to
is_current
```

Example:

```text
10 | Bangalore | 2025-01-01 | 2026-09-30 | false
10 | Hyderabad | 2026-10-01 | NULL       | true
```

---

## 31. Data Quality Checks

### NULL check

```sql
SELECT *
FROM stg_orders
WHERE customer_id IS NULL;
```

### Positive amount

```sql
SELECT *
FROM stg_orders
WHERE total_amount <= 0;
```

### Valid status

```sql
SELECT *
FROM stg_orders
WHERE order_status NOT IN
    ('COMPLETED', 'CANCELLED', 'PENDING');
```

### Duplicate ID

```sql
SELECT
    order_id,
    COUNT(*)
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
```

### Foreign-key validation

```sql
SELECT s.*
FROM stg_orders s
LEFT JOIN customers c
    ON c.customer_id = s.customer_id
WHERE c.customer_id IS NULL;
```

---

# 32. Complete ETL Example

Suppose source data contains:

```text
1001 | 1   | completed | 2500
1002 | 2   | completed | 1800
1003 | 999 | completed | 500
1004 | 4   | completed | -200
```

## Step 1 — Load staging

```sql
INSERT INTO stg_orders
    (order_id, customer_id, order_status, total_amount, batch_id)
VALUES
    (1001, 1, 'completed', 2500, 'B001'),
    (1002, 2, 'completed', 1800, 'B001'),
    (1003, 999, 'completed', 500, 'B001'),
    (1004, 4, 'completed', -200, 'B001');
```

## Step 2 — Validate

```text
1001 → valid
1002 → valid
1003 → invalid customer
1004 → invalid amount
```

## Step 3 — Transform

```sql
UPPER(TRIM(order_status))
```

Result:

```text
completed → COMPLETED
```

## Step 4 — Load target

```sql
INSERT INTO etl_orders (...)
SELECT ...
FROM stg_orders s
JOIN customers c
    ON c.customer_id = s.customer_id
WHERE s.total_amount > 0;
```

Only valid rows such as:

```text
1001
1002
```

are loaded.

## Step 5 — Audit

```text
Source     = 4
Loaded     = 2
Rejected   = 2
Status     = PARTIAL
```

## Step 6 — Cleanup

```sql
DELETE FROM stg_orders
WHERE batch_id = 'B001';
```

---

# 33. Complete ETL Mental Model

Remember this sequence:

```text
1. EXTRACT
      ↓
2. STAGE
      ↓
3. VALIDATE
      ↓
4. REJECT BAD DATA
      ↓
5. TRANSFORM
      ↓
6. LOAD TARGET
      ↓
7. UPSERT / MERGE IF REQUIRED
      ↓
8. RECONCILE COUNTS
      ↓
9. AUDIT
      ↓
10. CLEAN STAGING
```

---

# 34. Most Important ETL SQL Syntax

### Create staging

```sql
CREATE TABLE stg_table (...);
```

### Load staging

```sql
INSERT INTO stg_table (...)
VALUES (...);
```

### Validate

```sql
SELECT *
FROM stg_table
WHERE condition;
```

### Transform

```sql
SELECT
    UPPER(TRIM(status)),
    COALESCE(amount, 0),
    CASE
        WHEN amount >= 5000 THEN 'HIGH'
        ELSE 'LOW'
    END
FROM stg_table;
```

### Load target

```sql
INSERT INTO target_table (...)
SELECT ...
FROM stg_table
WHERE ...;
```

### Upsert

```sql
INSERT INTO target (...)
VALUES (...)
ON CONFLICT (id)
DO UPDATE SET ...;
```

### Merge

```sql
MERGE INTO target t
USING source s
ON ...
WHEN MATCHED THEN
    UPDATE SET ...
WHEN NOT MATCHED THEN
    INSERT ...;
```

### Procedure

```sql
CREATE OR REPLACE PROCEDURE load_data(...)
LANGUAGE plpgsql
AS $$
BEGIN
    ...
END;
$$;
```

### Execute procedure

```sql
CALL load_data(...);
```

### Transaction

```sql
BEGIN;

-- ETL operations

COMMIT;
```

### Rollback

```sql
ROLLBACK;
```

### Savepoint

```sql
SAVEPOINT sp1;

ROLLBACK TO SAVEPOINT sp1;
```

### Audit

```sql
INSERT INTO etl_audit (...);
```

### Cleanup

```sql
DELETE FROM stg_table
WHERE batch_id = 'B001';
```

or:

```sql
TRUNCATE TABLE stg_table;
```

---

# 35. ETL Exam Checklist

When you see an ETL question, think in this order:

```text
SOURCE
 ↓
Where do I stage it?
 ↓
What makes a row invalid?
 ↓
How do I identify rejects?
 ↓
What transformations are required?
 ↓
What is the target structure?
 ↓
INSERT SELECT / UPSERT / MERGE?
 ↓
Can duplicates occur?
 ↓
Do I need a transaction?
 ↓
Do I need a procedure?
 ↓
How do I audit source vs loaded vs rejected?
 ↓
When is it safe to clean staging?
```

## High-value ETL topics to practice

```text
INSERT INTO ... SELECT ...
JOIN
CASE
COALESCE
FILTER
GROUP BY / HAVING
COUNT(*) OVER (...)
ON CONFLICT
MERGE
CREATE PROCEDURE
CALL
BEGIN / COMMIT / ROLLBACK
SAVEPOINT
RAISE EXCEPTION
TRUNCATE
DELETE ... WHERE
Audit / reconciliation
Batch processing
Incremental loading
Data validation
Reject handling
Idempotent loading
```

## Final ETL Pattern

```text
          SOURCE
             ↓
          EXTRACT
             ↓
          STAGING
             ↓
       ┌─────┴─────┐
       ↓           ↓
    VALID       INVALID
       ↓           ↓
  TRANSFORM     REJECT
       ↓
     TARGET
       ↓
     AUDIT
       ↓
    CLEANUP
```
