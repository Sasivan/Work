"""Reset and seed the SQL predicted mock assessment databases.

WARNING: This script DROPS and recreates the databases listed below.
Use only with the disposable local MySQL container from docker/docker-compose.yml.

Run from the package root:
    python seed/seed_mysql.py
"""

from __future__ import annotations

import pymysql

DB_HOST = "localhost"
DB_PORT = 3308
DB_USER = "root"
DB_PASSWORD = "InternTest_2026!"

DATABASES = (
    "sql_mock_core",
    "sql_mock_select",
    "sql_mock_staging",
    "sql_mock_intermediate",
    "sql_mock_reporting",
)

SELECT_DDL_AND_SEED = r"""
CREATE TABLE q1_email_signups (
    signup_id INT PRIMARY KEY,
    email VARCHAR(150) NOT NULL,
    source_name VARCHAR(30) NOT NULL
);
INSERT INTO q1_email_signups (signup_id, email, source_name) VALUES
(1, 'asha@example.com', 'web'),
(2, ' BEN@example.com ', 'mobile'),
(3, 'ASHA@example.com ', 'import'),
(4, 'cara@example.com', 'web'),
(5, 'ben@example.com', 'import'),
(6, 'dev@example.com', 'mobile');

CREATE TABLE q2_categories (
    id INT PRIMARY KEY,
    name VARCHAR(60) NOT NULL,
    parent_id INT NULL
);
INSERT INTO q2_categories (id, name, parent_id) VALUES
(1, 'Electronics', NULL),
(2, 'Phones', 1),
(3, 'Laptops', 1),
(4, 'Cameras', 1),
(5, 'Audio', 1),
(6, 'Wearables', 1),
(7, 'Tablets', 1),
(8, 'Smartphones', 2),
(9, 'Accessories', 2),
(10, 'Home', NULL),
(11, 'Furniture', 10),
(12, 'Kitchen', 10);

CREATE TABLE q3_prices (
    product_id INT PRIMARY KEY,
    price DECIMAL(10,2) NOT NULL
);
INSERT INTO q3_prices (product_id, price) VALUES
(1, 900.00), (2, 900.00), (3, 750.00),
(4, 600.00), (5, 500.00), (6, 400.00);

CREATE TABLE q4_members (
    member_id INT PRIMARY KEY,
    member_name VARCHAR(60) NOT NULL
);
CREATE TABLE q4_workshops (
    workshop_id INT PRIMARY KEY,
    workshop_name VARCHAR(60) NOT NULL
);
CREATE TABLE q4_attendance (
    attendance_id INT PRIMARY KEY,
    member_id INT NOT NULL,
    workshop_id INT NOT NULL
);
INSERT INTO q4_members VALUES
(1, 'Asha'), (2, 'Ben'), (3, 'Cara'), (4, 'Dev');
INSERT INTO q4_workshops VALUES
(1, 'SQL Basics'), (2, 'Python Basics'), (3, 'Data Modelling');
INSERT INTO q4_attendance VALUES
(1, 1, 1), (2, 1, 2), (3, 1, 3),
(4, 2, 1), (5, 2, 2),
(6, 3, 1), (7, 3, 2), (8, 3, 3), (9, 3, 1);

CREATE TABLE q5_purchases (
    customer_id INT NOT NULL,
    purchase_date DATE NOT NULL
);
INSERT INTO q5_purchases VALUES
(1, '2026-03-28'), (1, '2026-03-30'),
(2, '2026-03-29'),
(3, '2026-03-25'), (3, '2026-03-31'),
(4, '2026-04-01'),
(5, '2026-03-27');
"""

STAGING_DDL_AND_SEED = r"""
CREATE TABLE raw_customers (
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(50),
    signup_date DATE
);
INSERT INTO raw_customers VALUES
(1, 'ASHA', 'SHARMA', 'asha@example.com', 'Pune', '2024-01-15'),
(2, 'ben', 'kumar', 'ben@example.com', 'Delhi', '2024-02-20'),
(3, 'Cara', 'Rao', NULL, 'Mumbai', '2024-03-05'),
(4, 'DEV', 'MEHTA', 'dev@example.com', 'Bengaluru', '2024-04-10'),
(5, 'neha', 'das', 'neha@example.com', 'Hyderabad', '2024-05-01'),
(1, 'ASHA', 'SHARMA', 'asha@example.com', 'Pune', '2024-01-15');

CREATE TABLE raw_orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20)
);
INSERT INTO raw_orders VALUES
(201, 1, '2026-01-05', 'shipped'),
(202, 1, '2026-02-10', 'shipped'),
(203, 2, '2026-02-15', 'pending'),
(204, 3, '2026-02-20', 'shipped'),
(205, 4, '2026-03-01', 'pending'),
(206, 5, '2026-03-05', 'shipped'),
(299, 99, '2026-03-10', 'pending');

CREATE TABLE raw_order_items (
    order_item_id INT,
    order_id INT,
    product_name VARCHAR(100),
    quantity INT,
    unit_price DECIMAL(10,2)
);
INSERT INTO raw_order_items VALUES
(1, 201, 'Widget', 2, 25.00),
(2, 201, 'Gadget', 1, 75.00),
(3, 202, 'Gizmo', 3, 150.00),
(4, 202, 'Widget', 1, 25.00),
(5, 203, 'Widget', 2, 25.00),
(6, 204, 'Gadget', 1, 75.00),
(7, 205, 'Gizmo', 2, 150.00),
(8, 206, 'Widget', 1, 25.00),
(9, 299, 'Gadget', 1, 75.00);
"""


def run_sql_block(cursor, sql_block: str) -> None:
    """Run simple DDL/DML statements; source blocks contain no procedure bodies."""
    sql_only = "\n".join(
        line for line in sql_block.splitlines()
        if not line.strip().startswith("--")
    )
    for statement in sql_only.split(";"):
        statement = statement.strip()
        if statement:
            cursor.execute(statement)


def main() -> None:
    connection = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        autocommit=True,
    )
    try:
        with connection.cursor() as cursor:
            for db_name in DATABASES:
                cursor.execute(f"DROP DATABASE IF EXISTS `{db_name}`")
                cursor.execute(f"CREATE DATABASE `{db_name}`")

            cursor.execute("USE sql_mock_select")
            run_sql_block(cursor, SELECT_DDL_AND_SEED)

            cursor.execute("USE sql_mock_staging")
            run_sql_block(cursor, STAGING_DDL_AND_SEED)
    finally:
        connection.close()

    print("Seed complete.")
    print("Created empty: sql_mock_core, sql_mock_intermediate, sql_mock_reporting")
    print("Seeded: sql_mock_select and sql_mock_staging")
    print("Run this script again to reset the mock-test databases.")


if __name__ == "__main__":
    main()
