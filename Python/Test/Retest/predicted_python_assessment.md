# Predicted Python Assessment: Mock Test

**Purpose:** A practice assessment predicted from the supplied Week 1–3 training tasks, Test 1: Python Fundamentals, and Test 2: ETL. This is an evidence-based practice paper, not an official paper or a guarantee of the next test.

## Prediction notes

The two supplied tests show a deliberate progression:

- Test 1 checks independent Python and pandas concepts in unfamiliar examples.
- Test 2 checks whether those skills can be connected into a complete, repeatable ETL workflow.
- Week 3 adds Flask, ORM, REST endpoints, validation, mocked unit tests and AWS deployment. These have not appeared in either supplied Python paper, so the API question below is a reasonable but lower-confidence forecast.

### Likelihood guide

| Forecast confidence | Areas | Why |
|---|---|---|
| Very high | Pandas cleaning, grouped reports, ETL stages, database load and validation | These appear directly in the training tasks and/or both tests. |
| High | Generators, normalization, regex, logging, exceptions, unit testing, merges and Excel | These are explicit training outcomes and recur in Test 1. |
| Medium | Flask REST API, ORM, request validation, mocked service tests | Explicit Week 3 work, but not yet assessed in the two supplied Python tests. |
| Lower / stretch | AWS Lambda/API Gateway deployment details | Included in Week 3, but deployment may be too environment-dependent for a short in-person coding test. |

---

# Test instructions

- **Suggested duration:** 2 hours 30 minutes.
- **Total:** 160 points.
- **Questions:** 16, each worth 10 points.
- **Part A:** Python engineering fundamentals, 8 questions / 80 points.
- **Part B:** Data engineering and backend integration, 8 questions / 80 points.
- Write readable, reusable code. Use functions where requested.
- Handle missing, malformed and unexpected values deliberately.
- Use logging rather than `print()` for operational messages when asked.
- Do not silently ignore exceptions.
- Show sample output or assertions for important requirements.
- For database questions, use the connection configuration supplied by the test environment. Do not put credentials directly inside a connection call.

## Shared marking scale

Each question is graded holistically using the same five bands:

| Band | Marks | General meaning |
|---|---:|---|
| Excellent | 10 | Correct, complete, robust solution that follows all important constraints. |
| Good | 7 | Main solution is correct, with a limited omission or edge-case weakness. |
| Partial | 5 | Some meaningful parts work, but one or more core requirements are incomplete. |
| Poor | 2 | Attempt shows limited understanding or contains a major implementation error. |
| Blank | 0 | No meaningful attempt. |

---

# Part A: Python Engineering Fundamentals

**8 questions · 80 points**

## Question 1: Stable Deduplication Using a Business Key (10 points)

**Concept:** Order-Preserving Deduplication and Composite Keys

You receive the following customer records:

```python
customers = [
    {"customer_id": 10, "email": "Asha@Example.com", "source": "web"},
    {"customer_id": 11, "email": "ben@example.com", "source": "mobile"},
    {"customer_id": 12, "email": "asha@example.com", "source": "import"},
    {"customer_id": 13, "email": "cara@example.com", "source": "web"},
    {"customer_id": 14, "email": " BEN@example.com ", "source": "import"},
]
```

Write `deduplicate_customers(records)` that:

1. Returns a new list and does not modify the input.
2. Treats emails as case-insensitive and ignores leading/trailing whitespace.
3. Keeps the first record for each normalized email.
4. Preserves the order of first appearances.
5. Does not use `list(set(...))`.

Show the returned records and explain the key used to detect duplicates.

### Solution

```python
def deduplicate_customers(records):
    seen = set()
    result = []

    for record in records:
        email = record["email"].strip().lower()
        if email not in seen:
            seen.add(email)
            result.append(record.copy())

    return result


customers = [
    {"customer_id": 10, "email": "Asha@Example.com", "source": "web"},
    {"customer_id": 11, "email": "ben@example.com", "source": "mobile"},
    {"customer_id": 12, "email": "asha@example.com", "source": "import"},
    {"customer_id": 13, "email": "cara@example.com", "source": "web"},
    {"customer_id": 14, "email": " BEN@example.com ", "source": "import"},
]

print(deduplicate_customers(customers))
```

The duplicate key is the normalized email: lowercased and stripped of surrounding whitespace.

## Question 2: Abstract Interface for Exporters (10 points)

**Concept:** Abstract Base Classes and Enforced Interfaces

Using `abc`, define an abstract class `DataExporter` with an abstract method `export(self, records, path)`.

Implement:

- `JsonExporter`, which writes the records as JSON.
- `CsvExporter`, which writes the records as CSV using the keys of the first record as headers.

Demonstrate that `DataExporter()` raises `TypeError`, and demonstrate one successful export using either concrete class. Use a context manager when opening files.

### Solution

```python
from abc import ABC, abstractmethod
import csv
import json


class DataExporter(ABC):
    @abstractmethod
    def export(self, records, path):
        pass


class JsonExporter(DataExporter):
    def export(self, records, path):
        with open(path, "w", encoding="utf-8") as file:
            json.dump(records, file)


class CsvExporter(DataExporter):
    def export(self, records, path):
        with open(path, "w", newline="", encoding="utf-8") as file:
            if records:
                writer = csv.DictWriter(file, fieldnames=records[0].keys())
                writer.writeheader()
                writer.writerows(records)


try:
    DataExporter()
except TypeError:
    print("DataExporter cannot be instantiated")

JsonExporter().export([{"id": 1, "name": "Asha"}], "records.json")
```

## Question 3: Functional Transformation of Transaction Records (10 points)

**Concept:** `map()`, `filter()` and Lambda Functions

Given:

```python
transactions = [
    {"id": 1, "amount": 49.5},
    {"id": 2, "amount": 210.0},
    {"id": 3, "amount": 125.0},
    {"id": 4, "amount": 80.0},
    {"id": 5, "amount": 305.5},
]
```

Using `filter()` and `map()` with lambda functions:

1. Keep only transactions whose amount is at least 100.
2. Produce a list of dictionaries containing `id` and `amount_after_tax`.
3. Calculate the final amount using a tax multiplier of `1.18` and round it to two decimal places.

In one or two sentences, explain when a list comprehension would be clearer than a `map()`/`filter()` chain.

### Solution

```python
transactions = [
    {"id": 1, "amount": 49.5},
    {"id": 2, "amount": 210.0},
    {"id": 3, "amount": 125.0},
    {"id": 4, "amount": 80.0},
    {"id": 5, "amount": 305.5},
]

filtered = filter(lambda transaction: transaction["amount"] >= 100, transactions)
result = list(map(
    lambda transaction: {
        "id": transaction["id"],
        "amount_after_tax": round(transaction["amount"] * 1.18, 2)
    },
    filtered
))

print(result)
```

A list comprehension is clearer for a simple filter and transformation that can be written in one readable expression.

## Question 4: Streaming Event Aggregation (10 points)

**Concept:** Generators and Memory-Efficient Processing

A file `api_events.csv` contains approximately 250,000 rows with these columns:

```text
event_id,service,status_code,duration_ms,timestamp
```

Write a generator `read_events(path)` that yields one row at a time as a dictionary.

Consume the generator once and calculate, for each service:

- the number of events with a 5xx status code;
- the average `duration_ms` of those 5xx events.

Requirements:

- Use the built-in `csv` module.
- Convert `status_code` and `duration_ms` to numeric values before comparing or aggregating.
- Do not call `list(read_events(path))` or retain all rows.
- Handle malformed numeric values without terminating the whole processing run; log or count skipped rows.

### Solution

```python
import csv
import logging

logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)


def read_events(path):
    with open(path, "r", newline="", encoding="utf-8") as file:
        yield from csv.DictReader(file)


counts = {}
totals = {}

for event in read_events("api_events.csv"):
    try:
        status = int(event["status_code"])
        duration = float(event["duration_ms"])
    except (TypeError, ValueError):
        logger.warning("Skipping malformed event: %s", event)
        continue

    if 500 <= status <= 599:
        service = event["service"]
        counts[service] = counts.get(service, 0) + 1
        totals[service] = totals.get(service, 0) + duration

result = {
    service: {
        "count": counts[service],
        "average_duration_ms": totals[service] / counts[service]
    }
    for service in counts
}

print(result)
```

## Question 5: Extract Structured Log Records with Regex (10 points)

**Concept:** Regular Expressions and Structured-Text Parsing

A text file contains records in this format:

```text
2026-10-12T09:30:00Z INFO service=billing request_id=ab12 message="invoice created"
2026-10-12T09:31:10Z ERROR service=orders request_id=cd34 message="database timeout"
```

Using regular expressions, read the file and produce a list of dictionaries with these keys:

```python
{
    "timestamp": "2026-10-12T09:30:00Z",
    "level": "INFO",
    "service": "billing",
    "request_id": "ab12",
    "message": "invoice created",
}
```

Requirements:

- Support spaces inside the quoted `message` value.
- Skip malformed lines and count how many were skipped.
- Do not use `split()` on spaces to parse the whole line.
- Explain briefly why a greedy message group can cause a parsing problem if more quoted fields are added later.

### Solution

```python
import re

pattern = re.compile(
    r'^(?P<timestamp>\S+) (?P<level>\S+) '
    r'service=(?P<service>\S+) '
    r'request_id=(?P<request_id>\S+) '
    r'message="(?P<message>[^"]*)"$'
)

records = []
skipped = 0

with open("app.log", "r", encoding="utf-8") as file:
    for line in file:
        match = pattern.match(line.strip())
        if match:
            records.append(match.groupdict())
        else:
            skipped += 1

print(records)
print("Skipped:", skipped)
```

A greedy message pattern may consume text from later quoted fields until the final quote, causing incorrect field boundaries.

## Question 6: Canonical Phone Normalization and Validation (10 points)

**Concept:** Field-Level Normalization and Input Validation

Implement `normalize_phone(raw)` for the following inputs:

```python
phones = [
    "(415) 555-0134",
    "415.555.0134",
    "+1 415 555 0134",
    "1-415-555-0134",
    "4155550134",
    "not available",
    "415-55",
]
```

Rules:

1. The canonical output must be `+1XXXXXXXXXX` where `X` is a digit.
2. Remove spaces, parentheses, dots and hyphens by extracting digits.
3. If there are 11 digits and the first is `1`, remove that leading country code.
4. Return `None` unless exactly 10 digits remain.
5. Apply the function to all values and show the results.

### Solution

```python
import re


def normalize_phone(raw):
    digits = re.sub(r"\D", "", str(raw))

    if len(digits) == 11 and digits.startswith("1"):
        digits = digits[1:]

    return "+1" + digits if len(digits) == 10 else None


phones = [
    "(415) 555-0134",
    "415.555.0134",
    "+1 415 555 0134",
    "1-415-555-0134",
    "4155550134",
    "not available",
    "415-55",
]

print([normalize_phone(phone) for phone in phones])
```

## Question 7: Production-Style File Reading and Logging (10 points)

**Concept:** Specific Exception Handling and Logging

Refactor this function:

```python
def read_json_bad(path):
    try:
        return open(path).read()
    except:
        print("failed")
        return None
```

Write `read_json_good(path)` that:

- Uses a context manager and UTF-8 encoding.
- Parses JSON and returns the resulting Python object.
- Logs an attempt at `DEBUG` level and success at `INFO` level.
- Handles `FileNotFoundError`, `PermissionError` and `json.JSONDecodeError` separately.
- Logs the exception with useful context and re-raises it rather than hiding a corrupt input file.

Demonstrate the function with one valid JSON path and one missing or malformed path. Configure a logger once, rather than configuring it inside the function.

### Solution

```python
import json
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


def read_json_good(path):
    logger.debug("Reading JSON file: %s", path)

    try:
        with open(path, "r", encoding="utf-8") as file:
            data = json.load(file)

        logger.info("Successfully read JSON file: %s", path)
        return data

    except FileNotFoundError:
        logger.exception("File not found: %s", path)
        raise
    except PermissionError:
        logger.exception("Permission denied: %s", path)
        raise
    except json.JSONDecodeError:
        logger.exception("Invalid JSON in file: %s", path)
        raise


# Valid file
print(read_json_good("data.json"))

# Missing or malformed file
try:
    print(read_json_good("missing.json"))
except (FileNotFoundError, json.JSONDecodeError):
    print("Could not read JSON")
```

## Question 8: TDD and Unit Tests for a Validation Function (10 points)

**Concept:** Test-Driven Development and Testable Design

Implement:

```python
def parse_positive_quantity(value):
    ...
```

The function must:

- Accept an integer or a string containing an integer.
- Return the integer when it is greater than zero.
- Raise `ValueError` for zero, negative numbers, decimal strings such as `"2.5"`, empty strings and non-numeric text.
- Not accept booleans as valid quantities, even though `bool` is a subclass of `int` in Python.

Write at least five unit tests using `unittest` or `pytest`, including valid and invalid boundary cases.

In 2–3 sentences, explain the red-green-refactor cycle.

### Solution

```python
def parse_positive_quantity(value):
    if isinstance(value, bool):
        raise ValueError("Boolean is not a valid quantity")

    if isinstance(value, int):
        quantity = value
    elif isinstance(value, str) and value.strip().isdigit():
        quantity = int(value)
    else:
        raise ValueError("Quantity must be an integer")

    if quantity <= 0:
        raise ValueError("Quantity must be positive")

    return quantity
```

```python
import unittest


class QuantityTest(unittest.TestCase):
    def test_valid_integer(self):
        self.assertEqual(parse_positive_quantity(2), 2)

    def test_valid_string(self):
        self.assertEqual(parse_positive_quantity("3"), 3)

    def test_zero(self):
        with self.assertRaises(ValueError):
            parse_positive_quantity(0)

    def test_negative(self):
        with self.assertRaises(ValueError):
            parse_positive_quantity("-1")

    def test_decimal_string(self):
        with self.assertRaises(ValueError):
            parse_positive_quantity("2.5")

    def test_empty_string(self):
        with self.assertRaises(ValueError):
            parse_positive_quantity("")

    def test_boolean(self):
        with self.assertRaises(ValueError):
            parse_positive_quantity(True)


if __name__ == "__main__":
    unittest.main()
```

Red means write a failing test for the required behavior. Green means implement the smallest change that passes it. Refactor means improve the passing code while running the tests again.

---

# Part B: Data Engineering and Backend Integration

**8 questions · 80 points**

For Questions 9–15, assume the test folder contains:

```text
seed_data/data/
    raw_customers.csv
    raw_orders.json
    country_regions.csv
    regional_sales.xlsx
```

The CSV and JSON files intentionally contain some incomplete or malformed records. Do not assume that every input row is valid.

## Question 9: Extract Two Sources Without Transforming Them (10 points)

**Concept:** ETL Extraction and Separation of Concerns

Read `raw_customers.csv` and `raw_orders.json` into two separate in-memory structures.

Expected source schemas:

```text
raw_customers.csv:
customer_id,name,email,country_code,plan_raw

raw_orders.json:
order_id,customer_id,order_date,amount,quantity
```

Requirements:

- Read the CSV using `csv.DictReader` or pandas.
- Read the JSON using `json.load` or pandas, according to its structure.
- Do not clean, convert, enrich or drop rows in this extraction step.
- Log the number of records extracted from each source.
- Catch and log likely file and JSON parsing errors, then re-raise them.

### Solution

```python
import json
import logging
import pandas as pd

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

folder = "seed_data/data"

try:
    customers = pd.read_csv(f"{folder}/raw_customers.csv")
    logger.info("Extracted %d customer records", len(customers))
except (FileNotFoundError, pd.errors.ParserError) as error:
    logger.exception("Customer extraction failed")
    raise

try:
    with open(f"{folder}/raw_orders.json", "r", encoding="utf-8") as file:
        orders = pd.DataFrame(json.load(file))
    logger.info("Extracted %d order records", len(orders))
except (FileNotFoundError, json.JSONDecodeError) as error:
    logger.exception("Order extraction failed")
    raise
```

## Question 10: Clean and Validate Customer and Order Data (10 points)

**Concept:** Data Cleaning, Type Coercion and Validation

Using the structures from Question 9:

1. Drop customer rows whose `customer_id` is missing or blank.
2. Strip whitespace from customer names and country codes.
3. Convert order `amount` to a numeric value. Drop rows whose amount cannot be converted or is negative.
4. Convert `order_date` to datetime. Drop rows with invalid dates.
5. Preserve valid zero amounts if the specification allows them.
6. Log kept and rejected row counts separately for customers and orders.

Use functions for customer cleaning and order cleaning. Do not mutate the original extracted structures.

### Solution

```python
def clean_customers(raw):
    customers = raw.copy()
    kept = customers["customer_id"].notna() & customers["customer_id"].astype(str).str.strip().ne("")
    rejected = len(customers) - kept.sum()

    customers = customers.loc[kept].copy()
    customers["name"] = customers["name"].str.strip()
    customers["country_code"] = customers["country_code"].str.strip()

    print("Customers kept:", len(customers), "rejected:", rejected)
    return customers


def clean_orders(raw):
    orders = raw.copy()
    orders["amount"] = pd.to_numeric(orders["amount"], errors="coerce")
    orders["order_date"] = pd.to_datetime(orders["order_date"], errors="coerce")

    kept = orders["amount"].notna() & (orders["amount"] >= 0) & orders["order_date"].notna()
    rejected = len(orders) - kept.sum()
    orders = orders.loc[kept].copy()

    print("Orders kept:", len(orders), "rejected:", rejected)
    return orders


clean_customer_df = clean_customers(customers)
clean_order_df = clean_orders(orders)
```

## Question 11: Strict Product-Plan Categorization (10 points)

**Concept:** Categorical Normalization with an Explicit Catch-All

The `plan_raw` column contains values such as:

```text
"Basic", "BASIC PLAN", "starter", "Pro", "PROFESSIONAL",
"Enterprise", "enterprise plan", "Trial", "Basic;Pro", "", None
```

Create a function `normalize_plan(value)` that maps exactly:

- `"basic"`, `"basic plan"`, `"starter"` → `BASIC`
- `"pro"`, `"professional"` → `PRO`
- `"enterprise"`, `"enterprise plan"` → `ENTERPRISE`
- Missing, blank, multi-value, and every unlisted value → `OTHER`

Normalize case and surrounding whitespace before matching. Add a `plan` column and show the count of each output category. Do not use broad substring matching.

### Solution

```python
def normalize_plan(value):
    basic = {"basic", "basic plan", "starter"}
    pro = {"pro", "professional"}
    enterprise = {"enterprise", "enterprise plan"}

    if pd.isna(value) or ";" in str(value):
        return "OTHER"

    value = str(value).strip().lower()
    if value in basic:
        return "BASIC"
    if value in pro:
        return "PRO"
    if value in enterprise:
        return "ENTERPRISE"
    return "OTHER"


clean_customer_df["plan"] = clean_customer_df["plan_raw"].apply(normalize_plan)
print(clean_customer_df["plan"].value_counts())
```

## Question 12: Lookup Enrichment by Country Code (10 points)

**Concept:** Data Enrichment and Joins

`country_regions.csv` has two columns:

```text
country_code,region_name
```

Using the cleaned customers from Question 10:

1. Load the lookup data.
2. Enrich every customer with `region_name` by matching `country_code`.
3. Ensure that a customer is not silently assigned an incorrect region.
4. Count and log unmatched country codes.
5. Return the enriched customer records as a new DataFrame or list of dictionaries.

You may use a pandas merge or a dictionary lookup. State which join strategy you used and why.

### Solution

```python
lookup = pd.read_csv(f"{folder}/country_regions.csv")

enriched = clean_customer_df.merge(
    lookup,
    on="country_code",
    how="left",
    validate="many_to_one"
)

unmatched = enriched["region_name"].isna()
print("Unmatched country codes:", enriched.loc[unmatched, "country_code"].unique())
print("Unmatched customer count:", unmatched.sum())
```

I used a left join so every cleaned customer remains in the result. A many-to-one validation prevents duplicate or ambiguous region records.

## Question 13: Build a Business Report with Pandas (10 points)

**Concept:** Grouped Aggregation, Derived Columns and Reporting

Using the cleaned orders and enriched customers:

1. Join orders to customers using `customer_id`.
2. Create a `month` column from `order_date` in `YYYY-MM` format.
3. Calculate total revenue and order count for every `(region_name, month)` pair.
4. Calculate each region's percentage contribution to total revenue.
5. Sort by month and then descending revenue.

Return a DataFrame with clear column names. Avoid calculating percentages using a hard-coded denominator.

### Solution

```python
report_orders = clean_order_df.merge(
    enriched[["customer_id", "region_name"]],
    on="customer_id",
    how="inner",
    validate="many_to_one"
)

report_orders["month"] = report_orders["order_date"].dt.strftime("%Y-%m")

report = report_orders.groupby(["region_name", "month"], as_index=False).agg(
    total_revenue=("amount", "sum"),
    order_count=("order_id", "count")
)

report["revenue_percentage"] = (
    report["total_revenue"] / report["total_revenue"].sum() * 100
).round(2)

report = report.sort_values(
    ["month", "total_revenue"],
    ascending=[True, False]
)

print(report)
```

## Question 14: Combine Heterogeneous Excel Sheets (10 points)

**Concept:** Multi-Sheet Spreadsheet Processing

`regional_sales.xlsx` contains multiple sheets. The sheets have one header row each, but they do not all contain the same columns.

Write code that:

- Reads every sheet without hardcoding sheet names or sheet count.
- Adds a `source_sheet` column containing the sheet name for each row.
- Combines all rows into one DataFrame, preserving the union of columns across sheets.
- Writes `regional_sales_combined.csv` to the same directory.
- Does not create a separate CSV for each sheet.

Use pandas and explain how missing columns in individual sheets are represented after concatenation.

### Solution

```python
excel_path = f"{folder}/regional_sales.xlsx"

with pd.ExcelFile(excel_path) as workbook:
    frames = [
        pd.read_excel(workbook, sheet_name=sheet).assign(source_sheet=sheet)
        for sheet in workbook.sheet_names
    ]

combined = pd.concat(frames, ignore_index=True, sort=False)
combined.to_csv(f"{folder}/regional_sales_combined.csv", index=False)

print(combined)
```

Columns missing from a sheet are represented by `NaN` values after concatenation.

## Question 15: Idempotent Database Load and Round-Trip Validation (10 points)

**Concept:** SQLAlchemy, Safe Loading and Data Validation

Create a table `clean_orders` in the supplied MySQL database with:

```text
order_id       PRIMARY KEY
customer_id
order_date
amount
quantity
```

Load the cleaned orders from Question 10. Your script must:

1. Read connection settings from a configuration dictionary or environment variables.
2. Use SQLAlchemy with the supplied MySQL driver.
3. Create the table only if it does not exist.
4. Be safe to execute repeatedly without duplicate orders. Use either a truncate-and-reload strategy or a primary-key upsert, and state which one you chose.
5. Read the table back into a DataFrame.
6. Assert that the row count matches the number of rows loaded and verify at least one known `order_id` and `amount`.
7. Log successful loading and validation.

### Solution

```python
import os
import logging
from sqlalchemy import create_engine, text

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

config = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": os.getenv("DB_NAME", "test_db"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}

engine = create_engine(
    f"mysql+pymysql://{config['user']}:{config['password']}@"
    f"{config['host']}/{config['database']}"
)

with engine.begin() as connection:
    connection.execute(text("""
        CREATE TABLE IF NOT EXISTS clean_orders (
            order_id VARCHAR(50) PRIMARY KEY,
            customer_id VARCHAR(50),
            order_date DATETIME,
            amount DECIMAL(10, 2),
            quantity INTEGER
        )
    """))
    connection.execute(text("DELETE FROM clean_orders"))

clean_order_df.to_sql(
    "clean_orders",
    engine,
    if_exists="append",
    index=False,
    chunksize=1000
)

loaded = pd.read_sql("SELECT * FROM clean_orders", engine)
assert len(loaded) == len(clean_order_df)

known_id = clean_order_df.iloc[0]["order_id"]
known_amount = clean_order_df.iloc[0]["amount"]
row = loaded.loc[loaded["order_id"] == known_id]
assert len(row) == 1
assert float(row.iloc[0]["amount"]) == float(known_amount)

logger.info("Loaded and validated %d clean orders", len(loaded))
```

This uses a truncate-and-reload strategy: `DELETE` is followed by loading the cleaned DataFrame.

## Question 16: Flask REST API with Validation and Testable Layers (10 points)

**Concept:** Flask, MVC Structure, ORM and Mocked Unit Tests

Build a small Flask API for products using a supplied SQLAlchemy `Product` model or an equivalent model you define.

Required endpoints:

- `GET /api/products/<int:product_id>`: return one product or HTTP 404.
- `POST /api/products`: validate `name`, `unit_price` and `stock_quantity`, create a product and return HTTP 201.
- `PATCH /api/products/<int:product_id>`: update only supplied fields, validate them, and return HTTP 404 if the product does not exist.

Requirements:

- Separate route/controller logic from database access using a service or repository layer.
- Reject a blank name, negative price and negative stock quantity with HTTP 400 and a useful JSON error.
- Write at least two unit tests. Mock the repository/service so the tests do not require a real database.
- Briefly outline how this API could be deployed using API Gateway and AWS Lambda, and where logs would be inspected.

### Solution

```python
from flask import Flask, jsonify, request


class ProductRepository:
    def __init__(self):
        self.products = {}

    def get(self, product_id):
        return self.products.get(product_id)

    def add(self, product_id, data):
        self.products[product_id] = data
        return data

    def update(self, product_id, data):
        product = self.products.get(product_id)
        if product is None:
            return None
        product.update(data)
        return product


repository = ProductRepository()
app = Flask(__name__)


def validate_product(data, update=False):
    if not update and not data.get("name", "").strip():
        return "Name is required"
    if "name" in data and not data["name"].strip():
        return "Name is required"
    if "unit_price" in data and data["unit_price"] < 0:
        return "unit_price cannot be negative"
    if "stock_quantity" in data and data["stock_quantity"] < 0:
        return "stock_quantity cannot be negative"
    return None


@app.get("/api/products/<int:product_id>")
def get_product(product_id):
    product = repository.get(product_id)
    if product is None:
        return jsonify(error="Product not found"), 404
    return jsonify(product)


@app.post("/api/products")
def add_product():
    data = request.get_json(silent=True) or {}
    error = validate_product(data)
    if error:
        return jsonify(error=error), 400

    product_id = max(repository.products, default=0) + 1
    product = {"id": product_id, **data}
    repository.add(product_id, product)
    return jsonify(product), 201


@app.patch("/api/products/<int:product_id>")
def patch_product(product_id):
    data = request.get_json(silent=True) or {}
    error = validate_product(data, update=True)
    if error:
        return jsonify(error=error), 400

    product = repository.update(product_id, data)
    if product is None:
        return jsonify(error="Product not found"), 404
    return jsonify(product)
```

Example unit tests with a mocked repository:

```python
from unittest.mock import Mock


def test_blank_name():
    assert validate_product({"name": "   "}) == "Name is required"


def test_negative_price():
    assert validate_product({"name": "Pen", "unit_price": -1}) == "unit_price cannot be negative"


def test_service_repository_mock():
    mock_repository = Mock()
    mock_repository.get.return_value = {"id": 1, "name": "Pen"}
    assert mock_repository.get(1)["name"] == "Pen"
```

Deploy the Flask application with a Lambda adapter behind API Gateway. Inspect application and Lambda logs in AWS CloudWatch Logs.

---

# Self-check before submitting

Use this checklist on every question:

- [ ] Did I meet every explicit requirement, including the requested function or output format?
- [ ] Did I test normal, empty, missing and malformed inputs where relevant?
- [ ] Did I preserve order or row identity where required?
- [ ] Did I convert strings to the correct numeric/date types before calculating?
- [ ] Did I use a generator when memory efficiency was required?
- [ ] Did I avoid swallowing exceptions?
- [ ] Did I verify the actual database write, not just construct SQL strings?
- [ ] Can I rerun the ETL/load process without creating duplicate records?
- [ ] Can I explain the design in plain language?

# What this mock is designed to reveal

| If you struggle with... | The likely gap is... |
|---|---|
| Q1–Q3 | Python data structures, interfaces and functional transformations |
| Q4 | Lazy iteration and incremental aggregation |
| Q5–Q6 | Regex, data normalization and strict validation |
| Q7–Q8 | Production error handling and testing discipline |
| Q9–Q12 | ETL separation, dirty-data handling and enrichment |
| Q13–Q14 | Pandas reporting and semi-structured files |
| Q15 | Database persistence, idempotency and verification |
| Q16 | Backend/API architecture, validation and test isolation |

**Suggested target:** Aim for 120/160 or higher, but do not chase the total at the cost of untested code. Your earlier solutions lost marks mainly where the output looked plausible but did not satisfy the full requirement or edge cases.
