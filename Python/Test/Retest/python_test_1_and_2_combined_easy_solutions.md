# Python Test 1 + Test 2: Combined Questions with Easy Solutions

**Purpose:** One revision document combining the two original Python assessments supplied for the internship. The questions follow the original test requirements, and each is immediately followed by a simple solution designed to be easy to remember.

**Test 1:** 16 questions, 160 marks. Core Python + pandas.  
**Test 2:** 8 questions, 80 marks. Database connection + end-to-end ETL.  
**Total:** 24 questions, 240 marks.

> Paths such as `seed_data/data/...` are relative to the original test notebook folder. The Test 2 database details are the local disposable test database supplied in the assessment. Do not reuse those credentials for a real database.

---

# Test 1: Python Fundamentals, Data Cleaning & Aggregation

## Q1. Order-preserving deduplication

**Question:** Write `dedup_preserve_order(values)` that removes duplicates but preserves the first-seen order. Explain why `list(set(values))` is not suitable.

**Easy solution:**

```python
def dedup_preserve_order(values):
    seen = set()
    result = []

    for value in values:
        if value not in seen:
            result.append(value)
            seen.add(value)

    return result

sample = [9, 33, 61, 9, 4, 78, 33, 4, 99]
print(dedup_preserve_order(sample))
# [9, 33, 61, 4, 78, 99]
```

**Remember:** `set` checks duplicates; `list` keeps the original order. `list(set(...))` does not guarantee first-seen order.

## Q2. Abstract base class hierarchy

**Question:** Create abstract class `Shape` with abstract method `describe()`. Create `Circle` and `Rectangle` returning their names. Demonstrate that `Shape()` raises `TypeError`.

**Easy solution:**

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def describe(self):
        pass

class Circle(Shape):
    def describe(self):
        return "Circle"

class Rectangle(Shape):
    def describe(self):
        return "Rectangle"

print(Circle().describe())
print(Rectangle().describe())

try:
    Shape()
except TypeError as error:
    print(error)
```

**Remember:** `ABC` makes the base class abstract; `@abstractmethod` forces child classes to implement the method.

## Q3. Cubes using `map()` and `lambda`

**Question:** Use `map()` and `lambda` to make a list of cubes from 5 through 25 inclusive. Say when a list comprehension is preferable.

**Easy solution:**

```python
cubes = list(map(lambda x: x ** 3, range(5, 26)))
print(cubes)
```

A list comprehension is usually clearer when the transformation also needs conditions or multiple steps:

```python
cubes = [x ** 3 for x in range(5, 26)]
```

## Q4. Memory-efficient generator aggregation

**Question:** Read approximately 100,000 rows from `transactions.csv` using a generator. Yield one dictionary per row, then calculate total amount and transaction count for every category without loading all rows into memory.

**Easy solution:**

```python
import csv


def read_transactions(path):
    with open(path, newline="", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for row in reader:
            yield row


summary = {}

for row in read_transactions("seed_data/data/transactions.csv"):
    category = row["category"]
    amount = float(row["amount"])

    if category not in summary:
        summary[category] = {"total": 0, "count": 0}

    summary[category]["total"] += amount
    summary[category]["count"] += 1

print(summary)
```

**Remember:** `yield` gives one row at a time. Do not use `readlines()` or `list(read_transactions(...))`, because those load all rows into memory.

## Q5. Extract SQL index definitions using regex

**Question:** Read `schema_migration.sql` and extract every `CREATE INDEX` or `CREATE UNIQUE INDEX`. Return dictionaries with index name, table, columns list and unique flag. Support multi-column indexes.

**Easy solution:**

```python
import re

pattern = re.compile(
    r"CREATE\s+(UNIQUE\s+)?INDEX\s+(\w+)\s+ON\s+(\w+)\s*\(([^)]+)\)",
    re.IGNORECASE,
)

with open("seed_data/data/schema_migration.sql", encoding="utf-8") as file:
    sql_text = file.read()

indexes = []

for match in pattern.finditer(sql_text):
    indexes.append({
        "index_name": match.group(2),
        "table": match.group(3),
        "columns": [c.strip() for c in match.group(4).split(",")],
        "unique": bool(match.group(1)),
    })

print(indexes)
```

**Remember:** `([^)]+)` captures everything inside the column parentheses. Split that captured part by commas to support composite indexes. This regex handles the simple statement format in the test, not every possible SQL syntax.

## Q6. Custom rotate encoding

**Question:** Each lowercase letter shifts forward by its 1-based position. Wrap around from `z` to `a`. Verify `rotate_encode("abc") == "bdf"`.

**Easy solution:**

```python
def rotate_encode(word):
    result = ""

    for position, letter in enumerate(word, start=1):
        new_letter = chr((ord(letter) - ord("a") + position) % 26 + ord("a"))
        result += new_letter

    return result

print(rotate_encode("abc"))  # bdf
```

**Remember:** `ord()` converts a letter to a number, `% 26` wraps around, and `chr()` converts back to a letter.

## Q7. Normalize phone numbers

**Question:** Convert all four formats into one canonical format and make the results identical:

```python
phone_numbers = [
    "(555) 123-4567",
    "555.123.4567",
    "+1 555 123 4567",
    "5551234567",
]
```

**Easy solution:** Canonical format: `+1XXXXXXXXXX`.

```python
import re


def normalize_phone(raw):
    digits = re.sub(r"\D", "", raw)

    if len(digits) == 11 and digits.startswith("1"):
        digits = digits[1:]

    if len(digits) != 10:
        raise ValueError("Invalid phone number")

    return "+1" + digits


phone_numbers = [
    "(555) 123-4567",
    "555.123.4567",
    "+1 555 123 4567",
    "5551234567",
]

for phone in phone_numbers:
    print(normalize_phone(phone))
```

**Remember:** Remove non-digits, remove leading country code `1` only when there are 11 digits, then add `+1`.

## Q8. Clean and convert reference codes

**Question:** Strip all non-numeric characters and convert the remaining digits to `int`. Return `None` if no digits remain.

```python
raw_codes = ["A-4471", "  90210  ", "12-34-56", "#8823", "n/a"]
```

**Easy solution:**

```python
import re


def clean_reference_code(value):
    digits = re.sub(r"\D", "", value)

    if digits == "":
        return None

    return int(digits)


print([clean_reference_code(x) for x in raw_codes])
# [4471, 90210, 123456, 8823, None]
```

**Remember:** `\D` means any non-digit. `int()` only runs when digits remain.

## Q9. Exception handling and logging

**Question:** Rewrite the bad file reader. Catch specific errors, log attempts/success/failures using DEBUG/INFO/WARNING or ERROR, and demonstrate with an existing and missing path.

**Easy solution:**

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format="%(levelname)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("file_read.log", encoding="utf-8"),
    ],
    force=True,
)

logger = logging.getLogger(__name__)


def read_files_good(paths):
    results = []

    for path in paths:
        logger.debug("Trying to read %s", path)

        try:
            with open(path, encoding="utf-8") as file:
                results.append(file.read())
            logger.info("Read successfully: %s", path)

        except FileNotFoundError:
            logger.warning("File not found: %s", path)
        except PermissionError:
            logger.error("Permission denied: %s", path)

    return results


read_files_good(["seed_data/data/transactions.csv", "missing.txt"])
```

**Remember:** No bare `except`. Log what happened. Continue to the next file only for the expected file errors.

## Q10. TDD and testable code design (written answer)

**Question:** Explain red-green-refactor and why separating I/O/side effects from pure logic improves unit testing. Write 4–6 sentences.

**Easy answer to remember:**

1. **Red:** Write a test first and confirm that it fails because the feature is not implemented yet.
2. **Green:** Write the smallest amount of code needed to make the test pass.
3. **Refactor:** Improve the code structure while keeping all tests passing.
4. Pure functions take input and return output without reading files, writing databases or calling APIs.
5. They are easier to test because test data can be passed directly without creating files or connecting to external services.
6. Separating side effects also makes bugs easier to locate because file, database and transformation failures are in different places.

---

## Q11. Fix pandas dtypes

**Question:** Load `developer_survey.csv`. Convert `age` and `salary` from mixed `object` columns to numeric dtype. The text `unknown` must become a real missing value. Print the dtypes.

**Easy solution:**

```python
import pandas as pd

df = pd.read_csv("seed_data/data/developer_survey.csv")

df["age"] = pd.to_numeric(df["age"], errors="coerce")
df["salary"] = pd.to_numeric(df["salary"], errors="coerce")

print(df[["age", "salary"]].dtypes)
```

**Remember:** `errors="coerce"` turns bad numeric text into `NaN` instead of failing.

## Q12. Remote-work percentage by company size

**Question:** Using the survey DataFrame, calculate the percentage of respondents who work remotely, grouped by `company_size`.

**Easy solution:** The seed data stores `remote_work` as Boolean (`True`/`False`), so its mean is the proportion of `True` values.

```python
remote_percent = df.groupby("company_size")["remote_work"].mean() * 100
print(remote_percent)
```

**Remember:** Boolean mean × 100 = percentage of `True`.

## Q13. Job satisfaction by employment type and continent

**Question:** For every `(employment_type, continent)` pair, report the percentage distribution of each `job_satisfaction` category. This uses the normalized column from Q14.

**Easy solution:** Run Q14 first, then:

```python
report = pd.crosstab(
    [df["employment_type"], df["continent"]],
    df["job_satisfaction"],
    normalize="index",
) * 100

print(report)
```

**Remember:** `crosstab` makes the report; `normalize="index"` makes each employment-type/continent row add up to 100%.

## Q14. Normalize employment-type categories

**Question:** Normalize `employment_type_raw` into exactly `EMPLOYEE`, `CONTRACTOR`, or `OTHER` using the assessment's exact rules.

**Easy solution:**

```python

def normalize_employment(value):
    if pd.isna(value):
        return "OTHER"

    value = str(value).strip().lower()

    if value in ["full-time", "fulltime", "full time", "ft", "employee"]:
        return "EMPLOYEE"

    if value in ["contractor", "contract", "freelance", "freelancer"]:
        return "CONTRACTOR"

    return "OTHER"


df["employment_type"] = df["employment_type_raw"].apply(normalize_employment)
print(df["employment_type"].value_counts())
```

**Remember:** Exact match only. Multi-value, missing, blank and unknown values go to `OTHER`.

## Q15. Combine every Excel sheet into one CSV

**Question:** Read every sheet in `regional_operations.xlsx`, add `source_sheet`, combine all different columns and write one combined CSV. Do not hardcode sheet names or count.

**Easy solution:**

```python
import pandas as pd

sheets = pd.read_excel(
    "seed_data/data/regional_operations.xlsx",
    sheet_name=None,
)

frames = []

for name, data in sheets.items():
    data["source_sheet"] = name
    frames.append(data)

combined = pd.concat(frames, ignore_index=True, sort=False)
combined.to_csv(
    "seed_data/data/regional_operations_combined.csv",
    index=False,
)
```

**Remember:** `sheet_name=None` reads all sheets; `pd.concat` combines them; `source_sheet` identifies their origin. Missing columns become `NaN`.

## Q16. Merge orders and products and calculate customer revenue

**Question:** Load orders/products, merge on `product_id`, calculate `line_total = quantity * unit_price`, then calculate total revenue per customer.

**Easy solution:**

```python
orders = pd.read_csv("seed_data/data/orders.csv")
products = pd.read_csv("seed_data/data/products.csv")

merged = pd.merge(orders, products, on="product_id", how="inner")
merged["line_total"] = merged["quantity"] * merged["unit_price"]

revenue = merged.groupby("customer_id")["line_total"].sum()
print(revenue)
```

**Remember:** Merge → multiply → groupby → sum. The question asks total revenue, so use `sum()`, not mean or standard deviation.

---

# Test 2: Python ETL Layers

## Q1. Config-driven MySQL connection and logging

**Question:** Connect to the local `python_test3_etl` database using SQLAlchemy and PyMySQL. Keep connection values in a config dictionary, log to console and `etl_run.log`, handle connection errors, and fetch all rows from `region_lookup`.

**Easy solution:**

```python
import logging
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.exc import SQLAlchemyError

DB_CONFIG = {
    "host": "localhost",
    "port": 3307,
    "user": "root",
    "password": "InternTest_2026!",
    "database": "python_test3_etl",
}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("etl_run.log", encoding="utf-8"),
    ],
    force=True,
)
logger = logging.getLogger(__name__)

url = URL.create(
    "mysql+pymysql",
    username=DB_CONFIG["user"],
    password=DB_CONFIG["password"],
    host=DB_CONFIG["host"],
    port=DB_CONFIG["port"],
    database=DB_CONFIG["database"],
)

engine = create_engine(url)

try:
    with engine.connect() as connection:
        rows = connection.execute(text("SELECT * FROM region_lookup")).fetchall()
        for row in rows:
            print(row)
    logger.info("Connected and read region_lookup")
except SQLAlchemyError:
    logger.exception("Database connection or query failed")
    raise
```

**Remember:** Config dictionary → URL → engine → connection → query. `URL.create()` safely handles special characters in passwords.

## Q2. Extract CSV and JSON without cleaning

**Question:** Read `raw_customers.csv` and `raw_orders.json` into separate structures. Do not clean or drop malformed rows during extraction. Catch missing-file and malformed-JSON errors and log row counts.

**Easy solution:**

```python
import csv
import json
import logging

logger = logging.getLogger(__name__)


def extract():
    try:
        with open("seed_data/data/raw_customers.csv", newline="", encoding="utf-8") as file:
            customers = list(csv.DictReader(file))

        with open("seed_data/data/raw_orders.json", encoding="utf-8") as file:
            orders = json.load(file)

        logger.info("Extracted %d customers", len(customers))
        logger.info("Extracted %d orders", len(orders))
        return customers, orders

    except FileNotFoundError:
        logger.exception("Source file missing")
        raise
    except json.JSONDecodeError:
        logger.exception("Orders JSON is invalid")
        raise
```

**Remember:** Extraction reads data as-is. Do not remove the bad rows here; that belongs in transform.

## Q3. Clean customers and orders

**Question:** Drop the customer with missing `customer_id`. Drop the order whose `amount` is non-numeric. Log kept and skipped counts.

**Easy solution:**

```python

def clean_data(customers, orders):
    good_customers = []
    good_orders = []

    for customer in customers:
        if customer["customer_id"] not in (None, ""):
            good_customers.append(customer)
        else:
            logger.warning("Customer dropped: missing customer_id")

    for order in orders:
        try:
            order["amount"] = float(order["amount"])
            good_orders.append(order)
        except (ValueError, TypeError):
            logger.warning("Order %s dropped: invalid amount", order.get("order_id"))

    logger.info("Customers kept=%d skipped=%d", len(good_customers), len(customers) - len(good_customers))
    logger.info("Orders kept=%d skipped=%d", len(good_orders), len(orders) - len(good_orders))

    return good_customers, good_orders
```

**Remember:** Missing customer ID → drop. Amount → `float()`. If conversion fails → warning and drop.

## Q4. Enrich customers using region_lookup

**Question:** Query `region_lookup`, match on `country_code`, add `region_name` to every clean customer, and log the number enriched. Log and re-raise if an expected lookup is missing.

**Easy solution:**

```python

def enrich_customers(customers, engine):
    try:
        with engine.connect() as connection:
            rows = connection.execute(
                text("SELECT country_code, region_name FROM region_lookup")
            ).fetchall()

        lookup = {row.country_code: row.region_name for row in rows}
        enriched = []

        for customer in customers:
            code = customer["country_code"]
            customer["region_name"] = lookup[code]
            enriched.append(customer)

        logger.info("Enriched %d customers", len(enriched))
        return enriched

    except (KeyError, SQLAlchemyError):
        logger.exception("Customer enrichment failed")
        raise
```

**Remember:** SQL lookup → dictionary → use country code as key → add region name. The test data guarantees every well-formed customer's code exists.

## Q5. Create and load clean_customers safely

**Question:** Create the table if it does not exist and load enriched customers. Use a repeat-safe strategy: `TRUNCATE` before full insert, or an upsert by primary key.

**Easy solution: Option 1, TRUNCATE + reload**

```python
from sqlalchemy import text


def load_customers(customers, engine):
    with engine.connect() as connection:
        connection.execute(text("""
            CREATE TABLE IF NOT EXISTS clean_customers (
                customer_id INT PRIMARY KEY,
                name VARCHAR(150),
                email VARCHAR(150),
                country_code CHAR(2),
                region_name VARCHAR(50)
            )
        """))
        connection.commit()

        connection.execute(text("TRUNCATE TABLE clean_customers"))
        connection.commit()

        connection.execute(text("""
            INSERT INTO clean_customers
                (customer_id, name, email, country_code, region_name)
            VALUES
                (:customer_id, :name, :email, :country_code, :region_name)
        """), customers)
        connection.commit()

    logger.info("Loaded %d customers", len(customers))
```

**Alternative:** Use `INSERT ... ON DUPLICATE KEY UPDATE` if you want an upsert instead of clearing the full table. The primary key on `customer_id` is essential.

**Remember:** Create table if missing → clear old full batch → insert current batch. MySQL `TRUNCATE` commits implicitly; this simple test strategy is repeat-safe, but production atomic-refresh designs may use a staging table and swap.

## Q6. Read back and validate

**Question:** Read `clean_customers` into a DataFrame. Assert row count equals the number loaded and verify at least one known customer's email and region.

**Easy solution:**

```python
import pandas as pd


def validate_load(customers, engine):
    with engine.connect() as connection:
        loaded = pd.read_sql(
            text("SELECT * FROM clean_customers"),
            connection,
        )

    assert len(loaded) == len(customers)

    expected = customers[0]
    actual = loaded[loaded["customer_id"] == int(expected["customer_id"])].iloc[0]

    assert actual["email"] == expected["email"]
    assert actual["region_name"] == expected["region_name"]

    logger.info("Round-trip validation passed: %d rows", len(loaded))
    return loaded
```

**Remember:** Check row count plus actual values. Comparing a DataFrame to itself does not validate a database load.

## Q7. Refactor into extract, transform, load and main

**Question:** Reorganize Q2–Q6 into `extract()`, `transform(...)`, `load(...)`, and `main()`. Transform must clean, query region_lookup and return enriched customers plus anything needed downstream. Log progress before and after each stage.

**Easy solution:** This reuses the functions above instead of rewriting their logic.

```python

def transform(customers, orders, engine):
    customers, orders = clean_data(customers, orders)
    customers = enrich_customers(customers, engine)
    return customers, orders


def main(engine):
    logger.info("ETL started")

    logger.info("Extract started")
    customers, orders = extract()
    logger.info("Extract completed")

    logger.info("Transform started")
    customers, orders = transform(customers, orders, engine)
    logger.info("Transform completed")

    logger.info("Load started")
    load_customers(customers, engine)
    logger.info("Load completed")

    validate_load(customers, engine)
    logger.info("ETL finished")


main(engine)
```

**Remember:** `main()` only controls the order. Each function does one stage. The same logger created in Q1 is reused everywhere.

## Q8. Why separate ETL into functions? (written answer, 4–6 sentences)

**Question:** Explain why separate extract, transform and load functions are easier to debug, test and maintain than one monolithic script.

**Easy answer to remember:**

Separating ETL into functions gives each stage one responsibility. If a file cannot be read, the problem is in extraction; if values are wrong, the problem is likely in transformation; if records do not reach MySQL, the problem is in loading. Each function can be tested independently using small input data, without running the entire pipeline. Pure transformation logic is especially easy to test because it does not depend on files, databases or APIs. Smaller functions are easier to reuse, debug and maintain.

---

# Last-minute memory sheet

| If the question says... | Remember this pattern |
|---|---|
| Remove duplicates but keep order | `seen = set()` + `result = []` |
| Abstract class | `class X(ABC)` + `@abstractmethod` |
| Apply one operation to a range | `list(map(lambda x: ..., range(...)))` |
| Large CSV, low memory | `csv.DictReader` + `yield` |
| Extract digits | `re.sub(r"\D", "", value)` |
| Shift letters with wraparound | `(ord(c) - ord('a') + shift) % 26` |
| Fix numeric pandas column | `pd.to_numeric(..., errors="coerce")` |
| Boolean percentage | `groupby(...).mean() * 100` |
| Percentage across two categories | `pd.crosstab([...], ..., normalize="index") * 100` |
| Excel all sheets | `read_excel(sheet_name=None)` + `pd.concat` |
| Merge and calculate total | `merge` → multiply → `groupby().sum()` |
| Read CSV | `csv.DictReader` |
| Read JSON | `json.load` |
| Convert bad amount safely | `float()` inside `try/except` |
| SQL query from Python | `connection.execute(text("SELECT ..."))` |
| Repeat-safe full reload | `CREATE IF NOT EXISTS` + `TRUNCATE` + insert |
| Validate DB load | row count + known field checks |
| ETL stages | `extract()` → `transform()` → `load()` → `main()` |
| TDD | Red → Green → Refactor |

## Recommended revision order

1. Practise Q4, Q11–Q16 of Test 1: generators and pandas are easy marks once the patterns are familiar.
2. Practise Test 2 Q2–Q7 as one connected pipeline. Understand where each function gets its input and what it returns.
3. Memorize the short written answers for T1 Q10 and T2 Q8.
4. Practise Q5 regex and Q9 logging without looking at the solutions.
5. Before submitting any code, test one normal input and one edge case.
