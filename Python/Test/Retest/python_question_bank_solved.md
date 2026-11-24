# Python, Pandas and ETL Question Bank with Solutions

**Purpose:** A practice bank built from the Week 1–3 tasks and the patterns visible in the two supplied Python assessments. Each topic contains five short questions with worked solutions.

The highest-priority themes are data cleaning, grouped aggregation, generators, ETL stages, logging, data normalization and database validation. Flask/ORM questions are included because they are in Week 3, even though they did not appear in the two supplied test papers.

> These are practice questions and model approaches, not official company answers. The code is intentionally compact so that you can type it from memory and explain it during an assessment.

## Quick priority map

| Priority | Topic | Why it matters |
|---|---|---|
| Very high | Pandas cleaning and aggregation | Explicitly tested in Test 1 and related to Week 2. |
| Very high | ETL, joins, SQL loading and validation | The entire Test 2 is built around this workflow. |
| High | Generators, regex, normalization | Directly tested in Test 1 and trained in Week 1/2. |
| High | Logging, exceptions and unit testing | Explicit Week 1 requirements and direct assessment coverage. |
| Medium | Flask, ORM, REST and mocks | Explicit Week 3 task; not yet present in the two Python tests. |

---

# Topic 1: Python Data Structures and Functions

## Q1. Remove duplicates while preserving order

**Question:** Write a function that removes duplicate values from a list without changing the order of first appearances.

**Solution:**

```python
def deduplicate(values):
    seen = set()
    result = []

    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)

    return result

print(deduplicate([4, 2, 4, 7, 2, 9]))
# [4, 2, 7, 9]
```

**Why it works:** A set provides fast membership checks, while the list preserves insertion order. `list(set(values))` is not the right solution when the original order must be preserved.

## Q2. Remove duplicate records using a normalized key

**Question:** Given a list of user dictionaries, keep only the first record for each email, ignoring case and surrounding whitespace.

**Solution:**

```python
def unique_users(users):
    seen_emails = set()
    result = []

    for user in users:
        key = user["email"].strip().casefold()
        if key not in seen_emails:
            seen_emails.add(key)
            result.append(user.copy())

    return result
```

**Key idea:** Normalize the key before checking duplicates. `casefold()` is designed for case-insensitive text comparison and is more comprehensive than `lower()` for some languages.

## Q3. Count occurrences of each value

**Question:** Count how many times each status appears in a list.

**Solution:**

```python
from collections import Counter

statuses = ["OK", "ERROR", "OK", "PENDING", "ERROR", "OK"]
counts = Counter(statuses)

print(dict(counts))
# {'OK': 3, 'ERROR': 2, 'PENDING': 1}
```

A loop-based alternative is:

```python
counts = {}
for status in statuses:
    counts[status] = counts.get(status, 0) + 1
```

## Q4. Safely calculate an average

**Question:** Calculate the average of a list containing integers, numeric strings, `None` and invalid strings. Ignore invalid values and return `None` if no valid values remain.

**Solution:**

```python
def safe_average(values):
    valid = []

    for value in values:
        try:
            number = float(value)
        except (TypeError, ValueError):
            continue
        valid.append(number)

    if not valid:
        return None

    return sum(valid) / len(valid)

print(safe_average([10, "20", None, "bad", 30]))  # 20.0
```

## Q5. Group records by a field

**Question:** Convert a list of employee dictionaries into a dictionary grouped by department.

**Solution:**

```python
from collections import defaultdict

employees = [
    {"name": "Asha", "department": "Data"},
    {"name": "Ben", "department": "Platform"},
    {"name": "Cara", "department": "Data"},
]

by_department = defaultdict(list)
for employee in employees:
    by_department[employee["department"]].append(employee)

by_department = dict(by_department)
```

**Test angle:** The examiner may change the grouping key, ask you to preserve order, or ask you to count/sum a field within each group.

---

# Topic 2: OOP, Inheritance and Abstract Base Classes

## Q1. Create an abstract shape class

**Question:** Define an abstract `Shape` with `area()`. Implement `Circle` and `Rectangle`.

**Solution:**

```python
from abc import ABC, abstractmethod
import math

class Shape(ABC):
    @abstractmethod
    def area(self):
        raise NotImplementedError

class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius

    def area(self):
        return math.pi * self.radius ** 2

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height

    def area(self):
        return self.width * self.height
```

`Shape()` raises `TypeError` because the abstract method has not been implemented.

## Q2. Enforce a payment interface

**Question:** Create an abstract `PaymentProcessor` with `pay(amount)`. Implement card and UPI processors.

**Solution:**

```python
from abc import ABC, abstractmethod

class PaymentProcessor(ABC):
    @abstractmethod
    def pay(self, amount):
        pass

class CardProcessor(PaymentProcessor):
    def pay(self, amount):
        return f"Card payment: {amount:.2f}"

class UpiProcessor(PaymentProcessor):
    def pay(self, amount):
        return f"UPI payment: {amount:.2f}"
```

**Why use an ABC?** It enforces a common interface so code using a processor can call `pay()` without checking the concrete class.

## Q3. Use inheritance with validation

**Question:** Create a base `User` class and an `Admin` subclass that adds a permission level.

**Solution:**

```python
class User:
    def __init__(self, user_id, name):
        if not name.strip():
            raise ValueError("name cannot be blank")
        self.user_id = user_id
        self.name = name.strip()

class Admin(User):
    def __init__(self, user_id, name, permission_level):
        super().__init__(user_id, name)
        self.permission_level = permission_level
```

`super()` reuses the base class initialization rather than duplicating it.

## Q4. Use composition instead of deep inheritance

**Question:** A `Report` should use a formatter. Implement a `JsonFormatter` and inject it into `Report`.

**Solution:**

```python
import json

class JsonFormatter:
    def format(self, data):
        return json.dumps(data, indent=2)

class Report:
    def __init__(self, formatter):
        self.formatter = formatter

    def render(self, data):
        return self.formatter.format(data)

report = Report(JsonFormatter())
```

**Key idea:** Composition means an object contains or uses another object. It often makes it easier to swap implementations and test behavior.

## Q5. Use a dataclass for structured records

**Question:** Define a `Product` record with `product_id`, `name` and `price`. Reject negative prices.

**Solution:**

```python
from dataclasses import dataclass

@dataclass
class Product:
    product_id: int
    name: str
    price: float

    def __post_init__(self):
        if self.price < 0:
            raise ValueError("price cannot be negative")
```

**Test angle:** Be ready to explain inheritance vs composition, abstract classes, overriding, `super()` and encapsulation.

---

# Topic 3: Generators and Memory-Efficient Processing

## Q1. Yield rows from a CSV file

**Question:** Read a large CSV without loading all rows into memory.

**Solution:**

```python
import csv

def read_rows(path):
    with open(path, newline="", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for row in reader:
            yield row

for row in read_rows("transactions.csv"):
    process(row)
```

A generator pauses at each `yield` and resumes when the next item is requested.

## Q2. Sum values by category in one pass

**Question:** Use the previous generator to calculate a sum and count per category.

**Solution:**

```python
from collections import defaultdict

summary = defaultdict(lambda: {"total": 0.0, "count": 0})

for row in read_rows("transactions.csv"):
    category = row["category"]
    amount = float(row["amount"])
    summary[category]["total"] += amount
    summary[category]["count"] += 1
```

Only the small summary dictionary is retained, not the entire input file.

## Q3. Create a generator pipeline

**Question:** From a list of raw strings, yield only non-empty normalized strings.

**Solution:**

```python
def normalize_lines(lines):
    for line in lines:
        cleaned = line.strip().lower()
        if cleaned:
            yield cleaned

lines = [" Alice ", "", " BOB "]
print(list(normalize_lines(lines)))
# ['alice', 'bob']
```

For a large file, pass the file iterator directly instead of first creating a list.

## Q4. Read a file in chunks

**Question:** Process a large file in fixed-size chunks.

**Solution:**

```python
def chunks(iterable, size):
    batch = []
    for item in iterable:
        batch.append(item)
        if len(batch) == size:
            yield batch
            batch = []
    if batch:
        yield batch

with open("large.txt", encoding="utf-8") as file:
    for batch in chunks(file, 500):
        process_batch(batch)
```

## Q5. Count errors per service from a streamed event source

**Question:** Count error events by service without keeping all events.

**Solution:**

```python
from collections import Counter

error_counts = Counter()

for event in read_rows("events.csv"):
    if event.get("level", "").upper() == "ERROR":
        error_counts[event["service"]] += 1
```

**Common traps:** Calling `list(generator)` defeats lazy processing; returning inside the loop stops after the first row; forgetting to convert numeric strings leads to string comparisons or concatenation.

---

# Topic 4: Regex, String Normalization and Sanitization

## Q1. Extract email addresses from text

**Question:** Extract all basic email-shaped values from a text string.

**Solution:**

```python
import re

text = "Contact a@example.com or support.team@example.org today."
emails = re.findall(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", text)
```

This is useful for practical extraction, but it is not a complete validator for every possible valid email address.

## Q2. Keep digits and convert a code to an integer

**Question:** Convert `"AB-12 034#"` to integer `12034`; return `None` if there are no digits.

**Solution:**

```python
import re

def clean_code(value):
    digits = re.sub(r"\D", "", str(value))
    return int(digits) if digits else None
```

If leading zeros are meaningful identifiers, return a string instead of an integer.

## Q3. Normalize phone numbers

**Question:** Convert different US phone formats to `+1XXXXXXXXXX` and return `None` for invalid lengths.

**Solution:**

```python
import re

def normalize_phone(raw):
    digits = re.sub(r"\D", "", str(raw))
    if len(digits) == 11 and digits.startswith("1"):
        digits = digits[1:]
    if len(digits) != 10:
        return None
    return "+1" + digits
```

## Q4. Parse structured application log lines

**Question:** Extract timestamp, level and service from a line such as `2026-10-12T09:30:00Z ERROR service=orders`.

**Solution:**

```python
import re

pattern = re.compile(
    r"^(?P<timestamp>\S+)\s+"
    r"(?P<level>DEBUG|INFO|WARNING|ERROR)\s+"
    r"service=(?P<service>[\w-]+)$"
)

match = pattern.match(line)
record = match.groupdict() if match else None
```

Named groups make the extracted fields easier to read.

## Q5. Extract index definitions from a SQL migration line

**Question:** Parse `CREATE UNIQUE INDEX uq_email ON customers (email, country_code);` into a dictionary.

**Solution:**

```python
import re

pattern = re.compile(
    r"CREATE\s+(?P<unique>UNIQUE\s+)?INDEX\s+"
    r"(?P<name>\w+)\s+ON\s+(?P<table>\w+)\s*"
    r"\((?P<columns>[^)]+)\)",
    re.IGNORECASE,
)

match = pattern.search(sql_line)
if match:
    result = {
        "index_name": match.group("name"),
        "table": match.group("table"),
        "columns": [c.strip() for c in match.group("columns").split(",")],
        "unique": bool(match.group("unique")),
    }
```

This targets the specified simple syntax. Regex is not a general SQL parser; quoted identifiers, nested expressions and comments may require more handling.

---

# Topic 5: Exceptions, Logging and Unit Testing

## Q1. Handle expected file errors separately

**Question:** Read a text file and log missing-file and permission errors separately.

**Solution:**

```python
import logging

logger = logging.getLogger(__name__)


def read_text(path):
    logger.debug("Reading file: %s", path)
    try:
        with open(path, encoding="utf-8") as file:
            content = file.read()
        logger.info("Read file successfully: %s", path)
        return content
    except FileNotFoundError:
        logger.warning("File does not exist: %s", path)
        raise
    except PermissionError:
        logger.error("Permission denied: %s", path)
        raise
```

## Q2. Parse JSON and handle malformed input

**Question:** Return a parsed JSON object and log invalid JSON separately from a missing file.

**Solution:**

```python
import json
import logging

logger = logging.getLogger(__name__)


def load_json(path):
    try:
        with open(path, encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        logger.exception("JSON file not found: %s", path)
        raise
    except json.JSONDecodeError:
        logger.exception("Invalid JSON in file: %s", path)
        raise
```

`logger.exception()` includes traceback information and should be called inside an exception handler.

## Q3. Validate a positive integer

**Question:** Accept positive integer values and reject booleans, zero, negatives and invalid strings.

**Solution:**

```python
def positive_int(value):
    if isinstance(value, bool):
        raise ValueError("boolean is not a valid quantity")

    try:
        number = int(value)
    except (TypeError, ValueError):
        raise ValueError("quantity must be an integer") from None

    if str(value).strip() not in {str(number), f"+{number}"} and not isinstance(value, int):
        raise ValueError("quantity must be a whole integer")
    if number <= 0:
        raise ValueError("quantity must be greater than zero")
    return number
```

The string check prevents values like `"2.5"` or `"2.0"` from being silently accepted through numeric conversion.

## Q4. Write unit tests with `unittest`

**Question:** Test the previous validation function.

**Solution:**

```python
import unittest

class TestPositiveInt(unittest.TestCase):
    def test_integer(self):
        self.assertEqual(positive_int(3), 3)

    def test_numeric_string(self):
        self.assertEqual(positive_int("4"), 4)

    def test_zero(self):
        with self.assertRaises(ValueError):
            positive_int(0)

    def test_negative(self):
        with self.assertRaises(ValueError):
            positive_int(-2)

    def test_boolean(self):
        with self.assertRaises(ValueError):
            positive_int(True)

    def test_decimal_string(self):
        with self.assertRaises(ValueError):
            positive_int("2.5")

if __name__ == "__main__":
    unittest.main()
```

## Q5. Separate pure logic from file I/O

**Question:** Refactor a function so that parsing can be tested without opening a real file.

**Solution:**

```python
import json


def parse_customer_json(raw_text):
    """Pure transformation: text in, Python data out."""
    data = json.loads(raw_text)
    if not isinstance(data, list):
        raise ValueError("expected a JSON array")
    return [row for row in data if row.get("customer_id")]


def load_customers(path):
    with open(path, encoding="utf-8") as file:
        return parse_customer_json(file.read())
```

Now `parse_customer_json()` can be tested with strings. Only `load_customers()` needs a filesystem test. The red-green-refactor cycle is: write a failing test, implement the smallest change that passes, then improve the design while keeping tests green.

---

# Topic 6: Pandas Cleaning and Categorical Normalization

Assume `import pandas as pd` for all questions in this topic.

## Q1. Convert a numeric column containing `"unknown"`

**Question:** Convert `age` to a numeric dtype and turn `"unknown"` into a missing value.

**Solution:**

```python
df["age"] = pd.to_numeric(df["age"], errors="coerce")
print(df["age"].dtype)
```

`errors="coerce"` converts invalid entries to `NaN` instead of raising an exception.

## Q2. Clean currency strings

**Question:** Convert values such as `"$1,250.50"`, `"800"` and `"unknown"` into numeric values.

**Solution:**

```python
df["salary"] = (
    df["salary"].astype("string")
      .str.replace(r"[$,]", "", regex=True)
)
df["salary"] = pd.to_numeric(df["salary"], errors="coerce")
```

## Q3. Normalize messy employment labels

**Question:** Map exact aliases into `EMPLOYEE`, `CONTRACTOR` or `OTHER`.

**Solution:**

```python
EMPLOYEE_VALUES = {"full-time", "fulltime", "full time", "ft", "employee"}
CONTRACTOR_VALUES = {"contractor", "contract", "freelance", "freelancer"}


def normalize_employment(value):
    if pd.isna(value):
        return "OTHER"

    cleaned = str(value).strip().lower()
    if not cleaned:
        return "OTHER"
    if cleaned in EMPLOYEE_VALUES:
        return "EMPLOYEE"
    if cleaned in CONTRACTOR_VALUES:
        return "CONTRACTOR"
    return "OTHER"


df["employment_type"] = df["employment_type_raw"].apply(normalize_employment)
print(df["employment_type"].value_counts(dropna=False))
```

Do not classify by broad substring when the requirement says exact matches. Values such as `"Full-time;Contractor"` should go to `OTHER` unless the specification says otherwise.

## Q4. Parse dates and remove invalid rows

**Question:** Convert `order_date` to datetime and drop invalid dates.

**Solution:**

```python
df["order_date"] = pd.to_datetime(df["order_date"], errors="coerce")
invalid_count = df["order_date"].isna().sum()
df = df.dropna(subset=["order_date"]).copy()
```

Log `invalid_count` before dropping rows if the assessment asks for an audit trail.

## Q5. Remove duplicate records using a business key

**Question:** Keep the most recent record for each `customer_id`.

**Solution:**

```python
df["updated_at"] = pd.to_datetime(df["updated_at"], errors="coerce")
df = df.sort_values("updated_at")
df = df.drop_duplicates(subset=["customer_id"], keep="last")
```

The sort determines which record counts as the latest. Do not assume the original row order is chronological unless the source guarantees it.

---

# Topic 7: Pandas Aggregation, Merges and Excel

## Q1. Calculate a percentage by group

**Question:** Calculate the percentage of respondents who work remotely by company size.

**Solution:**

```python
remote_pct = (
    df.assign(remote_flag=df["remote_work"].eq("Yes"))
      .groupby("company_size")["remote_flag"]
      .mean()
      .mul(100)
      .rename("remote_percentage")
      .reset_index()
)
```

A boolean column has `True`/`False` values, and its mean is the proportion of `True` rows.

## Q2. Produce a two-dimensional percentage report

**Question:** Show job satisfaction percentages by both continent and employment type.

**Solution:**

```python
report = pd.crosstab(
    [df["continent"], df["employment_type"]],
    df["job_satisfaction"],
    normalize="index",
).mul(100)
```

`normalize="index"` calculates percentages within each `(continent, employment_type)` row.

## Q3. Merge orders with products and calculate revenue

**Question:** Join orders to products, calculate line total and total revenue per customer.

**Solution:**

```python
merged = orders.merge(products, on="product_id", how="left", validate="many_to_one")
merged["line_total"] = merged["quantity"] * merged["unit_price"]

revenue = (
    merged.groupby("customer_id", as_index=False)["line_total"]
          .sum()
          .rename(columns={"line_total": "total_revenue"})
)
```

`validate="many_to_one"` catches an unexpected duplicate product key in the products table.

## Q4. Combine all sheets from an Excel workbook

**Question:** Combine sheets with different columns and record the sheet name for every row.

**Solution:**

```python
sheets = pd.read_excel("regional_operations.xlsx", sheet_name=None)
frames = []

for sheet_name, frame in sheets.items():
    frame = frame.copy()
    frame["source_sheet"] = sheet_name
    frames.append(frame)

combined = pd.concat(frames, ignore_index=True, sort=False)
combined.to_csv("regional_operations_combined.csv", index=False)
```

`pd.concat` aligns columns by name. Where a sheet does not contain a column present in another sheet, pandas fills that cell with a missing value.

## Q5. Group revenue by month and region

**Question:** Calculate revenue and order count per month and region.

**Solution:**

```python
orders["order_date"] = pd.to_datetime(orders["order_date"], errors="coerce")
orders["month"] = orders["order_date"].dt.to_period("M").astype("string")
orders["line_total"] = orders["quantity"] * orders["unit_price"]

monthly = (
    orders.groupby(["region", "month"], as_index=False)
          .agg(
              revenue=("line_total", "sum"),
              order_count=("order_id", "nunique"),
          )
)
```

**Test angle:** Be able to choose between `groupby`, `agg`, `transform`, `pivot_table` and `crosstab`. Know whether a percentage denominator should be a whole dataset or each group.

---

# Topic 8: ETL, SQLAlchemy and Idempotency

The examples use SQLAlchemy 2-style execution. The database connection string should come from configuration or environment variables in real work.

## Q1. Extract a CSV and JSON source separately

**Question:** Read a customer CSV and an order JSON file without changing the source records.

**Solution:**

```python
import csv
import json


def extract(customers_path, orders_path):
    with open(customers_path, newline="", encoding="utf-8") as file:
        customers = list(csv.DictReader(file))

    with open(orders_path, encoding="utf-8") as file:
        orders = json.load(file)

    return customers, orders
```

This is extraction only. Cleaning and validation should happen in the transform stage.

## Q2. Clean invalid order amounts

**Question:** Drop rows with missing customer IDs or non-numeric/negative amounts.

**Solution:**

```python
import pandas as pd


def clean_orders(orders):
    df = pd.DataFrame(orders).copy()
    original_count = len(df)

    df["amount"] = pd.to_numeric(df["amount"], errors="coerce")
    df["customer_id"] = df["customer_id"].astype("string").str.strip()

    valid = (
        df["customer_id"].notna()
        & df["customer_id"].ne("")
        & df["amount"].notna()
        & df["amount"].ge(0)
    )

    cleaned = df.loc[valid].copy()
    rejected_count = original_count - len(cleaned)
    return cleaned, rejected_count
```

## Q3. Enrich customers from a lookup table

**Question:** Add `region_name` using a `country_code` lookup.

**Solution:**

```python
customers_df = pd.DataFrame(customers)
regions_df = pd.read_csv("country_regions.csv")

enriched = customers_df.merge(
    regions_df,
    on="country_code",
    how="left",
    validate="many_to_one",
)

unmatched = enriched["region_name"].isna()
if unmatched.any():
    missing_codes = enriched.loc[unmatched, "country_code"].unique().tolist()
    raise ValueError(f"No region mapping for: {missing_codes}")
```

A left join preserves every customer and makes missing mappings visible. An inner join could silently drop customers without a lookup match.

## Q4. Load rows with an idempotent upsert

**Question:** Insert or update orders by `order_id` so that rerunning the load does not create duplicates.

**Solution (MySQL):**

```python
from sqlalchemy import text

create_sql = text("""
    CREATE TABLE IF NOT EXISTS clean_orders (
        order_id INT PRIMARY KEY,
        customer_id INT NOT NULL,
        amount DECIMAL(12, 2) NOT NULL
    )
""")

upsert_sql = text("""
    INSERT INTO clean_orders (order_id, customer_id, amount)
    VALUES (:order_id, :customer_id, :amount)
    ON DUPLICATE KEY UPDATE
        customer_id = VALUES(customer_id),
        amount = VALUES(amount)
""")

with engine.begin() as connection:
    connection.execute(create_sql)
    connection.execute(upsert_sql, records)
```

`engine.begin()` manages a transaction and commits on success. The primary key enforces the uniqueness of `order_id`.

## Q5. Read back and validate the load

**Question:** Read the loaded table back and compare its row count and a known record.

**Solution:**

```python
import pandas as pd

with engine.connect() as connection:
    loaded = pd.read_sql(text("SELECT * FROM clean_orders"), connection)

assert len(loaded) == len(records)

check = loaded.loc[loaded["order_id"] == 101]
assert len(check) == 1
assert float(check.iloc[0]["amount"]) == 250.00
```

Compare meaningful values, not a DataFrame to itself. For more robust systems, validate keys, nullability, totals and duplicate counts too.

---

# Topic 9: Flask REST API, ORM and Mocked Tests

This topic is a medium-confidence prediction because Flask, MVC, ORM and mocked service tests are explicit Week 3 training tasks, but neither supplied Python test assessed them.

## Q1. Create a minimal Flask health endpoint

**Question:** Build a Flask app with `GET /health` returning JSON status.

**Solution:**

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200
```

## Q2. Validate a product creation request

**Question:** Accept JSON with name, unit price and stock quantity. Reject invalid data.

**Solution:**

```python
from flask import request, jsonify

@app.post("/api/products")
def create_product():
    payload = request.get_json(silent=True) or {}

    name = payload.get("name")
    price = payload.get("unit_price")
    stock = payload.get("stock_quantity")

    errors = {}
    if not isinstance(name, str) or not name.strip():
        errors["name"] = "A non-empty name is required."
    if isinstance(price, bool) or not isinstance(price, (int, float)) or price < 0:
        errors["unit_price"] = "Price must be a non-negative number."
    if isinstance(stock, bool) or not isinstance(stock, int) or stock < 0:
        errors["stock_quantity"] = "Stock must be a non-negative integer."

    if errors:
        return jsonify({"errors": errors}), 400

    # Call a service/repository here in a real MVC application.
    return jsonify({"name": name.strip(), "unit_price": price,
                    "stock_quantity": stock}), 201
```

## Q3. Separate route and repository responsibilities

**Question:** Sketch a repository method for retrieving a product by ID and call it from a route.

**Solution:**

```python
class ProductRepository:
    def __init__(self, session):
        self.session = session

    def get_by_id(self, product_id):
        return self.session.get(Product, product_id)


from flask import current_app

@app.get("/api/products/<int:product_id>")
def get_product(product_id):
    repository = current_app.config["PRODUCT_REPOSITORY"]
    product = repository.get_by_id(product_id)
    if product is None:
        return jsonify({"error": "Product not found"}), 404
    return jsonify({"id": product.id, "name": product.name}), 200
```

The route handles HTTP concerns; the repository handles database access. In a larger application, a service layer can contain business rules between them.

## Q4. Test a route without a real database

**Question:** Mock the repository so a `GET` route can be tested independently.

**Solution:**

```python
from unittest.mock import Mock


def test_get_product_found(app):
    fake_product = Mock(id=7, name="Keyboard")
    app.config["PRODUCT_REPOSITORY"] = Mock()
    app.config["PRODUCT_REPOSITORY"].get_by_id.return_value = fake_product

    client = app.test_client()
    response = client.get("/api/products/7")

    assert response.status_code == 200
    assert response.get_json()["name"] == "Keyboard"
```

The example assumes the route gets the repository from app configuration. Injecting dependencies makes the route easier to test.

## Q5. Explain the deployment components

**Question:** Explain a basic AWS deployment path for a Flask REST API using API Gateway, Lambda and CloudWatch.

**Solution:**

- API Gateway exposes HTTP routes and forwards requests to the Lambda integration.
- Lambda runs the application handler code for each invocation; an adapter may be needed to bridge the WSGI Flask application and Lambda event format.
- The persistence layer is accessed by the application using the selected database or storage service and appropriate credentials/secrets.
- CloudWatch Logs collects application and runtime logs. Log useful request IDs and errors, but never passwords or sensitive payloads.

The key assessment point is understanding the role of each component. Do not claim that simply uploading a Flask folder to Lambda automatically makes it work; packaging and a compatible handler/adapter are required.

---

# Final revision checklist

Before the next test, make sure you can do each of these without copying a tutorial:

- [ ] Write a function with clear inputs, outputs and edge-case behavior.
- [ ] Explain why a set, dictionary, list, generator or DataFrame is appropriate.
- [ ] Use `yield` to process a large file incrementally.
- [ ] Parse structured text with a named-group regex.
- [ ] Normalize strings using exact mapping rules and a catch-all category.
- [ ] Convert dirty numeric/date columns with `errors="coerce"` and count rejected rows.
- [ ] Calculate percentages at the correct grouping level.
- [ ] Merge DataFrames and validate expected join cardinality.
- [ ] Combine Excel sheets without hardcoding their names.
- [ ] Build an ETL sequence that returns data from one stage to the next.
- [ ] Load data transactionally and make reruns safe.
- [ ] Read database records back and assert real values.
- [ ] Use specific exceptions, logging and unit tests.
- [ ] Explain how Flask routes, services, repositories and ORM models fit together.

## Recommended order of practice

1. Finish Topics 6, 7 and 8 first. These cover the biggest weaknesses exposed by the previous assessments.
2. Practise Topics 3, 4 and 5 next. They address generators, regex, normalization and production-quality code.
3. Revise Topics 1 and 2 to improve speed on smaller questions.
4. Finish with Topic 9 because it is a plausible Week 3 assessment area, but less strongly predicted from the two actual test papers.
