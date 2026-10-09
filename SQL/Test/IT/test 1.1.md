# SQL Fundamentals — Test 1

**Database:** PostgreSQL  
**Total Questions:** 17  
**Part A:** DDL & DML (Q1–Q7)  
**Part B:** Complex SELECT (Q8–Q17)

**Instructions:** Attempt all questions before checking the solutions. Sample data is provided as executable SQL code.

---

# Part A — DDL & DML

### Q1. Schema Design — Primary Key and Foreign Key

A training institute wants to maintain information about students, courses, and course registrations.

Create the following tables:

- `students`
- `courses`
- `registrations`

Requirements:

1. Each student must have a unique `student_id`.
2. Each course must have a unique `course_id`.
3. Each registration must have a unique `registration_id`.
4. A student's email cannot be duplicated.
5. A registration must refer to an existing student.
6. A registration must refer to an existing course.
7. Course fees cannot be negative.
8. Registration date should automatically use the current date when not supplied.

Write the complete DDL.

---

### Q2. Insert Records

Using the tables from Q1, insert this sample data:

```sql
INSERT INTO students (student_id, student_name, email)
VALUES
(101, 'Arun', 'arun@example.com'),
(102, 'Meera', 'meera@example.com'),
(103, 'Kiran', 'kiran@example.com'),
(104, 'Divya', 'divya@example.com');

INSERT INTO courses (course_id, course_name, fee)
VALUES
(201, 'PostgreSQL', 4500),
(202, 'Python', 5500),
(203, 'Data Engineering', 7000),
(204, 'Git', 3000);

INSERT INTO registrations
(registration_id, student_id, course_id, registration_date)
VALUES
(1, 101, 201, '2026-01-10'),
(2, 101, 202, '2026-01-15'),
(3, 102, 203, '2026-02-01'),
(4, 103, 201, '2026-02-05'),
(5, 104, 204, '2026-02-10');
```

Write the INSERT statements and verify the records.

---

### Q3. ALTER TABLE

The institute now wants additional information.

Modify the existing tables:

1. Add `phone` to `students`.
2. Add `duration_days` to `courses`.
3. Rename `fee` to `course_fee`.
4. Make `phone` unique.

Write the required `ALTER TABLE` statements.

---

### Q4. UPDATE with WHERE

The institute wants to increase the course fee by **15%** for courses whose current fee is greater than `4000`.

Update only those courses.

Write the `UPDATE` query using an appropriate `WHERE` condition.

---

### Q5. DELETE with WHERE

The institute wants to remove registrations made before:

```text
2026-02-01
```

Delete only those registrations.

Write the `DELETE` query.

---

### Q6. Filtering, Sorting and LIMIT

The institute wants to find expensive courses.

Return:

- course name
- course fee
- duration

Conditions:

- Course fee must be greater than `4000`.
- Highest fee should appear first.
- Only the top 2 courses should be returned.

Write the query using:

```text
WHERE
ORDER BY
LIMIT
```

---

### Q7. INNER JOIN with Aggregation

The institute wants a report showing how much each student has registered for.

Return:

- student name
- number of courses registered
- total course fees

Only students who have at least one registration should appear.

Use:

- `INNER JOIN`
- `COUNT`
- `SUM`
- `GROUP BY`

Also answer:

1. What is a PRIMARY KEY?
2. What is a FOREIGN KEY?
3. What is a UNIQUE constraint?
4. Can a table contain multiple UNIQUE constraints?
5. Can multiple rows contain the same FOREIGN KEY value?

---

# Part B — Complex SELECT

### Q8. Self-Join — Managers with Multiple Direct Reports

A company stores employees in a hierarchy. Each employee may have a manager.

Use this sample data:

```sql
CREATE TABLE company_employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50),
    manager_id INT
);

INSERT INTO company_employees
(employee_id, employee_name, manager_id)
VALUES
(1, 'Ramesh', NULL),
(2, 'Anita', 1),
(3, 'Bharat', 1),
(4, 'Charan', 1),
(5, 'Deepa', 1),
(6, 'Esha', 2),
(7, 'Farhan', 2),
(8, 'Gokul', 3),
(9, 'Hema', 3),
(10, 'Irfan', 4);
```

**Task:**

Find managers who have **at least 3 direct reports**.

Return:

- manager name
- number of direct reports

You must use a **self-join**.

---

### Q9. Third Highest Distinct Value

An electronics store maintains product prices.

```sql
CREATE TABLE electronics (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price NUMERIC(10,2)
);

INSERT INTO electronics
(product_id, product_name, price)
VALUES
(1, 'Keyboard', 1500),
(2, 'Mouse', 900),
(3, 'Monitor', 22000),
(4, 'Webcam', 5000),
(5, 'Headset', 5000),
(6, 'Speaker', 3000),
(7, 'USB Hub', 1500),
(8, 'Microphone', 8000),
(9, 'Laptop Stand', 3000);
```

**Task:**

Find the **3rd highest distinct price**.

Important:

- Duplicate prices must count only once.
- Do not simply use `LIMIT 1 OFFSET 2` on the original table.

Expected answer:

```text
5000
```

---

### Q10. Two-Way Relationship — Most Collaborators

A software company records developers who worked together.

```sql
CREATE TABLE developer_collaboration (
    developer_a INT,
    developer_b INT
);

INSERT INTO developer_collaboration
(developer_a, developer_b)
VALUES
(1, 2),
(1, 3),
(2, 3),
(1, 4),
(3, 4),
(3, 5),
(4, 5),
(3, 6),
(3, 6),
(2, 1);
```

**Task:**

Find the developer or developers who collaborated with the **largest number of distinct developers**.

Important:

- `(1,2)` and `(2,1)` represent the same collaboration.
- Duplicate rows must not be counted twice.
- A developer should not be counted as their own collaborator.

Return:

- developer ID
- number of distinct collaborators

---

### Q11. Window Function — Swap Adjacent Rows

A warehouse stores labels according to bin positions.

```sql
CREATE TABLE warehouse_bins (
    bin_id INT PRIMARY KEY,
    position_no INT,
    label VARCHAR(20)
);

INSERT INTO warehouse_bins
(bin_id, position_no, label)
VALUES
(1, 1, 'A'),
(2, 2, 'B'),
(3, 3, 'C'),
(4, 4, 'D'),
(5, 5, 'E'),
(6, 6, 'F');
```

The warehouse wants to swap every adjacent pair:

```text
1 ↔ 2
3 ↔ 4
5 ↔ 6
```

Expected result:

```text
position 1 -> B
position 2 -> A
position 3 -> D
position 4 -> C
position 5 -> F
position 6 -> E
```

**Task:**

Write a query using window functions such as:

```text
LAG()
LEAD()
```

Do not manually write separate values for A, B, C, etc.

---

### Q12. Relational Division — Members Who Attended Every Workshop

A company conducts several workshops.

```sql
CREATE TABLE workshops (
    workshop_id INT PRIMARY KEY,
    workshop_name VARCHAR(50)
);

INSERT INTO workshops
(workshop_id, workshop_name)
VALUES
(1, 'SQL'),
(2, 'Python'),
(3, 'Git'),
(4, 'Linux');

CREATE TABLE workshop_attendance (
    member_id INT,
    workshop_id INT
);

INSERT INTO workshop_attendance
(member_id, workshop_id)
VALUES
(101, 1),
(101, 2),
(101, 3),
(101, 4),

(102, 1),
(102, 2),

(103, 1),
(103, 2),
(103, 3),
(103, 4),

(104, 1),
(104, 3),
(104, 4);
```

**Task:**

Find members who attended **every workshop**.

Expected members:

```text
101
103
```

Use relational-division logic.

---

### Q13. LEFT JOIN — Include Rows with Zero Matches

A subscription company stores customers and their subscription renewals.

```sql
CREATE TABLE subscribers (
    subscriber_id INT PRIMARY KEY,
    subscriber_name VARCHAR(50)
);

INSERT INTO subscribers
(subscriber_id, subscriber_name)
VALUES
(1, 'Anu'),
(2, 'Bala'),
(3, 'Charan'),
(4, 'Divya'),
(5, 'Eshan');

CREATE TABLE subscription_renewals (
    renewal_id INT PRIMARY KEY,
    subscriber_id INT,
    renewal_date DATE
);

INSERT INTO subscription_renewals
(renewal_id, subscriber_id, renewal_date)
VALUES
(101, 1, '2026-01-10'),
(102, 1, '2026-04-10'),
(103, 2, '2026-03-15'),
(104, 4, '2026-05-20');
```

**Task:**

Return every subscriber and their number of renewals.

Expected behavior:

```text
Anu    -> 2
Bala   -> 1
Charan -> 0
Divya  -> 1
Eshan  -> 0
```

Subscribers with no renewals **must not disappear**.

---

### Q14. First Occurrence Within a Date Range

A website stores customer login history.

```sql
CREATE TABLE customer_logins (
    login_id INT PRIMARY KEY,
    customer_id INT,
    login_time TIMESTAMP
);

INSERT INTO customer_logins
(login_id, customer_id, login_time)
VALUES
(1, 101, '2026-01-05 09:10:00'),
(2, 101, '2026-02-10 10:00:00'),
(3, 102, '2026-02-15 11:00:00'),
(4, 103, '2026-01-20 08:30:00'),
(5, 103, '2026-03-01 12:00:00'),
(6, 104, '2026-02-20 14:00:00'),
(7, 105, '2026-03-05 15:00:00');
```

**Task:**

Find customers whose **first-ever login** happened during February 2026.

Return:

- customer ID
- first login time

Important:

A customer may have multiple logins. You must determine their first login **before** applying the date filter.

---

### Q15. Find Value as of a Given Date

A company stores salary history.

```sql
CREATE TABLE employee_salary_history (
    employee_id INT,
    salary NUMERIC(10,2),
    effective_from DATE
);

INSERT INTO employee_salary_history
(employee_id, salary, effective_from)
VALUES
(101, 40000, '2025-01-01'),
(101, 45000, '2025-07-01'),
(101, 50000, '2026-01-01'),

(102, 42000, '2025-03-01'),
(102, 47000, '2025-09-01'),

(103, 55000, '2025-06-01'),
(103, 60000, '2026-03-01');
```

**Task:**

Find every employee's salary **as of `2026-02-15`**.

Rules:

- Ignore changes after `2026-02-15`.
- Choose the latest salary change on or before that date.
- Return:
  - employee ID
  - salary
  - effective date

---

### Q16. Create and Query a VIEW

An online store wants a reusable report containing product sales.

```sql
CREATE TABLE shop_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price NUMERIC(10,2)
);

INSERT INTO shop_products
(product_id, product_name, price)
VALUES
(1, 'Laptop Stand', 3000),
(2, 'Desk Lamp', 1800),
(3, 'Keyboard', 2500);

CREATE TABLE shop_sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT
);

INSERT INTO shop_sales
(sale_id, product_id, quantity)
VALUES
(1, 1, 4),
(2, 1, 2),
(3, 2, 5),
(4, 3, 3);
```

**Task:**

Create a view named:

```text
product_sales_summary
```

The view should contain:

- product ID
- product name
- total quantity sold
- total revenue

Then query the view to show only products where total revenue is greater than `10000`.

---

### Q17. Reconcile Payments and Refunds

A payment system contains payments and refunds.

```sql
CREATE TABLE customer_payments (
    payment_id INT PRIMARY KEY,
    customer_id INT,
    amount NUMERIC(10,2)
);

INSERT INTO customer_payments
(payment_id, customer_id, amount)
VALUES
(1, 101, 1000),
(2, 102, 1500),
(3, 103, 2000),
(4, 104, 800);

CREATE TABLE customer_refunds (
    refund_id INT PRIMARY KEY,
    payment_id INT,
    refund_amount NUMERIC(10,2)
);

INSERT INTO customer_refunds
(refund_id, payment_id, refund_amount)
VALUES
(11, 1, 200),
(12, 1, 100),
(13, 3, 500),
(14, 5, 300);
```

**Task:**

Create a reconciliation report containing:

- `payment_id`
- `customer_id`
- original payment amount
- total refunded amount
- remaining amount

Requirements:

1. Every payment must appear.
2. A payment without a refund should show refund amount as `0`.
3. Multiple refunds for the same payment must be combined.
4. Refund `payment_id = 5` has no matching payment and must not create a payment row.
5. Do not duplicate payment rows because of multiple refunds.

---

# Solutions

### Solution 1 — Schema Design

```sql
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    fee NUMERIC(10,2) CHECK (fee >= 0)
);

CREATE TABLE registrations (
    registration_id INT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    registration_date DATE DEFAULT CURRENT_DATE,

    FOREIGN KEY (student_id)
        REFERENCES students(student_id),

    FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
);
```

### Solution 2 — Insert Records

```sql
INSERT INTO students
(student_id, student_name, email)
VALUES
(101, 'Arun', 'arun@example.com'),
(102, 'Meera', 'meera@example.com'),
(103, 'Kiran', 'kiran@example.com'),
(104, 'Divya', 'divya@example.com');

INSERT INTO courses
(course_id, course_name, fee)
VALUES
(201, 'PostgreSQL', 4500),
(202, 'Python', 5500),
(203, 'Data Engineering', 7000),
(204, 'Git', 3000);

INSERT INTO registrations
(registration_id, student_id, course_id, registration_date)
VALUES
(1, 101, 201, '2026-01-10'),
(2, 101, 202, '2026-01-15'),
(3, 102, 203, '2026-02-01'),
(4, 103, 201, '2026-02-05'),
(5, 104, 204, '2026-02-10');
```

### Solution 3 — ALTER TABLE

```sql
ALTER TABLE students
ADD COLUMN phone VARCHAR(20);

ALTER TABLE courses
ADD COLUMN duration_days INT;

ALTER TABLE courses
RENAME COLUMN fee TO course_fee;

ALTER TABLE students
ADD CONSTRAINT uq_students_phone UNIQUE (phone);
```

### Solution 4 — UPDATE

```sql
UPDATE courses
SET course_fee = course_fee * 1.15
WHERE course_fee > 4000;
```

### Solution 5 — DELETE

```sql
DELETE FROM registrations
WHERE registration_date < '2026-02-01';
```

### Solution 6 — WHERE + ORDER BY + LIMIT

```sql
SELECT
    course_name,
    course_fee,
    duration_days
FROM courses
WHERE course_fee > 4000
ORDER BY course_fee DESC
LIMIT 2;
```

### Solution 7 — INNER JOIN + Aggregation

```sql
SELECT
    s.student_name,
    COUNT(r.course_id) AS course_count,
    SUM(c.course_fee) AS total_fees
FROM students s
INNER JOIN registrations r
    ON s.student_id = r.student_id
INNER JOIN courses c
    ON r.course_id = c.course_id
GROUP BY
    s.student_id,
    s.student_name;
```

**Theory:**

- **PRIMARY KEY:** uniquely identifies each row and cannot contain `NULL`.
- **FOREIGN KEY:** references a key in another table and maintains referential integrity.
- **UNIQUE:** prevents duplicate values.
- A table can contain multiple UNIQUE constraints.
- A FOREIGN KEY can contain duplicate values.

---

### Solution 8 — Self-Join

```sql
SELECT
    m.employee_name AS manager_name,
    COUNT(e.employee_id) AS direct_reports
FROM company_employees m
INNER JOIN company_employees e
    ON e.manager_id = m.employee_id
GROUP BY
    m.employee_id,
    m.employee_name
HAVING COUNT(e.employee_id) >= 3;
```

---

### Solution 9 — Third Highest Distinct Price

```sql
SELECT price
FROM (
    SELECT
        price,
        DENSE_RANK() OVER (
            ORDER BY price DESC
        ) AS price_rank
    FROM electronics
) x
WHERE price_rank = 3;
```

---

### Solution 10 — Most Collaborators

```sql
WITH unique_pairs AS (
    SELECT
        LEAST(developer_a, developer_b) AS developer_1,
        GREATEST(developer_a, developer_b) AS developer_2
    FROM developer_collaboration
    WHERE developer_a <> developer_b
    GROUP BY
        LEAST(developer_a, developer_b),
        GREATEST(developer_a, developer_b)
),
connections AS (
    SELECT
        developer_1 AS developer,
        developer_2 AS collaborator
    FROM unique_pairs

    UNION ALL

    SELECT
        developer_2 AS developer,
        developer_1 AS collaborator
    FROM unique_pairs
),
collaborator_counts AS (
    SELECT
        developer,
        COUNT(DISTINCT collaborator) AS collaborator_count
    FROM connections
    GROUP BY developer
)
SELECT
    developer,
    collaborator_count
FROM collaborator_counts
WHERE collaborator_count = (
    SELECT MAX(collaborator_count)
    FROM collaborator_counts
);
```

---

### Solution 11 — Swap Adjacent Labels

```sql
SELECT
    position_no,
    CASE
        WHEN position_no % 2 = 1
            THEN LEAD(label) OVER (
                ORDER BY position_no
            )
        ELSE LAG(label) OVER (
            ORDER BY position_no
        )
    END AS new_label
FROM warehouse_bins
ORDER BY position_no;
```

---

### Solution 12 — Relational Division

```sql
SELECT
    member_id
FROM workshop_attendance
GROUP BY member_id
HAVING COUNT(DISTINCT workshop_id) = (
    SELECT COUNT(*)
    FROM workshops
);
```

---

### Solution 13 — LEFT JOIN with Zero

```sql
SELECT
    s.subscriber_id,
    s.subscriber_name,
    COUNT(r.renewal_id) AS renewal_count
FROM subscribers s
LEFT JOIN subscription_renewals r
    ON s.subscriber_id = r.subscriber_id
GROUP BY
    s.subscriber_id,
    s.subscriber_name
ORDER BY s.subscriber_id;
```

Important:

```sql
COUNT(r.renewal_id)
```

is preferable to:

```sql
COUNT(*)
```

because the LEFT JOIN creates a row for subscribers with no renewal, and `COUNT(*)` would count that row.

---

### Solution 14 — First Login in February

```sql
SELECT
    customer_id,
    MIN(login_time) AS first_login_time
FROM customer_logins
GROUP BY customer_id
HAVING MIN(login_time) >= '2026-02-01'
   AND MIN(login_time) < '2026-03-01'
ORDER BY customer_id;
```

The first login must be calculated before applying the February filter.

---

### Solution 15 — Salary as of Date

```sql
SELECT
    employee_id,
    salary,
    effective_from
FROM (
    SELECT
        employee_id,
        salary,
        effective_from,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY effective_from DESC
        ) AS rn
    FROM employee_salary_history
    WHERE effective_from <= '2026-02-15'
) x
WHERE rn = 1
ORDER BY employee_id;
```

---

### Solution 16 — VIEW

```sql
CREATE VIEW product_sales_summary AS
SELECT
    p.product_id,
    p.product_name,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * p.price) AS total_revenue
FROM shop_products p
INNER JOIN shop_sales s
    ON p.product_id = s.product_id
GROUP BY
    p.product_id,
    p.product_name;
```

Query the view:

```sql
SELECT
    product_id,
    product_name,
    total_quantity,
    total_revenue
FROM product_sales_summary
WHERE total_revenue > 10000;
```

---

### Solution 17 — Payments and Refunds Reconciliation

```sql
WITH refund_totals AS (
    SELECT
        payment_id,
        SUM(refund_amount) AS total_refunded
    FROM customer_refunds
    GROUP BY payment_id
)
SELECT
    p.payment_id,
    p.customer_id,
    p.amount AS original_amount,
    COALESCE(r.total_refunded, 0) AS total_refunded,
    p.amount - COALESCE(r.total_refunded, 0) AS remaining_amount
FROM customer_payments p
LEFT JOIN refund_totals r
    ON p.payment_id = r.payment_id
ORDER BY p.payment_id;
```

The important pattern is:

```sql
WITH refund_totals AS (
    SELECT
        payment_id,
        SUM(refund_amount) AS total_refunded
    FROM customer_refunds
    GROUP BY payment_id
)
```

Aggregate the many-side table **before** joining it to the payment table. This prevents multiple refunds from duplicating the payment row.
