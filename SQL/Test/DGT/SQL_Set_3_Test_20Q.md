# SQL Set 3 — PostgreSQL Test

## Scenario

You are working on an e-commerce database in PostgreSQL.

Existing schema:

```sql
sql_mastery_assignment
```

Existing tables include:

`customers`, `orders`, `order_items`, `products`, `payments`, `employees`, `departments`, `projects`, `employee_projects`, `attendance`.

Use schema-qualified names such as:

```sql
sql_mastery_assignment.orders
```

---

# Section 1 — SQL Fundamentals / DDL / DML / DQL / TCL

## Q1 — Intermediate — DDL + Constraints

Create `customer_segments` with:

- `segment_id` integer primary key
- `segment_name` text unique and not null
- `min_spend` numeric, >= 0
- `max_spend` numeric, > `min_spend`
- `created_at` timestamp default current timestamp

### Answer

```sql
CREATE TABLE sql_mastery_assignment.customer_segments (
    segment_id INT PRIMARY KEY,
    segment_name TEXT UNIQUE NOT NULL,
    min_spend NUMERIC(12,2) NOT NULL CHECK (min_spend >= 0),
    max_spend NUMERIC(12,2) NOT NULL CHECK (max_spend > min_spend),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Q2 — Fundamental — INSERT

Insert:

- LOW: 0–999.99
- MEDIUM: 1000–4999.99
- HIGH: 5000–999999.99

Do not manually provide `created_at`.

### Answer

```sql
INSERT INTO sql_mastery_assignment.customer_segments
    (segment_id, segment_name, min_spend, max_spend)
VALUES
    (1, 'LOW', 0, 999.99),
    (2, 'MEDIUM', 1000, 4999.99),
    (3, 'HIGH', 5000, 999999.99);
```

---

## Q3 — Intermediate — ALTER + UPDATE + CASE + Aggregate

Add `customer_tier` to `customers`.

Update it from completed-order spending:

- >= 5000 → HIGH
- >= 1000 → MEDIUM
- otherwise → LOW

Customers with no completed orders are LOW.

### Answer

```sql
ALTER TABLE sql_mastery_assignment.customers
ADD COLUMN customer_tier TEXT;
```

```sql
WITH customer_spend AS (
    SELECT
        c.customer_id,
        COALESCE(
            SUM(o.total_amount) FILTER (
                WHERE o.order_status = 'COMPLETED'
            ),
            0
        ) AS total_spend
    FROM sql_mastery_assignment.customers c
    LEFT JOIN sql_mastery_assignment.orders o
        USING (customer_id)
    GROUP BY c.customer_id
)
UPDATE sql_mastery_assignment.customers c
SET customer_tier =
    CASE
        WHEN cs.total_spend >= 5000 THEN 'HIGH'
        WHEN cs.total_spend >= 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END
FROM customer_spend cs
WHERE c.customer_id = cs.customer_id;
```

---

## Q4 — Intermediate — DELETE + NOT EXISTS

Delete customers who have never placed an order.

### Answer

```sql
DELETE FROM sql_mastery_assignment.customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM sql_mastery_assignment.orders o
    WHERE o.customer_id = c.customer_id
);
```

---

## Q5 — Advanced — VIEW + Window Function

Create `customer_order_summary` containing:

- customer ID
- customer name
- completed-order count
- completed revenue
- revenue rank across customers

Use a window function for the rank.

### Answer

```sql
CREATE OR REPLACE VIEW sql_mastery_assignment.customer_order_summary AS
WITH summary AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(o.order_id) AS completed_orders,
        COALESCE(SUM(o.total_amount), 0) AS completed_revenue
    FROM sql_mastery_assignment.customers c
    LEFT JOIN sql_mastery_assignment.orders o
        ON o.customer_id = c.customer_id
       AND o.order_status = 'COMPLETED'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    completed_orders,
    completed_revenue,
    DENSE_RANK() OVER (
        ORDER BY completed_revenue DESC
    ) AS revenue_rank
FROM summary;
```

---

## Q6 — Intermediate — ALTER TABLE + CHECK

Prevent `segment_name` from being an empty string.

### Answer

```sql
ALTER TABLE sql_mastery_assignment.customer_segments
ADD CONSTRAINT customer_segments_name_not_empty
CHECK (TRIM(segment_name) <> '');
```

---

## Q7 — Advanced — Transaction + SAVEPOINT

Perform one transaction:

1. Increase all salaries by 5%.
2. Create a savepoint.
3. Increase department 1 salaries by another 10%.
4. Roll back only the second increase.
5. Commit the 5% increase.

### Answer

```sql
BEGIN;

UPDATE sql_mastery_assignment.employees
SET salary = salary * 1.05;

SAVEPOINT salary_update;

UPDATE sql_mastery_assignment.employees
SET salary = salary * 1.10
WHERE department_id = 1;

ROLLBACK TO SAVEPOINT salary_update;

COMMIT;
```

---

## Q8 — Intermediate — UPSERT

Insert segment 2 as:

```text
MEDIUM, 1200, 4999.99
```

If segment 2 exists, update it instead of raising an error.

### Answer

```sql
INSERT INTO sql_mastery_assignment.customer_segments
    (segment_id, segment_name, min_spend, max_spend)
VALUES
    (2, 'MEDIUM', 1200, 4999.99)
ON CONFLICT (segment_id)
DO UPDATE SET
    segment_name = EXCLUDED.segment_name,
    min_spend = EXCLUDED.min_spend,
    max_spend = EXCLUDED.max_spend;
```

---

## Q9 — Advanced — PostgreSQL Function

Create `calculate_order_tax(amount)`:

- <= 1000 → 0%
- >1000 and <=5000 → 5%
- >5000 → 10%

Return numeric tax.

### Answer

```sql
CREATE OR REPLACE FUNCTION sql_mastery_assignment.calculate_order_tax(
    p_amount NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CASE
        WHEN p_amount <= 1000 THEN 0
        WHEN p_amount <= 5000 THEN p_amount * 0.05
        ELSE p_amount * 0.10
    END;
END;
$$;
```

Example:

```sql
SELECT
    order_id,
    total_amount,
    sql_mastery_assignment.calculate_order_tax(total_amount) AS tax
FROM sql_mastery_assignment.orders;
```

---

## Q10 — Advanced — DROP + Dependency Awareness

Remove the `customer_order_summary` view without removing the underlying tables.

### Answer

```sql
DROP VIEW IF EXISTS sql_mastery_assignment.customer_order_summary;
```

---

# Section 2 — ETL Pipeline

## Scenario

A daily external source sends order data containing:

- `order_id`
- `customer_id`
- `order_date`
- `order_status`
- `total_amount`

Pipeline:

```text
SOURCE
  ↓
STAGING
  ↓
VALIDATION
  ↓
TRANSFORMATION
  ↓
TARGET
  ↓
AUDIT
  ↓
STAGING CLEANUP
```

The questions are deliberately dependent. Later questions use objects created earlier.

---

## Q11 — Fundamental ETL — Staging Table

Create `stg_orders`.

Columns:

- order_id
- customer_id
- order_date
- order_status
- total_amount
- loaded_at
- batch_id

Allow imperfect source data because validation happens later.

### Answer

```sql
CREATE TABLE sql_mastery_assignment.stg_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    order_status TEXT,
    total_amount NUMERIC(12,2),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    batch_id TEXT
);
```

---

## Q12 — Fundamental ETL — Source Load

Insert this batch using batch ID `BATCH_20260902`:

```text
1001, 1, 2026-09-01, COMPLETED, 2500
1002, 2, 2026-09-01, COMPLETED, 1800
1003, 3, 2026-09-02, CANCELLED, 700
1004, 4, 2026-09-02, COMPLETED, -500
1005, 99999, 2026-09-02, COMPLETED, 1200
```

### Answer

```sql
INSERT INTO sql_mastery_assignment.stg_orders
    (order_id, customer_id, order_date, order_status, total_amount, batch_id)
VALUES
    (1001, 1, '2026-09-01', 'COMPLETED', 2500, 'BATCH_20260902'),
    (1002, 2, '2026-09-01', 'COMPLETED', 1800, 'BATCH_20260902'),
    (1003, 3, '2026-09-02', 'CANCELLED', 700, 'BATCH_20260902'),
    (1004, 4, '2026-09-02', 'COMPLETED', -500, 'BATCH_20260902'),
    (1005, 99999, '2026-09-02', 'COMPLETED', 1200, 'BATCH_20260902');
```

---

## Q13 — Intermediate ETL — Validation / Rejects

Identify invalid staging records.

Invalid when:

- amount <= 0
- customer does not exist
- status is not COMPLETED, CANCELLED, or PENDING

Return `order_id`, `customer_id`, `total_amount`, and `reject_reason`.

Do not modify data.

### Answer

```sql
SELECT
    s.order_id,
    s.customer_id,
    s.total_amount,
    CASE
        WHEN s.total_amount <= 0 THEN 'INVALID AMOUNT'
        WHEN c.customer_id IS NULL THEN 'CUSTOMER NOT FOUND'
        WHEN UPPER(TRIM(s.order_status))
             NOT IN ('COMPLETED', 'CANCELLED', 'PENDING')
            THEN 'INVALID STATUS'
    END AS reject_reason
FROM sql_mastery_assignment.stg_orders s
LEFT JOIN sql_mastery_assignment.customers c
    ON c.customer_id = s.customer_id
WHERE s.total_amount <= 0
   OR c.customer_id IS NULL
   OR UPPER(TRIM(s.order_status))
      NOT IN ('COMPLETED', 'CANCELLED', 'PENDING');
```

---

## Q14 — Intermediate ETL — Target Table

Create `etl_orders`.

Requirements:

- order_id primary key
- customer_id not null
- order_date not null
- valid status check
- positive amount
- batch_id
- loaded_at

### Answer

```sql
CREATE TABLE sql_mastery_assignment.etl_orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status TEXT NOT NULL
        CHECK (order_status IN ('COMPLETED', 'CANCELLED', 'PENDING')),
    total_amount NUMERIC(12,2) NOT NULL
        CHECK (total_amount > 0),
    batch_id TEXT NOT NULL,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Q15 — Intermediate ETL — Transform + INSERT SELECT

Load only valid records from the current staging batch into `etl_orders`.

Transform:

- trim status
- uppercase status
- reject invalid amounts
- reject unknown customers

### Answer

```sql
INSERT INTO sql_mastery_assignment.etl_orders
    (
        order_id,
        customer_id,
        order_date,
        order_status,
        total_amount,
        batch_id
    )
SELECT
    s.order_id,
    s.customer_id,
    s.order_date,
    UPPER(TRIM(s.order_status)),
    s.total_amount,
    s.batch_id
FROM sql_mastery_assignment.stg_orders s
JOIN sql_mastery_assignment.customers c
    ON c.customer_id = s.customer_id
WHERE s.batch_id = 'BATCH_20260902'
  AND s.total_amount > 0
  AND UPPER(TRIM(s.order_status))
      IN ('COMPLETED', 'CANCELLED', 'PENDING');
```

---

## Q16 — Advanced ETL — Audit / Reconciliation

Create `etl_audit` with:

- audit_id
- batch_id
- source_rows
- loaded_rows
- rejected_rows
- load_time
- status

Then insert an audit row for `BATCH_20260902`.

### Answer

```sql
CREATE TABLE sql_mastery_assignment.etl_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    batch_id TEXT NOT NULL,
    source_rows INT NOT NULL,
    loaded_rows INT NOT NULL,
    rejected_rows INT NOT NULL,
    load_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL
);
```

```sql
INSERT INTO sql_mastery_assignment.etl_audit
    (batch_id, source_rows, loaded_rows, rejected_rows, status)
SELECT
    'BATCH_20260902',
    COUNT(*),
    COUNT(*) FILTER (
        WHERE s.total_amount > 0
          AND c.customer_id IS NOT NULL
          AND UPPER(TRIM(s.order_status))
              IN ('COMPLETED', 'CANCELLED', 'PENDING')
    ),
    COUNT(*) FILTER (
        WHERE s.total_amount <= 0
           OR c.customer_id IS NULL
           OR UPPER(TRIM(s.order_status))
              NOT IN ('COMPLETED', 'CANCELLED', 'PENDING')
    ),
    CASE
        WHEN COUNT(*) FILTER (
            WHERE s.total_amount <= 0
               OR c.customer_id IS NULL
               OR UPPER(TRIM(s.order_status))
                  NOT IN ('COMPLETED', 'CANCELLED', 'PENDING')
        ) = 0
        THEN 'SUCCESS'
        ELSE 'PARTIAL'
    END
FROM sql_mastery_assignment.stg_orders s
LEFT JOIN sql_mastery_assignment.customers c
    ON c.customer_id = s.customer_id
WHERE s.batch_id = 'BATCH_20260902';
```

---

## Q17 — Advanced ETL — Procedure + UPSERT

Create procedure `load_valid_orders(batch_id)`.

It must:

1. Read the requested staging batch.
2. Load valid rows into `etl_orders`.
3. Avoid duplicate-key failures.
4. Update the target if the order already exists.

### Answer

```sql
CREATE OR REPLACE PROCEDURE sql_mastery_assignment.load_valid_orders(
    p_batch_id TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO sql_mastery_assignment.etl_orders
        (
            order_id,
            customer_id,
            order_date,
            order_status,
            total_amount,
            batch_id
        )
    SELECT
        s.order_id,
        s.customer_id,
        s.order_date,
        UPPER(TRIM(s.order_status)),
        s.total_amount,
        s.batch_id
    FROM sql_mastery_assignment.stg_orders s
    JOIN sql_mastery_assignment.customers c
        ON c.customer_id = s.customer_id
    WHERE s.batch_id = p_batch_id
      AND s.total_amount > 0
      AND UPPER(TRIM(s.order_status))
          IN ('COMPLETED', 'CANCELLED', 'PENDING')
    ON CONFLICT (order_id)
    DO UPDATE SET
        customer_id = EXCLUDED.customer_id,
        order_date = EXCLUDED.order_date,
        order_status = EXCLUDED.order_status,
        total_amount = EXCLUDED.total_amount,
        batch_id = EXCLUDED.batch_id,
        loaded_at = CURRENT_TIMESTAMP;

END;
$$;
```

Run:

```sql
CALL sql_mastery_assignment.load_valid_orders('BATCH_20260902');
```

---

## Q18 — Advanced ETL — Transaction + Validation

Execute the ETL load inside a transaction.

1. Begin transaction.
2. Call `load_valid_orders`.
3. Validate that no target row has a non-positive amount.
4. Raise an exception if validation fails.
5. Commit only after validation succeeds.

### Answer

```sql
BEGIN;

CALL sql_mastery_assignment.load_valid_orders('BATCH_20260902');

DO $$
DECLARE
    invalid_count INT;
BEGIN
    SELECT COUNT(*)
    INTO invalid_count
    FROM sql_mastery_assignment.etl_orders
    WHERE total_amount <= 0;

    IF invalid_count > 0 THEN
        RAISE EXCEPTION
            'ETL validation failed: % invalid rows',
            invalid_count;
    END IF;
END;
$$;

COMMIT;
```

If the `DO` block raises an exception, the transaction must be rolled back rather than committed.

---

## Q19 — Advanced ETL — TRUNCATE vs DELETE

After a successful batch, remove staging data.

Explain when `TRUNCATE` can be used and when `DELETE` is required.

### Answer

If the entire staging table can be cleared:

```sql
TRUNCATE TABLE sql_mastery_assignment.stg_orders;
```

If other batches must remain, use:

```sql
DELETE FROM sql_mastery_assignment.stg_orders
WHERE batch_id = 'BATCH_20260902';
```

`TRUNCATE` clears the whole table; it cannot target one batch using a `WHERE` clause. `DELETE` is appropriate for selective cleanup.

---

## Q20 — Advanced ETL — End-to-End Procedure

Create `run_orders_etl(batch_id)`.

It must:

1. Count source rows.
2. Count rejected rows.
3. Call `load_valid_orders`.
4. Count loaded target rows for the batch.
5. Insert the audit record.
6. Remove the processed batch from staging.
7. Keep the operations as one logical procedure.

### Answer

```sql
CREATE OR REPLACE PROCEDURE sql_mastery_assignment.run_orders_etl(
    p_batch_id TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_source_rows INT;
    v_rejected_rows INT;
    v_loaded_rows INT;
BEGIN

    SELECT COUNT(*)
    INTO v_source_rows
    FROM sql_mastery_assignment.stg_orders
    WHERE batch_id = p_batch_id;

    SELECT COUNT(*)
    INTO v_rejected_rows
    FROM sql_mastery_assignment.stg_orders s
    LEFT JOIN sql_mastery_assignment.customers c
        ON c.customer_id = s.customer_id
    WHERE s.batch_id = p_batch_id
      AND (
            s.total_amount <= 0
         OR c.customer_id IS NULL
         OR UPPER(TRIM(s.order_status))
              NOT IN ('COMPLETED', 'CANCELLED', 'PENDING')
      );

    CALL sql_mastery_assignment.load_valid_orders(p_batch_id);

    SELECT COUNT(*)
    INTO v_loaded_rows
    FROM sql_mastery_assignment.etl_orders
    WHERE batch_id = p_batch_id;

    INSERT INTO sql_mastery_assignment.etl_audit
        (
            batch_id,
            source_rows,
            loaded_rows,
            rejected_rows,
            status
        )
    VALUES
        (
            p_batch_id,
            v_source_rows,
            v_loaded_rows,
            v_rejected_rows,
            CASE
                WHEN v_rejected_rows = 0 THEN 'SUCCESS'
                ELSE 'PARTIAL'
            END
        );

    DELETE FROM sql_mastery_assignment.stg_orders
    WHERE batch_id = p_batch_id;

END;
$$;
```

Run:

```sql
CALL sql_mastery_assignment.run_orders_etl('BATCH_20260902');
```

---

# Coverage Map

## Section 1

| Topic | Questions |
|---|---|
| CREATE TABLE | Q1 |
| Constraints | Q1, Q6 |
| INSERT | Q2 |
| UPDATE | Q3 |
| DELETE | Q4 |
| SELECT / DQL | Q5, Q9 |
| CASE | Q3, Q9 |
| Aggregates | Q3, Q5 |
| NOT EXISTS | Q4 |
| VIEW | Q5, Q10 |
| Window functions | Q5 |
| ALTER TABLE | Q3, Q6 |
| Transactions | Q7 |
| SAVEPOINT | Q7 |
| ROLLBACK TO SAVEPOINT | Q7 |
| COMMIT | Q7 |
| UPSERT | Q8 |
| ON CONFLICT | Q8 |
| Function | Q9 |
| PL/pgSQL | Q9 |
| DROP | Q10 |

## Section 2 — ETL

| ETL topic | Questions |
|---|---|
| Staging | Q11 |
| Source ingestion | Q12 |
| Validation | Q13 |
| Reject identification | Q13, Q16 |
| Target design | Q14 |
| INSERT ... SELECT | Q15 |
| Transformation | Q15 |
| Data cleansing | Q15 |
| Audit | Q16, Q20 |
| Reconciliation | Q16, Q20 |
| Procedure | Q17, Q20 |
| UPSERT | Q17 |
| ON CONFLICT | Q17 |
| Transaction | Q18 |
| Validation + exception | Q18 |
| TRUNCATE | Q19 |
| DELETE cleanup | Q19, Q20 |
| Batch processing | Q12, Q15–Q20 |
| Idempotent loading | Q17 |
| End-to-end orchestration | Q20 |

# Notebook Format

Use each question as a separate notebook section:

```text
### Q1 — DDL + Constraints
Question
SQL answer
Verification

### Q2 — INSERT
Question
SQL answer
Verification

...

### Q20 — End-to-End ETL
Question
SQL answer
Verification
```

For an actual mock test, hide the `### Answer` sections and reveal them only after attempting each question.
