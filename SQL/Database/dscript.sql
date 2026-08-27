-- ============================================================================
-- SQL MASTERY ASSIGNMENT — SCHEMA + SAMPLE DATA
-- Target: PostgreSQL (tested on PostgreSQL 16)
-- Notes:
--   * Tables are created in FK-safe order (parents before children).
--   * orders/order_items/payments only include the rows explicitly given in
--     the reference doc (the doc says "40+ rows total" but only ~34 were
--     shown) — add more rows following the same pattern if your assignment
--     needs the full volume.
--   * attendance/employee_org_chart only include the explicitly given rows
--     (Sneha Iyer's 15 days; org chart mirrors the employees hierarchy).
--   * Run with: psql -U your_user -d your_db -f sql_mastery_schema_postgres.sql
-- ============================================================================
 

-- Drop in reverse dependency order (safe re-run)
-- DROP TABLE IF EXISTS product_prices_history CASCADE;
-- DROP TABLE IF EXISTS attendance CASCADE;
-- DROP TABLE IF EXISTS employee_org_chart CASCADE;
-- DROP TABLE IF EXISTS employee_projects CASCADE;
-- DROP TABLE IF EXISTS projects CASCADE;
-- DROP TABLE IF EXISTS payments CASCADE;
-- DROP TABLE IF EXISTS order_items CASCADE;
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS products CASCADE;
-- DROP TABLE IF EXISTS customers CASCADE;
-- DROP TABLE IF EXISTS employees CASCADE;
-- DROP TABLE IF EXISTS departments CASCADE;
 


SELECT current_schema();

SELECT tablename
FROM pg_tables
WHERE schemaname = 'sql_mastery_assignment'


-- ============================================================================
-- 1. departments  (created before employees since employees FKs to it)
-- ============================================================================
CREATE TABLE departments (
    department_id    INT PRIMARY KEY,
    department_name  VARCHAR(100) NOT NULL,
    location         VARCHAR(100),
    budget           NUMERIC(14,2)
);
 
INSERT INTO departments (department_id, department_name, location, budget) VALUES
(1, 'Engineering', 'Bengaluru', 5000000),
(2, 'Sales',       'Mumbai',    3000000),
(3, 'Finance',     'Mumbai',    1500000),
(4, 'Marketing',   'Delhi',     2000000),
(5, 'HR',          'Bengaluru', 800000);
-- Note: department_id 5 (HR) intentionally has zero employees (for OUTER JOIN practice).
 


-- ============================================================================
-- 2. employees  (self-referencing FK on manager_id)
-- ============================================================================
CREATE TABLE employees (
    employee_id      INT PRIMARY KEY,
    first_name       VARCHAR(50)  NOT NULL,
    last_name        VARCHAR(50)  NOT NULL,
    email            VARCHAR(150),
    department_id    INT,
    manager_id       INT,
    job_title        VARCHAR(100),
    salary           NUMERIC(12,2),
    hire_date        DATE,
    gender           VARCHAR(1)  CHECK (gender IN ('M','F')),
    city             VARCHAR(100),
    status           VARCHAR(20) CHECK (status IN ('ACTIVE','TERMINATED')),
    CONSTRAINT fk_emp_department FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_emp_manager    FOREIGN KEY (manager_id)    REFERENCES employees(employee_id)
);
 
INSERT INTO employees (employee_id, first_name, last_name, email, department_id, manager_id, job_title, salary, hire_date, gender, city, status) VALUES
(1,  'Arjun',  'Mehta',    'arjun.mehta@co.com',     1,    NULL, 'VP Engineering',      285000, '2015-01-12', 'M', 'Bengaluru', 'ACTIVE'),
(2,  'Priya',  'Nair',     'priya.nair@co.com',      1,    1,    'Engineering Manager', 190000, '2017-03-04', 'F', 'Bengaluru', 'ACTIVE'),
(3,  'Rohan',  'Gupta',    'rohan.gupta@co.com',     1,    2,    'Senior Engineer',     145000, '2018-06-15', 'M', 'Pune',      'ACTIVE'),
(4,  'Sneha',  'Iyer',     'sneha.iyer@co.com',      1,    2,    'Engineer',             98000, '2020-08-01', 'F', 'Bengaluru', 'ACTIVE'),
(5,  'Karan',  'Shah',     'karan.shah@co.com',      1,    2,    'Engineer',             95000, '2021-02-20', 'M', 'Hyderabad', 'ACTIVE'),
(6,  'Divya',  'Rao',      'divya.rao@co.com',       1,    3,    'Junior Engineer',      62000, '2022-07-11', 'F', 'Bengaluru', 'ACTIVE'),
(7,  'Manish', 'Kulkarni', 'manish.kulkarni@co.com', 2,    NULL, 'VP Sales',            260000, '2014-11-01', 'M', 'Mumbai',    'ACTIVE'),
(8,  'Anita',  'Desai',    'anita.desai@co.com',     2,    7,    'Sales Manager',       170000, '2016-09-23', 'F', 'Mumbai',    'ACTIVE'),
(9,  'Vikram', 'Joshi',    'vikram.joshi@co.com',    2,    8,    'Sales Executive',      88000, '2019-04-17', 'M', 'Pune',      'ACTIVE'),
(10, 'Neha',   'Menon',    'neha.menon@co.com',      2,    8,    'Sales Executive',      91000, '2020-01-05', 'F', 'Chennai',   'TERMINATED'),
(11, 'Suresh', 'Reddy',    'suresh.reddy@co.com',    2,    8,    'Sales Executive',      84000, '2022-03-14', 'M', 'Hyderabad', 'ACTIVE'),
(12, 'Kavita', 'Bhatt',    'kavita.bhatt@co.com',    3,    NULL, 'VP Finance',          250000, '2013-05-19', 'F', 'Mumbai',    'ACTIVE'),
(13, 'Amit',   'Trivedi',  'amit.trivedi@co.com',    3,    12,   'Finance Manager',     165000, '2017-10-02', 'M', 'Bengaluru', 'ACTIVE'),
(14, 'Pooja',  'Chawla',   'pooja.chawla@co.com',    3,    13,   'Financial Analyst',    78000, '2021-09-09', 'F', 'Bengaluru', 'ACTIVE'),
(15, 'Rahul',  'Verma',    'rahul.verma@co.com',     4,    NULL, 'VP Marketing',        240000, '2016-02-08', 'M', 'Delhi',     'ACTIVE'),
(16, 'Meera',  'Pillai',   'meera.pillai@co.com',    4,    15,   'Marketing Manager',   155000, '2018-12-01', 'F', 'Delhi',     'ACTIVE'),
(17, 'Sanjay', 'Kapoor',   'sanjay.kapoor@co.com',   4,    16,   'Marketing Executive',  72000, '2023-01-16', 'M', 'Delhi',     'ACTIVE'),
(18, 'Ritu',   'Malhotra', 'ritu.malhotra@co.com',   NULL, NULL, 'Consultant',          120000, '2023-06-01', 'F', 'Remote',    'ACTIVE');
 


-- ============================================================================
-- 3. customers  (self-referencing FK on referred_by)
-- ============================================================================
CREATE TABLE customers (
    customer_id      INT PRIMARY KEY,
    customer_name    VARCHAR(150) NOT NULL,
    email            VARCHAR(150),
    signup_date      DATE,
    country          VARCHAR(100),
    customer_segment VARCHAR(20) CHECK (customer_segment IN ('Retail','Enterprise','SMB')),
    referred_by      INT,
    CONSTRAINT fk_cust_referrer FOREIGN KEY (referred_by) REFERENCES customers(customer_id)
);
 
INSERT INTO customers (customer_id, customer_name, email, signup_date, country, customer_segment, referred_by) VALUES
(101, 'Rajesh Kumar',    'rajesh.k@mail.com',   '2021-01-15', 'India',   'Retail',     NULL),
(102, 'Fatima Al-Sayed', 'fatima.a@mail.com',   '2021-02-20', 'UAE',     'Enterprise', NULL),
(103, 'John Smith',      'john.smith@mail.com', '2021-03-10', 'USA',     'SMB',        NULL),
(104, 'Wei Zhang',       'wei.zhang@mail.com',  '2021-04-05', 'China',   'Retail',     101),
(105, 'Ananya Sharma',   'ananya.s@mail.com',   '2021-05-18', 'India',   'Enterprise', NULL),
(106, 'Carlos Mendez',   'carlos.m@mail.com',   '2021-06-22', 'Mexico',  'SMB',        NULL),
(107, 'Lena Fischer',    'lena.f@mail.com',     '2021-07-30', 'Germany', 'Retail',     102),
(108, 'David Okafor',    'david.o@mail.com',    '2021-09-14', 'Nigeria', 'SMB',        NULL),
(109, 'Meiko Tanaka',    'meiko.t@mail.com',    '2022-01-11', 'Japan',   'Enterprise', NULL),
(110, 'Sara Ali',        'sara.ali@mail.com',   '2022-03-25', 'UAE',     'Retail',     102),
(111, 'Tom Becker',      'tom.becker@mail.com', '2022-05-02', 'USA',     'Retail',     NULL),
(112, 'Nia Williams',    'nia.w@mail.com',      '2022-08-19', 'USA',     'SMB',        103),
(113, 'Ravi Patel',      'ravi.p@mail.com',     '2023-01-09', 'India',   'Retail',     101),
(114, 'Elena Petrova',   'elena.p@mail.com',    '2023-04-16', 'Russia',  'Enterprise', NULL),
(115, 'Omar Hassan',     'omar.h@mail.com',     '2023-06-30', 'Egypt',   'SMB',        NULL);
 


-- ============================================================================
-- 4. products
-- ============================================================================
CREATE TABLE products (
    product_id      INT PRIMARY KEY,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(50),
    unit_cost       NUMERIC(12,2),
    list_price      NUMERIC(12,2),
    launch_date     DATE,
    is_active       BOOLEAN
);
 
INSERT INTO products (product_id, product_name, category, unit_cost, list_price, launch_date, is_active) VALUES
(201, 'ProMax Laptop 14"',      'Electronics', 800.00,  1200.00,  '2020-01-10', TRUE),
(202, 'Wireless Mouse Pro',     'Accessories', 400.00,  1250.00,  '2020-03-05', TRUE),
(203, 'UltraView Monitor 27"',  'Electronics', 6000.00, 8900.00,  '2019-11-20', TRUE),
(204, 'Mechanical Keyboard',    'Accessories', 550.00,  950.00,   '2021-02-14', TRUE),
(205, 'NoiseCancel Headset',    'Electronics', 1400.00, 2500.00,  '2021-07-01', TRUE),
(206, 'USB-C Hub 7-in-1',       'Accessories', 90.00,   200.00,   '2022-01-15', TRUE),
(207, 'Portable SSD 1TB',       'Storage',     3200.00, 4500.00,  '2022-05-20', TRUE),
(208, 'Webcam HD Pro',          'Electronics', 900.00,  1500.00,  '2018-08-01', FALSE),
(209, 'Ergo Office Chair',      'Furniture',   4000.00, 7200.00,  '2023-02-10', TRUE),
(210, 'Standing Desk',          'Furniture',   6500.00, 11000.00, '2023-03-18', TRUE);
 

-- ============================================================================
-- 5. orders
-- ============================================================================
CREATE TABLE orders (
    order_id        INT PRIMARY KEY,
    customer_id     INT NOT NULL,
    order_date      DATE,
    order_status    VARCHAR(20) CHECK (order_status IN ('COMPLETED','CANCELLED','PENDING','RETURNED')),
    total_amount    NUMERIC(12,2),
    ship_country    VARCHAR(100),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
 
INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount, ship_country) VALUES
(5001, 101, '2023-01-05', 'COMPLETED', 2400.00,  'India'),
(5002, 101, '2023-02-14', 'COMPLETED', 1250.00,  'India'),
(5003, 102, '2023-01-20', 'COMPLETED', 8900.00,  'UAE'),
(5004, 103, '2023-03-02', 'CANCELLED', 560.00,   'USA'),
(5005, 104, '2023-03-11', 'COMPLETED', 3100.00,  'China'),
(5006, 105, '2023-04-01', 'COMPLETED', 12500.00, 'India'),
(5007, 101, '2023-04-19', 'RETURNED',  900.00,   'India'),
(5008, 106, '2023-05-05', 'COMPLETED', 450.00,   'Mexico'),
(5009, 107, '2023-05-22', 'COMPLETED', 2200.00,  'Germany'),
(5010, 102, '2023-06-02', 'COMPLETED', 6700.00,  'UAE'),
(5011, 108, '2023-06-18', 'PENDING',   1800.00,  'Nigeria'),
(5012, 109, '2023-07-01', 'COMPLETED', 15200.00, 'Japan'),
(5013, 110, '2023-07-15', 'COMPLETED', 980.00,   'UAE'),
(5014, 101, '2023-08-02', 'COMPLETED', 3400.00,  'India'),
(5015, 111, '2023-08-20', 'COMPLETED', 2100.00,  'USA'),
(5016, 105, '2023-09-03', 'COMPLETED', 9800.00,  'India'),
(5017, 112, '2023-09-25', 'CANCELLED', 700.00,   'USA'),
(5018, 102, '2023-10-11', 'COMPLETED', 5400.00,  'UAE'),
(5019, 113, '2023-10-28', 'COMPLETED', 1600.00,  'India'),
(5020, 104, '2023-11-05', 'COMPLETED', 2900.00,  'China'),
(5021, 114, '2023-11-19', 'COMPLETED', 11000.00, 'Russia'),
(5022, 101, '2023-12-01', 'COMPLETED', 1750.00,  'India'),
(5023, 115, '2023-12-15', 'COMPLETED', 620.00,   'Egypt'),
(5024, 105, '2024-01-08', 'COMPLETED', 13400.00, 'India'),
(5025, 102, '2024-01-22', 'COMPLETED', 7100.00,  'UAE'),
(5026, 107, '2024-02-05', 'RETURNED',  1900.00,  'Germany'),
(5027, 109, '2024-02-19', 'COMPLETED', 16800.00, 'Japan'),
(5028, 101, '2024-03-04', 'COMPLETED', 2600.00,  'India'),
(5029, 110, '2024-03-18', 'COMPLETED', 1100.00,  'UAE'),
(5030, 103, '2024-04-01', 'COMPLETED', 890.00,   'USA'),
(5031, 114, '2024-04-15', 'COMPLETED', 9600.00,  'Russia'),
(5032, 105, '2024-05-02', 'COMPLETED', 10200.00, 'India'),
(5033, 108, '2024-05-20', 'COMPLETED', 2300.00,  'Nigeria'),
(5034, 101, '2024-06-03', 'COMPLETED', 3050.00,  'India');
-- Note: per assignment doc, assume full table has 40+ rows spanning 2021-01 to 2024-06;
-- customer_id 106 and 115 each have exactly one order; customer_id 112 has one CANCELLED
-- order and nothing since; some customer_id values referenced elsewhere may have NO rows
-- here at all (edge case for LEFT JOIN / NOT EXISTS practice).
 


-- ============================================================================
-- 6. order_items
-- ============================================================================
CREATE TABLE order_items (
    order_item_id   INT PRIMARY KEY,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT,
    unit_price      NUMERIC(12,2),
    discount_pct    NUMERIC(5,2),
    CONSTRAINT fk_oi_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);
 
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_pct) VALUES
(9001, 5001, 201, 2, 1200.00, 0.00),
(9002, 5002, 202, 1, 1250.00, 0.00),
(9003, 5003, 203, 1, 8900.00, 0.05),
(9004, 5005, 201, 1, 1200.00, 0.00),
(9005, 5005, 204, 2, 950.00,  0.00),
(9006, 5006, 205, 5, 2500.00, 0.10),
(9007, 5008, 206, 3, 150.00,  0.00),
(9008, 5009, 202, 1, 1250.00, 0.00),
(9009, 5009, 206, 5, 190.00,  0.00),
(9010, 5010, 203, 1, 8900.00, 0.25),
(9011, 5012, 205, 6, 2500.00, 0.00),
(9012, 5013, 206, 4, 245.00,  0.00),
(9013, 5014, 201, 2, 1200.00, 0.15),
(9014, 5015, 204, 2, 950.00,  0.00),
(9015, 5016, 205, 3, 2500.00, 0.20),
(9016, 5018, 203, 1, 8900.00, 0.15),
(9017, 5019, 206, 8, 200.00,  0.00),
(9018, 5021, 205, 4, 2500.00, 0.10),
(9019, 5024, 205, 5, 2500.00, 0.05),
(9020, 5027, 203, 2, 8900.00, 0.20);
-- Note: quantity * unit_price * (1 - discount_pct) is line-item revenue and may not
-- always tie exactly to orders.total_amount (intentional, for reconciliation questions).



 
-- ============================================================================
-- 7. payments
-- ============================================================================
CREATE TABLE payments (
    payment_id      INT PRIMARY KEY,
    order_id        INT NOT NULL,
    payment_date    DATE,
    payment_method  VARCHAR(20) CHECK (payment_method IN ('CARD','UPI','NETBANKING','WALLET')),
    amount_paid     NUMERIC(12,2),
    payment_status  VARCHAR(20) CHECK (payment_status IN ('SUCCESS','FAILED','REFUNDED')),
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
 
INSERT INTO payments (payment_id, order_id, payment_date, payment_method, amount_paid, payment_status) VALUES
(7001, 5001, '2023-01-05', 'CARD',       2400.00,  'SUCCESS'),
(7002, 5002, '2023-02-14', 'UPI',        1250.00,  'SUCCESS'),
(7003, 5003, '2023-01-21', 'CARD',       8900.00,  'SUCCESS'),
(7004, 5004, '2023-03-02', 'CARD',       560.00,   'FAILED'),
(7005, 5005, '2023-03-12', 'NETBANKING', 3100.00,  'SUCCESS'),
(7006, 5006, '2023-04-01', 'CARD',       12500.00, 'SUCCESS'),
(7007, 5007, '2023-04-19', 'UPI',        900.00,   'REFUNDED'),
(7008, 5008, '2023-05-05', 'WALLET',     450.00,   'SUCCESS'),
(7009, 5009, '2023-05-22', 'CARD',       2200.00,  'SUCCESS'),
(7010, 5010, '2023-06-03', 'CARD',       6700.00,  'SUCCESS'),
(7011, 5012, '2023-07-02', 'UPI',        15200.00, 'SUCCESS'),
(7012, 5013, '2023-07-15', 'CARD',       980.00,   'SUCCESS'),
(7013, 5014, '2023-08-02', 'CARD',       3400.00,  'SUCCESS'),
(7014, 5015, '2023-08-20', 'NETBANKING', 2100.00,  'SUCCESS'),
(7015, 5016, '2023-09-03', 'CARD',       9800.00,  'SUCCESS'),
(7016, 5018, '2023-10-11', 'CARD',       5400.00,  'SUCCESS'),
(7017, 5019, '2023-10-29', 'UPI',        1600.00,  'SUCCESS'),
(7018, 5020, '2023-11-06', 'CARD',       2900.00,  'SUCCESS'),
(7019, 5021, '2023-11-20', 'CARD',       11000.00, 'SUCCESS'),
(7020, 5026, '2024-02-06', 'UPI',        1900.00,  'REFUNDED');
-- Note: not every order_id has a matching payment (e.g. PENDING orders like 5011) —
-- intentional, for outer join / reconciliation questions.
 


-- ============================================================================
-- 8. projects
-- ============================================================================
CREATE TABLE projects (
    project_id      INT PRIMARY KEY,
    project_name    VARCHAR(150) NOT NULL,
    department_id   INT,
    start_date      DATE,
    end_date        DATE,
    budget          NUMERIC(14,2),
    status          VARCHAR(20) CHECK (status IN ('ACTIVE','COMPLETED','ON_HOLD')),
    CONSTRAINT fk_proj_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
 
INSERT INTO projects (project_id, project_name, department_id, start_date, end_date, budget, status) VALUES
(301, 'Platform Migration',    1, '2023-01-10', '2023-09-30', 1200000, 'COMPLETED'),
(302, 'Mobile App Revamp',     1, '2023-05-01', NULL,         900000,  'ACTIVE'),
(303, 'CRM Rollout',           2, '2023-02-15', '2023-08-01', 600000,  'COMPLETED'),
(304, 'Market Expansion APAC', 4, '2023-06-01', NULL,         450000,  'ACTIVE'),
(305, 'Cost Audit FY23',       3, '2023-01-01', '2023-04-30', 150000,  'COMPLETED'),
(306, 'Data Warehouse V2',     1, '2024-01-15', NULL,         1500000, 'ACTIVE'),
(307, 'Brand Refresh',         4, '2023-09-01', '2024-01-15', 300000,  'COMPLETED'),
(308, 'Sales Enablement Tool', 2, '2024-02-01', NULL,         350000,  'ON_HOLD');
 


-- ============================================================================
-- 9. employee_projects  (bridge table, many-to-many, composite key)
-- ============================================================================
CREATE TABLE employee_projects (
    employee_id     INT NOT NULL,
    project_id      INT NOT NULL,
    role            VARCHAR(20) CHECK (role IN ('Lead','Contributor','Reviewer')),
    hours_logged    INT,
    PRIMARY KEY (employee_id, project_id),
    CONSTRAINT fk_ep_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_ep_project  FOREIGN KEY (project_id)  REFERENCES projects(project_id)
);
 
INSERT INTO employee_projects (employee_id, project_id, role, hours_logged) VALUES
(2,  301, 'Lead',        420),
(3,  301, 'Contributor', 610),
(4,  301, 'Contributor', 580),
(3,  306, 'Lead',        210),
(5,  306, 'Contributor', 190),
(6,  302, 'Contributor', 340),
(2,  302, 'Reviewer',    60),
(8,  303, 'Lead',        380),
(9,  303, 'Contributor', 400),
(11, 308, 'Contributor', 90),
(16, 304, 'Lead',        300),
(17, 304, 'Contributor', 350),
(16, 307, 'Lead',        260),
(13, 305, 'Lead',        220),
(14, 305, 'Contributor', 240);
 


-- ============================================================================
-- 10. employee_org_chart  (standalone, simplified hierarchy for recursive CTEs)
-- ============================================================================
CREATE TABLE employee_org_chart (
    emp_id          INT PRIMARY KEY,
    emp_name        VARCHAR(100) NOT NULL,
    manager_id      INT,
    CONSTRAINT fk_org_manager FOREIGN KEY (manager_id) REFERENCES employee_org_chart(emp_id)
);
 
INSERT INTO employee_org_chart (emp_id, emp_name, manager_id) VALUES
(1,  'Arjun Mehta',     NULL),
(2,  'Priya Nair',      1),
(3,  'Rohan Gupta',     2),
(4,  'Sneha Iyer',      2),
(5,  'Karan Shah',      2),
(6,  'Divya Rao',       3),
(7,  'Manish Kulkarni', 1),
(8,  'Anita Desai',     7),
(9,  'Vikram Joshi',    8),
(10, 'Neha Menon',      8),
(11, 'Suresh Reddy',    8),
(12, 'Kavita Bhatt',    1),
(13, 'Amit Trivedi',    12),
(14, 'Pooja Chawla',    13);



 
-- ============================================================================
-- 11. attendance  (gaps-and-islands / streak questions)
-- ============================================================================
CREATE TABLE attendance (
    employee_id      INT NOT NULL,
    attendance_date  DATE NOT NULL,
    status           VARCHAR(20) CHECK (status IN ('PRESENT','ABSENT','WFH','LEAVE')),
    PRIMARY KEY (employee_id, attendance_date),
    CONSTRAINT fk_att_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);
 
INSERT INTO attendance (employee_id, attendance_date, status) VALUES
(4, '2024-06-01', 'PRESENT'),
(4, '2024-06-02', 'PRESENT'),
(4, '2024-06-03', 'PRESENT'),
(4, '2024-06-04', 'ABSENT'),
(4, '2024-06-05', 'ABSENT'),
(4, '2024-06-06', 'PRESENT'),
(4, '2024-06-07', 'PRESENT'),
(4, '2024-06-08', 'WFH'),
(4, '2024-06-09', 'WFH'),
(4, '2024-06-10', 'WFH'),
(4, '2024-06-11', 'PRESENT'),
(4, '2024-06-12', 'LEAVE'),
(4, '2024-06-13', 'LEAVE'),
(4, '2024-06-14', 'PRESENT'),
(4, '2024-06-15', 'PRESENT');
-- Note: assignment doc says to assume similar 15-20 day patterns exist for
-- employee_id 3, 5, 6, 9, 10 with their own gaps. Only employee_id 4's data
-- was explicitly given — add similar synthetic rows for the others if your
-- exercise needs multi-employee streak comparisons.
 


-- ============================================================================
-- 12. product_prices_history  (SCD-style / "value as of date" questions)
-- ============================================================================
CREATE TABLE product_prices_history (
    product_id      INT NOT NULL,
    price           NUMERIC(12,2),
    effective_from  DATE NOT NULL,
    effective_to    DATE,
    CONSTRAINT fk_pph_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);
 
INSERT INTO product_prices_history (product_id, price, effective_from, effective_to) VALUES
(201, 1100.00, '2020-01-10', '2022-06-30'),
(201, 1150.00, '2022-07-01', '2023-12-31'),
(201, 1200.00, '2024-01-01', NULL),
(203, 8200.00, '2019-11-20', '2022-12-31'),
(203, 8900.00, '2023-01-01', NULL),
(205, 2300.00, '2021-07-01', '2023-06-30'),
(205, 2500.00, '2023-07-01', NULL);
 


-- ============================================================================
-- END OF SCRIPT
-- ============================================================================

