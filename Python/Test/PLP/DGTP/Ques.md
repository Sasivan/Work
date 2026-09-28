# DataGrokr PLP — Python Test Question Bank (Weeks 1–3)

*50 Questions | Predict-the-Output + Coding Problems | With Datasets*

Built from the Phase 1 – Python syllabus pattern: each topic pairs a short *Predict the Output* snippet with a *Coding Problem* that uses a small embedded dataset, mirroring the weekly test format (`Predict output + coding problem(s)`).

---

## WEEK 1 — Beginner (17 Questions)

### Topic 1: Data Types, Variables, Operators & Type Conversion

*Q1 (Predict Output)*

```python
a = "42"
b = int(a) + 8
c = str(b) + "!"
print(type(a).__name__, b, c, b / 5)
```

*Q2 (Coding Problem)* Dataset: `temperatures_celsius = [21.5, 33.0, 18.2, 40.1, 25.6]` Convert each to Fahrenheit (`F = C * 9/5 + 32`), print rounded to 1 decimal, and print the count of days above 30°C (in Celsius).

*Q3 (Predict Output)*

```python
x, y = 7, 2
print(x // y, x % y, x ** y, bool(x - 7))
```

---

### Topic 2: Lists, Tuples, Sets & Dictionaries

*Q4 (Coding Problem)* Dataset: `inventory = {"pens": 120, "pencils": 85, "erasers": 40, "sharpeners": 15}` Print items with stock below 50, compute total stock, and build a list of `(item, stock)` tuples sorted by stock descending.

*Q5 (Predict Output)*

```python
data = (1, 2, 3, [4, 5])
data[3].append(6)
print(data)
```

*Q6 (Coding Problem)* Dataset: `votes = ["red", "blue", "red", "green", "blue", "red", "green", "green", "green"]` Using a set and a dict, print unique candidates, vote counts per candidate, and the winner.

---

### Topic 3: Control Flow (if/elif, for/while)

*Q7 (Predict Output)*

```python
total = 0
for i in range(1, 10):
    if i % 3 == 0:
        continue
    if i > 7:
        break
    total += i
print(total)
```

*Q8 (Coding Problem)* Dataset: `marks = [45, 67, 89, 32, 78, 91, 55, 60]` Using a for loop, label each mark "Fail" (\<40), "Pass" (40-59), "Good" (60-79), "Excellent" (80+), and count each category.

*Q9 (Predict Output)*

```python
n = 5
result = 1
while n > 1:
    result *= n
    n -= 1
print(result)
```

---

### Topic 4: Functions (Arguments, Return Values, Defaults)

*Q10 (Coding Problem)* Write `compute_bill(units, rate=8.5, tax_pct=5)` that returns `(base_amount, tax, total)`. Raise `ValueError` if `units < 0`. Dataset (test calls): `units_list = [100, 250, 0, -5, 500]` — call the function on each and handle the error case.

*Q11 (Predict Output)*

```python
def modify(lst, val=10):
    lst.append(val)
    return lst

a = [1, 2, 3]
b = modify(a)
b = modify(a, 99)
print(a, b)
```

*Q12 (Coding Problem)* Dataset: `orders = [("A101", 3, 250), ("A102", 1, 900), ("A103", 5, 120)]` (order_id, qty, unit_price) Write `order_total(qty, price)` and use it in a loop to print each order's total and the grand total.

---

### Topic 5: String Operations & File I/O

*Q13 (Predict Output)*

```python
s = "  DataGrokr-PLP-2025  "
print(s.strip().lower().replace("-", "_"))
print(s.strip().split("-"))
```

*Q14 (Coding Problem)* Dataset (save as `attendance.txt`):

```
Aarav,Present
Diya,Absent
Kabir,Present
Meera,Present
Rohan,Absent
```

Read the file, count Present/Absent, print each name in title case with status, and append a summary line `"Attendance: X/Y Present"`.

*Q15 (Predict Output)*

```python
text = "python,sql,git,aws"
parts = text.split(",")
joined = " | ".join(parts).upper()
print(joined, len(parts))
```

---

### Topic 6: Exception Handling

*Q16 (Coding Problem)* Dataset: `transactions = [("T1", 500, 2), ("T2", 300, 0), ("T3", "abc", 5), ("T4", 800, 4)]` (id, amount, divisor) Write `safe_split(amount, divisor)` returning `amount/divisor`, handling `ZeroDivisionError` and `TypeError` per transaction, printing a clear message for each, and using `finally` to log `"Processed <id>"`.

*Q17 (Predict Output)*

```python
def check(n):
    try:
        if n < 0:
            raise ValueError("negative!")
        return 100 / n
    except ZeroDivisionError:
        return "inf"
    except ValueError as e:
        return str(e)

print(check(5), check(0), check(-3))
```

---

## WEEK 2 — Intermediate (17 Questions)

### Topic 1: Comprehensions, lambda, map, filter

*Q18 (Coding Problem)* Dataset: `prices = [199, 450, 999, 1200, 75, 2500, 340]` Using only comprehensions/functional tools: (a) list comprehension of prices > 500, (b) `filter()` for prices divisible by 5, (c) `map()` to apply 10% discount, (d) dict comprehension `{price: "expensive"/"cheap"}` (threshold 500).

*Q19 (Predict Output)*

```python
nums = [2, 5, 8, 11, 14, 17]
evens = [n for n in nums if n % 2 == 0]
tripled = list(map(lambda x: x * 3, nums[:3]))
big = list(filter(lambda x: x > 10, nums))
print(evens, tripled, big)
```

*Q20 (Coding Problem)* Dataset: `words = ["python", "sql", "git", "aws", "docker", "ai"]` Build a dict comprehension `{word: len(word)}`, then use `sorted()` with a lambda to print words ranked longest to shortest.

---

### Topic 2: OOP — Classes, Inheritance & Polymorphism

*Q21 (Coding Problem)* Dataset: `vehicles_data = [("Car", "Honda City", 4), ("Bike", "Royal Enfield", 2), ("Truck", "Tata 407", 6)]` (type, model, wheels) Build a base class `Vehicle` (model, wheels, `describe()`), subclasses `Car` and `Bike` overriding `describe()` with type-specific info, then loop through instances demonstrating polymorphism.

*Q22 (Predict Output)*

```python
class Shape:
    def area(self):
        return 0

class Circle(Shape):
    def __init__(self, r):
        self.r = r
    def area(self):
        return round(3.14 * self.r * 2, 2)

class Square(Shape):
    def __init__(self, s):
        self.s = s
    def area(self):
        return self.s * 2

for shape in [Circle(3), Square(4)]:
    print(shape.__class__.__name__, shape.area())
```

*Q23 (Coding Problem)* Dataset: `employees_raw = [{"name":"Asha","role":"Manager","salary":90000},{"name":"Ravi","role":"Dev","salary":60000}]` Create class `Employee` with `__init__`, a subclass `Manager` adding `team_size` and overriding a `summary()` method that includes team size; demonstrate with one `Employee` and one `Manager`.

---

### Topic 3: Decorators & Context Managers

*Q24 (Predict Output)*

```python
def shout(func):
    def wrapper(*args):
        result = func(*args)
        return result.upper()
    return wrapper

@shout
def greet(name):
    return f"hello {name}"

print(greet("priya"))
```

*Q25 (Coding Problem)* Write a decorator `@timer_log` that prints `"Started <func>"` and `"Finished <func>"` around a function call. Apply it to `process_batch(batch)`. Dataset: `batches = [[1,2,3], [4,5], [6,7,8,9]]` — call `process_batch` (returns sum of the batch) on each in a loop.

*Q26 (Coding Problem)* Write a context manager `LogSession` (class-based, `__enter__`/`__exit__`) that prints `"Session started"` on enter and `"Session ended"` on exit, even if an error occurs inside. Dataset: `records = [10, 20, "bad", 40]` — inside the `with` block, sum records, catching the `TypeError` from `"bad"`.

---

### Topic 4: pandas: read_csv, groupby, merge + numpy basics

*Q27 (Coding Problem)* Dataset A (`sales.csv`):

```
region,product,amount
North,Widget,1200
South,Widget,800
North,Gadget,1500
South,Gadget,600
North,Widget,900
```

Read into a DataFrame, `groupby` region and product to get total amount, then use numpy to compute the mean, std deviation, and 75th percentile of `amount`.

*Q28 (Predict Output)*

```python
import pandas as pd
data = {"dept": ["Eng","HR","Eng","HR"], "salary": [70000, 50000, 90000, 55000]}
df = pd.DataFrame(data)
print(df.groupby("dept")["salary"].sum().to_dict())
```

*Q29 (Coding Problem)* Dataset A (`students.csv`): `student_id,name` → `(1,Nina),(2,Omar),(3,Tara)` Dataset B (`marks.csv`): `student_id,subject,score` → `(1,Math,85),(1,Sci,90),(2,Math,60),(3,Sci,45)` Merge on `student_id`, add a `grade` column (A≥85, B≥70, C≥55, F otherwise), and print average score per student.

---

### Topic 5: Modules, Packages & Virtual Environments

*Q30 (Coding Problem)* Write the exact terminal commands to: create a virtual environment `plp_env2`, activate it, install `pandas` and `numpy`, then freeze dependencies into `requirements.txt`.

*Q31 (Predict Output)*

```python
# file: shapes.py
def square_area(s): return s * s

# file: main.py
from shapes import square_area as sa
print(sa(6), type(sa).__name__)
```

*Q32 (Coding Problem)* Design a package `inventory_pkg` with `items.py` (class `Item`) and `stock.py` (`total_value(items)`). Write `__init__.py` exposing both, and a `main.py` that imports from the top-level package only.

---

### Topic 6: Exception Patterns & Clean Code

*Q33 (Coding Problem)* Refactor this into clean code with type hints, a docstring, and specific exception handling:

```python
def f(a,b,c): 
    try: return (a+b)/c
    except: pass
```

Dataset for test calls: `[(10, 5, 3), (8, 2, 0), ("x", 1, 2)]`

*Q34 (Predict Output)*

```python
from typing import Optional

def safe_avg(nums: list) -> Optional[float]:
    try:
        return sum(nums) / len(nums)
    except ZeroDivisionError:
        return None

print(safe_avg([4, 8, 12]))
print(safe_avg([]))
```

---

## WEEK 3 — Advanced (16 Questions)

### Topic 1: Generators & Iterators

*Q35 (Coding Problem)* Write `even_gen()` yielding even numbers indefinitely and `take(n, gen)` returning the first `n` as a list. Use both to print the first 8 even numbers that are also multiples of 6.

*Q36 (Predict Output)*

```python
def counter(n):
    while n < 5:
        yield n
        n += 1

g = counter(1)
print(next(g))
print(next(g))
print(list(g))
```

*Q37 (Coding Problem)* Dataset: `log_lines = ["INFO start", "ERROR disk full", "INFO ok", "ERROR timeout", "INFO done"]` Write a generator `filter_errors(lines)` that yields only lines containing `"ERROR"`, memory-efficiently (no full list build), and print them.

---

### Topic 2: pytest — Test Cases, Fixtures & Assertions

*Q38 (Coding Problem)* Given `inventory.py` with `add_stock(current, qty)` and `remove_stock(current, qty)` (raises `ValueError` if resulting stock \< 0), write `test_inventory.py` with:

- fixture `sample_stock` returning `{"current": 50}`
- a parametrized test for `add_stock` with at least 3 quantity combos
- `pytest.raises(ValueError)` test for over-removal

*Q39 (Predict Output)*

```python
def is_valid_age(age):
    if age < 0 or age > 120:
        raise ValueError("invalid age")
    return True

try:
    print(is_valid_age(45))
    print(is_valid_age(-5))
except ValueError as e:
    print(f"Caught: {e}")
```

*Q40 (Coding Problem)* Dataset: `pairs = [(10, 2), (9, 0), (0, 5)]` Write parametrized pytest cases for a `divide(a, b)` function covering a normal case, a `ZeroDivisionError` case, and a zero-numerator case.

---

### Topic 3: JSON & REST API Interaction

*Q41 (Coding Problem)* Using `https://jsonplaceholder.typicode.com/users`, fetch all users, handle `ConnectionError`/`Timeout` (add `timeout=5`), extract `{id: {"name": name, "city": address.city}}`, and save as `users_summary.json` with `indent=2`.

*Q42 (Predict Output)*

```python
import json
data = '[{"id":1,"score":72},{"id":2,"score":95}]'
records = json.loads(data)
passed = {r["id"]: r["score"] >= 75 for r in records}
print(passed)
print(json.dumps(passed))
```

*Q43 (Coding Problem)* Dataset (simulated API response):

```python
comments = [
    {"postId": 1, "body": "great article thanks a lot"},
    {"postId": 1, "body": "not useful"},
    {"postId": 2, "body": "very detailed and clear explanation indeed"}
]
```

Filter comments with more than 4 words, then build `{postId: [bodies]}` and print the count per post.

---

### Topic 4: ETL Pipeline: API → pandas → File Output

*Q44 (Coding Problem)* Dataset (simulated `/posts` extract):

```python
posts = [
    {"userId": 1, "body": "short post"},
    {"userId": 1, "body": "this is a much longer post about python"},
    {"userId": 2, "body": "medium length example post here"},
]
```

Transform: add `word_count` column, add `category` (Short ≤3 words, Medium 4-6, Long >6), filter `word_count > 3`, then load to `output/etl_result.csv`, creating the directory if missing.

*Q45 (Predict Output)*

```python
import pandas as pd
data = [{"cat": "A", "wc": 12}, {"cat": "B", "wc": 3}, {"cat": "A", "wc": 20}]
df = pd.DataFrame(data)
df["level"] = df["wc"].apply(lambda x: "High" if x > 10 else "Low")
print(df.groupby("level")["wc"].count().to_dict())
```

*Q46 (Coding Problem)* Dataset: same `posts` list as Q44, plus `users = [{"id": 1, "name": "Zara"}, {"id": 2, "name": "Leo"}]`. Merge posts with users on `userId`/`id`, then print a one-line summary: total posts, unique users, average word count.

---

### Topic 5: Comprehensions & Functional Patterns (Applied)

*Q47 (Coding Problem)* Dataset:

```python
emps = [
    {"name": "Priya", "dept": "Eng", "salary": 82000},
    {"name": "Aman", "dept": "Sales", "salary": 54000},
    {"name": "Zoya", "dept": "Eng", "salary": 91000},
    {"name": "Kunal", "dept": "HR", "salary": 48000},
    {"name": "Sana", "dept": "Sales", "salary": 60000},
    {"name": "Rehan", "dept": "Eng", "salary": 77000},
]
```

Using only comprehensions/`functools.reduce`/`sorted`: (a) names of Eng employees, (b) dict of employees earning > 60000, (c) unique departments, (d) total payroll via `reduce`, (e) top 2 earners.

*Q48 (Predict Output)*

```python
from functools import reduce
nums = [3, 6, 9, 12, 15]
product = reduce(lambda acc, x: acc * x, nums, 1)
above_avg = [n for n in nums if n > sum(nums)/len(nums)]
print(product, above_avg)
```

---

### Topic 6: Project Structure & Code Quality

*Q49 (Coding Problem)* Design a package `sales_tracker/` with `models.py` (a `Sale` dataclass: `product: str`, `amounts: list[float]`, property `total -> float`), `__init__.py` exposing `Sale` and `load_sales(filepath)` (reads JSON), and `main.py` printing each sale's total with error handling for a missing file. Dataset (`sales.json`):

```json
[
  {"product": "Widget", "amounts": [100.0, 250.5, 60.0]},
  {"product": "Gadget", "amounts": [400.0, 150.0]}
]
```

*Q50 (Predict Output)*

```python
from dataclasses import dataclass
from typing import List

@dataclass
class Sale:
    product: str
    amounts: List[float]

    @property
    def total(self):
        return sum(self.amounts)

s = Sale("Widget", [100.0, 250.5, 60.0])
print(s.product, round(s.total, 2), isinstance(s, Sale))
```

---

## Summary Table

| Week | Phase | Topics Covered | Questions | Format Mirrors |
| --- | --- | --- | --- | --- |
| 1 | Beginner | 6 | 17 | 25-min test: Predict output + 1 coding problem |
| 2 | Intermediate | 6 | 17 | 30-min test: Predict output + 1 coding problem |
| 3 | Advanced | 6 | 16 | 40-min test: Predict output + 2 coding problems |
| *Total* |  | *18* | *50* |  |

*Usage note:* Each Predict-Output question can be used directly as a timed-test item (5–7 min each); each Coding Problem is sized for the "mini assignment" format already used in your Q1–Q6 weekly papers, and reuses the same dataset style (inline lists/dicts, small CSV/JSON blocks) seen in your existing document.

---

---

# SOLUTIONS

## WEEK 1 — Beginner

*Q1* — Output: `str 50 50!` and `6.25`

```
str 50 50! 6.25
```

*Q2*

```python
temperatures_celsius = [21.5, 33.0, 18.2, 40.1, 25.6]
fahrenheit = [round(c * 9/5 + 32, 1) for c in temperatures_celsius]
print(fahrenheit)
hot_days = sum(1 for c in temperatures_celsius if c > 30)
print(f"Days above 30°C: {hot_days}")
```

*Q3* — Output:

```
3 1 49 True
```

*Q4*

```python
inventory = {"pens": 120, "pencils": 85, "erasers": 40, "sharpeners": 15}
low_stock = {k: v for k, v in inventory.items() if v < 50}
print("Low stock:", low_stock)
total = sum(inventory.values())
print("Total stock:", total)
sorted_items = sorted(inventory.items(), key=lambda x: x[1], reverse=True)
print("Sorted:", sorted_items)
```

*Q5* — Output: `(1, 2, 3, [4, 5, 6])` (tuples are immutable, but the list inside can still mutate)

*Q6*

```python
votes = ["red", "blue", "red", "green", "blue", "red", "green", "green", "green"]
candidates = set(votes)
counts = {c: votes.count(c) for c in candidates}
print("Candidates:", candidates)
print("Counts:", counts)
winner = max(counts, key=counts.get)
print("Winner:", winner)
```

*Q7* — Output: `12` (1+2+4+5+7 — 3,6,9 skipped by continue, loop breaks when i>7 i.e. at i=8)

*Q8*

```python
marks = [45, 67, 89, 32, 78, 91, 55, 60]
counts = {"Fail": 0, "Pass": 0, "Good": 0, "Excellent": 0}
for m in marks:
    if m < 40:
        label = "Fail"
    elif m < 60:
        label = "Pass"
    elif m < 80:
        label = "Good"
    else:
        label = "Excellent"
    counts[label] += 1
    print(m, "->", label)
print(counts)
```

*Q9* — Output: `120` (5! factorial)

*Q10*

```python
def compute_bill(units, rate=8.5, tax_pct=5):
    if units < 0:
        raise ValueError("units cannot be negative")
    base_amount = units * rate
    tax = base_amount * tax_pct / 100
    total = base_amount + tax
    return round(base_amount, 2), round(tax, 2), round(total, 2)

units_list = [100, 250, 0, -5, 500]
for u in units_list:
    try:
        print(u, "->", compute_bill(u))
    except ValueError as e:
        print(u, "-> Error:", e)
```

*Q11* — Output: `[1, 2, 3, 10, 99] [1, 2, 3, 10, 99]` (same list object mutated both times, `b` and `a` refer to it)

*Q12*

```python
orders = [("A101", 3, 250), ("A102", 1, 900), ("A103", 5, 120)]

def order_total(qty, price):
    return qty * price

grand_total = 0
for oid, qty, price in orders:
    t = order_total(qty, price)
    grand_total += t
    print(oid, "->", t)
print("Grand total:", grand_total)
```

*Q13* — Output:

```
datagrokr_plp_2025
['  DataGrokr', 'PLP', '2025  ']
```

*Q14*

```python
def load_attendance(filepath="attendance.txt"):
    with open(filepath) as f:
        lines = [l.strip() for l in f if l.strip()]
    present = absent = 0
    for line in lines:
        name, status = line.split(",")
        print(name.title(), "-", status)
        if status == "Present":
            present += 1
        else:
            absent += 1
    with open(filepath, "a") as f:
        f.write(f"\nAttendance: {present}/{present+absent} Present\n")
    return present, absent

load_attendance()
```

*Q15* — Output:

```
PYTHON | SQL | GIT | AWS 4
```

*Q16*

```python
transactions = [("T1", 500, 2), ("T2", 300, 0), ("T3", "abc", 5), ("T4", 800, 4)]

def safe_split(amount, divisor):
    try:
        return amount / divisor
    except ZeroDivisionError:
        return "Error: division by zero"
    except TypeError:
        return "Error: invalid amount type"

for tid, amount, divisor in transactions:
    try:
        result = safe_split(amount, divisor)
        print(tid, "->", result)
    finally:
        print(f"Processed {tid}")
```

*Q17* — Output: `20.0 inf negative!`

---

## WEEK 2 — Intermediate

*Q18*

```python
prices = [199, 450, 999, 1200, 75, 2500, 340]
expensive = [p for p in prices if p > 500]
div_by_5 = list(filter(lambda p: p % 5 == 0, prices))
discounted = list(map(lambda p: round(p * 0.9, 2), prices))
tag = {p: ("expensive" if p > 500 else "cheap") for p in prices}
print(expensive, div_by_5, discounted, tag)
```

*Q19* — Output: `[2, 8, 14] [6, 15, 24] [11, 14, 17]`

*Q20*

```python
words = ["python", "sql", "git", "aws", "docker", "ai"]
lengths = {w: len(w) for w in words}
ranked = sorted(lengths.items(), key=lambda x: x[1], reverse=True)
print(lengths)
for w, l in ranked:
    print(w, l)
```

*Q21*

```python
class Vehicle:
    def __init__(self, model, wheels):
        self.model = model
        self.wheels = wheels
    def describe(self):
        return f"{self.model} ({self.wheels} wheels)"

class Car(Vehicle):
    def describe(self):
        return f"Car: {self.model} — {self.wheels} wheels, 4-seater"

class Bike(Vehicle):
    def describe(self):
        return f"Bike: {self.model} — {self.wheels} wheels, 2-seater"

vehicles_data = [("Car", "Honda City", 4), ("Bike", "Royal Enfield", 2), ("Truck", "Tata 407", 6)]
fleet = []
for vtype, model, wheels in vehicles_data:
    if vtype == "Car":
        fleet.append(Car(model, wheels))
    elif vtype == "Bike":
        fleet.append(Bike(model, wheels))
    else:
        fleet.append(Vehicle(model, wheels))

for v in fleet:
    print(v.describe())
```

*Q22* — Output:

```
Circle 28.26
Square 16
```

*Q23*

```python
class Employee:
    def __init__(self, name, role, salary):
        self.name = name
        self.role = role
        self.salary = salary
    def summary(self):
        return f"{self.name} ({self.role}): ₹{self.salary}"

class Manager(Employee):
    def __init__(self, name, role, salary, team_size):
        super().__init__(name, role, salary)
        self.team_size = team_size
    def summary(self):
        base = super().summary()
        return f"{base}, manages {self.team_size} people"

e = Employee("Ravi", "Dev", 60000)
m = Manager("Asha", "Manager", 90000, 8)
for person in [e, m]:
    print(person.summary())
```

*Q24* — Output: `HELLO PRIYA`

*Q25*

```python
def timer_log(func):
    def wrapper(*args, *kwargs):
        print(f"Started {func.__name__}")
        result = func(*args, *kwargs)
        print(f"Finished {func.__name__}")
        return result
    return wrapper

@timer_log
def process_batch(batch):
    return sum(batch)

batches = [[1,2,3], [4,5], [6,7,8,9]]
for b in batches:
    print("Total:", process_batch(b))
```

*Q26*

```python
class LogSession:
    def __enter__(self):
        print("Session started")
        return self
    def __exit__(self, exc_type, exc_val, exc_tb):
        print("Session ended")
        return True  # suppress exception

records = [10, 20, "bad", 40]
with LogSession():
    total = 0
    for r in records:
        try:
            total += r
        except TypeError:
            print(f"Skipping invalid record: {r}")
    print("Total:", total)
```

*Q27*

```python
import pandas as pd
import numpy as np

df = pd.read_csv("sales.csv")
summary = df.groupby(["region", "product"])["amount"].sum()
print(summary)

print("Mean:", np.mean(df["amount"]))
print("Std:", np.std(df["amount"]))
print("75th percentile:", np.percentile(df["amount"], 75))
```

*Q28* — Output: `{'Eng': 160000, 'HR': 105000}`

*Q29*

```python
import pandas as pd

students = pd.read_csv("students.csv")
marks = pd.read_csv("marks.csv")
merged = pd.merge(marks, students, on="student_id")

def grade(score):
    if score >= 85: return "A"
    if score >= 70: return "B"
    if score >= 55: return "C"
    return "F"

merged["grade"] = merged["score"].apply(grade)
print(merged)
print(merged.groupby("name")["score"].mean())
```

*Q30*

```bash
python -m venv plp_env2
source plp_env2/bin/activate      # Windows: plp_env2\Scripts\activate
pip install pandas numpy
pip freeze > requirements.txt
```

*Q31* — Output: `36 function`

*Q32*

```python
# inventory_pkg/items.py
class Item:
    def __init__(self, name, price, qty):
        self.name = name
        self.price = price
        self.qty = qty

# inventory_pkg/stock.py
def total_value(items):
    return sum(i.price * i.qty for i in items)

# inventory_pkg/__init__.py
from .items import Item
from .stock import total_value

# main.py
from inventory_pkg import Item, total_value
items = [Item("Pen", 10, 100), Item("Notebook", 40, 50)]
print(total_value(items))
```

*Q33*

```python
from typing import Optional

def safe_weighted_avg(a: float, b: float, c: float) -> Optional[float]:
    """
    Compute (a + b) / c safely.
    Args: a, b - numeric values to sum; c - divisor.
    Returns: the result, or None if c is zero or inputs are invalid.
    Raises: nothing — errors are handled internally.
    """
    try:
        return (a + b) / c
    except ZeroDivisionError:
        print("Error: division by zero")
        return None
    except TypeError:
        print("Error: invalid operand type")
        return None

for a, b, c in [(10, 5, 3), (8, 2, 0), ("x", 1, 2)]:
    print(safe_weighted_avg(a, b, c))
```

*Q34* — Output: `8.0` then `None`

---

## WEEK 3 — Advanced

*Q35*

```python
def even_gen():
    n = 0
    while True:
        yield n
        n += 2

def take(n, gen):
    return [next(gen) for _ in range(n)]

def multiples_of_6(gen):
    while True:
        val = next(gen)
        if val % 6 == 0:
            yield val

result = take(8, multiples_of_6(even_gen()))
print(result)
```

*Q36* — Output: `1`, `2`, `[3, 4]`

*Q37*

```python
log_lines = ["INFO start", "ERROR disk full", "INFO ok", "ERROR timeout", "INFO done"]

def filter_errors(lines):
    for line in lines:
        if "ERROR" in line:
            yield line

for err in filter_errors(log_lines):
    print(err)
```

*Q38*

```python
# inventory.py
def add_stock(current, qty):
    return current + qty

def remove_stock(current, qty):
    if current - qty < 0:
        raise ValueError("insufficient stock")
    return current - qty

# test_inventory.py
import pytest
from inventory import add_stock, remove_stock

@pytest.fixture
def sample_stock():
    return {"current": 50}

@pytest.mark.parametrize("qty", [10, 25, 100])
def test_add_stock(sample_stock, qty):
    assert add_stock(sample_stock["current"], qty) == sample_stock["current"] + qty

def test_remove_stock_over_limit(sample_stock):
    with pytest.raises(ValueError):
        remove_stock(sample_stock["current"], 999)
```

*Q39* — Output:

```
True
Caught: invalid age
```

*Q40*

```python
import pytest

def divide(a, b):
    if b == 0:
        raise ZeroDivisionError("cannot divide by zero")
    return a / b

pairs = [(10, 2), (9, 0), (0, 5)]

@pytest.mark.parametrize("a,b", pairs)
def test_divide(a, b):
    if b == 0:
        with pytest.raises(ZeroDivisionError):
            divide(a, b)
    else:
        assert divide(a, b) == a / b
```

*Q41*

```python
import requests, json

try:
    resp = requests.get("https://jsonplaceholder.typicode.com/users", timeout=5)
    resp.raise_for_status()
    users = resp.json()
    summary = {u["id"]: {"name": u["name"], "city": u["address"]["city"]} for u in users}
    with open("users_summary.json", "w") as f:
        json.dump(summary, f, indent=2)
    print(f"Saved {len(summary)} users")
except requests.exceptions.ConnectionError:
    print("Connection failed")
except requests.exceptions.Timeout:
    print("Request timed out")
```

*Q42* — Output:

```
{1: False, 2: True}
{"1": false, "2": true}
```

*Q43*

```python
comments = [
    {"postId": 1, "body": "great article thanks a lot"},
    {"postId": 1, "body": "not useful"},
    {"postId": 2, "body": "very detailed and clear explanation indeed"}
]

long_comments = [c for c in comments if len(c["body"].split()) > 4]

by_post = {}
for c in long_comments:
    by_post.setdefault(c["postId"], []).append(c["body"])

for pid, bodies in by_post.items():
    print(pid, "->", len(bodies), "comments")
```

*Q44*

```python
import pandas as pd
import os

posts = [
    {"userId": 1, "body": "short post"},
    {"userId": 1, "body": "this is a much longer post about python"},
    {"userId": 2, "body": "medium length example post here"},
]

df = pd.DataFrame(posts)
df["word_count"] = df["body"].apply(lambda x: len(x.split()))

def categorize(wc):
    if wc <= 3: return "Short"
    if wc <= 6: return "Medium"
    return "Long"

df["category"] = df["word_count"].apply(categorize)
df = df[df["word_count"] > 3]

os.makedirs("output", exist_ok=True)
df.to_csv("output/etl_result.csv", index=False)
print(df)
```

*Q45* — Output: `{'High': 2, 'Low': 1}`

*Q46*

```python
import pandas as pd

posts = [
    {"userId": 1, "body": "short post"},
    {"userId": 1, "body": "this is a much longer post about python"},
    {"userId": 2, "body": "medium length example post here"},
]
users = [{"id": 1, "name": "Zara"}, {"id": 2, "name": "Leo"}]

posts_df = pd.DataFrame(posts)
posts_df["word_count"] = posts_df["body"].apply(lambda x: len(x.split()))
users_df = pd.DataFrame(users)

merged = pd.merge(posts_df, users_df, left_on="userId", right_on="id")
print(f"Total posts: {len(merged)}, "
      f"Unique users: {merged['userId'].nunique()}, "
      f"Avg word count: {merged['word_count'].mean():.1f}")
```

*Q47*

```python
from functools import reduce

emps = [
    {"name": "Priya", "dept": "Eng", "salary": 82000},
    {"name": "Aman", "dept": "Sales", "salary": 54000},
    {"name": "Zoya", "dept": "Eng", "salary": 91000},
    {"name": "Kunal", "dept": "HR", "salary": 48000},
    {"name": "Sana", "dept": "Sales", "salary": 60000},
    {"name": "Rehan", "dept": "Eng", "salary": 77000},
]

eng_names = [e["name"] for e in emps if e["dept"] == "Eng"]
high_earners = {e["name"]: e["salary"] for e in emps if e["salary"] > 60000}
depts = {e["dept"] for e in emps}
total_payroll = reduce(lambda acc, e: acc + e["salary"], emps, 0)
top2 = sorted(emps, key=lambda e: e["salary"], reverse=True)[:2]

print(eng_names)
print(high_earners)
print(depts)
print(total_payroll)
print([(e["name"], e["salary"]) for e in top2])
```

*Q48* — Output: `43740 [15]` (product = 3*6*9*12*15 = 43740; average = 9, only 12 and 15 are >9 → wait, recompute: nums>avg where avg=9 → 12 and 15 qualify) → correct output: `43740 [12, 15]`

*Q49*

```python
# sales_tracker/models.py
from dataclasses import dataclass
from typing import List

@dataclass
class Sale:
    product: str
    amounts: List[float]

    @property
    def total(self) -> float:
        return sum(self.amounts)

# sales_tracker/__init__.py
import json
from .models import Sale

def load_sales(filepath: str):
    with open(filepath) as f:
        data = json.load(f)
    return [Sale(d["product"], d["amounts"]) for d in data]

# main.py
from sales_tracker import load_sales

try:
    sales = load_sales("sales.json")
    for s in sales:
        print(s.product, round(s.total, 2))
except FileNotFoundError:
    print("sales.json not found")
```

*Q50* — Output: `Widget 410.5 True`

---

*Note:* Q48's stated output has been corrected inline above — the `above_avg` filter (`n > average`) correctly yields `[12, 15]`, not `[15]` alone; this is a good example item to keep as a genuine "trace the average calculation carefully" trick question for students.