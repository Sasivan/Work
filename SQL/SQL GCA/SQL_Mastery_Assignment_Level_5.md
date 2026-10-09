# SQL Mastery Assignment — Level 5 (Addendum)

**Data Engineering & Modern Analytics Patterns — Topics 20–25, Questions 109–128**

This is a companion addendum to the original *SQL Mastery Assignment* (Levels 1–4, Topics 1–19, Questions 1–108). It picks up exactly where Level 4 left off — same dataset, same "primer + numbered questions" format, same difficulty register as Level 4 (Expert). Nothing here duplicates Levels 1–4: Window Functions, CTEs/Recursive CTEs, Set Operations, Transactions/ACID, and Query Optimization/Indexing are already covered there (Topics 10, 12, 13, 18, 19) and are deliberately **not** repeated.

Level 5 covers the topics that were genuinely missing after that comparison: multi-level aggregation (ROLLUP/CUBE/GROUPING SETS), dimensional modeling and Slowly Changing Dimensions, MERGE/UPSERT patterns, batched DML at scale, bulk loading, and JSON/JSONB. These are the topics that separate "can write analytical queries" from "can design and operate the data pipelines those queries run against" — the data-engineering half of job-readiness.

**Schema note:** Topics 20–24 use only the existing 12 tables, unchanged. Topic 25 (JSON/JSONB) requires one schema extension, described in that section — two nullable JSONB columns added to `products` and `customers`. This is called out explicitly so you know it's new, not something you missed in the original Database Reference.

---

## LEVEL 5 — DATA ENGINEERING & MODERN ANALYTICS PATTERNS

### 20. GROUPING SETS, ROLLUP, and CUBE

`GROUP BY` normally produces exactly one aggregation level — one row per unique combination of the grouped columns. Real reports usually need **several** aggregation levels at once: department subtotals AND a company-wide grand total, in a single result set, without running three separate queries and `UNION ALL`-ing them together by hand. `ROLLUP`, `CUBE`, and `GROUPING SETS` are the standard SQL extensions to `GROUP BY` that do exactly this.

**ROLLUP(a, b)** produces a hierarchical set of subtotals: the full `(a, b)` grouping, then `(a)` alone (subtotal per `a`, collapsing `b`), then the grand total (collapsing everything). It assumes a hierarchy — `a` is the "outer" level, `b` is "inner" — so it only rolls up in that one direction.

```sql
-- Department subtotals + company grand total, in one query
SELECT department_id, job_title,
       COUNT(*) AS emp_count,
       SUM(salary) AS total_salary
FROM employees
WHERE status = 'ACTIVE'
GROUP BY ROLLUP(department_id, job_title)
ORDER BY department_id, job_title;
```

This returns one row per `(department_id, job_title)` combo, then one row per `department_id` with `job_title = NULL` (the subtotal), then one final row with both `department_id` and `job_title` NULL (the grand total).

**CUBE(a, b)** produces subtotals for **every possible combination** of the grouped columns — `(a,b)`, `(a)`, `(b)`, and `()` — not just the hierarchical rollup direction. Useful when there's no natural hierarchy between the two columns and you want every cross-section (e.g., revenue by country, by status, and by country×status, all at once).

**GROUPING SETS(...)** is the most flexible and explicit form: you list out exactly which grouping combinations you want, with no implied hierarchy and no combinations you didn't ask for. `ROLLUP` and `CUBE` are technically shorthand for specific `GROUPING SETS` lists.

```sql
-- Exactly these three levels, nothing else
SELECT ship_country, order_status,
       SUM(total_amount) AS revenue
FROM orders
GROUP BY GROUPING SETS (
    (ship_country, order_status),
    (ship_country),
    ()
)
ORDER BY ship_country, order_status;
```

**The GROUPING() function — telling a real NULL from a subtotal NULL**

The subtotal rows above show `NULL` in the collapsed columns — but if the underlying data can *also* contain a genuine NULL in one of those columns (e.g., `employees.department_id` is NULL for the unassigned consultant, Ritu Malhotra), you can no longer tell "this NULL means subtotal" from "this NULL means the actual department_id was NULL" just by looking at the value. `GROUPING(column)` solves this: it returns `1` if that row is a subtotal row for that column (the column was rolled up/collapsed), and `0` if the NULL is a genuine data value.

```sql
SELECT department_id,
       GROUPING(department_id) AS is_subtotal,
       COUNT(*) AS emp_count
FROM employees
GROUP BY ROLLUP(department_id);
```

**Common mistakes**
- Confusing a subtotal's NULL with a genuine data NULL — always use `GROUPING()` when the grouped column can itself contain NULLs, or replace the display value with `COALESCE`/`CASE` based on `GROUPING()` (e.g., label subtotal rows `'ALL DEPARTMENTS'` instead of leaving them NULL).
- Using `CUBE` when you only need a handful of specific subtotal combinations — `CUBE` computes 2^n combinations for n columns, which can be wasteful and confusing to consume; `GROUPING SETS` lets you ask for only what you need.
- MySQL does not support `CUBE` or `GROUPING SETS` (as of standard MySQL 8.x) — it only supports `WITH ROLLUP` as a trailing clause (`GROUP BY a, b WITH ROLLUP`), with different NULL-vs-subtotal semantics than ANSI `ROLLUP(...)`. Always state your target engine for this topic.
- Forgetting that `ROLLUP` order matters (it rolls up right-to-left) — `ROLLUP(a, b)` is not the same as `ROLLUP(b, a)`.

**Practice Questions — 20. GROUPING SETS, ROLLUP, and CUBE**

**Question 109** [Tables: employees, departments]
Using `employees` joined to `departments`, write a query with `ROLLUP` that returns, for active employees, the count of employees and total salary at three levels: per `department_name`, then a company-wide grand total. Use `GROUPING()` to replace the subtotal row's NULL `department_name` with the literal `'ALL DEPARTMENTS'`.

**Question 110** [Tables: orders]
Using `orders`, write a query with `CUBE(ship_country, order_status)` that returns total `total_amount` and order count for every combination of country and status, plus the country-only subtotals, status-only subtotals, and grand total. Use `GROUPING()` on both columns to label each subtotal row clearly (e.g., `'ALL COUNTRIES'`, `'ALL STATUSES'`).

**Question 111** [Tables: orders]
Using `GROUPING SETS`, write a query that returns *exactly* three things in one result set — no more, no fewer: (a) total COMPLETED revenue per `ship_country`, (b) total COMPLETED revenue per calendar year of `order_date`, and (c) one grand total row. Explain in a comment why `CUBE` would have been the wrong tool here.

**Question 112** [Tables: employees, departments]
Using `ROLLUP(department_name, job_title)`, build a headcount and average-salary report showing every job title within every department, department-level subtotals, and a grand total — then, in a comment, describe one real reporting scenario (e.g., a Power BI matrix visual) where this single query would replace three separate GROUP BY queries UNION'd together.

---

### 21. Star Schema Design and Slowly Changing Dimensions (SCD Type 2)

Everything in Levels 1–4 queried this dataset as a flat relational schema. Real analytics warehouses are usually organized differently: **dimensional modeling**, most commonly as a **star schema** — one or more central **fact tables** (the events/transactions you're measuring, at a fine grain — one row per order, one row per order line item) surrounded by **dimension tables** (the descriptive context you slice and filter by — customers, products, employees, departments, dates). This is the mental model behind almost every BI tool's matrix/pivot visual, including the Power BI work referenced earlier in this assignment.

In this dataset: `orders` and `order_items` are natural **fact tables** (transactional, additive measures like `total_amount`, `quantity`). `customers`, `products`, `employees`, and `departments` are **dimension tables** (descriptive attributes you group and filter by, that change slowly if at all).

**Slowly Changing Dimensions (SCD)** — what happens when a dimension attribute changes over time

A product's price changes. A customer's segment changes. An employee's department changes. The question SCD modeling answers is: *when that happens, do you overwrite the old value, or keep history?*

- **Type 1 (overwrite)** — just `UPDATE` the row in place. Simple, but you lose the ability to ask "what was true at the time of this historical transaction?" Fine for corrections (fixing a typo), wrong for anything you'll want to report on historically (like price).
- **Type 2 (historize)** — never overwrite; instead, close out the old row (set an `effective_to` date) and insert a new row with the new value and its own `effective_from`. This is exactly what `product_prices_history` in this dataset already does — it's a live Type 2 SCD table. The `effective_to IS NULL` row is the "current" version; every other row is a historical version, kept for exactly this kind of "what was true as of date X" query.
- **Type 3 (limited history)** — add one extra column like `previous_price` to hold just the immediately-prior value. Cheap, but only remembers one step back — rarely used compared to Type 2.

**The point-in-time join — the pattern that matters most**

The single most common mistake with Type 2 SCD tables is joining a fact row to the dimension's *current* row instead of the version that was actually in effect when the fact happened. For a report on a 2023 order, you want the *2023* price, not today's price.

```sql
-- WRONG: joins every order_item to whatever price is current TODAY,
-- even for orders placed years before that price took effect.
SELECT oi.order_item_id, oi.unit_price AS charged_price, pph.price AS "current_price_ignoring_date"
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN product_prices_history pph
    ON pph.product_id = oi.product_id AND pph.effective_to IS NULL;

-- CORRECT: point-in-time join — find the price row whose effective range
-- actually covers the order's date.
SELECT oi.order_item_id, oi.unit_price AS charged_price, pph.price AS "price_as_of_order_date"
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN product_prices_history pph
    ON pph.product_id = oi.product_id
   AND o.order_date >= pph.effective_from
   AND o.order_date <  COALESCE(pph.effective_to, DATE '9999-12-31');
```

Note the `COALESCE(pph.effective_to, DATE '9999-12-31')` — because the current row's `effective_to` is `NULL`, a naive `o.order_date < pph.effective_to` would exclude every order for a product's current price range (comparing anything to NULL yields UNKNOWN, exactly as covered in Level 1, Topic 6). Coalescing NULL to a far-future date makes the "currently in effect" row correctly match any recent order date.

**Common mistakes**
- Joining a fact table to a dimension's current-only row for historical reporting — silently applies today's attribute values (price, segment, department) to old transactions, quietly corrupting historical numbers.
- Forgetting `effective_to` can be NULL and not guarding the upper bound of the date range comparison with `COALESCE`.
- Building a "fact table" at too coarse a grain (e.g., aggregating `order_items` up to `orders` before you actually need to) — you lose the ability to analyze by product, which is exactly the fan-out-avoidance tradeoff introduced in Level 4, Question 102.
- Treating a Type 1 (overwrite) dimension as if it were Type 2 — assuming you can look up "what was this customer's segment last year" when the table only ever stored the current value.

**Practice Questions — 21. Star Schema Design and Slowly Changing Dimensions**

**Question 113** [Tables: order_items, orders, product_prices_history]
Using the point-in-time join pattern above, for every `order_items` row, find the price that was actually in effect on that order's `order_date` from `product_prices_history`. Return `order_item_id`, `order_id`, `order_date`, `product_id`, `unit_price` (what was actually charged), `price_as_of_order_date`, and a flag `'PRICE MISMATCH'` where the two differ by more than a trivial rounding amount.

**Question 114** [Tables: product_prices_history]
Product 205 (NoiseCancel Headset) is getting a new price of 2650.00, effective 2024-07-01. Write the SQL (as an `UPDATE` to close the current row's `effective_to`, plus an `INSERT` for the new row) that correctly applies this as a Type 2 SCD change — i.e., write it as you would if this were a real, executable data-load step, not a live destructive statement against your working database.

**Question 115** [Tables: orders, order_items, products, customers]
Write a query that aggregates total revenue by `product.category` and `customer.customer_segment`, treating `orders`/`order_items` as the fact table and `products`/`customers` as dimensions. In a comment above the query, explicitly label which tables are playing the fact role and which are playing the dimension role, and note the grain (one row per what?) of your fact table before aggregation.

**Question 116** [No query needed]
Explain, in writing, why `product_prices_history` existing as a genuine Type 2 SCD table matters for financial reporting accuracy, and describe — using a concrete example from this dataset — the specific risk of accidentally equi-joining `order_items` to a product's *current* price row when building a historical revenue report.

---

### 22. MERGE / UPSERT Patterns

An **upsert** is a single operation that inserts a row if it doesn't exist yet, or updates it if it does — "insert or update," collapsed into one atomic statement instead of two separate ones that each carry their own race-condition risk. This comes up constantly in ETL/data-load work: reloading a batch of records where some are brand new and some are corrections to records you already loaded, and you want the operation to be **idempotent** — safe to re-run without creating duplicates or erroring on conflict.

**MERGE (ANSI standard / SQL Server / Oracle / Postgres 15+)**

The full ANSI `MERGE` statement compares a target table against a source (often a staging table or a `VALUES` list) and lets you specify different actions for matched vs. unmatched rows in one statement:

```sql
MERGE INTO product_prices_history AS target
USING (SELECT 207 AS product_id, 4200.00 AS price, DATE '2024-08-01' AS effective_from) AS source
ON target.product_id = source.product_id AND target.effective_to IS NULL
WHEN MATCHED THEN
    UPDATE SET effective_to = source.effective_from - INTERVAL '1 day'
WHEN NOT MATCHED THEN
    INSERT (product_id, price, effective_from, effective_to)
    VALUES (source.product_id, source.price, source.effective_from, NULL);
```

**Postgres's native upsert — `INSERT ... ON CONFLICT`**

Postgres supported upserts via `ON CONFLICT` years before it added a full `MERGE` statement (Postgres 15+), and `ON CONFLICT` remains the more common idiom for simple single-target upserts in Postgres code you'll encounter:

```sql
INSERT INTO customers (customer_id, customer_name, email, signup_date, country, customer_segment, referred_by)
VALUES (105, 'Ananya Sharma', 'ananya.s@mail.com', '2021-05-18', 'India', 'Enterprise', NULL)
ON CONFLICT (customer_id)
DO UPDATE SET
    customer_name = EXCLUDED.customer_name,
    email = EXCLUDED.email,
    customer_segment = EXCLUDED.customer_segment;
```

`EXCLUDED` refers to the row that *would* have been inserted — i.e., the new incoming values — so `EXCLUDED.email` means "the email value from the row I was trying to insert," letting you decide exactly which columns get overwritten on conflict versus left untouched.

**When to use which**

Use `ON CONFLICT` (Postgres) for straightforward single-table upserts keyed on a unique/primary key constraint. Reach for full `MERGE` when you need multiple conditional branches (different logic for matched vs. not-matched vs. "matched but a specific field changed"), or when you're also deleting rows that exist in the target but not the source (`WHEN NOT MATCHED BY SOURCE THEN DELETE`, SQL Server syntax) — a full three-way sync in one statement.

**Common mistakes**
- Matching on a non-unique or overly broad condition, causing the "update" branch to silently update far more rows than intended.
- Using `MERGE`/`ON CONFLICT` across many concurrent sessions without understanding your engine's locking behavior for the operation — early Postgres versions had documented race-condition edge cases with high-concurrency `ON CONFLICT` under certain isolation levels.
- Forgetting that an upsert still needs a real uniqueness constraint (primary key or unique index) to detect a "conflict" against — there's nothing to match on otherwise.
- Reaching for `MERGE`/upsert when a plain idempotent `INSERT ... WHERE NOT EXISTS` would do, adding unnecessary complexity for a load pattern that never actually needs to update existing rows.

**Practice Questions — 22. MERGE / UPSERT Patterns**

**Question 117** [Tables: product_prices_history, products]
Write an upsert (either full `MERGE` or Postgres `ON CONFLICT`) for product 207 (Portable SSD 1TB): if a current price row (`effective_to IS NULL`) already exists at exactly the new price, do nothing; otherwise close out the old current row and insert a new one at 4200.00 effective 2024-08-01.

**Question 118** [Tables: customers]
Write an `INSERT ... ON CONFLICT (customer_id) DO UPDATE` statement for loading a batch of customer records from a staging source, where existing customers should have their `customer_name`, `email`, and `customer_segment` refreshed, but their original `signup_date` and `referred_by` should never be overwritten by a reload.

**Question 119** [No query needed]
Explain, in writing, the difference between a single `MERGE`/`ON CONFLICT` statement and running two separate statements (`INSERT ... WHERE NOT EXISTS`, then `UPDATE ... WHERE EXISTS`) to accomplish the same upsert. Specifically address why the single-statement approach is safer under concurrent writes, referencing the atomicity concept from Level 4, Topic 19.

---

### 23. DML at Scale — Batched Updates and Deletes

Every `UPDATE` and `DELETE` you've written so far in this assignment has targeted a small, fixed dataset — fine for a training exercise, but a single unbatched `UPDATE` or `DELETE` against a genuinely large production table (millions of rows) creates real operational risk: it holds locks on every affected row for the duration of the statement, can blow up the transaction log/WAL, may cause replication lag, and — if something goes wrong partway through — leaves you rolling back a very expensive, very long-running transaction.

**The batching pattern**

Instead of one giant statement, you break the operation into a loop of smaller statements, each committing its own small batch, so no single transaction holds locks for long and a mid-run interruption only costs you the current batch, not the whole job.

```sql
-- Conceptual batched DELETE, repeated until 0 rows are affected
DELETE FROM orders
WHERE order_id IN (
    SELECT order_id FROM orders
    WHERE order_status = 'CANCELLED' AND order_date < '2022-01-01'
    LIMIT 500
);
-- Application/script layer re-runs this statement in a loop
-- until it reports 0 rows deleted, pausing briefly between batches
-- to avoid saturating the database with continuous write load.
```

For batched `UPDATE`s, the same idea applies, but you typically need a way to track progress across batches — either a `LIMIT`-based loop identical to the delete pattern above, or chunking by a range of primary keys (`WHERE employee_id BETWEEN 1 AND 1000`, then `1001 AND 2000`, and so on) so each batch is independently identifiable and the job is resumable if interrupted partway through.

**Why this matters even in an analytics-adjacent role**

You'll encounter this pattern directly in dbt/ETL incremental models, in one-off cleanup scripts against production-scale tables, and in any migration or backfill job — exactly the kind of work that turns "wrote correct SQL" into "wrote SQL that's safe to run against a live 50-million-row table without taking the application down."

**Common mistakes**
- Running one massive `UPDATE`/`DELETE` against a large table with no batching, holding row locks and blocking other transactions for the entire duration.
- Batching without an `ORDER BY`/deterministic selection inside the batch-selection subquery, risking the same rows being re-selected or some rows being skipped entirely across iterations.
- Committing too infrequently (batches too large) or too frequently (batches too small, adding excessive round-trip overhead) — batch size is a real tuning decision, not an arbitrary constant.
- Forgetting to add a short pause between batches in high-traffic production systems, effectively still saturating the database even though each individual statement is small.

**Practice Questions — 23. DML at Scale — Batched Updates and Deletes**

**Question 120** [Tables: orders]
Write a batched `DELETE` pattern (using a `LIMIT`-based subquery, intended to be re-run in a loop by an application/script layer) that purges CANCELLED orders older than 2022-01-01 in batches of 500 rows. In a comment, explain specifically why this is safer than one unbatched `DELETE` against a hypothetical 50-million-row `orders` table.

**Question 121** [Tables: employees]
Write a batched `UPDATE` pattern that applies a 5% raise to every active Engineering department employee, processed in chunks by `employee_id` ranges rather than all at once. In a comment, describe how you'd track which ranges have already been processed so the job could safely resume if it were interrupted halfway through.

**Question 122** [No query needed]
Explain, in writing, why a single giant unbatched `UPDATE` risks lock contention and a dangerously long-running transaction, referencing the isolation-level and locking concepts already covered in Level 4, Topic 19 (Transactions and Data Integrity Basics).

---

### 24. Bulk Loading and Staging Tables

Row-by-row `INSERT` statements — even hundreds of them — are far slower than a purpose-built bulk-load mechanism, because each individual `INSERT` carries its own parsing, planning, and (depending on configuration) transaction-commit overhead. Every major engine provides a dedicated bulk-load path: `COPY` (Postgres), `BULK INSERT`/`bcp` (SQL Server), `LOAD DATA INFILE` (MySQL). These read a file directly into a table in one efficient pass, bypassing most of that per-row overhead.

```sql
-- Postgres: bulk-load a CSV directly into a staging table
COPY stg_orders (order_id, customer_id, order_date, order_status, total_amount, ship_country)
FROM '/path/to/daily_orders_export.csv'
WITH (FORMAT csv, HEADER true);
```

**The staging table pattern**

Loading raw external data directly into a production table with real constraints (foreign keys, `NOT NULL`, checks) is risky — if even one row in a 100,000-row file is malformed, the *entire load can fail*, or the constraint violation aborts the whole batch. The standard pattern instead:

1. Bulk-load the raw file into an **unconstrained staging table** (same shape as the target, but no foreign keys, no NOT NULL enforcement) — nothing here can fail on bad data.
2. **Validate** the staged data with ordinary `SELECT` queries — find rows with missing required fields, orphaned foreign keys, duplicate keys, bad data types.
3. **Promote** only the clean rows into the real target table with an `INSERT ... SELECT`, often combined with the upsert pattern from Topic 22 for idempotent reloads.

```sql
-- Step 2: validation — find staged orders referencing a customer that doesn't exist
SELECT s.* FROM stg_orders s
LEFT JOIN customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Step 3: promote only valid, non-duplicate rows
INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount, ship_country)
SELECT s.order_id, s.customer_id, s.order_date, s.order_status, s.total_amount, s.ship_country
FROM stg_orders s
JOIN customers c ON s.customer_id = c.customer_id
ON CONFLICT (order_id) DO NOTHING;
```

**Common mistakes**
- Loading directly into a constrained production table, letting one bad row abort or corrupt an entire batch load.
- Never truncating/clearing the staging table between loads, causing old rows to be reprocessed (or duplicated) on the next run.
- Skipping the validation step entirely and assuming source files are always clean — exactly the kind of assumption that breaks in production even when it held during testing.
- Using `ON CONFLICT DO NOTHING` without actually checking *why* rows are conflicting — silently swallowing real data-quality problems (e.g., a genuinely different order accidentally reusing an existing `order_id`) instead of surfacing them for review.

**Practice Questions — 24. Bulk Loading and Staging Tables**

**Question 123** [Tables: orders]
Write the Postgres `COPY` command to bulk-load a CSV of new orders into a staging table `stg_orders` (same columns as `orders`). Then write the validation query that flags any staged row whose `customer_id` doesn't exist in `customers`, before it's allowed to be promoted into the real `orders` table.

**Question 124** [Tables: order_items]
Design the staging-table pattern for a daily `order_items` export: write the `CREATE TABLE stg_order_items` statement (unconstrained, matching `order_items`' shape), then the `INSERT INTO order_items ... SELECT ... ON CONFLICT (order_item_id) DO NOTHING` promotion step. In a comment, explain specifically why `ON CONFLICT DO NOTHING` here makes the daily load idempotent — safe to accidentally re-run against the same file without creating duplicate line items.

---

### 25. JSON and JSONB

Some attributes don't fit cleanly into fixed columns — product specifications vary wildly by category (a laptop has RAM and storage; an office chair has material and warranty years), and forcing every possible attribute into its own nullable column produces a wide, mostly-empty, hard-to-extend table. JSON/JSONB columns let you store semi-structured, variable-shape data alongside your normal relational columns, queried with dedicated operators rather than plain `=`/`LIKE`.

**Schema extension for this topic**

Two nullable JSONB columns are added for these questions only — nothing in Levels 1–4 or Topics 20–24 depends on them, and no other assignment table is affected:

```sql
ALTER TABLE products  ADD COLUMN specifications JSONB;
ALTER TABLE customers ADD COLUMN preferences    JSONB;
```

Sample data — `products.specifications`:

| product_id | specifications |
|---|---|
| 201 | `{"ram_gb": 16, "storage_gb": 512, "screen_inches": 14, "weight_kg": 1.4}` |
| 203 | `{"screen_inches": 27, "resolution": "4K", "refresh_hz": 144}` |
| 205 | `{"noise_cancelling": true, "battery_hours": 30, "wireless": true}` |
| 207 | `{"storage_gb": 1000, "interface": "USB-C", "warranty_years": 3}` |
| 209 | `{"material": "mesh", "adjustable_height": true, "warranty_years": 5}` |
| 210 | `{"material": "laminate", "adjustable_height": true, "max_height_cm": 130, "warranty_years": 5}` |

Sample data — `customers.preferences`:

| customer_id | preferences |
|---|---|
| 101 | `{"newsletter": true, "interested_categories": ["Electronics", "Accessories"]}` |
| 105 | `{"newsletter": false, "interested_categories": ["Electronics", "Furniture"]}` |
| 109 | `{"newsletter": true, "interested_categories": ["Storage"]}` |

**Postgres JSONB operators — the ones you'll actually use**

- `->` — get a JSON field **as JSON** (keeps nesting/type). `specifications -> 'ram_gb'` returns the JSON number `16`, not a plain integer.
- `->>` — get a JSON field **as text**. `specifications ->> 'ram_gb'` returns the text `'16'`, which you can then `CAST`/`::` to a real numeric type for comparisons or math.
- `#>` / `#>>` — same idea, but for a **path** (array of keys) into nested JSON, for when a value is buried more than one level deep.
- `@>` — **containment**: does the left JSON value contain the right one? `specifications @> '{"wireless": true}'` matches any row where that key/value pair is present, regardless of what else is in the JSON.
- `?` — **key existence**: does this top-level key exist at all, regardless of its value? `specifications ? 'warranty_years'`.
- `jsonb_array_elements(...)` — expands a JSON array field into one row per element, for use in a `LATERAL`/`CROSS JOIN` when you need to treat array contents as normal rows.

```sql
-- -> vs ->>: -> keeps JSON type, ->> gives text you can cast
SELECT product_id,
       specifications -> 'ram_gb'  AS ram_as_json,
       (specifications ->> 'ram_gb')::INT AS ram_as_integer
FROM products
WHERE specifications ? 'ram_gb';

-- Containment: find every product with wireless capability, whatever category it's in
SELECT product_id, product_name
FROM products
WHERE specifications @> '{"wireless": true}';
```

**Common mistakes**
- Confusing `->` (returns JSON) with `->>` (returns text) — using `->` where a plain text/number comparison is needed causes type-mismatch errors or silently-wrong comparisons, since a JSON number and a plain integer are not the same type.
- Forgetting to `CAST`/`::` a `->>`-extracted text value before doing numeric comparisons or math on it (`->>'ram_gb' > 8` compares text lexicographically, not numerically, which is wrong).
- Assuming a JSONB column is efficiently queryable at scale without an index — for frequent `@>` containment lookups on a large table, a **GIN index** (`CREATE INDEX ... USING GIN (specifications)`) is what makes those queries fast; without it, every containment query is a full scan.
- Over-using JSON for attributes that are actually fixed and frequently queried/filtered/joined-on across every row (e.g., putting `category` inside JSON instead of as its own column) — this is a real anti-pattern sometimes called "schema-on-read overuse." JSON is for genuinely variable, sparse, or rapidly-evolving attributes; well-known, universally-present, frequently-filtered attributes belong in real typed columns where the query planner and indexes can work properly, tying directly back to the star-schema/dimensional-modeling tradeoffs in Topic 21.

**Practice Questions — 25. JSON and JSONB**

**Question 125** [Tables: products]
Using `products.specifications`, extract `ram_gb` as a proper integer for every product that has that key, and separately find every Electronics product whose `screen_inches` value exceeds 20.

**Question 126** [Tables: products]
Using the `@>` containment operator (or the `?` key-existence operator, whichever fits better), find every product whose `specifications` includes a `warranty_years` key at all, then separately find every product with `"wireless": true`.

**Question 127** [Tables: customers]
Using `customers.preferences` and `jsonb_array_elements`, expand the `interested_categories` array into one row per customer per category, joined back to `customer_name`, so each row reads as "this customer is interested in this category."

**Question 128** [No query needed]
Explain, in writing, when you'd choose a JSONB column over a fully normalized table (e.g., a separate `product_specifications` table with one row per product per attribute) for semi-structured data like product specifications, referencing the dimensional-modeling and star-schema tradeoffs discussed in Topic 21.

---

## Level 5 Complete

Topics 20–25 close the gap between the analytical SQL fluency built in Levels 1–4 and the data-engineering patterns needed to actually own the pipelines that feed those queries: collapsing multiple report levels into one query, modeling and correctly joining historized dimensions, safely upserting and batching writes at scale, loading external data without corrupting production tables, and working with semi-structured data alongside the relational core. Combined with Levels 1–4, this is the same 12-table dataset carried end-to-end from "write a correct SELECT" through "design and safely operate the pipeline."
