# DAY 2 PYTHON TEST — FINAL MASTER QUESTION BANK

## How to use this file

- Day 1 already tested the same versions of deduplication, ABC, `map()`/lambda, generators, regex index extraction, custom encoding, phone normalization, sanitization, logging, basic TDD theory, dtype fixing, grouped reporting, employment normalization, satisfaction grouping, Excel combining, and orders/products merging.
- This file focuses on the **remaining PDF work** and **Test-2 Docker/MySQL ETL variations**.
- Predictions are inferred from the supplied assignment and Test-2 setup. They are not claims about the exact unseen exam.
- The strongest areas are marked `HIGH`.

---

# TOPIC 1 — PYTHON + DOCKER MYSQL

## Q1. Connect Python to the Test-2 MySQL Docker database — HIGH

```python
import pymysql

conn = pymysql.connect(
    host="localhost",
    port=3307,
    user="root",
    password="InternTest_2026!"
)

print("Connected")
conn.close()
```

## Q2. Connect to a named database

```python
conn = pymysql.connect(
    host="localhost",
    port=3307,
    user="root",
    password="InternTest_2026!",
    database="test_db"
)
```

## Q3. Execute a SELECT query

```python
cursor = conn.cursor()

cursor.execute("SELECT * FROM customers")

rows = cursor.fetchall()

for row in rows:
    print(row)
```

## Q4. Read rows without storing the full result

```python
cursor.execute("SELECT * FROM customers")

for row in cursor:
    print(row)
```

## Q5. Get one row

```python
cursor.execute(
    "SELECT * FROM customers LIMIT 1"
)

row = cursor.fetchone()

print(row)
```

## Q6. Get the number of rows

```python
cursor.execute(
    "SELECT COUNT(*) FROM customers"
)

count = cursor.fetchone()[0]

print(count)
```

## Q7. Run a parameterized SELECT — HIGH

```python
customer_id = 5

cursor.execute(
    """
    SELECT *
    FROM customers
    WHERE customer_id = %s
    """,
    (customer_id,)
)

print(cursor.fetchall())
```

## Q8. Insert one record

```python
cursor.execute(
    """
    INSERT INTO customers(customer_name, email)
    VALUES (%s, %s)
    """,
    ("John", "john@gmail.com")
)

conn.commit()
```

## Q9. Insert many records — HIGH

```python
rows = [
    ("A", "a@gmail.com"),
    ("B", "b@gmail.com"),
    ("C", "c@gmail.com")
]

cursor.executemany(
    """
    INSERT INTO customers(customer_name, email)
    VALUES (%s, %s)
    """,
    rows
)

conn.commit()
```

## Q10. Safely update/delete with rollback

```python
try:
    cursor.execute(
        """
        UPDATE customers
        SET email = %s
        WHERE customer_id = %s
        """,
        ("new@gmail.com", 5)
    )

    conn.commit()

except Exception:
    conn.rollback()
    raise
```

### Must know for Topic 1

```text
pymysql.connect()
cursor()
execute()
executemany()
fetchone()
fetchall()
commit()
rollback()
close()
parameterized SQL
```

---

# TOPIC 2 — JSON → MYSQL → PANDAS

The PDF specifically asks for JSON with `cols` and `data`, loading into MySQL table `json_to_sql_table`, then unloading it into Pandas and transforming email, `postalZip`, and `phone`.

## Q11. Load JSON — PDF task continuation — HIGH

```python
import json

with open(
    "sample_data_for_assignment.json",
    encoding="utf-8"
) as file:
    data = json.load(file)

print(data)
```

## Q12. Extract `cols` and `data`

```python
columns = data["cols"]
rows = data["data"]

print(columns)
print(rows)
```

## Q13. Convert JSON rows to DataFrame — HIGH

```python
import pandas as pd

df = pd.DataFrame(
    rows,
    columns=columns
)

print(df)
```

## Q14. Create placeholders dynamically

```python
placeholders = ", ".join(
    ["%s"] * len(columns)
)

print(placeholders)
```

## Q15. Insert all JSON rows into MySQL — HIGH

```python
query = f"""
INSERT INTO json_to_sql_table
({", ".join(columns)})
VALUES ({placeholders})
"""

cursor.executemany(
    query,
    rows
)

conn.commit()
```

## Q16. Load MySQL table into Pandas — HIGH

```python
df = pd.read_sql(
    "SELECT * FROM json_to_sql_table",
    conn
)

print(df)
```

## Q17. Display all rows and columns

```python
print(df)
print(df.columns)
print(df.shape)
```

## Q18. Change every email to `@gmail.com` — PDF task — HIGH

```python
df["email"] = (
    df["email"]
    .astype(str)
    .str.split("@")
    .str[0]
    + "@gmail.com"
)
```

## Q19. Clean `postalZip` — PDF task — HIGH

```python
import re

def clean_postal(value):
    digits = re.sub(
        r"\D",
        "",
        str(value)
    )

    if digits:
        return int(digits)

    return None

df["postalZip"] = df["postalZip"].apply(
    clean_postal
)
```

## Q20. Phone to ASCII code and rename column — PDF task — HIGH

```python
def encode_phone(phone):
    digits = re.sub(
        r"\D",
        "",
        str(phone)
    )

    result = []

    for i in range(
        0,
        len(digits) - 1,
        2
    ):
        value = int(
            digits[i:i + 2]
        )

        if value < 65:
            result.append("O")
        else:
            result.append(chr(value))

    return "".join(result)

df["phone"] = df["phone"].apply(
    encode_phone
)

df = df.rename(
    columns={
        "phone": "coded_phone_number"
    }
)
```

## Q21. Count missing values

```python
print(df.isna().sum())
```

## Q22. Find the rows with missing email

```python
print(
    df[df["email"].isna()]
)
```

## Q23. Convert a numeric column safely

```python
df["amount"] = pd.to_numeric(
    df["amount"],
    errors="coerce"
)
```

## Q24. Save cleaned DataFrame

```python
df.to_csv(
    "cleaned_output.csv",
    index=False
)
```

## Q25. Load cleaned DataFrame back into SQL

```python
df.to_sql(
    "json_cleaned",
    conn,
    if_exists="append",
    index=False
)
```

## Q26. Verify SQL and DataFrame row counts

```python
cursor.execute(
    "SELECT COUNT(*) FROM json_to_sql_table"
)

sql_count = cursor.fetchone()[0]

pandas_count = len(df)

print(sql_count)
print(pandas_count)
```

## Q27. Build one reusable JSON-to-MySQL function

```python
def load_json_to_mysql(
    file_path,
    connection
):
    with open(
        file_path,
        encoding="utf-8"
    ) as file:
        data = json.load(file)

    columns = data["cols"]
    rows = data["data"]

    placeholders = ", ".join(
        ["%s"] * len(columns)
    )

    query = f"""
    INSERT INTO json_to_sql_table
    ({", ".join(columns)})
    VALUES ({placeholders})
    """

    cursor = connection.cursor()

    cursor.executemany(
        query,
        rows
    )

    connection.commit()
```

## Q28. Use a transaction for the JSON load

```python
try:
    cursor.executemany(
        query,
        rows
    )
    conn.commit()

except Exception:
    conn.rollback()
    raise
```

## Q29. Read only required fields from MySQL

```python
df = pd.read_sql(
    """
    SELECT email, postalZip, phone
    FROM json_to_sql_table
    """,
    conn
)
```

## Q30. Complete JSON ETL chain — VERY HIGH

```python
with open(
    "sample_data_for_assignment.json",
    encoding="utf-8"
) as file:
    data = json.load(file)

df = pd.DataFrame(
    data["data"],
    columns=data["cols"]
)

df["email"] = (
    df["email"]
    .astype(str)
    .str.split("@")
    .str[0]
    + "@gmail.com"
)

df["postalZip"] = df["postalZip"].apply(
    clean_postal
)

df["phone"] = df["phone"].apply(
    encode_phone
)

df = df.rename(
    columns={
        "phone": "coded_phone_number"
    }
)

df.to_csv(
    "final_output.csv",
    index=False
)
```

---

# TOPIC 3 — STACK OVERFLOW 2019 ETL

The PDF requires six reports from the Stack Overflow 2019 survey.

## Q31. Average age when first code was written — PDF task — HIGH

```python
df["Age1stCode"] = pd.to_numeric(
    df["Age1stCode"],
    errors="coerce"
)

print(
    df["Age1stCode"].mean()
)
```

## Q32. Python developers as a percentage of each country — PDF task — VERY HIGH

```python
python_flag = (
    df["LanguageWorkedWith"]
    .fillna("")
    .str.contains(
        "Python",
        regex=False
    )
)

result = (
    df.assign(
        knows_python=python_flag
    )
    .groupby("Country")["knows_python"]
    .mean()
    .mul(100)
    .reset_index(
        name="python_percentage"
    )
)

print(result)
```

## Q33. Average salary by continent — PDF task — HIGH

```python
df["salary"] = pd.to_numeric(
    df["salary"],
    errors="coerce"
)

result = (
    df.groupby("continent")["salary"]
    .mean()
    .reset_index(
        name="average_salary"
    )
)

print(result)
```

## Q34. Find most desired programming language — PDF task — VERY HIGH

```python
counts = (
    df["LanguageDesireNextYear"]
    .dropna()
    .str.split(";")
    .explode()
    .value_counts()
)

print(counts)
print(counts.index[0])
```

## Q35. Count desired languages by country

```python
temp = (
    df[["Country", "LanguageDesireNextYear"]]
    .dropna()
    .assign(
        language=lambda x:
        x["LanguageDesireNextYear"]
        .str.split(";")
    )
    .explode("language")
)

result = (
    temp.groupby(
        ["Country", "language"]
    )
    .size()
    .reset_index(name="count")
)

print(result)
```

## Q36. Normalize survey gender to MAN/WOMAN/OTHERS — PDF task — HIGH

```python
def normalize_gender(value):
    value = str(value).strip().lower()

    if value == "man":
        return "MAN"

    if value == "woman":
        return "WOMAN"

    return "OTHERS"

df["gender_normalized"] = df[
    "gender"
].apply(normalize_gender)
```

## Q37. Hobby coding by gender and continent — PDF task — HIGH

```python
df["hobby_flag"] = df["Hobby"].eq(
    "Yes"
)

result = (
    df.groupby(
        [
            "gender_normalized",
            "continent"
        ]
    )["hobby_flag"]
    .mean()
    .mul(100)
    .reset_index(
        name="percentage"
    )
)

print(result)
```

## Q38. Job satisfaction by gender and continent — PDF task — HIGH

```python
result = (
    df.groupby(
        [
            "gender_normalized",
            "continent"
        ]
    )["JobSat"]
    .mean()
    .reset_index(
        name="average_job_satisfaction"
    )
)

print(result)
```

## Q39. Career satisfaction by gender and continent — predicted variant

```python
result = (
    df.groupby(
        [
            "gender_normalized",
            "continent"
        ]
    )["CareerSat"]
    .mean()
    .reset_index(
        name="average_career_satisfaction"
    )
)

print(result)
```

## Q40. Percentage of Python users by continent — HIGH

```python
python_flag = (
    df["LanguageWorkedWith"]
    .fillna("")
    .str.contains(
        "Python",
        regex=False
    )
)

result = (
    df.assign(
        python_flag=python_flag
    )
    .groupby("continent")["python_flag"]
    .mean()
    .mul(100)
    .reset_index(
        name="python_percentage"
    )
)

print(result)
```

## Q41. Top five desired languages

```python
top5 = (
    df["LanguageDesireNextYear"]
    .dropna()
    .str.split(";")
    .explode()
    .value_counts()
    .head(5)
)

print(top5)
```

## Q42. Salary median by continent

```python
result = (
    df.groupby("continent")["salary"]
    .median()
    .reset_index(
        name="median_salary"
    )
)

print(result)
```

## Q43. Salary count by continent

```python
result = (
    df.groupby("continent")["salary"]
    .count()
    .reset_index(
        name="salary_count"
    )
)

print(result)
```

## Q44. Sort the salary report

```python
result = result.sort_values(
    "average_salary",
    ascending=False
)

print(result)
```

## Q45. Filter only respondents who code as hobby

```python
hobby_df = df[
    df["Hobby"].eq("Yes")
]

print(hobby_df)
```

## Q46. Count hobby coders by continent

```python
result = (
    df[df["Hobby"].eq("Yes")]
    .groupby("continent")
    .size()
    .reset_index(
        name="hobby_coders"
    )
)

print(result)
```

## Q47. Calculate country-level total and Python count

```python
python_flag = (
    df["LanguageWorkedWith"]
    .fillna("")
    .str.contains(
        "Python",
        regex=False
    )
)

result = (
    df.assign(
        python_flag=python_flag
    )
    .groupby("Country")
    .agg(
        total=("python_flag", "size"),
        python_users=("python_flag", "sum")
    )
    .reset_index()
)

result["percentage"] = (
    result["python_users"]
    / result["total"]
    * 100
)

print(result)
```

## Q48. Build all survey reports in one pipeline — VERY HIGH

```python
df["Age1stCode"] = pd.to_numeric(
    df["Age1stCode"],
    errors="coerce"
)

df["salary"] = pd.to_numeric(
    df["salary"],
    errors="coerce"
)

df["gender_normalized"] = df[
    "gender"
].apply(normalize_gender)

salary_report = (
    df.groupby("continent")["salary"]
    .mean()
    .reset_index()
)

python_report = (
    df.assign(
        python_flag=
        df["LanguageWorkedWith"]
        .fillna("")
        .str.contains(
            "Python",
            regex=False
        )
    )
    .groupby("Country")["python_flag"]
    .mean()
    .mul(100)
    .reset_index()
)

language_report = (
    df["LanguageDesireNextYear"]
    .dropna()
    .str.split(";")
    .explode()
    .value_counts()
)

print(salary_report)
print(python_report)
print(language_report)
```

---

# TOPIC 4 — XLSX → CSV

The PDF requires every sheet to be converted, with no hardcoded sheet names or sheet count.

## Q49. Read all sheets — PDF task — HIGH

```python
import pandas as pd

sheets = pd.read_excel(
    "Sample_Data.xlsx",
    sheet_name=None
)

print(sheets.keys())
```

## Q50. Convert every sheet to a CSV — PDF task — HIGH

```python
from pathlib import Path

output_dir = Path(
    "Sample_Data"
)

output_dir.mkdir(
    parents=True,
    exist_ok=True
)

for sheet_name, frame in sheets.items():
    frame.to_csv(
        output_dir /
        f"{sheet_name}.csv",
        index=False
    )
```

## Q51. Do not hardcode sheet names

```python
for sheet_name in sheets:
    print(sheet_name)
```

## Q52. Create output directory from input filename

```python
from pathlib import Path

input_file = Path(
    "Sample_Data.xlsx"
)

output_dir = input_file.with_suffix("")

output_dir.mkdir(
    exist_ok=True
)
```

## Q53. Convert sheets one by one

```python
for sheet_name, frame in pd.read_excel(
    "Sample_Data.xlsx",
    sheet_name=None
).items():

    frame.to_csv(
        f"{sheet_name}.csv",
        index=False
    )
```

## Q54. Add source sheet column

```python
result = []

for sheet_name, frame in sheets.items():
    frame = frame.copy()

    frame["source_sheet"] = (
        sheet_name
    )

    result.append(frame)
```

## Q55. Combine sheets with different columns

```python
combined = pd.concat(
    result,
    ignore_index=True,
    sort=False
)

print(combined)
```

## Q56. Save combined result

```python
combined.to_csv(
    "combined.csv",
    index=False
)
```

## Q57. Accept the XLSX path from CLI

```python
import argparse

parser = argparse.ArgumentParser()

parser.add_argument(
    "input_file"
)

args = parser.parse_args()

print(args.input_file)
```

## Q58. Complete XLSX converter

```python
from pathlib import Path
import pandas as pd

def convert_xlsx(input_file):
    input_path = Path(input_file)

    output_dir = input_path.with_suffix("")

    output_dir.mkdir(
        parents=True,
        exist_ok=True
    )

    sheets = pd.read_excel(
        input_path,
        sheet_name=None
    )

    for sheet_name, frame in sheets.items():
        frame.to_csv(
            output_dir /
            f"{sheet_name}.csv",
            index=False
        )

convert_xlsx(
    "Sample_Data.xlsx"
)
```

---

# TOPIC 5 — SQL FILE INFORMATION EXTRACTION WITH REGEX

The PDF asks for a Python script that accepts a SQL file and writes a JSON result, using regex.

## Q59. Read SQL text — PDF task — HIGH

```python
with open(
    "sample_stored_procedure.sql",
    encoding="utf-8"
) as file:
    sql = file.read()
```

## Q60. Find procedure names — HIGH

```python
import re

matches = re.findall(
    r"CREATE\s+PROCEDURE\s+(\w+)",
    sql,
    flags=re.IGNORECASE
)

print(matches)
```

## Q61. Find CREATE FUNCTION statements

```python
matches = re.findall(
    r"CREATE\s+FUNCTION\s+(\w+)",
    sql,
    flags=re.IGNORECASE
)

print(matches)
```

## Q62. Find table names after INSERT INTO

```python
tables = re.findall(
    r"INSERT\s+INTO\s+(\w+)",
    sql,
    flags=re.IGNORECASE
)

print(tables)
```

## Q63. Find table names after FROM

```python
tables = re.findall(
    r"\bFROM\s+(\w+)",
    sql,
    flags=re.IGNORECASE
)

print(tables)
```

## Q64. Extract procedure name and parameter text

```python
pattern = (
    r"CREATE\s+PROCEDURE\s+"
    r"(\w+)\s*\((.*?)\)"
)

matches = re.findall(
    pattern,
    sql,
    flags=re.IGNORECASE |
    re.DOTALL
)

print(matches)
```

## Q65. Convert regex result to dictionaries

```python
result = []

for name, params in matches:
    result.append(
        {
            "name": name,
            "parameters": params
        }
    )

print(result)
```

## Q66. Write JSON output — PDF task

```python
import json

with open(
    "sample_stored_procedure.json",
    "w",
    encoding="utf-8"
) as file:
    json.dump(
        result,
        file,
        indent=4
    )
```

## Q67. Accept SQL filename from CLI

```python
import argparse

parser = argparse.ArgumentParser()

parser.add_argument(
    "sql_file"
)

args = parser.parse_args()

print(args.sql_file)
```

## Q68. Complete SQL extraction script — HIGH

```python
import argparse
import json
import re

parser = argparse.ArgumentParser()

parser.add_argument(
    "sql_file"
)

args = parser.parse_args()

with open(
    args.sql_file,
    encoding="utf-8"
) as file:
    sql = file.read()

matches = re.findall(
    r"CREATE\s+PROCEDURE\s+(\w+)",
    sql,
    flags=re.IGNORECASE
)

result = {
    "procedures": matches
}

with open(
    "sample_stored_procedure.json",
    "w",
    encoding="utf-8"
) as file:
    json.dump(
        result,
        file,
        indent=4
    )
```

---

# TOPIC 6 — HTML + CLI + FILE PROCESSING

The PDF requires `anti_html.py`: URL argument → download HTML → remove HTML tags → print cleaned text.

## Q69. Download HTML — PDF task — HIGH

```python
from urllib.request import urlopen

url = "https://example.com"

with urlopen(url) as response:
    html = response.read().decode(
        "utf-8",
        errors="ignore"
    )

print(html)
```

## Q70. Strip HTML tags with `HTMLParser` — HIGH

```python
from html.parser import HTMLParser

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)

parser = TextExtractor()

parser.feed(
    "<html><body>Hello <b>world</b></body></html>"
)

print(" ".join(parser.parts))
```

## Q71. Combine URL download and HTML stripping — PDF task

```python
from html.parser import HTMLParser
from urllib.request import urlopen

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)

url = "https://example.com"

with urlopen(url) as response:
    html = response.read().decode(
        "utf-8",
        errors="ignore"
    )

parser = TextExtractor()
parser.feed(html)

print(
    " ".join(parser.parts)
)
```

## Q72. Use `argparse` for URL

```python
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("url")

args = parser.parse_args()

print(args.url)
```

## Q73. Handle URL errors

```python
from urllib.error import URLError
from urllib.request import urlopen

def download(url):
    try:
        with urlopen(url) as response:
            return response.read().decode(
                "utf-8",
                errors="ignore"
            )
    except URLError:
        return ""
```

## Q74. Save cleaned HTML text

```python
with open(
    "output.txt",
    "w",
    encoding="utf-8"
) as file:
    file.write(cleaned_text)
```

## Q75. Count links in HTML

```python
from html.parser import HTMLParser

class LinkCounter(HTMLParser):
    def __init__(self):
        super().__init__()
        self.count = 0

    def handle_starttag(
        self,
        tag,
        attrs
    ):
        if tag == "a":
            self.count += 1

parser = LinkCounter()
parser.feed(html)

print(parser.count)
```

## Q76. Read a text file line by line

```python
with open(
    "input.txt",
    encoding="utf-8"
) as file:

    for line in file:
        print(line.strip())
```

## Q77. Count error lines

```python
count = 0

with open(
    "app.log",
    encoding="utf-8"
) as file:

    for line in file:
        if "ERROR" in line:
            count += 1

print(count)
```

## Q78. Write CLI output to a file

```python
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("input_file")
parser.add_argument("output_file")

args = parser.parse_args()

with open(
    args.input_file,
    encoding="utf-8"
) as source:
    text = source.read()

with open(
    args.output_file,
    "w",
    encoding="utf-8"
) as target:
    target.write(text)
```

---

# TOPIC 7 — FLASK REST API

The PDF requires customer, product, and order INSERT/UPDATE/SELECT operations plus customer order history.

## Q79. Create Flask app

```python
from flask import Flask

app = Flask(__name__)

if __name__ == "__main__":
    app.run()
```

## Q80. GET all customers — HIGH

```python
from flask import jsonify

@app.get("/customers")
def get_customers():
    return jsonify([]), 200
```

## Q81. GET one customer

```python
@app.get("/customers/<int:customer_id>")
def get_customer(customer_id):
    return jsonify(
        {
            "customer_id": customer_id
        }
    ), 200
```

## Q82. POST a customer with validation — HIGH

```python
from flask import request, jsonify

@app.post("/customers")
def create_customer():
    data = request.get_json()

    if not data:
        return jsonify(
            {"error": "JSON body required"}
        ), 400

    if not data.get("name"):
        return jsonify(
            {"error": "name is required"}
        ), 400

    return jsonify(data), 201
```

## Q83. PUT/update customer

```python
@app.put("/customers/<int:customer_id>")
def update_customer(customer_id):
    data = request.get_json()

    if not data:
        return jsonify(
            {"error": "JSON body required"}
        ), 400

    return jsonify(
        {
            "customer_id": customer_id,
            "data": data
        }
    ), 200
```

## Q84. Return 404 when customer is missing

```python
customer = find_customer(
    customer_id
)

if customer is None:
    return jsonify(
        {"error": "customer not found"}
    ), 404
```

## Q85. Delete a customer

```python
@app.delete(
    "/customers/<int:customer_id>"
)
def delete_customer(customer_id):
    delete_customer_from_db(
        customer_id
    )

    return jsonify(
        {"deleted": customer_id}
    ), 200
```

## Q86. Product endpoint

```python
@app.get("/products")
def get_products():
    products = get_all_products()

    return jsonify(products), 200
```

## Q87. Order endpoint

```python
@app.get("/orders")
def get_orders():
    orders = get_all_orders()

    return jsonify(orders), 200
```

## Q88. Customer order history — PDF task — VERY HIGH

```python
@app.get(
    "/customers/<int:customer_id>/orders"
)
def customer_order_history(
    customer_id
):
    orders = get_orders_for_customer(
        customer_id
    )

    return jsonify(orders), 200
```

## Q89. Return 201 for successful creation

```python
@app.post("/products")
def create_product():
    data = request.get_json()

    product = save_product(data)

    return jsonify(product), 201
```

## Q90. Test request data validation

```python
data = request.get_json()

required = [
    "name",
    "email"
]

for field in required:
    if not data.get(field):
        return jsonify(
            {
                "error":
                f"{field} is required"
            }
        ), 400
```

---

# TOPIC 8 — PYTEST / TDD / MOCKING

The PDF requires unit tests and mocking external service calls.

## Q91. Basic function test

```python
def add(a, b):
    return a + b

def test_add():
    assert add(2, 3) == 5
```

## Q92. Test multiple inputs

```python
import pytest

@pytest.mark.parametrize(
    "a,b,expected",
    [
        (1, 2, 3),
        (5, 5, 10),
        (10, 20, 30)
    ]
)
def test_add(a, b, expected):
    assert add(a, b) == expected
```

## Q93. Test expected exception

```python
import pytest

def divide(a, b):
    return a / b

def test_zero_division():
    with pytest.raises(
        ZeroDivisionError
    ):
        divide(10, 0)
```

## Q94. Fixture

```python
import pytest

@pytest.fixture
def sample_data():
    return [1, 2, 3]

def test_length(sample_data):
    assert len(sample_data) == 3
```

## Q95. Mock an external service — HIGH

```python
from unittest.mock import patch

@patch("__main__.external_service")
def test_external_service(
    mock_service
):
    mock_service.return_value = {
        "status": "ok"
    }

    result = external_service()

    assert result["status"] == "ok"

    mock_service.assert_called_once()
```

## Q96. Test Flask GET endpoint

```python
def test_get_customers():
    app.testing = True

    client = app.test_client()

    response = client.get(
        "/customers"
    )

    assert response.status_code == 200
```

## Q97. Test Flask POST validation

```python
def test_missing_name():
    app.testing = True

    client = app.test_client()

    response = client.post(
        "/customers",
        json={
            "email": "a@gmail.com"
        }
    )

    assert response.status_code == 400
```

## Q98. Mock the database/service layer

```python
from unittest.mock import patch

@patch("app.get_all_customers")
def test_customers(mock_get):
    mock_get.return_value = [
        {
            "id": 1,
            "name": "John"
        }
    ]

    response = client.get(
        "/customers"
    )

    assert response.status_code == 200
    mock_get.assert_called_once()
```

## Q99. Test 404

```python
def test_customer_not_found():
    response = client.get(
        "/customers/9999"
    )

    assert response.status_code == 404
```

## Q100. Run tests from PowerShell

```powershell
pytest -v
```

Useful:

```powershell
pytest
pytest -q
pytest -x
pytest test_file.py
pytest test_file.py::test_add
```

---

# TOPIC 9 — NOTEPAD TRACKER + GIT

The PDF requires a Flask note editor, saving files to any directory, and committing changes with Git after writing stops.

## Q101. Save note text

```python
from pathlib import Path

def save_note(path, content):
    Path(path).write_text(
        content,
        encoding="utf-8"
    )
```

## Q102. Read note text

```python
from pathlib import Path

def read_note(path):
    return Path(path).read_text(
        encoding="utf-8"
    )
```

## Q103. Check whether file exists

```python
from pathlib import Path

path = Path("notes.txt")

print(path.exists())
```

## Q104. Create parent directories

```python
from pathlib import Path

path = Path(
    "notes/project/day1.txt"
)

path.parent.mkdir(
    parents=True,
    exist_ok=True
)
```

## Q105. Run `git add` from Python

```python
import subprocess

subprocess.run(
    ["git", "add", "notes.txt"],
    check=True
)
```

## Q106. Run `git commit` from Python

```python
subprocess.run(
    [
        "git",
        "commit",
        "-m",
        "Update note"
    ],
    check=True
)
```

## Q107. Save and commit a note — HIGH

```python
def save_and_commit(
    path,
    content
):
    save_note(
        path,
        content
    )

    subprocess.run(
        ["git", "add", path],
        check=True
    )

    subprocess.run(
        [
            "git",
            "commit",
            "-m",
            "Update note"
        ],
        check=True
    )
```

## Q108. Check Git status

```python
result = subprocess.run(
    ["git", "status", "--short"],
    capture_output=True,
    text=True,
    check=True
)

print(result.stdout)
```

## Q109. Flask endpoint to save a note

```python
from flask import request, jsonify

@app.post("/notes")
def create_note():
    data = request.get_json()

    save_note(
        data["path"],
        data["content"]
    )

    return jsonify(
        {"message": "saved"}
    ), 201
```

## Q110. Commit after the save operation

```python
@app.post("/notes/commit")
def commit_note():
    path = request.json["path"]

    subprocess.run(
        ["git", "add", path],
        check=True
    )

    subprocess.run(
        [
            "git",
            "commit",
            "-m",
            "Update note"
        ],
        check=True
    )

    return jsonify(
        {"message": "committed"}
    ), 200
```

---

# BONUS — CROSS-TOPIC PREDICTIONS

These combine two or more areas and are strong practical-test possibilities.

## Q111. Docker MySQL → Pandas → report

```python
query = """
SELECT *
FROM orders
"""

df = pd.read_sql(
    query,
    conn
)

report = (
    df.groupby("customer_id")
    ["amount"]
    .sum()
    .reset_index(
        name="total_amount"
    )
)

print(report)
```

## Q112. SQL query → DataFrame → CSV

```python
df = pd.read_sql(
    """
    SELECT *
    FROM customers
    """,
    conn
)

df.to_csv(
    "customers.csv",
    index=False
)
```

## Q113. JSON → MySQL → SQL verification

```python
cursor.executemany(
    query,
    rows
)

conn.commit()

cursor.execute(
    "SELECT COUNT(*) FROM json_to_sql_table"
)

print(
    cursor.fetchone()[0]
)
```

## Q114. SQL data → clean email → MySQL

```python
df = pd.read_sql(
    "SELECT * FROM customers",
    conn
)

df["email"] = (
    df["email"]
    .astype(str)
    .str.split("@")
    .str[0]
    + "@gmail.com"
)

df.to_sql(
    "customers_cleaned",
    conn,
    if_exists="replace",
    index=False
)
```

## Q115. Read XLSX → clean → CSV

```python
sheets = pd.read_excel(
    "input.xlsx",
    sheet_name=None
)

for name, frame in sheets.items():
    frame = frame.drop_duplicates()

    frame.to_csv(
        f"{name}.csv",
        index=False
    )
```

## Q116. SQL file → regex → JSON

```python
with open(
    "input.sql",
    encoding="utf-8"
) as file:
    sql = file.read()

names = re.findall(
    r"CREATE\s+PROCEDURE\s+(\w+)",
    sql,
    flags=re.IGNORECASE
)

with open(
    "output.json",
    "w",
    encoding="utf-8"
) as file:
    json.dump(
        {"procedures": names},
        file,
        indent=4
    )
```

## Q117. Flask → MySQL

```python
@app.get("/customers")
def customers():
    df = pd.read_sql(
        "SELECT * FROM customers",
        conn
    )

    return jsonify(
        df.to_dict(
            orient="records"
        )
    ), 200
```

## Q118. Flask → JSON validation → MySQL INSERT

```python
@app.post("/customers")
def create():
    data = request.get_json()

    if not data.get("name"):
        return jsonify(
            {"error": "name required"}
        ), 400

    cursor.execute(
        """
        INSERT INTO customers(name)
        VALUES (%s)
        """,
        (data["name"],)
    )

    conn.commit()

    return jsonify(data), 201
```

## Q119. Flask endpoint + pytest mock

```python
@patch("app.get_all_customers")
def test_get_customers(mock_get):
    mock_get.return_value = []

    response = client.get(
        "/customers"
    )

    assert response.status_code == 200
    mock_get.assert_called_once()
```

## Q120. Complete mini ETL pipeline — VERY HIGH

```python
import json
import pandas as pd

# Extract
with open(
    "sample_data_for_assignment.json",
    encoding="utf-8"
) as file:
    data = json.load(file)

# Transform
df = pd.DataFrame(
    data["data"],
    columns=data["cols"]
)

df["email"] = (
    df["email"]
    .astype(str)
    .str.split("@")
    .str[0]
    + "@gmail.com"
)

df["postalZip"] = df["postalZip"].apply(
    clean_postal
)

df["phone"] = df["phone"].apply(
    encode_phone
)

df = df.rename(
    columns={
        "phone": "coded_phone_number"
    }
)

# Load
df.to_sql(
    "json_cleaned",
    conn,
    if_exists="replace",
    index=False
)

print("ETL completed")
```

---

# PDF REMAINING AREAS CHECKLIST

These are the PDF areas that were **not the same questions as Day 1** and therefore remain relevant for Test 2.

## PDF area 1 — Large database processing

```text
Large number of records
Python + MySQL
Low memory processing
Generator/lazy fetching
```

The Day-1 generator question was a CSV generator task, so the Test-2 variation to revise is **database-backed or cursor-based incremental processing**.

## PDF area 2 — HTML

```text
URL as argument
Download HTML
Strip HTML tags
Print cleaned text
```

## PDF area 3 — REST API

```text
Customer INSERT / UPDATE / SELECT
Product INSERT / UPDATE / SELECT
Order INSERT / UPDATE / SELECT
Customer order history
Validation
MVC
ORM
Unit tests
Mocking
```

## PDF area 4 — Stack Overflow ETL

```text
Average Age1stCode
Python percentage by Country
Average salary by continent
Most desired language
Hobby coding by gender + continent
Job/Career satisfaction by gender + continent
```

The gender requirement is exactly:

```text
MAN
WOMAN
OTHERS
```

Ambiguous values belong to `OTHERS`.

## PDF area 5 — Notepad Tracker

```text
Flask application
Text editor
Save to any directory
Commit after writing stops
Git VCS
```

## PDF area 6 — XLSX → CSV

```text
Read all sheets
Do not hardcode sheet names
Write one CSV per sheet
Create output directory
Accept local file / path argument
```

## PDF area 7 — SQL Information Extraction

```text
Read .sql file
Use regex
Extract information
Create JSON output
```

## PDF area 8 — JSON / MySQL / Pandas

```text
JSON has cols + data
Load into MySQL
Table: json_to_sql_table
MySQL → Pandas
Email → gmail.com
postalZip → int
phone → ASCII coding
phone → coded_phone_number
```

---

# WHAT TO REVISE FIRST FOR TEST 2

## 🔴 EXTREME PRIORITY

```text
1. Python → MySQL using pymysql
2. pd.read_sql()
3. SELECT / INSERT / UPDATE
4. executemany()
5. commit() / rollback()
6. JSON → DataFrame
7. JSON → MySQL
8. MySQL → DataFrame
9. email transformation
10. postalZip cleaning
11. phone ASCII coding
12. groupby()
13. percentage calculations
14. split(";") + explode()
15. Stack Overflow survey reports
16. XLSX sheet iteration
17. SQL → regex → JSON
18. Flask CRUD
19. customer order history
20. pytest + mocking
```

## 🟠 HIGH PRIORITY

```text
argparse
HTMLParser
file I/O
Path
transactions
Flask validation
HTTP status codes
Git subprocess
```

## 🟡 LOWER PRIORITY BUT STILL FROM PDF

```text
MVC folder structure
ORM concept
AWS API Gateway + Lambda
DynamoDB
CloudWatch
```

These are in the assignment specification, but the supplied Test-2 Docker setup makes **local Python/MySQL/ETL execution** more directly relevant to the practical test.

---

# FINAL 30-MINUTE PRACTICE SET

Before the test, practise these without looking at the answer:

```text
1. Connect to Docker MySQL.
2. SELECT rows using Python.
3. INSERT using executemany().
4. Use commit and rollback.
5. pd.read_sql().
6. Load JSON.
7. JSON → DataFrame.
8. JSON → MySQL.
9. MySQL → DataFrame.
10. Convert all emails to gmail.com.
11. Convert postalZip to int.
12. Encode phone into ASCII.
13. Rename phone column.
14. Python percentage by country.
15. Most desired language with explode().
16. Average salary by continent.
17. Gender normalization.
18. Hobby report.
19. Satisfaction report.
20. Read all Excel sheets.
21. Write every sheet to CSV.
22. Read SQL file.
23. Regex extraction.
24. Save JSON.
25. Flask GET.
26. Flask POST validation.
27. Customer order history.
28. pytest.
29. Mock an external service.
30. Git add + commit from Python.
```

# IMPORTANT

The exact table names, columns, and inserted rows for the Docker Test-2 database should be taken from the actual Test-2 seed script. Where those exact seed definitions were not available in the supplied files, the examples above intentionally use generic names such as `customers`, `orders`, and `test_db` rather than pretending those are the exact unseen schema.

