# SQL Fundamentals – Final Practice Test 1 (17 Questions)

Dialect: **MySQL 8**. Every question has a **copy-paste-ready data block** right below it (run it as-is in MySQL Workbench / any SQL client). All solutions are at the end.

- Part A (Q1–7) builds on one set of bookstore tables. Do Q1 first, then run the Q2 data block.
- Part B (Q8–17) is independent: each question's block creates its own tables. Q16 reuses the Part A tables.
- Tip: run `DROP TABLE IF EXISTS ...` lines (included in each block) to re-run any question cleanly.

---

# PART A – DDL & DML

## Q1. Schema design with PK and FK
Design a schema for an online bookstore with three tables:
- `customers`: id, full name, unique email, city, created date
- `orders`: id, customer, order date, status (only 'NEW', 'SHIPPED' or 'CANCELLED')
- `order_items`: id, order, book title, quantity (> 0), unit price (>= 0)

Use primary keys, foreign keys, and constraints where suitable.

*(No data needed. Your tables are used in Q2–Q7 and Q16.)*

## Q2. Inserting records
Insert the following rows into the tables from Q1 (6 order items, 4 orders, 3 customers).

```sql
INSERT INTO customers (customer_id, full_name, email, city, created_on) VALUES
(1, 'Asha Rao',    'asha@mail.com',   'Bengaluru', '2025-01-10'),
(2, 'Vikram Shah', 'vikram@mail.com', 'Mumbai',    '2025-02-15'),
(3, 'Meena Iyer',  'meena@mail.com',  'Chennai',   '2025-03-05');

INSERT INTO orders (order_id, customer_id, order_date, status) VALUES
(1, 1, '2025-04-01', 'SHIPPED'),
(2, 1, '2025-04-20', 'NEW'),
(3, 2, '2025-04-22', 'SHIPPED'),
(4, 3, '2025-05-02', 'CANCELLED');

INSERT INTO order_items (item_id, order_id, book_title, quantity, unit_price) VALUES
(1, 1, 'Database Systems',   1, 650.00),
(2, 1, 'SQL in 10 Minutes',  2, 300.00),
(3, 2, 'Data Science 101',   1, 800.00),
(4, 3, 'Database Systems',   2, 650.00),
(5, 3, 'Python Basics',      1, 450.00),
(6, 4, 'SQL in 10 Minutes',  1, 300.00);
```

## Q3. Changing table structure
(a) Add a `loyalty_points` column (integer, default 0) to `customers`.
(b) Increase the size of `city` to 100 characters.
(c) Add a `discount_pct` column to `order_items`, allowed range 0 to 50.
(d) Remove the `created_on` column from `customers`.

*(Uses the Q2 tables.)*

## Q4. UPDATE with WHERE
(a) Add 100 loyalty points to every customer from Bengaluru.
(b) Change order 2 to 'SHIPPED', but only if its status is currently 'NEW'.

*(Uses the Q2 data. Do Q3(a) first so `loyalty_points` exists.)*

## Q5. DELETE with WHERE
Remove all cancelled orders together with their items. Respect the foreign key order.

*(Uses the Q2 data.)*

## Q6. Filtering and sorting
List the 3 most expensive line items (book title, quantity, unit price) where unit price is at least 300. Break ties by title A to Z.

*(Uses the Q2 data.)*
Expected: Data Science 101 (800), Database Systems (650), Database Systems (650).

## Q7. INNER JOIN with aggregation + written answer
(a) For each customer who has placed orders, show name, number of orders and total spend (quantity × unit price), highest spend first.
(b) Explain the difference between PRIMARY KEY, FOREIGN KEY and UNIQUE.

*(Uses the Q2 data.)*
Expected for (a) with the original Q2 data: Asha (2 orders, 2050), Vikram (1 order, 1750), Meena (1 order, 300).

---

# PART B – COMPLEX SELECT

## Q8. Self-join in a hierarchy
Find categories that have **at least 4 direct subcategories**.

```sql
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (category_id INT PRIMARY KEY, name VARCHAR(50), parent_id INT NULL);
INSERT INTO categories VALUES
(1,'Electronics',NULL),
(2,'Mobiles',1),
(3,'Laptops',1),
(4,'Cameras',1),
(5,'Audio',1),
(6,'Books',NULL),
(7,'Fiction',6),
(8,'Science',6),
(9,'Gaming Laptops',3);
```
Expected: Electronics (4).

## Q9. Nth-ranked value
Return the **3rd highest distinct price**. If it does not exist, return NULL.

```sql
DROP TABLE IF EXISTS products;
CREATE TABLE products (product_id INT PRIMARY KEY, name VARCHAR(50), price INT);
INSERT INTO products VALUES
(1,'A',500),
(2,'B',900),
(3,'C',900),
(4,'D',700),
(5,'E',300);
```
Expected: 500.

## Q10. Two-way relationship
Each collaboration is stored **once** (if A worked with B, then B also worked with A). Find the person with the **most collaborators**.

```sql
DROP TABLE IF EXISTS collaborations;
CREATE TABLE collaborations (person_a INT, person_b INT);
INSERT INTO collaborations VALUES
(1,2),
(1,3),
(2,3),
(4,1),
(5,1),
(6,2);
```
Expected: person 1 with 4 collaborators.

## Q11. Conditional row changes with window functions
Swap the label of every two consecutive bins (1↔2, 3↔4, ...). If the number of bins is odd, the last bin keeps its label.

```sql
DROP TABLE IF EXISTS bins;
CREATE TABLE bins (bin_id INT PRIMARY KEY, label VARCHAR(10));
INSERT INTO bins VALUES
(1,'Red'),
(2,'Blue'),
(3,'Green'),
(4,'Black'),
(5,'White');
```
Expected: 1 Blue, 2 Red, 3 Black, 4 Green, 5 White.

## Q12. Relational division
Find members who attended **every** workshop. Note: member 3 has a duplicate attendance row.

```sql
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS workshops;
CREATE TABLE members   (member_id INT PRIMARY KEY, name VARCHAR(40));
CREATE TABLE workshops (workshop_id INT PRIMARY KEY, title VARCHAR(40));
CREATE TABLE attendance (member_id INT, workshop_id INT);

INSERT INTO members   VALUES (1,'Ravi'),(2,'Sana'),(3,'Tom');
INSERT INTO workshops VALUES (10,'SQL'),(20,'Python'),(30,'Excel');
INSERT INTO attendance VALUES
(1,10),(1,20),(1,30),
(2,10),(2,20),
(3,10),(3,10),(3,20),(3,30);
```
Expected: Ravi, Tom.

## Q13. Keep all rows, including those with no match
Show every subscriber with the number of renewals, including 0.

```sql
DROP TABLE IF EXISTS renewals;
DROP TABLE IF EXISTS subscribers;
CREATE TABLE subscribers (sub_id INT PRIMARY KEY, name VARCHAR(40));
CREATE TABLE renewals (renewal_id INT PRIMARY KEY, sub_id INT, renewed_on DATE);

INSERT INTO subscribers VALUES (1,'Anu'),(2,'Bala'),(3,'Chitra');
INSERT INTO renewals VALUES
(1,1,'2025-01-01'),
(2,1,'2025-07-01'),
(3,3,'2025-03-01');
```
Expected: Anu 2, Bala 0, Chitra 1.

## Q14. First occurrence + date range
Find users whose **first-ever purchase** was in **March 2025**, and show that date.

```sql
DROP TABLE IF EXISTS purchases;
CREATE TABLE purchases (purchase_id INT PRIMARY KEY, user_id INT, purchase_date DATE, amount INT);
INSERT INTO purchases VALUES
(1,1,'2025-03-05',100),
(2,1,'2025-04-02',200),
(3,2,'2025-02-20',150),
(4,2,'2025-03-10',90),
(5,3,'2025-03-28',60);
```
Expected: user 1 (2025-03-05) and user 3 (2025-03-28).

## Q15. Value as of a given date
Show each employee's salary **as on 2025-06-30**. Skip employees with no salary on that date.

```sql
DROP TABLE IF EXISTS salary_history;
CREATE TABLE salary_history (emp_id INT, effective_date DATE, salary INT);
INSERT INTO salary_history VALUES
(1,'2024-01-01',50000),
(1,'2025-04-01',58000),
(1,'2025-09-01',65000),
(2,'2025-07-15',40000),
(3,'2023-05-01',70000);
```
Expected: emp 1 → 58000, emp 3 → 70000.

## Q16. Views
Create a reusable view `v_customer_summary` showing customer name, city, number of orders and total spend. Customers with no orders must still appear (spend 0). Then query the view for customers who spent more than 1000.

*(Uses the Part A tables with the Q2 data. If you already ran Q5, re-run the Q2 data block on fresh tables first.)*
Expected with original data: Asha 2050, Vikram 1750.

## Q17. Reconciling two fact tables without losing unmatched rows
For every order that appears in **either** table, show total paid, total refunded and net amount (paid − refunded). MySQL has no FULL JOIN, so combine joins another way.

```sql
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS refunds;
CREATE TABLE payments (order_id INT, amount INT);
CREATE TABLE refunds  (order_id INT, amount INT);
INSERT INTO payments VALUES (1,500),(1,200),(2,300),(3,150);
INSERT INTO refunds  VALUES (1,100),(3,150),(4,80);
```
Expected: 1 → 700/100/600, 2 → 300/0/300, 3 → 150/150/0, 4 → 0/80/-80 (paid/refunded/net).

---
---

# SOLUTIONS

## Part A

### Q1
```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    city        VARCHAR(60),
    created_on  DATE NOT NULL DEFAULT (CURRENT_DATE)
);

CREATE TABLE orders (
    order_id    INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date  DATE NOT NULL,
    status      VARCHAR(10) NOT NULL DEFAULT 'NEW',
    CONSTRAINT chk_status CHECK (status IN ('NEW','SHIPPED','CANCELLED')),
    CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id    INT PRIMARY KEY AUTO_INCREMENT,
    order_id   INT NOT NULL,
    book_title VARCHAR(150) NOT NULL,
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    CONSTRAINT fk_item_ord FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
```

### Q2
Run the data block given under Q2.

### Q3
```sql
ALTER TABLE customers ADD COLUMN loyalty_points INT NOT NULL DEFAULT 0;
ALTER TABLE customers MODIFY COLUMN city VARCHAR(100);
ALTER TABLE order_items ADD COLUMN discount_pct DECIMAL(5,2) DEFAULT 0
    CHECK (discount_pct BETWEEN 0 AND 50);
ALTER TABLE customers DROP COLUMN created_on;
```

### Q4
```sql
UPDATE customers SET loyalty_points = loyalty_points + 100 WHERE city = 'Bengaluru';

UPDATE orders SET status = 'SHIPPED' WHERE order_id = 2 AND status = 'NEW';
```

### Q5
```sql
DELETE FROM order_items
WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'CANCELLED');

DELETE FROM orders WHERE status = 'CANCELLED';
```

### Q6
```sql
SELECT book_title, quantity, unit_price
FROM order_items
WHERE unit_price >= 300
ORDER BY unit_price DESC, book_title ASC
LIMIT 3;
```

### Q7
```sql
-- (a)
SELECT c.full_name,
       COUNT(DISTINCT o.order_id)       AS total_orders,
       SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c
INNER JOIN orders o       ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spend DESC;
```

**(b) Written answer**

| | Primary Key | Foreign Key | Unique |
|---|---|---|---|
| Purpose | Uniquely identifies each row | Links a row to a row in a parent table | Prevents duplicate values in a column |
| NULLs | Not allowed | Allowed | Allowed (MySQL permits multiple NULLs) |
| Per table | Only one | Many | Many |
| Duplicates | No | Yes (many children per parent) | No |
| Rule | Must be unique and not null | Value must exist in the referenced key or be NULL | Must be unique |

## Part B

### Q8
```sql
SELECT p.category_id, p.name, COUNT(c.category_id) AS direct_children
FROM categories p
JOIN categories c ON c.parent_id = p.category_id
GROUP BY p.category_id, p.name
HAVING COUNT(c.category_id) >= 4;
```

### Q9
```sql
-- Option 1: OFFSET (returns NULL when missing)
SELECT (SELECT DISTINCT price FROM products
        ORDER BY price DESC LIMIT 1 OFFSET 2) AS third_highest;

-- Option 2: DENSE_RANK
SELECT MAX(price) AS third_highest
FROM (SELECT price, DENSE_RANK() OVER (ORDER BY price DESC) AS rnk FROM products) t
WHERE rnk = 3;
```

### Q10
```sql
WITH both_ways AS (
    SELECT person_a AS person, person_b AS partner FROM collaborations
    UNION ALL
    SELECT person_b, person_a FROM collaborations
)
SELECT person, COUNT(DISTINCT partner) AS collaborators
FROM both_ways
GROUP BY person
ORDER BY collaborators DESC
LIMIT 1;
```
Use `RANK()` instead of `LIMIT 1` if ties must all be returned.

### Q11
```sql
SELECT bin_id,
       CASE
         WHEN bin_id % 2 = 1 THEN COALESCE(LEAD(label) OVER (ORDER BY bin_id), label)
         ELSE LAG(label) OVER (ORDER BY bin_id)
       END AS swapped_label
FROM bins
ORDER BY bin_id;
```

### Q12
```sql
SELECT m.member_id, m.name
FROM members m
JOIN attendance a ON a.member_id = m.member_id
GROUP BY m.member_id, m.name
HAVING COUNT(DISTINCT a.workshop_id) = (SELECT COUNT(*) FROM workshops);
```
`DISTINCT` handles Tom's duplicate row.

### Q13
```sql
SELECT s.sub_id, s.name, COUNT(r.renewal_id) AS renewal_count
FROM subscribers s
LEFT JOIN renewals r ON r.sub_id = s.sub_id
GROUP BY s.sub_id, s.name
ORDER BY s.sub_id;
```
Use `COUNT(r.renewal_id)`, not `COUNT(*)`, otherwise Bala shows 1.

### Q14
```sql
SELECT user_id, MIN(purchase_date) AS first_purchase
FROM purchases
GROUP BY user_id
HAVING MIN(purchase_date) >= '2025-03-01'
   AND MIN(purchase_date) <  '2025-04-01';
```

### Q15
```sql
SELECT emp_id, salary AS salary_on_date
FROM (
    SELECT emp_id, salary,
           ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY effective_date DESC) AS rn
    FROM salary_history
    WHERE effective_date <= '2025-06-30'
) t
WHERE rn = 1;
```

### Q16
```sql
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT c.customer_id, c.full_name, c.city,
       COUNT(DISTINCT o.order_id)                    AS total_orders,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spend
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.full_name, c.city;

SELECT * FROM v_customer_summary
WHERE total_spend > 1000
ORDER BY total_spend DESC;
```

### Q17
```sql
WITH p AS (SELECT order_id, SUM(amount) AS paid     FROM payments GROUP BY order_id),
     r AS (SELECT order_id, SUM(amount) AS refunded FROM refunds  GROUP BY order_id)
SELECT p.order_id, p.paid, COALESCE(r.refunded,0) AS refunded,
       p.paid - COALESCE(r.refunded,0) AS net
FROM p LEFT JOIN r ON r.order_id = p.order_id
UNION
SELECT r.order_id, COALESCE(p.paid,0), r.refunded,
       COALESCE(p.paid,0) - r.refunded
FROM r LEFT JOIN p ON p.order_id = r.order_id
ORDER BY order_id;
```
PostgreSQL / SQL Server: use `FROM p FULL OUTER JOIN r ON p.order_id = r.order_id` with `COALESCE` on `order_id`, `paid` and `refunded`.
