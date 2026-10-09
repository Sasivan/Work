# SQL Test 1 – LeetCode-Level Practice Workbook (PostgreSQL)

Covers: **Advance SQL assignment**, **Week 4 (Beginner)**, **Week 5 (Intermediate + Advanced)**, **Week 6 (Advanced / DE)**, and the **10-problem SQL Assignment PDF** (plus bonus LeetCode classics).
Difficulty tags: 🟢 Easy · 🟡 Medium · 🔴 Hard. Every topic goes basic → advanced.
Week 7 (Git) is not SQL, so it is not included.

> **Tip:** Run each part in a scratch schema (`CREATE SCHEMA practice; SET search_path = practice;`) because several parts re-create tables with the same names (e.g. partitioned `orders`).
> **Version note:** `MERGE` needs PostgreSQL 15+. `MERGE ... RETURNING` needs 17+.

---

## 0. Common Practice Schema

```sql
CREATE TABLE customers (
  id SERIAL PRIMARY KEY, name TEXT NOT NULL, email TEXT, city TEXT,
  registration_date DATE, last_order_date DATE
);
CREATE TABLE products (
  id SERIAL PRIMARY KEY, name TEXT, category TEXT, price NUMERIC(10,2),
  stock_qty INT, supplier_id INT, attributes JSONB
);
CREATE TABLE orders (
  id SERIAL PRIMARY KEY, customer_id INT REFERENCES customers(id),
  order_date DATE, total_amount NUMERIC(10,2), status TEXT
);
CREATE TABLE order_items (
  id SERIAL PRIMARY KEY, order_id INT REFERENCES orders(id),
  product_id INT REFERENCES products(id), quantity INT, unit_price NUMERIC(10,2)
);

INSERT INTO customers(name,email,city,registration_date) VALUES
 ('Alice','alice@gmail.com','Mumbai','2024-01-10'),
 ('Bob','bob@yahoo.com','Delhi','2024-03-05'),
 ('Carol','carol@gmail.com','Pune','2024-06-20'),
 ('Dan',NULL,'Mumbai','2023-11-11');
INSERT INTO products(name,category,price,stock_qty,supplier_id,attributes) VALUES
 ('Phone','Electronics',999,10,NULL,'{"color":"red","weight":1.2,"tags":["sale","new"]}'),
 ('Laptop','Electronics',1500,0,10,'{"color":"blue","weight":2.1,"tags":["new"]}'),
 ('Tablet','Electronics',500,5,NULL,'{"color":"red","weight":0.6,"tags":["sale"]}'),
 ('Shirt','Clothing',200,50,20,'{"color":"white","weight":0.2,"tags":[]}');
INSERT INTO orders(customer_id,order_date,total_amount,status) VALUES
 (1,'2024-01-15',500,'completed'),(1,'2024-02-20',300,'completed'),
 (2,'2024-02-10',800,'completed'),(2,'2024-03-01',400,'cancelled'),
 (1,'2024-03-15',700,'completed');
INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES
 (1,1,1,500),(2,3,1,300),(3,2,1,800),(4,4,2,200),(5,1,1,700);
```

---

# PART A – WEEK 4 (BEGINNER)

## A1. SELECT, WHERE, ORDER BY, LIMIT, Aliases & NULL Handling

**A1.1 🟢** List all `Electronics` products costing more than 500, highest price first. Alias `name` → `product_name`, `price` → `unit_price`.
```sql
SELECT name AS product_name, price AS unit_price
FROM products
WHERE category = 'Electronics' AND price > 500
ORDER BY price DESC;
```

**A1.2 🟢** Find the 5 most expensive products overall (include ties for the 5th place).
```sql
-- Plain LIMIT cuts ties arbitrarily
SELECT * FROM products ORDER BY price DESC LIMIT 5;

-- PostgreSQL 13+: keeps all rows tied with the 5th
SELECT * FROM products ORDER BY price DESC FETCH FIRST 5 ROWS WITH TIES;
```

**A1.3 🟢** Show `supplier_id` if present, else `'No Supplier'`. Also return NULL when `stock_qty = 0`.
```sql
SELECT name,
       COALESCE(supplier_id::text, 'No Supplier') AS supplier,   -- cast: both branches must be same type
       NULLIF(stock_qty, 0) AS stock_or_null
FROM products;
```

**A1.4 🟢** Count products with and without a supplier.
```sql
SELECT COUNT(*) FILTER (WHERE supplier_id IS NULL)     AS no_supplier,
       COUNT(*) FILTER (WHERE supplier_id IS NOT NULL) AS has_supplier,
       COUNT(supplier_id)                              AS same_as_has_supplier  -- COUNT(col) skips NULLs
FROM products;
```

**A1.5 🟡** Compute *price per unit of stock* without a divide-by-zero error.
```sql
SELECT name, price / NULLIF(stock_qty, 0) AS price_per_stock   -- NULL instead of error when stock=0
FROM products;
```

**A1.6 🟡 (LeetCode 584 – Find Customer Referee)** `customer(id, name, referee_id)`. Return names of customers **not referred by id 2** (NULL referee counts as "not referred by 2").
```sql
SELECT name FROM customer
WHERE referee_id IS DISTINCT FROM 2;   -- NULL-safe; "<> 2" would drop NULL rows
```

**A1.7 🟡 (LeetCode 176 – Second Highest Salary)** Return the second highest *distinct* salary, or NULL if none.
```sql
SELECT (SELECT DISTINCT salary FROM employee
        ORDER BY salary DESC LIMIT 1 OFFSET 1) AS secondhighestsalary;
-- Wrapping in a scalar subquery guarantees one row with NULL when no 2nd value exists.
```

**A1.8 🟢 Predict the output**
```sql
-- products: (1,'Phone',999,NULL),(2,'Laptop',1500,10),(3,'Tablet',500,NULL)
SELECT name, COALESCE(supplier_id::text,'No Supplier') AS supplier, NULLIF(price,500) AS price
FROM products ORDER BY price DESC NULLS LAST;
```
| name | supplier | price |
|---|---|---|
| Laptop | 10 | 1500 |
| Phone | No Supplier | 999 |
| Tablet | No Supplier | NULL |

*Why:* `NULLIF(500,500)` → NULL for Tablet; ORDER BY uses the output alias `price`; `NULLS LAST` pushes it to the bottom.

---

## A2. Aggregates, GROUP BY & HAVING

**A2.1 🟢** City, number of customers, and total revenue; only cities with revenue > 10000, highest first.
```sql
SELECT c.city,
       COUNT(DISTINCT c.id)  AS customers,
       SUM(o.total_amount)   AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.city
HAVING SUM(o.total_amount) > 10000
ORDER BY revenue DESC;
-- WHERE filters rows BEFORE grouping; HAVING filters groups AFTER aggregation.
```

**A2.2 🟡** Month with the highest total order amount.
```sql
SELECT DATE_TRUNC('month', order_date)::date AS month, SUM(total_amount) AS total
FROM orders
GROUP BY 1
ORDER BY total DESC
LIMIT 1;
```

**A2.3 🟡** Average order amount per customer; only customers with ≥3 orders AND average > 500.
```sql
SELECT customer_id, COUNT(*) AS orders, AVG(total_amount) AS avg_amt
FROM orders
GROUP BY customer_id
HAVING COUNT(*) >= 3 AND AVG(total_amount) > 500;
```

**A2.4 🟡** Distinct customers who ordered in **each month of 2024**, including months with zero.
```sql
SELECT m::date AS month, COUNT(DISTINCT o.customer_id) AS active_customers
FROM generate_series('2024-01-01'::date, '2024-12-01', '1 month') m
LEFT JOIN orders o ON DATE_TRUNC('month', o.order_date) = m
GROUP BY m ORDER BY m;
```

**A2.5 🟢 (LeetCode 182 – Duplicate Emails)**
```sql
SELECT email FROM person GROUP BY email HAVING COUNT(*) > 1;
```

**A2.6 🟡 (LeetCode 586 – Customer Placing the Largest Number of Orders)**
```sql
SELECT customer_number FROM orders
GROUP BY customer_number ORDER BY COUNT(*) DESC LIMIT 1;
```

**A2.7 🔴 (LeetCode 1193 – Monthly Transactions I)** `transactions(id, country, state, amount, trans_date)`: per month+country → total count, approved count, total amount, approved amount.
```sql
SELECT TO_CHAR(trans_date,'YYYY-MM') AS month, country,
       COUNT(*)                                            AS trans_count,
       COUNT(*) FILTER (WHERE state='approved')            AS approved_count,
       SUM(amount)                                         AS trans_total_amount,
       COALESCE(SUM(amount) FILTER (WHERE state='approved'),0) AS approved_total_amount
FROM transactions
GROUP BY 1, 2;
```

**A2.8 🟢 Predict the output**
```sql
-- orders: (1,'Mumbai',500),(2,'Mumbai',300),(3,'Delhi',800),(4,'Delhi',400),(5,'Mumbai',700)
SELECT city, COUNT(*) cnt, SUM(total_amount) rev FROM orders
GROUP BY city HAVING SUM(total_amount) > 1000 ORDER BY rev DESC;
```
| city | cnt | rev |
|---|---|---|
| Mumbai | 3 | 1500 |
| Delhi | 2 | 1200 |

---

## A3. JOINs: INNER, LEFT, RIGHT, FULL OUTER

**A3.1 🟢** Customer name, order date, total amount for all **2024** orders.
```sql
SELECT c.name, o.order_date, o.total_amount
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id
WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01';  -- sargable range, not EXTRACT(year...)
```

**A3.2 🟢** ALL customers with their order count (0 if none).
```sql
SELECT c.id, c.name, COUNT(o.id) AS order_count   -- COUNT(o.id) ignores NULLs from unmatched rows
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
-- INNER JOIN keeps only matching rows (customers without orders vanish).
-- LEFT JOIN keeps every left row; right columns become NULL when no match.
-- Pitfall: COUNT(*) would return 1 for customers with no orders.
```

**A3.3 🟡** Products that have **never** appeared in an order.
```sql
-- Option 1: NOT EXISTS (preferred: NULL-safe, anti-join, stops at first match)
SELECT p.* FROM products p
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);

-- Option 2: LEFT JOIN ... IS NULL (also an anti-join in the planner)
SELECT p.* FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
WHERE oi.id IS NULL;
```
*Choice:* NOT EXISTS expresses intent clearly and is not broken by NULLs (unlike `NOT IN`).

**A3.4 🟡** FULL OUTER JOIN: show customers without orders **and** orders without a valid customer.
```sql
SELECT c.id AS cust_id, c.name, o.id AS order_id, o.total_amount
FROM customers c
FULL OUTER JOIN orders o ON o.customer_id = c.id;
```
Rows that appear **only** here: unmatched on the left (customer with no orders → order cols NULL) **and** unmatched on the right (order with NULL/orphan customer_id → customer cols NULL) *at the same time*. INNER shows neither; LEFT shows only the first kind; RIGHT only the second.

**A3.5 🟢 (LeetCode 181 – Employees Earning More Than Their Managers)**
```sql
SELECT e.name AS employee
FROM employee e JOIN employee m ON e.managerid = m.id
WHERE e.salary > m.salary;
```

**A3.6 🟢 (LeetCode 183 – Customers Who Never Order)**
```sql
SELECT c.name AS customers FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customerid = c.id);
```

**A3.7 🟢 (LeetCode 197 – Rising Temperature)**
```sql
SELECT w1.id
FROM weather w1 JOIN weather w2 ON w1.recorddate = w2.recorddate + 1   -- date + int works in PG
WHERE w1.temperature > w2.temperature;
```

**A3.8 🔴 (LeetCode 262 – Trips and Users)** Cancellation rate per day (2013-10-01 to 2013-10-03) counting only trips where **both** client and driver are unbanned.
```sql
SELECT t.request_at AS "Day",
       ROUND(COUNT(*) FILTER (WHERE t.status <> 'completed')::numeric / COUNT(*), 2) AS "Cancellation Rate"
FROM trips t
JOIN users c ON t.client_id = c.users_id AND c.banned = 'No'
JOIN users d ON t.driver_id = d.users_id AND d.banned = 'No'
WHERE t.request_at BETWEEN '2013-10-01' AND '2013-10-03'
GROUP BY t.request_at;
```

**A3.9 🟢 Predict the output**
```sql
-- customers: (1,'Alice'),(2,'Bob'),(3,'Carol');  orders: (101,1,500),(102,1,300)
SELECT c.name, COUNT(o.id) AS order_count
FROM customers c LEFT JOIN orders o ON c.id=o.customer_id
GROUP BY c.name ORDER BY c.name;
```
| name | order_count |
|---|---|
| Alice | 2 |
| Bob | 0 |
| Carol | 0 |

---

## A4. Subqueries: Scalar, Correlated, EXISTS / NOT EXISTS vs IN / NOT IN

**A4.1 🟢** Each order alongside the overall average order amount.
```sql
SELECT id, total_amount, (SELECT AVG(total_amount) FROM orders) AS overall_avg
FROM orders;
```

**A4.2 🟡** Customers who ordered in the last 30 days — with `EXISTS`, then `IN`.
```sql
SELECT c.* FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o
              WHERE o.customer_id = c.id AND o.order_date >= CURRENT_DATE - 30);

SELECT c.* FROM customers c
WHERE c.id IN (SELECT customer_id FROM orders WHERE order_date >= CURRENT_DATE - 30);
```
*Performance:* `EXISTS` is a semi-join: it stops at the first match per customer and never builds a full list. Modern PostgreSQL often plans both identically, but `EXISTS` is safer on huge inner sets and has no NULL surprises. Index `orders(customer_id, order_date)` helps either.

**A4.3 🟡** Customers who have **never** ordered — `NOT EXISTS` vs `NOT IN` and the NULL trap.
```sql
SELECT c.* FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- Dangerous:
SELECT c.* FROM customers c
WHERE c.id NOT IN (SELECT customer_id FROM orders);
```
**NULL trap:** if `orders.customer_id` contains even one NULL, `id NOT IN (1, 2, NULL)` evaluates to `UNKNOWN` for every non-listed id, so **zero rows** are returned. Fix: `NOT EXISTS`, or `NOT IN (... WHERE customer_id IS NOT NULL)`.

**A4.4 🟡** Derived table: per-customer totals, then customers above the overall average customer total.
```sql
SELECT t.customer_id, t.total
FROM (SELECT customer_id, SUM(total_amount) AS total FROM orders GROUP BY customer_id) t
WHERE t.total > (SELECT AVG(total) FROM
                 (SELECT SUM(total_amount) AS total FROM orders GROUP BY customer_id) x);
```

**A4.5 🟡 Correlated subquery:** orders larger than **that customer's own** average.
```sql
SELECT o.*
FROM orders o
WHERE o.total_amount > (SELECT AVG(o2.total_amount) FROM orders o2
                        WHERE o2.customer_id = o.customer_id);
```

**A4.6 🟡** Employees earning above their **department** average (correlated).
```sql
SELECT e.* FROM employee e
WHERE e.salary > (SELECT AVG(salary) FROM employee WHERE departmentid = e.departmentid);
```

**A4.7 🟢 Predict the output**
```sql
-- orders: (1,100),(2,200),(3,300),(4,400),(5,500)
SELECT id, total_amount, (SELECT AVG(total_amount) FROM orders) AS avg
FROM orders WHERE total_amount > (SELECT AVG(total_amount) FROM orders);
```
AVG = 300 → only 400 and 500 qualify.
| id | total_amount | avg |
|---|---|---|
| 4 | 400 | 300.00… |
| 5 | 500 | 300.00… |

---

## A5. String & Date/Time Functions + CASE WHEN

**A5.1 🟢** Name in UPPER, email in lower, and the email domain.
```sql
SELECT UPPER(name) AS name, LOWER(email) AS email,
       SPLIT_PART(email, '@', 2) AS domain          -- alt: SUBSTRING(email FROM POSITION('@' IN email)+1)
FROM customers;
```

**A5.2 🟢** Format `registration_date` as `DD-Month-YYYY`.
```sql
SELECT TO_CHAR(registration_date, 'DD-FMMonth-YYYY') AS reg   -- FM removes Month's blank padding
FROM customers;
```

**A5.3 🟡** Days since registration; only customers registered in the last 90 days.
```sql
SELECT name, CURRENT_DATE - registration_date AS days_ago     -- date - date = integer days
FROM customers
WHERE registration_date >= CURRENT_DATE - 90;
```

**A5.4 🟡** Label products Premium (>1000) / Standard (200–1000) / Budget (<200); only products present in at least one order.
```sql
SELECT p.name, p.price,
  CASE WHEN p.price > 1000 THEN 'Premium'
       WHEN p.price >= 200 THEN 'Standard'
       ELSE 'Budget' END AS tier
FROM products p
WHERE EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);
```

**A5.5 🟢 (LeetCode 1667 – Fix Names)** Capitalize first letter, lowercase the rest.
```sql
SELECT user_id, UPPER(LEFT(name,1)) || LOWER(SUBSTRING(name FROM 2)) AS name
FROM users ORDER BY user_id;
-- INITCAP(name) would also capitalize every word, which is different for multi-word names
```

**A5.6 🟡 (LeetCode 1527 – Patients With a Condition)** Conditions that start with `DIAB1` as a *word*.
```sql
SELECT * FROM patients
WHERE conditions LIKE 'DIAB1%' OR conditions LIKE '% DIAB1%';
```

**A5.7 🟡 (LeetCode 196 – Delete Duplicate Emails)** Keep the smallest id per email.
```sql
DELETE FROM person p
USING person q
WHERE p.email = q.email AND p.id > q.id;
```

**A5.8 🟡 (LeetCode 1907 – Count Salary Categories)** Low (<20000), Average (20000–50000), High (>50000) — include categories with 0.
```sql
SELECT c.category, COUNT(a.account_id) AS accounts_count
FROM (VALUES ('Low Salary'),('Average Salary'),('High Salary')) c(category)
LEFT JOIN (
  SELECT account_id,
    CASE WHEN income < 20000 THEN 'Low Salary'
         WHEN income <= 50000 THEN 'Average Salary'
         ELSE 'High Salary' END AS category
  FROM accounts) a USING (category)
GROUP BY c.category;
```

**A5.9 🟡** Conditional aggregation: revenue pivot by status per customer.
```sql
SELECT customer_id,
  SUM(total_amount) FILTER (WHERE status='completed') AS completed_rev,
  SUM(total_amount) FILTER (WHERE status='cancelled') AS cancelled_rev
FROM orders GROUP BY customer_id;
```

**A5.10 🟢 Predict the output**
```sql
-- customer: id=1, name='john doe', email='john.doe@gmail.com'
SELECT UPPER(name) AS name, LOWER(email) AS email, SPLIT_PART(email,'@',2) AS domain
FROM customers WHERE id=1;
```
| name | email | domain |
|---|---|---|
| JOHN DOE | john.doe@gmail.com | gmail.com |

---

## A6. DDL: CREATE / ALTER & Normalization (1NF → 3NF)

Given `orders_flat(order_id, customer_name, customer_email, customer_city, product1_name, product1_price, product2_name, product2_price, salesperson_name, salesperson_region)`.

**A6.1 🟡 Identify violations**
| Violation | Where | Why |
|---|---|---|
| **1NF** | `product1_*`, `product2_*` | Repeating group of columns; limited to 2 products, hard to query |
| **2NF** | Product attributes (if PK is `order_id + product`) | `product_price` depends only on product, not the full key |
| **3NF** | `customer_city`, `customer_email` depend on `customer_name`, not on `order_id` | Transitive dependency (order → customer → city) |
| **3NF** | `salesperson_region` depends on `salesperson_name` | Transitive dependency |

**A6.2 🟡 3NF design**
- `customers(customer_id PK, name, email UNIQUE, city)`
- `salespersons(salesperson_id PK, name, region)`
- `products(product_id PK, name, price)`
- `orders(order_id PK, customer_id FK→customers, salesperson_id FK→salespersons, order_date)`
- `order_items(order_id FK→orders, product_id FK→products, quantity, unit_price; PK(order_id, product_id))`

**A6.3 🟡 CREATE TABLE**
```sql
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  name  VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL,
  city  VARCHAR(80)
);
CREATE TABLE salespersons (
  salesperson_id SERIAL PRIMARY KEY,
  name   VARCHAR(100) NOT NULL,
  region VARCHAR(50)  NOT NULL
);
CREATE TABLE products (
  product_id SERIAL PRIMARY KEY,
  name  VARCHAR(100) NOT NULL,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  customer_id    INT NOT NULL REFERENCES customers(customer_id),
  salesperson_id INT REFERENCES salespersons(salesperson_id),
  order_date DATE NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE order_items (
  order_id   INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id INT NOT NULL REFERENCES products(product_id),
  quantity   INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
  PRIMARY KEY (order_id, product_id)
);
```

**A6.4 🟢 ALTER TABLE**
```sql
ALTER TABLE customers ADD COLUMN phone_number VARCHAR(15);
ALTER TABLE customers ADD CONSTRAINT uq_customers_email UNIQUE (email);
ALTER TABLE products  ADD CONSTRAINT chk_products_price CHECK (price > 0);
```

**A6.5 🟡** Identify the normal form: `enroll(student_id, course_id, student_name, instructor, instructor_office)` with PK `(student_id, course_id)`.
- `student_name` depends only on `student_id` → **2NF violation** (partial dependency).
- `instructor_office` depends on `instructor` which depends on `course_id` → **3NF violation** (transitive).
- Fix: `students(student_id, name)`, `courses(course_id, instructor_id)`, `instructors(instructor_id, name, office)`, `enrollments(student_id, course_id)`.

**A6.6 🟢 Predict which INSERTs succeed**
```sql
CREATE TABLE emp(id INT PRIMARY KEY, name VARCHAR(50) NOT NULL, sal DECIMAL CHECK(sal>0));
INSERT INTO emp VALUES (1,'Alice',50000);  -- A
INSERT INTO emp VALUES (2,NULL,60000);     -- B
INSERT INTO emp VALUES (3,'Bob',-100);     -- C
```
- **A succeeds.**
- **B fails** – NOT NULL violation on `name`.
- **C fails** – CHECK violation (`sal > 0`).

---

# PART B – WEEK 5 (INTERMEDIATE + ADVANCED)

## B1. Window Functions

**B1.1 🟢** Number each customer's orders chronologically.
```sql
SELECT o.*, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, id) AS order_no
FROM orders o;
```

**B1.2 🟡 Top-N per group:** first order of every customer.
```sql
SELECT * FROM (
  SELECT o.*, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, id) rn
  FROM orders o) t
WHERE rn = 1;
-- Alternative: SELECT DISTINCT ON (customer_id) * FROM orders ORDER BY customer_id, order_date;
```

**B1.3 🟢** `RANK()` vs `DENSE_RANK()` — show where they differ.
```sql
SELECT id, total_amount,
       RANK()       OVER (ORDER BY total_amount DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY total_amount DESC) AS dense_rnk
FROM orders;
-- amounts 500,500,300 → RANK: 1,1,3 | DENSE_RANK: 1,1,2   (RANK skips after ties)
```

**B1.4 🟡** Previous and next order amount per customer; NULL when none.
```sql
SELECT customer_id, order_date, total_amount,
       LAG(total_amount)  OVER w AS prev_order_amount,
       LEAD(total_amount) OVER w AS next_order_amount
FROM orders
WINDOW w AS (PARTITION BY customer_id ORDER BY order_date);
```

**B1.5 🟡** Days between consecutive orders per customer.
```sql
SELECT customer_id, order_date,
       order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_since_prev
FROM orders;
```

**B1.6 🟡** 3-order rolling average per customer.
```sql
SELECT customer_id, order_date, total_amount,
       AVG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date
                               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_avg_3
FROM orders;
```

**B1.7 🟡** Running total and % of customer total.
```sql
SELECT customer_id, order_date, total_amount,
       SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
       ROUND(100.0 * total_amount / SUM(total_amount) OVER (PARTITION BY customer_id), 1) AS pct_of_customer
FROM orders;
```

**B1.8 🟡 Frame trap:** `LAST_VALUE` returns the *current* row by default. Fix it.
```sql
SELECT customer_id, order_date,
  LAST_VALUE(total_amount) OVER (
     PARTITION BY customer_id ORDER BY order_date
     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS latest_amount
FROM orders;
-- Default frame = RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW (when ORDER BY is present).
-- ROWS counts physical rows; RANGE groups peers (rows with equal ORDER BY values).
```

**B1.9 🟡 (LeetCode 178 – Rank Scores)**
```sql
SELECT score, DENSE_RANK() OVER (ORDER BY score DESC) AS "rank"
FROM scores ORDER BY score DESC;
```

**B1.10 🟡 (LeetCode 185 – Department Top Three Salaries)**
```sql
SELECT d.name AS department, e.name AS employee, e.salary
FROM (SELECT *, DENSE_RANK() OVER (PARTITION BY departmentid ORDER BY salary DESC) rk
      FROM employee) e
JOIN department d ON d.id = e.departmentid
WHERE e.rk <= 3;
```

**B1.11 🟡 (LeetCode 180 – Consecutive Numbers)** Numbers appearing at least 3 times in a row.
```sql
SELECT DISTINCT num AS consecutivenums
FROM (SELECT num,
             LAG(num)    OVER (ORDER BY id) AS p1,
             LAG(num, 2) OVER (ORDER BY id) AS p2
      FROM logs) t
WHERE num = p1 AND num = p2;
```

**B1.12 🔴 Gaps & Islands (LeetCode 601 – Human Traffic of Stadium)** Rows with ≥ 100 people for 3+ consecutive ids.
```sql
WITH grp AS (
  SELECT *, id - ROW_NUMBER() OVER (ORDER BY id) AS g    -- constant within a consecutive run
  FROM stadium WHERE people >= 100)
SELECT id, visit_date, people FROM grp
WHERE g IN (SELECT g FROM grp GROUP BY g HAVING COUNT(*) >= 3)
ORDER BY visit_date;
```

**B1.13 🔴 Login streaks:** users with a streak of ≥ 3 consecutive login days.
```sql
WITH d AS (SELECT DISTINCT user_id, login_date FROM logins),
g AS (SELECT user_id, login_date,
             login_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date))::int AS grp
      FROM d)
SELECT user_id, MIN(login_date) AS streak_start, MAX(login_date) AS streak_end, COUNT(*) AS days
FROM g GROUP BY user_id, grp HAVING COUNT(*) >= 3;
```

**B1.14 🔴 (LeetCode 550 – Game Play Analysis IV)** Fraction of players who logged in again the day after their first login.
```sql
WITH f AS (SELECT player_id, MIN(event_date) AS first_date FROM activity GROUP BY player_id)
SELECT ROUND(COUNT(a.player_id)::numeric / (SELECT COUNT(*) FROM f), 2) AS fraction
FROM f LEFT JOIN activity a
  ON a.player_id = f.player_id AND a.event_date = f.first_date + 1;
```

**B1.15 🔴 (LeetCode 1204 – Last Person to Fit in the Bus)** Weight limit 1000.
```sql
SELECT person_name FROM (
  SELECT person_name, SUM(weight) OVER (ORDER BY turn) AS total FROM queue) t
WHERE total <= 1000 ORDER BY total DESC LIMIT 1;
```

**B1.16 🔴 (LeetCode 1321 – Restaurant Growth)** 7-day moving sum and average (first output at the 7th day).
```sql
WITH daily AS (SELECT visited_on, SUM(amount) AS amount FROM customer GROUP BY visited_on),
w AS (
  SELECT visited_on,
         SUM(amount) OVER (ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS amount,
         ROUND(AVG(amount) OVER (ORDER BY visited_on ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS average_amount,
         ROW_NUMBER() OVER (ORDER BY visited_on) AS rn
  FROM daily)
SELECT visited_on, amount, average_amount FROM w WHERE rn >= 7 ORDER BY visited_on;
-- If days can be missing use: RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW
```

**B1.17 🔴 (LeetCode 585 – Investments in 2016)** Sum `tiv_2016` where `tiv_2015` is shared with another policy AND `(lat, lon)` is unique.
```sql
SELECT ROUND(SUM(tiv_2016)::numeric, 2) AS tiv_2016 FROM (
  SELECT tiv_2016,
         COUNT(*) OVER (PARTITION BY tiv_2015)  AS c15,
         COUNT(*) OVER (PARTITION BY lat, lon)  AS cloc
  FROM insurance) t
WHERE c15 > 1 AND cloc = 1;
```

**B1.18 🟡 Median and quartiles**
```sql
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary FROM employee;
SELECT NTILE(4) OVER (ORDER BY salary) AS quartile, name, salary FROM employee;
```

**B1.19 🟢 Predict the output**
```sql
-- orders: (1,1,'2024-01-01',100),(2,1,'2024-02-01',300),(3,2,'2024-01-01',400)
SELECT customer_id, total_amount,
  RANK() OVER(ORDER BY total_amount DESC) AS rnk,
  LAG(total_amount) OVER(PARTITION BY customer_id ORDER BY order_date) AS prev
FROM orders;
```
| customer_id | total_amount | rnk | prev |
|---|---|---|---|
| 1 | 100 | 3 | NULL |
| 1 | 300 | 2 | 100 |
| 2 | 400 | 1 | NULL |
(Row order is not guaranteed without an outer ORDER BY.)

---

## B2. CTEs, Recursive CTEs, Set Operators, ROLLUP / CUBE / GROUPING SETS

**B2.1 🟡** CTE `top_customers` (top 5 by spend) joined to orders to show each one's most recent purchase.
```sql
WITH top_customers AS (
  SELECT customer_id, SUM(total_amount) AS spent
  FROM orders GROUP BY customer_id ORDER BY spent DESC LIMIT 5)
SELECT tc.customer_id, tc.spent, MAX(o.order_date) AS last_purchase
FROM top_customers tc JOIN orders o USING (customer_id)
GROUP BY tc.customer_id, tc.spent;
```

**B2.2 🟡** Recursive CTE generating 1..10.
```sql
WITH RECURSIVE nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 10)
SELECT n FROM nums;
```
*Useful for:* hierarchies (org charts, categories, bill of materials), graph/path traversal, generating calendars when `generate_series` isn't available.

**B2.3 🔴** Employee hierarchy: for CEO-down tree, show level and full path.
```sql
WITH RECURSIVE tree AS (
  SELECT id, name, manager_id, 1 AS level, name::text AS path
  FROM employee WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.name, e.manager_id, t.level + 1, t.path || ' > ' || e.name
  FROM employee e JOIN tree t ON e.manager_id = t.id)
SELECT * FROM tree ORDER BY path;
-- Guard against cycles with a depth limit (WHERE level < 20) or PG14+ CYCLE clause.
```

**B2.4 🔴** Count **all** (direct + indirect) reports for each manager.
```sql
WITH RECURSIVE r AS (
  SELECT id AS manager, id AS emp FROM employee
  UNION ALL
  SELECT r.manager, e.id FROM r JOIN employee e ON e.manager_id = r.emp)
SELECT manager, COUNT(*) - 1 AS total_reports FROM r GROUP BY manager;
```

**B2.5 🟡** `UNION ALL` of 2023 and 2024 orders with a year column; compare totals; find customers in **both** years.
```sql
WITH yearly AS (
  SELECT 2023 AS year, customer_id, total_amount FROM orders_2023
  UNION ALL
  SELECT 2024, customer_id, total_amount FROM orders_2024)
SELECT year, SUM(total_amount) AS total FROM yearly GROUP BY year;

SELECT customer_id FROM orders_2023
INTERSECT
SELECT customer_id FROM orders_2024;
```

**B2.6 🟡** Churned: ordered in 2023 but **not** in 2024 (`EXCEPT`).
```sql
SELECT customer_id FROM orders WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01'
EXCEPT
SELECT customer_id FROM orders WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';
-- UNION/INTERSECT/EXCEPT remove duplicates; use the ALL variants to keep them (UNION ALL is faster).
```

**B2.7 🟡** `ROLLUP (category, city)` then the `GROUPING SETS` rewrite for only 2 of the 3 levels.
```sql
SELECT category, city, SUM(amount) AS revenue,
       GROUPING(category, city) AS grp_flag
FROM sales
GROUP BY ROLLUP (category, city);     -- (cat,city) + (cat) + ()

-- Only category subtotal and grand total:
SELECT category, SUM(amount) FROM sales
GROUP BY GROUPING SETS ((category), ());

-- CUBE (category, city) = all 4 combos: (cat,city),(cat),(city),()
```

**B2.5b 🟡 Replace NULL labels from ROLLUP**
```sql
SELECT COALESCE(category,'ALL CATEGORIES') AS category,
       COALESCE(city,'ALL CITIES') AS city, SUM(amount)
FROM sales GROUP BY ROLLUP (category, city);
-- Caveat: a real NULL in data looks like a subtotal row; use GROUPING() to tell them apart.
```

**B2.8 🟢 Predict the output**
```sql
-- sales: ('A','X',100),('A','Y',200),('B','X',300)
SELECT category, city, SUM(amount) FROM sales GROUP BY ROLLUP(category,city);
```
| category | city | sum |
|---|---|---|
| A | X | 100 |
| A | Y | 200 |
| A | NULL | 300 |
| B | X | 300 |
| B | NULL | 300 |
| NULL | NULL | 600 |

---

## B3. Query Optimization: EXPLAIN ANALYZE, Indexes, Materialized Views

Given: `SELECT * FROM orders o JOIN customers c ON o.customer_id=c.id WHERE c.city='Mumbai' AND o.order_date>'2024-01-01' ORDER BY o.total_amount DESC;`

**B3.1 🟢** EXPLAIN ANALYZE and what to read.
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders o JOIN customers c ON o.customer_id = c.id
WHERE c.city = 'Mumbai' AND o.order_date > '2024-01-01'
ORDER BY o.total_amount DESC;
```
Look for: **Seq Scan vs Index/Bitmap Scan**; **estimated vs actual rows** (big gaps → stale stats → run `ANALYZE`); `cost=startup..total`; **Buffers** (`shared hit` vs `read`); **join type** (Nested Loop / Hash / Merge); **Sort Method** (`external merge` = spilled to disk); `loops`; **Rows Removed by Filter**; and total **Execution Time**. Remember `ANALYZE` actually *executes* the query (wrap DML in a transaction and ROLLBACK).

**B3.2 🟡** Propose indexes and explain composite vs two single-column indexes.
```sql
CREATE INDEX idx_customers_city        ON customers (city);
CREATE INDEX idx_orders_cust_date      ON orders (customer_id, order_date);
```
A composite index serves `WHERE customer_id = ? AND order_date > ?` with **one** index traversal: equality on the first column narrows to a contiguous range, which is already sorted by `order_date`. Two single indexes force a BitmapAnd (two scans + merge) or one index + filtering. Left-prefix rule: it also helps `WHERE customer_id = ?` alone, but not `WHERE order_date > ?` alone.

**B3.3 🟢** Replace `SELECT *`.
```sql
SELECT o.id, o.order_date, o.total_amount, c.name
FROM orders o JOIN customers c ON o.customer_id = c.id
WHERE c.city = 'Mumbai' AND o.order_date > '2024-01-01'
ORDER BY o.total_amount DESC;
```
`SELECT *` on wide tables: more I/O and memory, wider sorts spill to disk sooner, blocks index-only scans, transfers extra network data, and breaks when columns are added/reordered.

**B3.4 🟡** Materialized view of revenue per customer.
```sql
CREATE MATERIALIZED VIEW mv_customer_revenue AS
SELECT customer_id, SUM(total_amount) AS revenue, COUNT(*) AS orders
FROM orders GROUP BY customer_id;

CREATE UNIQUE INDEX ON mv_customer_revenue (customer_id);       -- required for CONCURRENTLY
REFRESH MATERIALIZED VIEW mv_customer_revenue;                  -- locks readers
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_revenue;     -- no read lock
```
Regular view = stored query, always fresh, recomputed each time. Materialized view = stored **result**, fast for heavy aggregates, but stale until refreshed. Use it for dashboards/reports tolerant of slight staleness.

**B3.5 🟡 Fix non-sargable predicates** (functions on indexed columns kill index use).
```sql
-- Bad                                   -- Good
WHERE DATE(order_date) = '2024-03-01'    WHERE order_date >= '2024-03-01' AND order_date < '2024-03-02'
WHERE EXTRACT(YEAR FROM order_date)=2024 WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'
WHERE LOWER(email) = 'a@x.com'           CREATE INDEX ON customers (LOWER(email));  -- expression index
WHERE name LIKE '%son'                   -- cannot use B-tree; use pg_trgm GIN
```

**B3.6 🔴** Replace `OFFSET` pagination with keyset pagination.
```sql
-- Slow for deep pages (scans and discards 1,000,000 rows)
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 1000000;
-- Fast: seek from the last seen id
SELECT * FROM orders WHERE id > :last_seen_id ORDER BY id LIMIT 20;
```

**B3.7 🟡 Predict the change**
```
Before: Seq Scan on orders, cost=0.00..450.00, rows=10000
CREATE INDEX idx_ord ON orders(customer_id, order_date);
```
For a selective query such as `WHERE customer_id = 42`, the plan becomes an **Index Scan (or Bitmap Index Scan + Bitmap Heap Scan) using idx_ord** with a far lower cost (illustratively `cost=0.29..8.31 rows≈5`). If the query filters only on `order_date`, the left-prefix rule means the planner will likely keep the Seq Scan.

---

## B4. ACID Transactions & Isolation Levels

**B4.1 🟡** Transfer 5000 from account 101 to 202, record it, roll back if the balance would go negative.
```sql
CREATE OR REPLACE PROCEDURE transfer_funds(p_from INT, p_to INT, p_amount NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE v_balance NUMERIC;
BEGIN
  IF p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be positive'; END IF;

  SELECT balance INTO v_balance FROM accounts WHERE id = p_from FOR UPDATE;  -- pessimistic row lock
  IF NOT FOUND THEN RAISE EXCEPTION 'Account % not found', p_from; END IF;
  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient funds: balance %, requested %', v_balance, p_amount;
  END IF;

  UPDATE accounts SET balance = balance - p_amount WHERE id = p_from;
  UPDATE accounts SET balance = balance + p_amount WHERE id = p_to;
  INSERT INTO transactions(from_account, to_account, amount, created_at)
  VALUES (p_from, p_to, p_amount, now());
END $$;

CALL transfer_funds(101, 202, 5000);   -- any exception rolls back the whole call
```

**B4.2 🟡** Defence in depth: let the database enforce the rule too.
```sql
ALTER TABLE accounts ADD CONSTRAINT chk_balance_nonneg CHECK (balance >= 0);

BEGIN;
UPDATE accounts SET balance = balance - 5000 WHERE id = 101;  -- fails with check_violation if < 0
UPDATE accounts SET balance = balance + 5000 WHERE id = 202;
INSERT INTO transactions(from_account,to_account,amount,created_at) VALUES (101,202,5000,now());
COMMIT;      -- after any error, run ROLLBACK;
```

**B4.3 🟡** Read anomalies and isolation levels.
| Anomaly | Meaning | Prevented by (SQL standard) |
|---|---|---|
| **Dirty read** | Read another transaction's *uncommitted* data | READ COMMITTED and above |
| **Non-repeatable read** | Same row read twice gives different values (another tx committed an UPDATE) | REPEATABLE READ and above |
| **Phantom read** | Same query returns a different *set of rows* (another tx inserted/deleted matching rows) | SERIALIZABLE (standard) |

PostgreSQL specifics: `READ UNCOMMITTED` behaves exactly like `READ COMMITTED` (dirty reads never happen); `REPEATABLE READ` uses snapshot isolation and **also prevents phantoms**; `SERIALIZABLE` (SSI) additionally prevents write-skew and may raise `serialization_failure` (SQLSTATE 40001) – the app must retry.

**B4.4 🟡** Optimistic vs pessimistic locking.
```sql
-- Pessimistic: lock first, then change. Good when conflicts are frequent (bank balance, seat booking).
BEGIN;
SELECT balance FROM accounts WHERE id = 101 FOR UPDATE;
UPDATE accounts SET balance = balance - 100 WHERE id = 101;
COMMIT;

-- Optimistic: no lock, detect conflict at write time with a version column.
-- Good when conflicts are rare (editing a profile / CMS page).
UPDATE products SET price = 120, version = version + 1
WHERE id = 1 AND version = 7;        -- 0 rows updated => someone else changed it; retry
```

**B4.5 🔴** Avoid deadlocks and build a job queue.
```sql
-- Lock rows in a consistent order (e.g. lowest id first) in every transaction:
SELECT * FROM accounts WHERE id IN (101, 202) ORDER BY id FOR UPDATE;

-- Multiple workers pulling jobs without blocking each other:
SELECT id FROM jobs WHERE status = 'pending'
ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED;
```

**B4.6 🟢 Predict the output**
```sql
-- accounts: (1,5000),(2,5000)
BEGIN; UPDATE accounts SET balance=balance-1000 WHERE id=1;
       UPDATE accounts SET balance=balance+1000 WHERE id=2; COMMIT;
SELECT balance FROM accounts ORDER BY id;
```
→ **4000**, then **6000** (total preserved = atomicity).

---

## B5. Star Schema, Snowflake Schema & SCD Type 2

**B5.1 🟡** Star schema for the e-commerce warehouse.
```sql
CREATE TABLE dim_date (
  date_key INT PRIMARY KEY,            -- e.g. 20240615
  full_date DATE NOT NULL, year INT, quarter INT, month INT, month_name TEXT,
  day_of_week INT, is_weekend BOOLEAN);

CREATE TABLE dim_product (
  product_key SERIAL PRIMARY KEY, product_id INT NOT NULL,
  name TEXT, category TEXT, sub_category TEXT, brand TEXT);   -- denormalized hierarchy

CREATE TABLE dim_customer (
  customer_key SERIAL PRIMARY KEY, customer_id INT NOT NULL,
  name TEXT, email TEXT, city TEXT, state TEXT, region TEXT);

CREATE TABLE fact_sales (
  sales_key BIGSERIAL PRIMARY KEY,
  date_key     INT NOT NULL REFERENCES dim_date(date_key),
  product_key  INT NOT NULL REFERENCES dim_product(product_key),
  customer_key INT NOT NULL REFERENCES dim_customer(customer_key),
  order_id INT,                         -- degenerate dimension
  quantity INT NOT NULL, unit_price NUMERIC(10,2), sales_amount NUMERIC(12,2));
```
*Why:* the fact table holds numeric measures at a single grain (one order line); dimensions are wide and denormalized, so reports need only 1 join per dimension.

**B5.2 🟡** `dim_customer` with SCD Type 2 columns.
```sql
CREATE TABLE dim_customer (
  customer_key   SERIAL PRIMARY KEY,         -- surrogate key
  customer_id    INT NOT NULL,               -- business key
  name VARCHAR(100), email VARCHAR(150), city VARCHAR(80),
  effective_from DATE NOT NULL,
  effective_to   DATE,                       -- NULL = still open
  is_current     BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX uq_dim_customer_current ON dim_customer (customer_id) WHERE is_current;
-- guarantees at most one current row per customer
```

**B5.3 🟡** Customer 101 moves Delhi → Pune.
```sql
BEGIN;
UPDATE dim_customer
SET effective_to = DATE '2024-06-01', is_current = FALSE
WHERE customer_id = 101 AND is_current;

INSERT INTO dim_customer (customer_id, name, email, city, effective_from, effective_to, is_current)
VALUES (101, 'Priya', 'p@x.com', 'Pune', DATE '2024-06-01', NULL, TRUE);
COMMIT;
```

**B5.4 🟡** Point-in-time ("as-of") join — what city was the customer in on the order date?
```sql
SELECT o.id, c.city
FROM orders o
JOIN dim_customer c
  ON c.customer_id = o.customer_id
 AND o.order_date >= c.effective_from
 AND (o.order_date < c.effective_to OR c.effective_to IS NULL);
```

**B5.5 🟡** Snowflake vs star.
Snowflake normalizes dimensions into sub-dimensions (`dim_product → dim_category → dim_department`). Choose it when dimensions are huge with deep hierarchies, to cut storage and ensure one place to update shared attributes. **Trade-off:** less redundancy and easier maintenance vs **more joins → slower, more complex queries**.

**B5.6 🟡** Report on the star: revenue by category, region and month.
```sql
SELECT d.year, d.month, p.category, c.region, SUM(f.sales_amount) AS revenue
FROM fact_sales f
JOIN dim_date d     USING (date_key)
JOIN dim_product p  USING (product_key)
JOIN dim_customer c USING (customer_key)
GROUP BY d.year, d.month, p.category, c.region;
```

**B5.7 🔴** Set-based SCD2 load from a staging table in one statement.
```sql
WITH expired AS (
  UPDATE dim_customer d
  SET effective_to = CURRENT_DATE, is_current = FALSE
  FROM stg_customer s
  WHERE d.customer_id = s.customer_id AND d.is_current
    AND (d.name, d.email, d.city) IS DISTINCT FROM (s.name, s.email, s.city)
  RETURNING d.customer_id)
INSERT INTO dim_customer (customer_id, name, email, city, effective_from, effective_to, is_current)
SELECT s.customer_id, s.name, s.email, s.city, CURRENT_DATE, NULL, TRUE
FROM stg_customer s
WHERE s.customer_id IN (SELECT customer_id FROM expired)                      -- changed
   OR NOT EXISTS (SELECT 1 FROM dim_customer d WHERE d.customer_id = s.customer_id);  -- brand new
```

**B5.8 🟢 Predict the output**
```sql
-- dim_customer: (key=1,cust_id=101,city='Delhi',is_current=TRUE)
UPDATE dim_customer SET effective_to='2024-06-01', is_current=FALSE WHERE customer_key=1;
INSERT INTO dim_customer VALUES (2,101,'Priya','p@x.com','Pune','2024-06-01',NULL,TRUE);
SELECT customer_key, city, is_current FROM dim_customer WHERE customer_id=101 ORDER BY customer_key;
```
| customer_key | city | is_current |
|---|---|---|
| 1 | Delhi | f |
| 2 | Pune | t |

---

# PART C – WEEK 6 (ADVANCED / DE-FOCUSED)

## C1. DML: INSERT, UPDATE, DELETE

**C1.1 🟢** Insert a customer and 3 `order_items` rows in one statement.
```sql
INSERT INTO customers (name, email, city, registration_date)
VALUES ('Eve', 'eve@gmail.com', 'Pune', CURRENT_DATE);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 2, 999), (1, 3, 1, 500), (1, 4, 3, 200);
```

**C1.2 🟡** Insert a customer, an order and an item in one statement using CTEs + `RETURNING`.
```sql
WITH c AS (
  INSERT INTO customers (name, email, city) VALUES ('Frank','f@x.com','Delhi') RETURNING id),
o AS (
  INSERT INTO orders (customer_id, order_date, total_amount, status)
  SELECT id, CURRENT_DATE, 999, 'completed' FROM c RETURNING id)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT id, 1, 1, 999 FROM o;
```

**C1.3 🟢** +10% on Electronics; stock = 0 for products never ordered.
```sql
UPDATE products SET price = price * 1.10 WHERE category = 'Electronics';

UPDATE products p SET stock_qty = 0
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id);
```

**C1.4 🟡** `UPDATE ... FROM`: recompute order totals from their items.
```sql
UPDATE orders o
SET total_amount = s.total
FROM (SELECT order_id, SUM(quantity * unit_price) AS total FROM order_items GROUP BY order_id) s
WHERE o.id = s.order_id;
```

**C1.5 🟡** Delete orders before 2020 under 100 (and their items).
```sql
-- 1) Always preview first
SELECT * FROM orders WHERE order_date < '2020-01-01' AND total_amount < 100;

-- 2) Delete children then parents atomically
WITH del AS (
  DELETE FROM orders WHERE order_date < '2020-01-01' AND total_amount < 100 RETURNING id)
DELETE FROM order_items WHERE order_id IN (SELECT id FROM del);
-- (Not valid ordering with FK: the child delete must happen first, or use ON DELETE CASCADE.)
```
Cleaner with an FK defined `ON DELETE CASCADE`, or:
```sql
BEGIN;
DELETE FROM order_items WHERE order_id IN
  (SELECT id FROM orders WHERE order_date < '2020-01-01' AND total_amount < 100);
DELETE FROM orders WHERE order_date < '2020-01-01' AND total_amount < 100;
COMMIT;
```
*Why SELECT first:* DELETE is irreversible once committed; the preview confirms the row count and predicate (a missing/incorrect WHERE deletes everything).

**C1.6 🟡** Atomic order creation.
```sql
BEGIN;
WITH o AS (
  INSERT INTO orders (customer_id, order_date, total_amount, status)
  VALUES (1, CURRENT_DATE, 1400, 'completed') RETURNING id)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT id, v.pid, v.qty, v.price FROM o, (VALUES (1,1,999),(4,2,200)) v(pid, qty, price);
UPDATE customers SET last_order_date = CURRENT_DATE WHERE id = 1;
COMMIT;
```

**C1.7 🟢 (LeetCode 627 – Swap Salary)** Swap 'm' and 'f' in one UPDATE.
```sql
UPDATE salary SET sex = CASE sex WHEN 'm' THEN 'f' ELSE 'm' END;
```

**C1.8 🟡** `DELETE` vs `TRUNCATE` vs `DROP`.
`DELETE`: row-by-row, WHERE allowed, fires triggers, MVCC (needs VACUUM). `TRUNCATE`: instant, removes all rows, resets identity with `RESTART IDENTITY`, fully transactional in PG. `DROP`: removes the table itself.

**C1.9 🟢 Predict the output**
```sql
-- products: (1,'Phone',100.00,'Electronics'),(2,'Shirt',200.00,'Clothing')
UPDATE products SET price=price*1.10 WHERE category='Electronics';
SELECT id, price FROM products ORDER BY id;
```
| id | price |
|---|---|
| 1 | 110.00 |
| 2 | 200.00 |

---

## C2. MERGE / UPSERT

**C2.1 🟡** MERGE: update existing customers, insert new ones from a staging table (PG 15+).
```sql
MERGE INTO customers AS t
USING stg_customers AS s ON t.id = s.customer_id
WHEN MATCHED THEN
  UPDATE SET name = s.name, email = s.email, city = s.city
WHEN NOT MATCHED THEN
  INSERT (id, name, email, city) VALUES (s.customer_id, s.name, s.email, s.city);
```

**C2.2 🟡** Same with `INSERT ... ON CONFLICT`.
```sql
INSERT INTO customers (id, name, email, city)
SELECT customer_id, name, email, city FROM stg_customers
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name, email = EXCLUDED.email, city = EXCLUDED.city;
```
*Difference:* `ON CONFLICT` needs a unique index/constraint to detect conflicts, is atomic and safe under concurrency (guaranteed insert-or-update), but only supports insert/update. `MERGE` is SQL-standard, can join on any condition, supports `UPDATE`, `DELETE` and `DO NOTHING` branches with extra conditions (`WHEN MATCHED AND ...`), but under concurrency it can raise unique-violation errors since it doesn't lock like ON CONFLICT.

**C2.3 🟡** Only write when something actually changed (avoids dead tuples / write amplification).
```sql
INSERT INTO customers (id, name, email, city)
SELECT customer_id, name, email, city FROM stg_customers
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name, email = EXCLUDED.email, city = EXCLUDED.city
WHERE (customers.name, customers.email, customers.city)
      IS DISTINCT FROM (EXCLUDED.name, EXCLUDED.email, EXCLUDED.city);
```

**C2.4 🔴** Common error: `ON CONFLICT DO UPDATE command cannot affect row a second time` — the source has duplicate keys. Deduplicate first:
```sql
INSERT INTO customers (id, name, email, city)
SELECT DISTINCT ON (customer_id) customer_id, name, email, city
FROM stg_customers
ORDER BY customer_id, updated_at DESC          -- keep the latest record per key
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email, city = EXCLUDED.city;
```

**C2.5 🔴** MERGE implementing SCD Type 2 (expire changed rows and insert new versions, plus brand-new customers).
```sql
MERGE INTO dim_customer d
USING (
  SELECT s.customer_id AS merge_key, s.customer_id, s.name, s.email, s.city FROM stg_customer s
  UNION ALL                                           -- extra copy of changed rows, key NULL => forces INSERT
  SELECT NULL, s.customer_id, s.name, s.email, s.city
  FROM stg_customer s
  JOIN dim_customer c ON c.customer_id = s.customer_id AND c.is_current
  WHERE c.city IS DISTINCT FROM s.city
) src
ON d.customer_id = src.merge_key AND d.is_current
WHEN MATCHED AND d.city IS DISTINCT FROM src.city THEN
  UPDATE SET effective_to = CURRENT_DATE, is_current = FALSE
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email, city, effective_from, effective_to, is_current)
  VALUES (src.customer_id, src.name, src.email, src.city, CURRENT_DATE, NULL, TRUE);
```
Why the trick: a single source row can trigger only one MERGE action, but a changed customer needs **both** an UPDATE (expire) and an INSERT (new version), so we feed the changed rows twice.

**C2.6 🟡** When MERGE is slow and alternatives.
Problems: no index on the join key → nested loop/hash over the full target; huge batches create bloat, long locks and WAL; updating every row even when unchanged; many tiny updates fragment the table. Alternatives: load to a **staging table**, `ANALYZE` it, then
```sql
BEGIN;
DELETE FROM target t USING staging s WHERE t.id = s.id;
INSERT INTO target SELECT * FROM staging;
COMMIT;
```
or batch in chunks, or partition the target and swap partitions, or `UPDATE ... FROM` + `INSERT ... WHERE NOT EXISTS`.

**C2.7 🟢 Predict the output**
```sql
-- target: (1,'Alice','Delhi'),(2,'Bob','Mumbai')   source: (1,'Alice','Pune'),(3,'Carol','Chennai')
-- MERGE: update city if matched, insert if new
SELECT id,name,city FROM customers ORDER BY id;
```
| id | name | city |
|---|---|---|
| 1 | Alice | Pune |
| 2 | Bob | Mumbai |
| 3 | Carol | Chennai |

---

## C3. Table Partitioning

**C3.1 🟡** RANGE partition on `order_date` (2023, 2024, 2025).
```sql
CREATE TABLE orders (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  customer_id INT NOT NULL,
  order_date DATE NOT NULL,
  total_amount NUMERIC(12,2),
  PRIMARY KEY (id, order_date)             -- PK/UNIQUE must include the partition key
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2023 PARTITION OF orders FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE orders_2024 PARTITION OF orders FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE orders_2025 PARTITION OF orders FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
-- Upper bound is exclusive.
```

**C3.2 🟡** LIST partition with DEFAULT.
```sql
CREATE TABLE customers_p (
  id INT NOT NULL, name TEXT, region TEXT NOT NULL,
  PRIMARY KEY (id, region)
) PARTITION BY LIST (region);
CREATE TABLE customers_north PARTITION OF customers_p FOR VALUES IN ('North');
CREATE TABLE customers_south PARTITION OF customers_p FOR VALUES IN ('South');
CREATE TABLE customers_east  PARTITION OF customers_p FOR VALUES IN ('East');
CREATE TABLE customers_west  PARTITION OF customers_p FOR VALUES IN ('West');
CREATE TABLE customers_other PARTITION OF customers_p DEFAULT;
```

**C3.3 🟡** HASH partition into 4 buckets.
```sql
CREATE TABLE order_items_p (
  id BIGINT NOT NULL, order_id BIGINT NOT NULL, product_id INT, quantity INT,
  PRIMARY KEY (id, order_id)
) PARTITION BY HASH (order_id);
CREATE TABLE order_items_p0 PARTITION OF order_items_p FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE order_items_p1 PARTITION OF order_items_p FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE order_items_p2 PARTITION OF order_items_p FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE order_items_p3 PARTITION OF order_items_p FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```
Hash is best when there is **no natural range/list key** and you want even data and write distribution (high-cardinality keys like `order_id`, `user_id`), to avoid hot partitions. Downside: no pruning for range queries and no easy "drop old data".

**C3.4 🟡** Partition pruning.
```sql
EXPLAIN SELECT * FROM orders WHERE order_date > '2024-01-01';
```
The planner excludes `orders_2023` (and scans only 2024 & 2025) because the partition bounds contradict the WHERE clause. Less data is read → less I/O, smaller indexes, better cache hit rate. Pruning only works when the **filter uses the partition key** with comparable constants (and avoid wrapping the key in functions).

**C3.5 🔴** Maintenance and pitfalls.
```sql
-- Archive an old partition instantly:
ALTER TABLE orders DETACH PARTITION orders_2023;
-- Load-then-attach with minimal locking:
CREATE TABLE orders_2026 (LIKE orders INCLUDING ALL);
-- ... bulk load orders_2026, add CHECK matching bounds ...
ALTER TABLE orders ATTACH PARTITION orders_2026 FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
-- Safety net for unexpected dates:
CREATE TABLE orders_default PARTITION OF orders DEFAULT;
```
Inserting a row with no matching partition raises: `no partition of relation "orders" found for row`.

**C3.6 🟢 Predict the output**
```sql
INSERT INTO orders VALUES (1,'2023-06-15'),(2,'2024-03-20');
SELECT tableoid::regclass, id FROM orders ORDER BY id;
```
| tableoid | id |
|---|---|
| orders_2023 | 1 |
| orders_2024 | 2 |

---

## C4. Bulk Loading: COPY

**C4.1 🟢** Server-side `COPY` vs client-side `\copy`.
```sql
-- Server-side: file must exist on the DB server; needs superuser or pg_read_server_files
COPY orders FROM '/var/lib/postgresql/import/orders_2024.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- Client-side (psql): file is on YOUR machine; streamed over the connection; no superuser needed
\copy orders FROM 'orders_2024.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
```

**C4.2 🟡** Load only some columns.
```sql
-- A) File contains exactly those 3 columns:
COPY orders (customer_id, order_date, total_amount) FROM '/tmp/o.csv' WITH (FORMAT csv, HEADER true);

-- B) File has extra columns to skip (COPY cannot skip file columns): stage then select
CREATE TEMP TABLE stg_orders (id INT, customer_id INT, order_date DATE, total_amount NUMERIC, status TEXT, notes TEXT);
\copy stg_orders FROM 'orders_2024.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO orders (customer_id, order_date, total_amount)
SELECT customer_id, order_date, total_amount FROM stg_orders;
```

**C4.3 🟡** Five bulk-load best practices.
1. Use `COPY` (not row-by-row `INSERT`), in one transaction.
2. Drop/disable secondary indexes and FK/triggers, then recreate after the load.
3. Use an `UNLOGGED` table or load into a fresh/truncated table (`TRUNCATE` in the same transaction as the COPY enables WAL-skipping with `wal_level=minimal`).
4. Increase `maintenance_work_mem` (index builds) and `max_wal_size`/checkpoint settings for the load window.
5. Run `ANALYZE` afterwards; split huge files and load in parallel into partitions.
Bonus: `COPY ... FREEZE` for newly created/truncated tables; PG17+ `ON_ERROR ignore` to skip bad rows.

**C4.4 🟡** Post-load maintenance order.
```sql
-- 1) Recreate indexes / constraints (or REINDEX TABLE orders; if you kept the indexes)
CREATE INDEX idx_orders_cust_date ON orders (customer_id, order_date);
-- 2) VACUUM sets hint bits and the visibility map (enables index-only scans)
VACUUM orders;
-- 3) ANALYZE refreshes planner statistics (or combine: VACUUM (ANALYZE) orders;)
ANALYZE orders;
```
`REINDEX` rebuilds bloated/corrupt indexes; `VACUUM` reclaims dead tuples; `ANALYZE` updates the stats that drive the query planner.

**C4.5 🟡 Predict the result**
```sql
-- orders is empty; orders_2024.csv has a header + 3 data rows
COPY orders FROM '/tmp/orders_2024.csv' CSV HEADER;
SELECT COUNT(*), MAX(total_amount), MIN(total_amount) FROM orders;
```
`COUNT = 3` (header skipped); MAX/MIN are the largest/smallest `total_amount` in the file. Without `HEADER` the header line would be read as data and the load would fail with an invalid input syntax error. If any row fails, the whole COPY aborts and **no** rows are loaded (unless using `ON_ERROR`).

---

## C5. Advanced Indexes

**C5.1 🟡** B-tree vs Hash vs GIN.
| Index | Supports | Best for |
|---|---|---|
| **B-tree** (default) | `= < > BETWEEN`, ORDER BY, prefix `LIKE 'abc%'` | Most columns: dates, ids, amounts |
| **Hash** | only `=` | Large equality lookups on long keys (e.g., UUID/URL tokens) |
| **GIN** | containment/membership in composite values | `jsonb @>`, arrays `@>`, full-text search `tsvector`, `pg_trgm` LIKE '%x%' |
(Also: **GiST** for geometry/ranges, **BRIN** for huge naturally ordered tables like time-series logs.)

**C5.2 🟡** Composite index and column order.
```sql
CREATE INDEX idx_orders_cust_date ON orders (customer_id, order_date DESC);
```
Rule of thumb: **equality columns first**, then range/sort columns; most selective/most used first. *Left-prefix:* the index supports `(customer_id)` and `(customer_id, order_date)` filters, but not `order_date` alone.

**C5.3 🟡** Partial index.
```sql
CREATE INDEX idx_orders_completed_amt ON orders (total_amount) WHERE status = 'completed';
```
Better when queries always target a small subset (e.g., active rows). Storage is roughly proportional to the fraction of qualifying rows (if 20% are `completed`, the index is ~20% of the full one); faster to scan and maintain. The query's WHERE must imply the index predicate. Classic use: `CREATE UNIQUE INDEX ... ON users(email) WHERE deleted_at IS NULL;`.

**C5.4 🟡** Covering index and index-only scan.
```sql
CREATE INDEX idx_cov ON orders (customer_id) INCLUDE (order_date, total_amount);
SELECT order_date, total_amount FROM orders WHERE customer_id = 42;
```
An *index-only scan* answers the query from the index alone without visiting the table heap. It needs all columns present in the index and pages marked all-visible (the visibility map – kept current by `VACUUM`). `INCLUDE` columns are payload only (not searchable/sortable) so keys stay small.

**C5.5 🟡 Other useful index patterns**
```sql
CREATE INDEX ON customers (LOWER(email));                       -- expression index for WHERE LOWER(email)=...
CREATE INDEX ON customers (name text_pattern_ops);              -- LIKE 'abc%' with non-C collation
CREATE EXTENSION pg_trgm;
CREATE INDEX ON customers USING gin (name gin_trgm_ops);        -- LIKE '%abc%'
CREATE INDEX CONCURRENTLY idx_x ON orders (status);             -- no write lock (cannot run in a tx block)
```

**C5.6 🔴** Pick the right index.
| Query | Best index |
|---|---|
| `WHERE customer_id=? ORDER BY order_date DESC LIMIT 10` | `(customer_id, order_date DESC)` |
| `WHERE status='pending'` (1% rows) | partial `(id) WHERE status='pending'` |
| `WHERE attributes @> '{"tags":["sale"]}'` | GIN on `attributes` |
| `WHERE created_at BETWEEN ...` on 1B-row append-only table | BRIN on `created_at` |
| `WHERE order_date=? AND customer_id=?` | either order works for equality, but align with other queries |

**C5.7 🟡 Predict what EXPLAIN shows**
```sql
CREATE INDEX idx_cov ON orders(customer_id) INCLUDE(order_date,total_amount);
EXPLAIN SELECT order_date, total_amount FROM orders WHERE customer_id=42;
```
→ **Index Only Scan using idx_cov on orders**, `Index Cond: (customer_id = 42)`, with a much lower cost than 450 (e.g. `0.42..8.44`). It shows `Heap Fetches: 0` only if the table is recently vacuumed.

---

## C6. JSON / JSONB

**C6.1 🟢** Extract color (text) and tags (JSON); filter red products.
```sql
SELECT id, attributes ->> 'color' AS color, attributes -> 'tags' AS tags
FROM products
WHERE attributes ->> 'color' = 'red';
```

**C6.2 🟡** `JSON_AGG`: per customer, array of order ids and amounts.
```sql
SELECT customer_id,
       JSON_AGG(JSON_BUILD_OBJECT('order_id', id, 'amount', total_amount) ORDER BY id) AS orders
FROM orders GROUP BY customer_id;
```

**C6.3 🟡** Update one key without replacing the column.
```sql
UPDATE products
SET attributes = jsonb_set(attributes, '{weight}', '1.5')   -- or to_jsonb(1.5)
WHERE id = 1;
-- Add key:     attributes || '{"size":"L"}'
-- Remove key:  attributes - 'size'
```

**C6.4 🟡** GIN index and containment.
```sql
CREATE INDEX idx_products_attr ON products USING gin (attributes);
SELECT * FROM products WHERE attributes @> '{"tags":["sale"]}';
-- Other operators: ? (key exists), ?| (any key), ?& (all keys)
```
GIN is an inverted index (key/value → rows), ideal for "does this document contain X" queries; B-tree can't index inside a JSON structure. Use `jsonb_path_ops` for smaller, faster `@>`-only indexes.

**C6.5 🟡** Unnest the tags array and count products per tag.
```sql
SELECT tag, COUNT(*) AS products
FROM products, jsonb_array_elements_text(attributes -> 'tags') AS tag
GROUP BY tag ORDER BY products DESC;
```

**C6.6 🔴** Nested JSON: each customer with orders, each with its items.
```sql
SELECT jsonb_build_object(
  'customer_id', c.id, 'name', c.name,
  'orders', COALESCE((
     SELECT jsonb_agg(jsonb_build_object(
         'order_id', o.id, 'total', o.total_amount,
         'items', (SELECT jsonb_agg(jsonb_build_object('product_id', oi.product_id, 'qty', oi.quantity))
                   FROM order_items oi WHERE oi.order_id = o.id)))
     FROM orders o WHERE o.customer_id = c.id), '[]'::jsonb)) AS doc
FROM customers c;
```

**C6.7 🟡** Numeric filter/cast on JSON values.
```sql
SELECT id FROM products WHERE (attributes ->> 'weight')::numeric > 1;
SELECT SUM((attributes ->> 'weight')::numeric) FROM products;
```

**C6.8 🟡 Predict the output**
```sql
-- products: (id=1, attributes='{"color":"red","weight":1.2,"tags":["sale"]}')
SELECT id, attributes->>'color' AS color,
       (attributes->>'weight')::float + 0.3 AS new_weight,
       attributes->'tags' AS tags
FROM products WHERE id=1;
```
| id | color | new_weight | tags |
|---|---|---|---|
| 1 | red | 1.5 | ["sale"] |

---

# PART D – ADVANCE SQL ASSIGNMENT (Data Warehouse Design)

## D1. Denormalizing a retail schema for fast reporting (category / region / time)

**Problem:** normalized joins (`sales → products → categories → departments`, `stores → cities → regions`) are slow for reports.
**Solution:** star schema with denormalized dimensions + optional pre-aggregated summary.
```sql
CREATE TABLE dim_product (
  product_key SERIAL PRIMARY KEY, product_id INT, product_name TEXT,
  category TEXT, department TEXT, brand TEXT);           -- hierarchy flattened into one row
CREATE TABLE dim_store (
  store_key SERIAL PRIMARY KEY, store_id INT, store_name TEXT,
  city TEXT, state TEXT, region TEXT);
CREATE TABLE dim_date (
  date_key INT PRIMARY KEY, full_date DATE, year INT, quarter INT, month INT, week INT);
CREATE TABLE fact_sales (
  date_key INT REFERENCES dim_date, product_key INT REFERENCES dim_product,
  store_key INT REFERENCES dim_store, quantity INT, revenue NUMERIC(12,2));

-- Pre-aggregated table / MV for the hottest report
CREATE MATERIALIZED VIEW mv_sales_cat_region_month AS
SELECT d.year, d.month, p.category, s.region, SUM(f.revenue) AS revenue, SUM(f.quantity) AS qty
FROM fact_sales f JOIN dim_date d USING (date_key)
JOIN dim_product p USING (product_key) JOIN dim_store s USING (store_key)
GROUP BY 1,2,3,4;
CREATE INDEX ON fact_sales (date_key, product_key, store_key);
```
*Justify:* fewer joins, flat dimensions, summary tables. *Trade-offs:* redundancy and storage ↑, ETL complexity ↑, risk of update anomalies (mitigated by loading dimensions only through ETL, constraints, and a single source of truth).

## D2. View: total order value per customer
```sql
CREATE OR REPLACE VIEW v_customer_order_value AS
SELECT c.id AS customer_id, c.name,
       COALESCE(SUM(o.total_amount), 0) AS total_order_value,
       COUNT(o.id) AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id       -- LEFT JOIN keeps customers with no orders
GROUP BY c.id, c.name;

SELECT * FROM v_customer_order_value ORDER BY total_order_value DESC;
-- For big data use a MATERIALIZED VIEW + scheduled REFRESH.
```

## D3. Procedure: employee salary history
```sql
CREATE TABLE salary_changes (emp_id INT, salary NUMERIC(12,2), effective_date DATE);
CREATE TABLE employee_salary_history (
  emp_id INT, salary NUMERIC(12,2), valid_from DATE, valid_to DATE,
  prev_salary NUMERIC(12,2), pct_change NUMERIC(6,2));

CREATE OR REPLACE PROCEDURE sp_build_salary_history()
LANGUAGE plpgsql AS $$
BEGIN
  TRUNCATE employee_salary_history;
  INSERT INTO employee_salary_history
  SELECT emp_id, salary, effective_date,
         LEAD(effective_date) OVER w - 1                         AS valid_to,   -- NULL = current
         LAG(salary) OVER w                                      AS prev_salary,
         ROUND(100.0 * (salary - LAG(salary) OVER w) / NULLIF(LAG(salary) OVER w, 0), 2) AS pct_change
  FROM salary_changes
  WINDOW w AS (PARTITION BY emp_id ORDER BY effective_date);
END $$;

CALL sp_build_salary_history();
SELECT * FROM employee_salary_history ORDER BY emp_id, valid_from;
```
(Parametrized variant: `CREATE FUNCTION get_salary_history(p_emp INT) RETURNS TABLE(...) AS $$ ... $$ LANGUAGE sql;`)

## D4. SCD Type 2 for customer data
```sql
CREATE TABLE dim_customer (
  customer_key SERIAL PRIMARY KEY, customer_id INT NOT NULL,
  name TEXT, email TEXT, city TEXT,
  effective_from DATE NOT NULL, effective_to DATE, is_current BOOLEAN NOT NULL DEFAULT TRUE);
CREATE UNIQUE INDEX ON dim_customer (customer_id) WHERE is_current;

CREATE OR REPLACE PROCEDURE sp_scd2_customer(p_id INT, p_name TEXT, p_email TEXT, p_city TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM dim_customer WHERE customer_id = p_id AND is_current
             AND (name, email, city) IS NOT DISTINCT FROM (p_name, p_email, p_city)) THEN
    RETURN;                                     -- nothing changed
  END IF;
  UPDATE dim_customer SET effective_to = CURRENT_DATE, is_current = FALSE
  WHERE customer_id = p_id AND is_current;
  INSERT INTO dim_customer (customer_id, name, email, city, effective_from, is_current)
  VALUES (p_id, p_name, p_email, p_city, CURRENT_DATE, TRUE);
END $$;
```
Use the set-based version from **B5.7** for batch loads.

## D5. Social media: daily active users (DAU) report

**Requirement A – only the daily count:** maintain a summary table.
```sql
CREATE TABLE user_activity (
  user_id INT NOT NULL REFERENCES users(user_id),
  activity_date DATE NOT NULL,
  activity_type TEXT NOT NULL,
  PRIMARY KEY (user_id, activity_date, activity_type));

CREATE TABLE daily_active_users (
  activity_date DATE PRIMARY KEY,
  active_users INT NOT NULL CHECK (active_users >= 0),
  updated_at TIMESTAMPTZ DEFAULT now());

-- Daily job (idempotent)
INSERT INTO daily_active_users (activity_date, active_users)
SELECT activity_date, COUNT(DISTINCT user_id)
FROM user_activity WHERE activity_date = CURRENT_DATE - 1
GROUP BY activity_date
ON CONFLICT (activity_date) DO UPDATE
SET active_users = EXCLUDED.active_users, updated_at = now();
```
**Requirement B – who was active and with what attributes at that time:** keep a daily fact table `fact_daily_activity(date_key, user_key)` joined to an **SCD2 `dim_user`** (so a user's country/plan *on that day* is preserved). Integrity: FKs, PK to prevent duplicates, CHECK constraints, loading in transactions, and a reconciliation query:
```sql
SELECT s.activity_date, s.active_users, r.real_cnt
FROM daily_active_users s
JOIN (SELECT activity_date, COUNT(DISTINCT user_id) real_cnt FROM user_activity GROUP BY 1) r USING (activity_date)
WHERE s.active_users <> r.real_cnt;     -- must return 0 rows
```
*Reasoning:* pre-aggregation trades storage and a small risk of drift for large read speedups; SCD2 is only needed when historical attributes matter. For billions of events consider partitioning `user_activity` by date and HyperLogLog (`hll` extension) for approximate distinct counts.

---

# PART E – SQL ASSIGNMENT PDF (10 LeetCode Problems)

> Table/column names are lowercase for PostgreSQL.

### E1. 🟡 Managers with at least five direct reports (LeetCode 570)
```sql
SELECT m.name
FROM employee m
JOIN employee e ON e.managerid = m.id
GROUP BY m.id, m.name
HAVING COUNT(*) >= 5;
```

### E2. 🟡 Nth highest salary (LeetCode 177)
```sql
CREATE OR REPLACE FUNCTION getNthHighestSalary(n INT) RETURNS INT AS $$
  SELECT (
    SELECT salary FROM (SELECT DISTINCT salary FROM employee) s
    ORDER BY salary DESC
    LIMIT 1 OFFSET GREATEST(n, 1) - 1)   -- GREATEST avoids a negative OFFSET error
  WHERE n >= 1;                           -- n < 1 => no row => NULL
$$ LANGUAGE sql;

SELECT getNthHighestSalary(2);
-- Alternative: SELECT salary FROM (SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) r FROM employee) t WHERE r = n LIMIT 1;
```

### E3. 🟡 Person with the most friends (LeetCode 602)
```sql
WITH all_friends AS (
  SELECT requester_id AS id FROM requestaccepted
  UNION ALL
  SELECT accepter_id FROM requestaccepted)
SELECT id, COUNT(*) AS num
FROM all_friends GROUP BY id ORDER BY num DESC LIMIT 1;
```

### E4. 🟡 Exchange seats (LeetCode 626)
```sql
SELECT CASE
         WHEN id % 2 = 1 AND id = (SELECT MAX(id) FROM seat) THEN id   -- last odd row stays
         WHEN id % 2 = 1 THEN id + 1
         ELSE id - 1 END AS id,
       student
FROM seat
ORDER BY id;                         -- sorts by the NEW id (output alias wins over column)
```
Alternative:
```sql
SELECT id, COALESCE(CASE WHEN id % 2 = 1 THEN LEAD(student) OVER (ORDER BY id)
                         ELSE LAG(student)  OVER (ORDER BY id) END, student) AS student
FROM seat ORDER BY id;
```

### E5. 🟡 Customers who bought all products (LeetCode 1045)
```sql
SELECT customer_id
FROM customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (SELECT COUNT(*) FROM product);
```

### E6. 🟡 Orders per user as buyer in 2019 (LeetCode 1158)
```sql
SELECT u.user_id AS buyer_id, u.join_date, COUNT(o.order_id) AS orders_in_2019
FROM users u
LEFT JOIN orders o
  ON o.buyer_id = u.user_id
 AND o.order_date >= '2019-01-01' AND o.order_date < '2020-01-01'   -- filter in ON, not WHERE!
GROUP BY u.user_id, u.join_date;
```
(Putting the date filter in `WHERE` would turn the LEFT JOIN into an INNER JOIN and drop users with 0 orders.)

### E7. 🟡 New users per day in the 90 days up to 2019-06-30 (LeetCode 1107)
```sql
SELECT login_date, COUNT(*) AS user_count
FROM (SELECT user_id, MIN(activity_date) AS login_date
      FROM traffic WHERE activity = 'login' GROUP BY user_id) t
WHERE login_date BETWEEN DATE '2019-06-30' - 90 AND DATE '2019-06-30'
GROUP BY login_date;
```

### E8. 🟡 Price of all products on 2019-08-16 (LeetCode 1164)
```sql
SELECT p.product_id, COALESCE(lp.new_price, 10) AS price
FROM (SELECT DISTINCT product_id FROM products) p
LEFT JOIN (
  SELECT DISTINCT ON (product_id) product_id, new_price
  FROM products
  WHERE change_date <= '2019-08-16'
  ORDER BY product_id, change_date DESC) lp USING (product_id);
```

### E9. 🔴 Monthly Transactions II (LeetCode 1205)
```sql
WITH approved AS (
  SELECT TO_CHAR(trans_date,'YYYY-MM') AS month, country,
         COUNT(*) AS approved_count, SUM(amount) AS approved_amount
  FROM transactions WHERE state = 'approved' GROUP BY 1, 2),
cb AS (
  SELECT TO_CHAR(c.trans_date,'YYYY-MM') AS month, t.country,
         COUNT(*) AS chargeback_count, SUM(t.amount) AS chargeback_amount
  FROM chargebacks c JOIN transactions t ON t.id = c.trans_id
  GROUP BY 1, 2)
SELECT COALESCE(a.month, cb.month)       AS month,
       COALESCE(a.country, cb.country)   AS country,
       COALESCE(a.approved_count, 0)     AS approved_count,
       COALESCE(a.approved_amount, 0)    AS approved_amount,
       COALESCE(cb.chargeback_count, 0)  AS chargeback_count,
       COALESCE(cb.chargeback_amount, 0) AS chargeback_amount
FROM approved a
FULL OUTER JOIN cb ON a.month = cb.month AND a.country = cb.country;
```
Chargeback month comes from the **chargeback's** `trans_date`, but the amount/country come from the **original** transaction (this is why 2019-09 shows 5000 for id 105). FULL JOIN is needed because a month can have chargebacks but no approvals, and vice versa.

### E10. 🟡 Tournament points (LeetCode 1212)
```sql
SELECT t.team_id, t.team_name, COALESCE(SUM(p.points), 0) AS num_points
FROM teams t
LEFT JOIN (
  SELECT host_team AS team_id,
         CASE WHEN host_goals > guest_goals THEN 3 WHEN host_goals = guest_goals THEN 1 ELSE 0 END AS points
  FROM matches
  UNION ALL
  SELECT guest_team,
         CASE WHEN guest_goals > host_goals THEN 3 WHEN guest_goals = host_goals THEN 1 ELSE 0 END
  FROM matches) p USING (team_id)
GROUP BY t.team_id, t.team_name
ORDER BY num_points DESC, t.team_id;
```

---

# PART F – BONUS LEETCODE CLASSICS (Mixed Topics)

**F1. 🟢 (LeetCode 608 – Tree Node)** Root / Inner / Leaf.
```sql
SELECT id,
  CASE WHEN p_id IS NULL THEN 'Root'
       WHEN id IN (SELECT p_id FROM tree WHERE p_id IS NOT NULL) THEN 'Inner'
       ELSE 'Leaf' END AS type
FROM tree;
```

**F2. 🟡 (LeetCode 1174 – Immediate Food Delivery II)** % of customers whose **first** order was immediate.
```sql
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE order_date = customer_pref_delivery_date) / COUNT(*), 2)
       AS immediate_percentage
FROM (SELECT DISTINCT ON (customer_id) * FROM delivery ORDER BY customer_id, order_date) t;
```

**F3. 🟡 (LeetCode 1141 – User Activity for the Past 30 Days I)** Active users per day for the 30 days ending 2019-07-27.
```sql
SELECT activity_date AS day, COUNT(DISTINCT user_id) AS active_users
FROM activity
WHERE activity_date > DATE '2019-07-27' - 30 AND activity_date <= '2019-07-27'
GROUP BY activity_date;
```

**F4. 🟡 (LeetCode 1398 – Bought A and B but not C)**
```sql
SELECT customer_id, customer_name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id AND product_name='A')
  AND EXISTS (SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id AND product_name='B')
  AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id AND product_name='C');
```

**F5. 🔴 Cohort retention** – % of users from each signup month who return in the following month.
```sql
WITH first_m AS (
  SELECT user_id, DATE_TRUNC('month', MIN(activity_date)) AS cohort FROM activity GROUP BY user_id),
act AS (SELECT DISTINCT user_id, DATE_TRUNC('month', activity_date) AS m FROM activity)
SELECT f.cohort::date,
       COUNT(DISTINCT f.user_id) AS cohort_size,
       ROUND(100.0 * COUNT(DISTINCT a.user_id) / COUNT(DISTINCT f.user_id), 1) AS retained_next_month_pct
FROM first_m f
LEFT JOIN act a ON a.user_id = f.user_id AND a.m = f.cohort + INTERVAL '1 month'
GROUP BY f.cohort ORDER BY f.cohort;
```

**F6. 🔴 Sessionization** – start a new session when the gap between events exceeds 30 minutes.
```sql
WITH flagged AS (
  SELECT user_id, event_time,
         CASE WHEN event_time - LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time)
                   > INTERVAL '30 minutes' THEN 1 ELSE 0 END AS new_session
  FROM events)
SELECT user_id, event_time,
       SUM(new_session) OVER (PARTITION BY user_id ORDER BY event_time) + 1 AS session_no
FROM flagged;
```

**F7. 🔴 Top-selling product per category per month, with ties (and zero-sales categories)**
```sql
WITH m AS (
  SELECT p.category, DATE_TRUNC('month', o.order_date)::date AS month, p.name, SUM(oi.quantity) AS qty
  FROM order_items oi JOIN orders o ON o.id = oi.order_id JOIN products p ON p.id = oi.product_id
  GROUP BY 1, 2, 3),
r AS (SELECT *, RANK() OVER (PARTITION BY category, month ORDER BY qty DESC) rk FROM m)
SELECT category, month, name, qty FROM r WHERE rk = 1;
```

---

# QUICK GOTCHA CHECKLIST

1. `NULL = NULL` is not true → use `IS NULL` / `IS NOT DISTINCT FROM`.
2. `NOT IN` + NULL in the subquery = empty result → prefer `NOT EXISTS`.
3. `COUNT(*)` counts rows, `COUNT(col)` skips NULLs, `COUNT(DISTINCT col)` de-duplicates.
4. Filter on the right table of a LEFT JOIN in `ON`, not `WHERE`.
5. `WHERE` filters rows before `GROUP BY`; `HAVING` filters groups after.
6. `RANK` leaves gaps after ties; `DENSE_RANK` doesn't; `ROW_NUMBER` never ties.
7. Default window frame with ORDER BY ends at the **current row** (`LAST_VALUE` surprise).
8. Don't wrap indexed columns in functions in WHERE (use ranges or expression indexes).
9. A composite index obeys the **left-prefix** rule.
10. A PK/UNIQUE on a partitioned table must include the partition key.
11. `COPY` aborts the whole load on the first bad row (unless `ON_ERROR` in PG17+).
12. `MERGE` is PG15+; for concurrency-safe upserts use `INSERT ... ON CONFLICT`.
13. Always `SELECT` with the same WHERE before `UPDATE`/`DELETE`, and wrap in a transaction.
14. Integer date math: `date + 1`, `date - date` (days); for timestamps use `INTERVAL`.
