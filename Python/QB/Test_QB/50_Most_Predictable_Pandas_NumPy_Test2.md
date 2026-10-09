# 50 Most Predictable Pandas + NumPy Questions
# Based only on the supplied assignment / practice material

> Structure: 25 Pandas + 25 NumPy.
>
> Pandas predictions are based on the assignment PDF, your Day-1 Pandas/NumPy notes, and the Day-1 test notebook.
>
> NumPy predictions are based on your 101 NumPy Exercises notebook and your Day-1 Pandas/NumPy notes.
>
> The questions are prediction-style variations, not claims about the exact test.

---

# PART A — PANDAS
# 25 Most Predictable Questions

## P01 — Read a CSV and inspect it — HIGH

Question:

Load a CSV file and display the first five rows, shape, columns, and dtypes.

```python
import pandas as pd

df = pd.read_csv("data.csv")

print(df.head())
print(df.shape)
print(df.columns)
print(df.dtypes)
```

---

## P02 — Parse a date column — HIGH

Question:

Read a CSV and make sure `order_date` is loaded as a datetime column.

```python
df = pd.read_csv(
    "orders.csv",
    parse_dates=["order_date"]
)

print(df.dtypes)
```

---

## P03 — Extract year, month and day — HIGH

Question:

Create separate columns for year, month, and day from a datetime column.

```python
df["year"] = df["order_date"].dt.year
df["month"] = df["order_date"].dt.month
df["day"] = df["order_date"].dt.day

print(df)
```

---

## P04 — Calculate days between two dates — HIGH

Question:

Calculate the number of days between `start_date` and `end_date`.

```python
df["start_date"] = pd.to_datetime(
    df["start_date"]
)

df["end_date"] = pd.to_datetime(
    df["end_date"]
)

df["days"] = (
    df["end_date"] -
    df["start_date"]
).dt.days

print(df)
```

---

## P05 — Filter rows with one condition

Question:

Select rows where `amount > 1000`.

```python
result = df[
    df["amount"] > 1000
]

print(result)
```

---

## P06 — Filter with AND

Question:

Select rows where `amount > 1000` and `status == "Completed"`.

```python
result = df[
    (df["amount"] > 1000) &
    (df["status"] == "Completed")
]

print(result)
```

---

## P07 — Filter with OR

Question:

Select rows where status is either `Open` or `Pending`.

```python
result = df[
    (df["status"] == "Open") |
    (df["status"] == "Pending")
]

print(result)
```

---

## P08 — Filter values from a list

Question:

Select rows where `country` is India, USA, or UK.

```python
result = df[
    df["country"].isin(
        ["India", "USA", "UK"]
    )
]

print(result)
```

---

## P09 — Sort by multiple columns — HIGH

Question:

Sort by `department` ascending and `salary` descending.

```python
result = df.sort_values(
    by=["department", "salary"],
    ascending=[True, False]
)

print(result)
```

---

## P10 — Select rows and columns with `loc`

Question:

Return only `name` and `salary` for employees with salary greater than 50000.

```python
result = df.loc[
    df["salary"] > 50000,
    ["name", "salary"]
]

print(result)
```

---

## P11 — Select by position with `iloc`

Question:

Select rows 0 through 4 and the first three columns.

```python
result = df.iloc[
    0:5,
    0:3
]

print(result)
```

---

## P12 — Count missing values

Question:

Find the number of missing values in every column.

```python
missing = df.isnull().sum()

print(missing)
```

---

## P13 — Find rows containing missing values

Question:

Display only rows where `salary` is missing.

```python
result = df[
    df["salary"].isna()
]

print(result)
```

---

## P14 — Convert a dirty column to numeric — HIGH

Question:

Convert a column containing numbers and text such as `"unknown"` into numeric values, turning invalid values into missing values.

```python
df["salary"] = pd.to_numeric(
    df["salary"],
    errors="coerce"
)

print(df.dtypes)
```

---

## P15 — Count values with `value_counts()`

Question:

Find how many rows belong to each `status`.

```python
result = df[
    "status"
].value_counts()

print(result)
```

---

## P16 — GroupBy count

Question:

Count records for every `state`.

```python
result = (
    df.groupby("state")
    .size()
    .reset_index(
        name="count"
    )
)

print(result)
```

---

## P17 — GroupBy average — HIGH

Question:

Calculate average salary for each department.

```python
result = (
    df.groupby("department")["salary"]
    .mean()
    .reset_index(
        name="average_salary"
    )
)

print(result)
```

---

## P18 — GroupBy sum and count together — HIGH

Question:

For each category, calculate total sales and number of rows.

```python
result = (
    df.groupby("category")
    .agg(
        total_sales=("sales", "sum"),
        row_count=("sales", "size")
    )
    .reset_index()
)

print(result)
```

---

## P19 — Two-column groupby

Question:

Count records for every `(state, status)` combination.

```python
result = (
    df.groupby(
        ["state", "status"]
    )
    .size()
    .reset_index(
        name="count"
    )
)

print(result)
```

---

## P20 — Percentage using GroupBy — VERY HIGH

Question:

Calculate the percentage of respondents satisfying a boolean condition for each country.

```python
df["flag"] = (
    df["status"] == "Completed"
)

result = (
    df.groupby("country")["flag"]
    .mean()
    .mul(100)
    .reset_index(
        name="percentage"
    )
)

print(result)
```

This is especially relevant to the survey requirement for percentages by country.

---

## P21 — Split + explode — VERY HIGH

Question:

A column contains multiple values separated by `;`. Split and count individual values.

```python
values = (
    df["languages"]
    .dropna()
    .str.split(";")
    .explode()
)

result = values.value_counts()

print(result)
```

---

## P22 — Find the most frequent item after `explode()` — VERY HIGH

Question:

Find the most desired programming language.

```python
result = (
    df["languages"]
    .dropna()
    .str.split(";")
    .explode()
    .value_counts()
)

print(result.index[0])
```

---

## P23 — Merge two DataFrames

Question:

Join two DataFrames using a common ID.

```python
result = pd.merge(
    orders,
    products,
    on="product_id",
    how="inner"
)

print(result)
```

Possible variation:

```python
result = pd.merge(
    orders,
    products,
    on="product_id",
    how="left"
)
```

---

## P24 — Create a derived column after merge — HIGH

Question:

After merging orders and products, calculate line revenue.

```python
result = pd.merge(
    orders,
    products,
    on="product_id",
    how="inner"
)

result["line_total"] = (
    result["quantity"] *
    result["unit_price"]
)

print(result)
```

This is a natural variation of the Day-1 merge task and the assignment's ETL style.

---

## P25 — MySQL → Pandas + report — VERY HIGH

Question:

Read data from the Docker MySQL database into Pandas, then calculate a grouped report.

```python
import pandas as pd

query = """
SELECT *
FROM orders
"""

df = pd.read_sql(
    query,
    conn
)

report = (
    df.groupby("customer_id")["amount"]
    .sum()
    .reset_index(
        name="total_amount"
    )
)

print(report)
```

This is particularly important because Test 2 uses the Docker MySQL environment.

---

# PART B — NUMPY
# 25 Most Predictable Questions

## N01 — Create a sequence with `arange()` — HIGH

Question:

Create an array containing numbers from 0 to 9.

```python
import numpy as np

arr = np.arange(10)

print(arr)
```

Variation:

```python
arr = np.arange(
    5,
    26
)
```

---

## N02 — Extract values using a boolean mask — HIGH

Question:

Extract all values greater than 30.

```python
arr = np.array(
    [10, 20, 30, 40, 50]
)

result = arr[
    arr > 30
]

print(result)
```

---

## N03 — Filter using multiple conditions — HIGH

Question:

Extract values between 20 and 50.

```python
result = arr[
    (arr >= 20) &
    (arr <= 50)
]

print(result)
```

---

## N04 — Replace values conditionally

Question:

Replace all odd values with `-1`.

```python
arr = np.array(
    [1, 2, 3, 4, 5, 6]
)

result = arr.copy()

result[
    result % 2 == 1
] = -1

print(result)
```

---

## N05 — `np.where()` — VERY HIGH

Question:

Convert marks into Pass/Fail.

```python
marks = np.array(
    [45, 75, 32, 90, 60]
)

result = np.where(
    marks >= 50,
    "Pass",
    "Fail"
)

print(result)
```

---

## N06 — `np.where()` with three categories — HIGH

Question:

Create `Excellent`, `Pass`, and `Fail` categories.

```python
result = np.where(
    marks >= 80,
    "Excellent",
    np.where(
        marks >= 50,
        "Pass",
        "Fail"
    )
)

print(result)
```

---

## N07 — Vectorization — VERY HIGH

Question:

Multiply every element by 2 without using a loop.

```python
arr = np.array(
    [10, 20, 30, 40, 50]
)

result = arr * 2

print(result)
```

---

## N08 — Broadcasting — VERY HIGH

Question:

Add 5 to every element.

```python
arr = np.array(
    [10, 20, 30, 40]
)

result = arr + 5

print(result)
```

---

## N09 — Row-wise broadcasting — HIGH

Question:

Subtract a 1D array from every row of a 2D array.

```python
matrix = np.array([
    [10, 20, 30],
    [40, 50, 60]
])

values = np.array(
    [1, 2, 3]
)

result = (
    matrix - values
)

print(result)
```

---

## N10 — Reshape an array — HIGH

Question:

Convert a 1D array into a 2D array with 2 rows.

```python
arr = np.arange(10)

result = arr.reshape(
    2,
    5
)

print(result)
```

---

## N11 — Stack arrays vertically

Question:

Stack two arrays row-wise.

```python
a = np.array(
    [[1, 2], [3, 4]]
)

b = np.array(
    [[5, 6], [7, 8]]
)

result = np.vstack(
    [a, b]
)

print(result)
```

---

## N12 — Stack arrays horizontally

Question:

Stack two arrays column-wise.

```python
result = np.hstack(
    [a, b]
)

print(result)
```

---

## N13 — Find common elements

Question:

Find values present in both arrays.

```python
a = np.array(
    [1, 2, 3, 4]
)

b = np.array(
    [3, 4, 5, 6]
)

result = np.intersect1d(
    a,
    b
)

print(result)
```

---

## N14 — Find unique values and counts — HIGH

Question:

Find unique values and their frequencies.

```python
arr = np.array(
    [1, 2, 2, 3, 3, 3]
)

values, counts = np.unique(
    arr,
    return_counts=True
)

print(values)
print(counts)
```

---

## N15 — Mean, median, standard deviation — VERY HIGH

Question:

Calculate all three statistics.

```python
arr = np.array(
    [10, 20, 30, 40, 50]
)

print(np.mean(arr))
print(np.median(arr))
print(np.std(arr))
```

---

## N16 — Min and max — HIGH

Question:

Find the minimum and maximum values.

```python
print(np.min(arr))
print(np.max(arr))
```

---

## N17 — Percentiles — HIGH

Question:

Calculate the 25th, 50th, 75th and 95th percentiles.

```python
print(
    np.percentile(
        arr,
        [25, 50, 75, 95]
    )
)
```

---

## N18 — Min-max normalization — VERY HIGH

Question:

Scale the array to the 0–1 range.

```python
arr = np.array(
    [10, 20, 30, 40, 50]
)

result = (
    (arr - np.min(arr)) /
    (np.max(arr) - np.min(arr))
)

print(result)
```

---

## N19 — Standardize to zero mean and unit variance — HIGH

Question:

Standardize an array.

```python
arr = np.array(
    [10, 20, 30, 40, 50]
)

result = (
    (arr - np.mean(arr)) /
    np.std(arr)
)

print(result)
```

---

## N20 — Find missing values — HIGH

Question:

Find positions containing `NaN`.

```python
arr = np.array(
    [10, np.nan, 30, np.nan, 50]
)

positions = np.where(
    np.isnan(arr)
)

print(positions)
```

---

## N21 — Remove missing values

Question:

Remove all `NaN` values from a 1D array.

```python
result = arr[
    ~np.isnan(arr)
]

print(result)
```

---

## N22 — Outlier detection with mean + 2 std — HIGH

Question:

Find values greater than `mean + 2 * std`.

```python
arr = np.array(
    [10, 12, 11, 13, 12, 14, 100]
)

mean = np.mean(arr)
std = np.std(arr)

mask = arr > (
    mean + 2 * std
)

outliers = arr[mask]

print(outliers)
```

---

## N23 — Cumulative sum and product — HIGH

Question:

Calculate cumulative sum and cumulative product.

```python
arr = np.array(
    [1, 2, 3, 4]
)

print(
    np.cumsum(arr)
)

print(
    np.cumprod(arr)
)
```

---

## N24 — Maximum in every row — HIGH

Question:

Find the maximum value from each row of a 2D array.

```python
arr = np.array([
    [10, 20, 30],
    [40, 15, 60],
    [25, 90, 50]
])

result = np.max(
    arr,
    axis=1
)

print(result)
```

---

## N25 — Top-N positions — HIGH

Question:

Find the positions of the top five values.

```python
arr = np.array(
    [10, 80, 30, 70, 90, 40, 60]
)

positions = np.argsort(arr)[-5:]

print(positions)
```

---

# MOST LIKELY COMBINED PANDAS + NUMPY PATTERNS

These are especially useful because the materials repeatedly mix DataFrame work with numerical transformations.

## C01 — DataFrame column → NumPy → statistics

```python
arr = df["salary"].to_numpy()

print(np.mean(arr))
print(np.median(arr))
print(np.std(arr))
```

## C02 — DataFrame column → NumPy → normalization

```python
arr = df["amount"].to_numpy()

normalized = (
    (arr - np.min(arr)) /
    (np.max(arr) - np.min(arr))
)

print(normalized)
```

## C03 — Pandas column with NumPy condition

```python
df["category"] = np.where(
    df["amount"] >= 1000,
    "HIGH",
    "LOW"
)

print(df)
```

## C04 — Pandas filtering + NumPy statistics

```python
filtered = df[
    df["status"] == "Completed"
]

values = filtered[
    "amount"
].to_numpy()

print(
    np.mean(values)
)
```

## C05 — Pandas groupby + NumPy percentile

```python
for group, values in (
    df.groupby("category")["amount"]
):
    arr = values.to_numpy()

    print(
        group,
        np.percentile(
            arr,
            95
        )
    )
```

---

# FINAL PRIORITY ORDER

## 🔴 Do these first

```text
P20  Pandas percentage by group
P21  split + explode
P22  most frequent exploded value
P25  MySQL → Pandas → report
P17  groupby mean
P18  groupby multiple aggregations
P23  merge
P24  merge + derived column
P14  numeric conversion
P04  datetime difference

N05  np.where()
N07  vectorization
N08  broadcasting
N09  row-wise broadcasting
N15  mean / median / std
N17  percentile
N18  min-max normalization
N20  NaN positions
N22  outlier mask
N23  cumulative operations
```

## 🟠 Next

```text
P01  read_csv
P02  parse_dates
P03  datetime extraction
P06  AND filtering
P07  OR filtering
P10  loc
P11  iloc
P12  missing values
P15  value_counts
P19  multi-column groupby

N01  arange
N03  multiple-condition mask
N04  conditional replacement
N10  reshape
N11  vstack
N12  hstack
N13  intersect
N14  unique + counts
N16  min / max
N19  standardization
N21  remove NaN
N24  row-wise max
N25  top-N positions
```

# TEST-2-SPECIFIC TAKEAWAY

The supplied assignment PDF makes these Pandas patterns particularly important:

```text
JSON
  ↓
MySQL
  ↓
Pandas DataFrame
  ↓
clean columns
  ↓
group / aggregate
  ↓
report
```

The exact PDF transformations include:

```text
email → @gmail.com
postalZip → integer
phone → coded ASCII string
phone → coded_phone_number
```

The survey work emphasizes:

```text
mean
percentage
groupby
gender normalization
continent grouping
language splitting
explode
```

The Docker Test-2 environment makes:

```text
Python
  ↓
MySQL
  ↓
pd.read_sql()
  ↓
Pandas
  ↓
ETL/report
```

a particularly important practical pattern.

# SOURCE BOUNDARY

The assignment PDF directly supports the Pandas/ETL items such as survey aggregation and the JSON → MySQL → Pandas transformations.

The NumPy items are drawn from the supplied 101 NumPy Exercises notebook and your Pandas/NumPy notes. NumPy is not specified as a separate assignment section in the six-page Python Assignment PDF.

