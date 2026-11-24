"""Reset the disposable MySQL database and seed the region lookup table."""
import os
import pymysql

DB_CONFIG = {
    "host": os.getenv("PY_RETEST_DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("PY_RETEST_DB_PORT", "3307")),
    "user": os.getenv("PY_RETEST_DB_USER", "root"),
    "password": os.getenv("PY_RETEST_DB_PASSWORD", "PythonRetest_2026!"),
    "database": os.getenv("PY_RETEST_DB_NAME", "python_retest"),
}

LOOKUP_ROWS = [
    ("IN", "South Asia"),
    ("SG", "Southeast Asia"),
    ("AU", "Oceania"),
    ("GB", "Europe"),
    ("DE", "Europe"),
    ("CA", "North America"),
    ("US", "North America"),
    ("ZA", "Africa"),
]


def main():
    connection = pymysql.connect(
        host=DB_CONFIG["host"], port=DB_CONFIG["port"],
        user=DB_CONFIG["user"], password=DB_CONFIG["password"],
        autocommit=True,
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute(f"DROP DATABASE IF EXISTS `{DB_CONFIG['database']}`")
            cursor.execute(f"CREATE DATABASE `{DB_CONFIG['database']}` CHARACTER SET utf8mb4")
            cursor.execute(f"USE `{DB_CONFIG['database']}`")
            cursor.execute("""
                CREATE TABLE region_lookup (
                    country_code CHAR(2) PRIMARY KEY,
                    region_name VARCHAR(50) NOT NULL
                )
            """)
            cursor.executemany(
                "INSERT INTO region_lookup (country_code, region_name) VALUES (%s, %s)",
                LOOKUP_ROWS,
            )
        print(f"Seeded {DB_CONFIG['database']}.region_lookup with {len(LOOKUP_ROWS)} rows")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
