# Python Assignment PDF: 10 Practice Questions per Topic (170 total)

This file uses only the **Python Assignment PDF** and has 17 topics with 10 questions each. Each question is a plain function with an example input and output, so it is easy to check with `assert`. Solutions are kept short and simple. I haven't run them, so run the examples before trusting a snippet.

| # | Topic in the PDF | # | Topic in the PDF |
|---|---|---|---|
| 1 | MySQL + generator (large data) | 10 | ETL: avg salary by continent |
| 2 | Person / Male / Female (abstract class) | 11 | ETL: most desired language |
| 3 | Remove duplicates, keep order | 12 | ETL: hobbyists by gender + continent |
| 4 | `map()` + `lambda` | 13 | ETL: job/career satisfaction |
| 5 | `anti_html.py` | 14 | Notepad Tracker (Flask + git) |
| 6 | Unit testing (TDD) | 15 | XLSX → CSV converter |
| 7 | REST API (Flask, validation, AWS) | 16 | SQL information extraction (regex) |
| 8 | ETL: avg age of first code | 17 | Data manipulation (JSON/MySQL/pandas) |
| 9 | ETL: % who know Python per country | | |

**Common setup for topics 8-13** (put this at the top of your ETL file):
```python
import pandas as pd

CONTINENT = {
    "India": "Asia", "China": "Asia", "Japan": "Asia",
    "United States": "North America", "Canada": "North America",
    "Germany": "Europe", "France": "Europe", "United Kingdom": "Europe",
    "Brazil": "South America", "Australia": "Oceania", "Nigeria": "Africa",
}                                     # extend with all countries in the survey


def add_continent(df):
    df = df.copy()
    df["continent"] = df["Country"].map(CONTINENT).fillna("Other")
    return df


def gender_category(value):
    if value == "Man":
        return "MAN"
    if value == "Woman":
        return "WOMAN"
    return "OTHERS"                    # ambiguous (e.g. "Man;Non-binary") or missing


def has_language(series, lang):
    """True for rows whose ';'-separated text contains exactly `lang`."""
    return series.fillna("").str.split(";").apply(lambda langs: lang in langs)
```

---

# 1. MySQL + Generator (process large data with low memory)

**1.1** `chunked(iterable, n)` yields lists of size `n` (last one may be smaller). `list(chunked(range(5), 2))` → `[[0,1],[2,3],[4]]`
```python
def chunked(iterable, n):
    chunk = []
    for item in iterable:
        chunk.append(item)
        if len(chunk) == n:
            yield chunk
            chunk = []
    if chunk:
        yield chunk
```

**1.2** `fetch_in_chunks(cursor, size=1000)` yields rows one by one using `cursor.fetchmany(size)`.
```python
def fetch_in_chunks(cursor, size=1000):
    while True:
        rows = cursor.fetchmany(size)
        if not rows:
            break
        yield from rows
```

**1.3** `rows_as_dicts(cursor, size=1000)` yields each row as a dict using the column names in `cursor.description`.
```python
def rows_as_dicts(cursor, size=1000):
    columns = [col[0] for col in cursor.description]
    while True:
        rows = cursor.fetchmany(size)
        if not rows:
            break
        for row in rows:
            yield dict(zip(columns, row))
```

**1.4** `total_salary(rows)` returns the sum of the 2nd value of each row without building a list. `total_salary([(1, 100), (2, 50)])` → `150`
```python
def total_salary(rows):
    return sum(row[1] for row in rows)
```

**1.5** `filter_gender(rows, gender)` lazily yields rows whose 2nd value equals `gender`.
```python
def filter_gender(rows, gender):
    for row in rows:
        if row[1] == gender:
            yield row
```

**1.6** `paginate(fetch_page, page_size)` calls `fetch_page(offset, limit)` repeatedly and yields rows until a page is empty.
```python
def paginate(fetch_page, page_size):
    offset = 0
    while True:
        page = fetch_page(offset, page_size)
        if not page:
            return
        yield from page
        offset += page_size
```

**1.7** `build_query(table, columns, limit=None)` returns a SELECT string. `build_query("employees", ["emp_no", "first_name"], 5)` → `"SELECT emp_no, first_name FROM employees LIMIT 5"`. Raise `ValueError` for empty columns or names that are not letters/digits/underscore.
```python
import re


def build_query(table, columns, limit=None):
    if not columns:
        raise ValueError("columns required")
    for name in [table, *columns]:
        if not re.fullmatch(r"\w+", name):
            raise ValueError(f"bad identifier: {name}")
    sql = f"SELECT {', '.join(columns)} FROM {table}"
    if limit is not None:
        sql += f" LIMIT {int(limit)}"
    return sql
```

**1.8** `write_csv_stream(rows, path, header)` writes rows to a CSV one at a time and returns the row count.
```python
import csv


def write_csv_stream(rows, path, header):
    count = 0
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for row in rows:
            writer.writerow(row)
            count += 1
    return count
```

**1.9** `top_n(rows, n, key)` returns the `n` rows with the largest `key(row)` without sorting everything.
```python
import heapq


def top_n(rows, n, key):
    return heapq.nlargest(n, rows, key=key)
```

**1.10** `running_average(values)` is a generator yielding the average so far. `list(running_average([2, 4, 6]))` → `[2.0, 3.0, 4.0]`
```python
def running_average(values):
    total = count = 0
    for v in values:
        total += v
        count += 1
        yield total / count
```

---

# 2. Person / Male / Female (abstract class)

**2.1** Abstract `Shape` with `area()`. `Circle(r)` and `Square(side)` implement it. `Shape()` must raise `TypeError`.
```python
import math
from abc import ABC, abstractmethod


class Shape(ABC):
    @abstractmethod
    def area(self):
        ...


class Circle(Shape):
    def __init__(self, r):
        self.r = r

    def area(self):
        return math.pi * self.r ** 2


class Square(Shape):
    def __init__(self, side):
        self.side = side

    def area(self):
        return self.side ** 2
```

**2.2** Abstract `Animal` with `sound()`. `Dog` returns `"Woof"`, `Cat` returns `"Meow"`.
```python
from abc import ABC, abstractmethod


class Animal(ABC):
    @abstractmethod
    def sound(self):
        ...


class Dog(Animal):
    def sound(self):
        return "Woof"


class Cat(Animal):
    def sound(self):
        return "Meow"
```

**2.3** Abstract `Employee` with `monthly_pay()`. `FullTime(salary)` returns salary. `PartTime(hours, rate)` returns `hours * rate`.
```python
from abc import ABC, abstractmethod


class Employee(ABC):
    @abstractmethod
    def monthly_pay(self):
        ...


class FullTime(Employee):
    def __init__(self, salary):
        self.salary = salary

    def monthly_pay(self):
        return self.salary


class PartTime(Employee):
    def __init__(self, hours, rate):
        self.hours, self.rate = hours, rate

    def monthly_pay(self):
        return self.hours * self.rate
```

**2.4** `Person` (abstract `get_gender`) with a normal method `describe()` returning `"<name> is <gender>"`. `Male("Ravi").describe()` → `"Ravi is Male"`.
```python
from abc import ABC, abstractmethod


class Person(ABC):
    def __init__(self, name):
        self.name = name

    @abstractmethod
    def get_gender(self):
        ...

    def describe(self):
        return f"{self.name} is {self.get_gender()}"


class Male(Person):
    def get_gender(self):
        return "Male"


class Female(Person):
    def get_gender(self):
        return "Female"
```

**2.5** Show that a subclass that forgets to implement the abstract method cannot be created (`TypeError`).
```python
from abc import ABC, abstractmethod


class Person(ABC):
    @abstractmethod
    def get_gender(self):
        ...


class Broken(Person):
    pass


try:
    Broken()
except TypeError:
    print("Cannot instantiate: get_gender not implemented")
```

**2.6** Abstract class with **two** abstract methods `start()` and `stop()`. A child implementing only `start()` still cannot be created.
```python
from abc import ABC, abstractmethod


class Machine(ABC):
    @abstractmethod
    def start(self):
        ...

    @abstractmethod
    def stop(self):
        ...


class HalfMachine(Machine):
    def start(self):
        return "started"


# HalfMachine() -> TypeError, because stop() is still abstract
```

**2.7** Abstract `Vehicle` with `wheels()`. Write `total_wheels(vehicles)` summing over a list. `total_wheels([Car(), Bike()])` → `6`
```python
from abc import ABC, abstractmethod


class Vehicle(ABC):
    @abstractmethod
    def wheels(self):
        ...


class Car(Vehicle):
    def wheels(self):
        return 4


class Bike(Vehicle):
    def wheels(self):
        return 2


def total_wheels(vehicles):
    return sum(v.wheels() for v in vehicles)
```

**2.8** Abstract `Payment` with `pay(amount)`. `CardPayment` returns `"Card paid 100"`, `UpiPayment` returns `"UPI paid 100"`. Write `process(payment, amount)` that calls it.
```python
from abc import ABC, abstractmethod


class Payment(ABC):
    @abstractmethod
    def pay(self, amount):
        ...


class CardPayment(Payment):
    def pay(self, amount):
        return f"Card paid {amount}"


class UpiPayment(Payment):
    def pay(self, amount):
        return f"UPI paid {amount}"


def process(payment, amount):
    return payment.pay(amount)
```

**2.9** `get_person(name, gender)` returns `Male` or `Female` (case-insensitive), else raises `ValueError`.
```python
def get_person(name, gender):
    classes = {"male": Male, "female": Female}     # Male/Female from 2.4
    if gender.lower() not in classes:
        raise ValueError(f"Unknown gender: {gender}")
    return classes[gender.lower()](name)
```

**2.10** `count_genders(people)` returns e.g. `{"Male": 2, "Female": 1}` for a list of `Person` objects.
```python
def count_genders(people):
    counts = {}
    for person in people:
        g = person.get_gender()
        counts[g] = counts.get(g, 0) + 1
    return counts
```

---

# 3. Remove Duplicates, Keep Order

**3.1** `unique_ordered(items)`. `[12, 24, 35, 24, 88]` → `[12, 24, 35, 88]`
```python
def unique_ordered(items):
    seen = set()
    result = []
    for item in items:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result
```

**3.2** Case-insensitive version for strings, keeping the first spelling. `["Apple", "apple", "Bat"]` → `["Apple", "Bat"]`
```python
def unique_ignore_case(words):
    seen = set()
    result = []
    for w in words:
        if w.lower() not in seen:
            seen.add(w.lower())
            result.append(w)
    return result
```

**3.3** `unique_by(items, key)` removes dicts with a repeated `key` value (keep the first).
```python
def unique_by(items, key):
    seen = set()
    result = []
    for item in items:
        if item[key] not in seen:
            seen.add(item[key])
            result.append(item)
    return result
```

**3.4** Keep the **last** occurrence instead. `[1, 2, 1, 3, 2]` → `[1, 3, 2]`
```python
def unique_keep_last(items):
    return list(reversed(list(dict.fromkeys(reversed(items)))))
```

**3.5** Remove only **consecutive** duplicates. `[1, 1, 2, 2, 1]` → `[1, 2, 1]`
```python
from itertools import groupby


def remove_consecutive(items):
    return [key for key, _ in groupby(items)]
```

**3.6** Return the values that appear **exactly once**. `[1, 2, 2, 3]` → `[1, 3]`
```python
def only_once(items):
    return [x for x in items if items.count(x) == 1]
```

**3.7** Return the values that repeat, each once, in order of first appearance. `[1, 2, 2, 3, 1]` → `[1, 2]`
```python
from collections import Counter


def duplicates(items):
    counts = Counter(items)
    return [x for x in dict.fromkeys(items) if counts[x] > 1]
```

**3.8** Remove duplicate words from a sentence. `"a b a c b"` → `"a b c"`
```python
def unique_words(sentence):
    return " ".join(dict.fromkeys(sentence.split()))
```

**3.9** Unique characters of a string in order. `"banana"` → `"ban"`
```python
def unique_chars(text):
    return "".join(dict.fromkeys(text))
```

**3.10** Remove duplicate inner lists. `[[1, 2], [3], [1, 2]]` → `[[1, 2], [3]]`
```python
def unique_lists(lists):
    return [list(t) for t in dict.fromkeys(tuple(x) for x in lists)]
```

---

# 4. `map()` + `lambda`

**4.1** Cubes of 1 to 10 using `map`.
```python
cubes = list(map(lambda x: x ** 3, range(1, 11)))
```

**4.2** Squares of only the even numbers from 1 to 20 (`map` + `filter`).
```python
result = list(map(lambda x: x ** 2, filter(lambda x: x % 2 == 0, range(1, 21))))
```

**4.3** Celsius list to Fahrenheit. `[0, 100]` → `[32.0, 212.0]`
```python
def to_fahrenheit(temps):
    return list(map(lambda c: c * 9 / 5 + 32, temps))
```

**4.4** Length of each word. `["hi", "hello"]` → `[2, 5]`
```python
def word_lengths(words):
    return list(map(lambda w: len(w), words))
```

**4.5** Add two lists element by element using `map` with two iterables. `[1, 2]`, `[10, 20]` → `[11, 22]`
```python
def add_lists(xs, ys):
    return list(map(lambda a, b: a + b, xs, ys))
```

**4.6** Title-case every string. `["ravi kumar"]` → `["Ravi Kumar"]`
```python
def title_all(words):
    return list(map(lambda w: w.title(), words))
```

**4.7** Multiply each pair. `[(2, 3), (4, 5)]` → `[6, 20]`
```python
def multiply_pairs(pairs):
    return list(map(lambda t: t[0] * t[1], pairs))
```

**4.8** `squares_between(a, b)` returns squares of numbers from `a` to `b` inclusive. `squares_between(3, 5)` → `[9, 16, 25]`
```python
def squares_between(a, b):
    return list(map(lambda x: x * x, range(a, b + 1)))
```

**4.9** Sum of a list of numeric strings using `map(int, ...)`. `["1", "2", "3"]` → `6`
```python
def sum_strings(values):
    return sum(map(int, values))
```

**4.10** Label each number `"Even"` or `"Odd"`. `[1, 2]` → `["Odd", "Even"]`
```python
def parity(numbers):
    return list(map(lambda n: "Even" if n % 2 == 0 else "Odd", numbers))
```

---

# 5. `anti_html.py` (strip HTML tags)

**5.1** `strip_tags(html)` removes all tags. `"<p>Hi <b>there</b></p>"` → `"Hi there"`
```python
import re


def strip_tags(html):
    return re.sub(r"<[^>]+>", "", html)
```

**5.2** Also remove the contents of `<script>` and `<style>` blocks.
```python
import re


def strip_tags_clean(html):
    html = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", "", html)
    return re.sub(r"<[^>]+>", "", html)
```

**5.3** `word_count(html)` returns the number of words in the visible text. `"<p>a b</p><p>c</p>"` → `3`
```python
import re


def word_count(html):
    return len(re.sub(r"<[^>]+>", " ", html).split())
```

**5.4** `extract_links(html)` returns all `href` values. `'<a href="x.com">a</a>'` → `["x.com"]`
```python
import re


def extract_links(html):
    return re.findall(r'href="([^"]+)"', html)
```

**5.5** Turn `<br>` and `<br/>` into newlines before stripping. `"a<br>b"` → `"a\nb"`
```python
import re


def strip_with_breaks(html):
    html = re.sub(r"(?i)<br\s*/?>", "\n", html)
    return re.sub(r"<[^>]+>", "", html)
```

**5.6** After stripping tags, decode entities. `"<p>Tom &amp; Jerry</p>"` → `"Tom & Jerry"`
```python
import re
from html import unescape


def strip_and_decode(html):
    return unescape(re.sub(r"<[^>]+>", "", html))
```

**5.7** `get_url(argv)` returns the URL from the command line arguments. Raise `ValueError("Usage: python anti_html.py <url>")` if there isn't exactly one argument. `get_url(["anti_html.py", "http://x.com"])` → `"http://x.com"`
```python
def get_url(argv):
    if len(argv) != 2:
        raise ValueError("Usage: python anti_html.py <url>")
    return argv[1]
```

**5.8** Collapse all whitespace to single spaces. `"<p>a</p>\n\n<p>  b </p>"` → `"a b"`
```python
import re


def clean_text(html):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", html)).strip()
```

**5.9** `get_title(html)` returns the `<title>` text or `None`.
```python
import re


def get_title(html):
    match = re.search(r"(?is)<title[^>]*>(.*?)</title>", html)
    return match.group(1).strip() if match else None
```

**5.10** `download_and_strip(url, fetcher)` where `fetcher(url)` returns HTML (so tests can pass a fake).
```python
import re


def download_and_strip(url, fetcher):
    return re.sub(r"<[^>]+>", "", fetcher(url))


# real fetcher:
# import urllib.request
# fetcher = lambda u: urllib.request.urlopen(u, timeout=10).read().decode("utf-8", "replace")
```

---

# 6. Unit Testing (TDD katas)
Each one comes with example checks. Write the tests first, then this code.

**6.1** `fizzbuzz(n)` returns a list of strings for 1..n. `fizzbuzz(5)` → `["1", "2", "Fizz", "4", "Buzz"]`
```python
def fizzbuzz(n):
    out = []
    for i in range(1, n + 1):
        if i % 15 == 0:
            out.append("FizzBuzz")
        elif i % 3 == 0:
            out.append("Fizz")
        elif i % 5 == 0:
            out.append("Buzz")
        else:
            out.append(str(i))
    return out
```

**6.2** `is_leap_year(y)`. 2000 → True, 1900 → False, 2024 → True, 2023 → False.
```python
def is_leap_year(y):
    return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)
```

**6.3** `is_palindrome(text)` ignoring case and non-alphanumerics. `"A man, a plan, a canal: Panama"` → True
```python
import re


def is_palindrome(text):
    cleaned = re.sub(r"[^a-z0-9]", "", text.lower())
    return cleaned == cleaned[::-1]
```

**6.4** String calculator `add(text)`: `""` → 0, `"1,2,3"` → 6, `"1\n2,3"` → 6, negatives raise `ValueError`.
```python
import re


def add(text):
    if not text.strip():
        return 0
    numbers = [int(x) for x in re.split(r"[,\n]", text)]
    negatives = [n for n in numbers if n < 0]
    if negatives:
        raise ValueError(f"negatives not allowed: {negatives}")
    return sum(numbers)
```

**6.5** `is_prime(n)`. 1 → False, 2 → True, 15 → False, 17 → True.
```python
def is_prime(n):
    if n < 2:
        return False
    return all(n % d != 0 for d in range(2, int(n ** 0.5) + 1))
```

**6.6** `are_anagrams(a, b)` ignoring case and spaces. `"Listen", "Silent"` → True
```python
def are_anagrams(a, b):
    clean = lambda s: sorted(s.lower().replace(" ", ""))
    return clean(a) == clean(b)
```

**6.7** `word_count(text)` returns a dict of lowercase word counts. `"a b a"` → `{"a": 2, "b": 1}`
```python
import re


def word_count(text):
    counts = {}
    for word in re.findall(r"[a-z']+", text.lower()):
        counts[word] = counts.get(word, 0) + 1
    return counts
```

**6.8** `is_balanced(s)` for `()[]{}`. `"{[()]}"` → True, `"(]"` → False.
```python
def is_balanced(s):
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in s:
        if ch in "([{":
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                return False
    return not stack
```

**6.9** `celsius_to_fahrenheit(c)`; below -273.15 raises `ValueError`. `100` → `212.0`
```python
def celsius_to_fahrenheit(c):
    if c < -273.15:
        raise ValueError("below absolute zero")
    return c * 9 / 5 + 32
```

**6.10** `Stack` with `push`, `pop`, `peek`, `is_empty`; `pop`/`peek` on empty raise `IndexError`.
```python
class Stack:
    def __init__(self):
        self._items = []

    def push(self, item):
        self._items.append(item)

    def pop(self):
        if not self._items:
            raise IndexError("pop from empty stack")
        return self._items.pop()

    def peek(self):
        if not self._items:
            raise IndexError("peek from empty stack")
        return self._items[-1]

    def is_empty(self):
        return not self._items
```

---

# 7. REST API (Flask, validation, MVC, AWS)

**7.1** `validate_customer(data)` returns a list of error strings (empty when valid). `customer_id` and `company_name` are required.
```python
def validate_customer(data):
    errors = []
    if not str(data.get("customer_id", "")).strip():
        errors.append("customer_id is required")
    if not str(data.get("company_name", "")).strip():
        errors.append("company_name is required")
    return errors
```

**7.2** `validate_product(data)`: `name` non-empty string, `price` number > 0, `stock` int ≥ 0.
```python
def _is_number(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool)


def validate_product(data):
    errors = []
    if not isinstance(data.get("name"), str) or not data["name"].strip():
        errors.append("name is required")
    if not _is_number(data.get("price")) or data["price"] <= 0:
        errors.append("price must be a positive number")
    stock = data.get("stock")
    if not isinstance(stock, int) or isinstance(stock, bool) or stock < 0:
        errors.append("stock must be a non-negative integer")
    return errors
```

**7.3** `validate_order(data)`: `customer_id` required; `items` a non-empty list where every item has integer `quantity > 0`.
```python
def validate_order(data):
    errors = []
    if not data.get("customer_id"):
        errors.append("customer_id is required")
    items = data.get("items")
    if not isinstance(items, list) or not items:
        errors.append("items must be a non-empty list")
    else:
        for item in items:
            q = item.get("quantity")
            if not isinstance(q, int) or q <= 0:
                errors.append("quantity must be a positive integer")
                break
    return errors
```

**7.4** Flask `create_app()` with `GET /health` returning `{"status": "ok"}`.
```python
from flask import Flask, jsonify


def create_app():
    app = Flask(__name__)

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    return app
```

**7.5** `POST /customers` stores a customer in memory: 201 on success, 400 with `errors` if invalid, 409 if the id already exists.
```python
from flask import Flask, jsonify, request

CUSTOMERS = {}


def create_app():
    app = Flask(__name__)

    @app.post("/customers")
    def add_customer():
        data = request.get_json(silent=True) or {}
        errors = validate_customer(data)          # from 7.1
        if errors:
            return jsonify(errors=errors), 400
        if data["customer_id"] in CUSTOMERS:
            return jsonify(error="exists"), 409
        CUSTOMERS[data["customer_id"]] = data
        return jsonify(data), 201

    return app
```

**7.6** `PUT /products/<int:pid>` updates fields of an existing product (404 if missing, 400 if invalid).
```python
PRODUCTS = {}


@app.put("/products/<int:pid>")
def update_product(pid):
    if pid not in PRODUCTS:
        return jsonify(error="Not found"), 404
    updated = {**PRODUCTS[pid], **(request.get_json(silent=True) or {})}
    errors = validate_product(updated)            # from 7.2
    if errors:
        return jsonify(errors=errors), 400
    PRODUCTS[pid] = updated
    return jsonify(updated), 200
```

**7.7** `GET /customers/<cid>/orders` returns that customer's orders, newest first (`order_date` as `YYYY-MM-DD` string); 404 if the customer is unknown.
```python
CUSTOMERS = {"C1": {"customer_id": "C1"}}
ORDERS = [
    {"order_id": 1, "customer_id": "C1", "order_date": "2024-01-01"},
    {"order_id": 2, "customer_id": "C1", "order_date": "2024-03-01"},
]


@app.get("/customers/<cid>/orders")
def order_history(cid):
    if cid not in CUSTOMERS:
        return jsonify(error="Customer not found"), 404
    mine = [o for o in ORDERS if o["customer_id"] == cid]
    mine.sort(key=lambda o: o["order_date"], reverse=True)
    return jsonify(mine), 200
```

**7.8** Return JSON for 404 errors instead of the default HTML page.
```python
@app.errorhandler(404)
def not_found(error):
    return jsonify(error="Not found"), 404
```

**7.9** Test a route with the service mocked. The route calls `service.get_customer(cid)`.
```python
# service.py
def get_customer(customer_id):
    raise NotImplementedError          # real version reads DynamoDB


# app.py
from flask import Flask, jsonify
import service


def create_app():
    app = Flask(__name__)

    @app.get("/customers/<cid>")
    def get_customer(cid):
        customer = service.get_customer(cid)
        return (jsonify(customer), 200) if customer else (jsonify(error="Not found"), 404)

    return app


# test_app.py
from unittest.mock import patch
from app import create_app


@patch("app.service.get_customer", return_value={"customer_id": "C1"})
def test_found(mock_get):
    res = create_app().test_client().get("/customers/C1")
    assert res.status_code == 200
    mock_get.assert_called_once_with("C1")


@patch("app.service.get_customer", return_value=None)
def test_missing(mock_get):
    assert create_app().test_client().get("/customers/X").status_code == 404
```

**7.10** `parse_event(event)` for an API Gateway → Lambda event returns `(method, path_params, body_dict)`. Body may be missing.
```python
import json


def parse_event(event):
    method = event.get("httpMethod")
    params = event.get("pathParameters") or {}
    body = json.loads(event["body"]) if event.get("body") else {}
    return method, params, body
```

---

# 8. ETL: Average Age of Developers at First Line of Code
Column: `Age1stCode`. Use the common setup above.

**8.1** `avg_first_code_age(df)` returns the mean age (ignore non-numeric values).
```python
def first_age(df):
    return pd.to_numeric(df["Age1stCode"], errors="coerce")


def avg_first_code_age(df):
    return first_age(df).mean()
```

**8.2** Average per country.
```python
def avg_age_by_country(df):
    return df.assign(age=first_age(df)).groupby("Country")["age"].mean()
```

**8.3** Average using only ages between `low` and `high`, inclusive.
```python
def avg_age_filtered(df, low=5, high=25):
    ages = first_age(df)
    return ages[(ages >= low) & (ages <= high)].mean()
```

**8.4** Median instead of mean.
```python
def median_first_age(df):
    return first_age(df).median()
```

**8.5** Average by `Hobbyist` (Yes/No).
```python
def avg_age_by_hobby(df):
    return df.assign(age=first_age(df)).groupby("Hobbyist")["age"].mean()
```

**8.6** How many developers started coding before age 10?
```python
def started_before_ten(df):
    return int((first_age(df) < 10).sum())
```

**8.7** Average by gender category (`MAN`, `WOMAN`, `OTHERS`).
```python
def avg_age_by_gender(df):
    d = df.assign(age=first_age(df), g=df["Gender"].apply(gender_category))
    return d.groupby("g")["age"].mean()
```

**8.8** Return `(youngest, oldest)` starting age.
```python
def age_range(df):
    ages = first_age(df).dropna()
    return ages.min(), ages.max()
```

**8.9** Return a dict `{"mean": ..., "min": ..., "max": ...}` with the mean rounded to 2 decimals.
```python
def age_summary(df):
    ages = first_age(df).dropna()
    return {"mean": round(ages.mean(), 2), "min": ages.min(), "max": ages.max()}
```

**8.10** Handle text values: `"Younger than 5 years"` → 4 and `"Older than 85"` → 86. Return the mean.
```python
def clean_age(value):
    if pd.isna(value):
        return None
    text = str(value)
    if text.startswith("Younger"):
        return 4
    if text.startswith("Older"):
        return 86
    try:
        return int(float(text))
    except ValueError:
        return None


def avg_age_clean(df):
    return pd.to_numeric(df["Age1stCode"].apply(clean_age)).mean()
```

---

# 9. ETL: Percentage of Developers Who Know Python per Country
Column: `LanguageWorkedWith` (values like `"Python;C++;SQL"`).

**9.1** `knows_language(series, lang)` returns a boolean Series.
```python
def knows_language(series, lang):
    return series.fillna("").str.split(";").apply(lambda langs: lang in langs)
```

**9.2** Percentage per country for Python, rounded to 2 decimals.
```python
def python_pct_by_country(df):
    knows = has_language(df["LanguageWorkedWith"], "Python")
    return (knows.groupby(df["Country"]).mean() * 100).round(2)
```

**9.3** Same for any language: `pct_by_country(df, lang)`.
```python
def pct_by_country(df, lang):
    knows = has_language(df["LanguageWorkedWith"], lang)
    return (knows.groupby(df["Country"]).mean() * 100).round(2)
```

**9.4** Countries with at least `min_count` respondents and a Python percentage above `threshold`.
```python
def strong_python_countries(df, min_count=50, threshold=50):
    grouped = has_language(df["LanguageWorkedWith"], "Python").groupby(df["Country"])
    pct = grouped.mean() * 100
    return pct[(grouped.size() >= min_count) & (pct > threshold)]
```

**9.5** Top 5 countries by Python percentage.
```python
def top_python_countries(df, n=5):
    return pct_by_country(df, "Python").sort_values(ascending=False).head(n)
```

**9.6** Number (not percentage) of Python developers per country.
```python
def python_count_by_country(df):
    knows = has_language(df["LanguageWorkedWith"], "Python")
    return knows.groupby(df["Country"]).sum()
```

**9.7** Overall percentage of Python developers, rounded to 2 decimals.
```python
def overall_python_pct(df):
    return round(has_language(df["LanguageWorkedWith"], "Python").mean() * 100, 2)
```

**9.8** DataFrame comparing several languages per country. `compare_languages(df, ["Python", "Java"])`
```python
def compare_languages(df, langs):
    return pd.DataFrame({lang: pct_by_country(df, lang) for lang in langs})
```

**9.9** Python percentage per country among **hobbyists only**.
```python
def python_pct_hobbyists(df):
    return pct_by_country(df[df["Hobbyist"] == "Yes"], "Python")
```

**9.10** Average number of languages known per respondent, per country.
```python
def avg_languages_by_country(df):
    counts = df["LanguageWorkedWith"].fillna("").apply(
        lambda s: len([x for x in s.split(";") if x]))
    return counts.groupby(df["Country"]).mean()
```

---

# 10. ETL: Average Salary by Continent
Column: `ConvertedComp`. Uses `add_continent` from the common setup.

**10.1** `avg_salary_by_continent(df)` rounded to 2 decimals.
```python
def avg_salary_by_continent(df):
    return add_continent(df).groupby("continent")["ConvertedComp"].mean().round(2)
```

**10.2** Median salary per continent.
```python
def median_salary_by_continent(df):
    return add_continent(df).groupby("continent")["ConvertedComp"].median()
```

**10.3** Name of the country with the highest average salary.
```python
def top_paying_country(df):
    return df.groupby("Country")["ConvertedComp"].mean().idxmax()
```

**10.4** Number of respondents with a salary value, per continent.
```python
def salary_count_by_continent(df):
    return add_continent(df).groupby("continent")["ConvertedComp"].count()
```

**10.5** Average per continent using only salaries between `low` and `high`.
```python
def avg_salary_filtered(df, low=1000, high=500000):
    d = add_continent(df)
    d = d[(d["ConvertedComp"] >= low) & (d["ConvertedComp"] <= high)]
    return d.groupby("continent")["ConvertedComp"].mean()
```

**10.6** Name of the continent with the highest average salary.
```python
def best_continent(df):
    return avg_salary_by_continent(df).idxmax()
```

**10.7** Average by continent and gender category.
```python
def avg_salary_by_continent_gender(df):
    d = add_continent(df)
    d["gender_cat"] = d["Gender"].apply(gender_category)
    return d.groupby(["continent", "gender_cat"])["ConvertedComp"].mean()
```

**10.8** DataFrame with columns `continent`, `avg_salary`, sorted highest first.
```python
def salary_report(df):
    series = avg_salary_by_continent(df).sort_values(ascending=False)
    return series.reset_index(name="avg_salary")
```

**10.9** Average per continent for `"Employed full-time"` only.
```python
def fulltime_salary_by_continent(df):
    return avg_salary_by_continent(df[df["Employment"] == "Employed full-time"])
```

**10.10** Percentage of respondents earning above `threshold`, per continent.
```python
def pct_above(df, threshold=100000):
    d = add_continent(df).dropna(subset=["ConvertedComp"])
    d = d.assign(high=d["ConvertedComp"] > threshold)
    return (d.groupby("continent")["high"].mean() * 100).round(2)
```

---

# 11. ETL: Most Desired Language for 2020
Column: `LanguageDesireNextYear` (`;`-separated).

**11.1** `most_desired(df)` returns the name of the most desired language.
```python
def most_desired(df):
    langs = df["LanguageDesireNextYear"].dropna().str.split(";").explode()
    return langs.value_counts().idxmax()
```

**11.2** Top `n` desired languages with counts.
```python
def top_desired(df, n=5):
    langs = df["LanguageDesireNextYear"].dropna().str.split(";").explode()
    return langs.value_counts().head(n)
```

**11.3** Percentage of respondents who want each language (rounded to 2 decimals).
```python
def desired_pct(df):
    answers = df["LanguageDesireNextYear"].dropna()
    counts = answers.str.split(";").explode().value_counts()
    return (counts / len(answers) * 100).round(2)
```

**11.4** Languages people **want but don't currently use**, most wanted first.
```python
def desired_not_used(df):
    d = df.dropna(subset=["LanguageDesireNextYear"])
    worked = d["LanguageWorkedWith"].fillna("").str.split(";")
    desired = d["LanguageDesireNextYear"].str.split(";")
    new = [l for want, have in zip(desired, worked) for l in want if l not in have]
    return pd.Series(new).value_counts()
```

**11.5** Most desired language per continent.
```python
def most_desired_by_continent(df):
    d = add_continent(df).dropna(subset=["LanguageDesireNextYear"])
    d = d.assign(lang=d["LanguageDesireNextYear"].str.split(";")).explode("lang")
    counts = d.groupby(["continent", "lang"]).size()
    return counts.groupby(level=0).idxmax().apply(lambda idx: idx[1])
```

**11.6** Languages that people **both use and want** (count each), most common first.
```python
def loved_languages(df):
    d = df.dropna(subset=["LanguageDesireNextYear", "LanguageWorkedWith"])
    worked = d["LanguageWorkedWith"].str.split(";")
    desired = d["LanguageDesireNextYear"].str.split(";")
    both = [l for want, have in zip(desired, worked) for l in want if l in have]
    return pd.Series(both).value_counts()
```

**11.7** Most desired language among hobbyists only.
```python
def most_desired_hobbyists(df):
    return most_desired(df[df["Hobbyist"] == "Yes"])
```

**11.8** The `n` least desired languages.
```python
def least_desired(df, n=3):
    langs = df["LanguageDesireNextYear"].dropna().str.split(";").explode()
    return langs.value_counts().tail(n)
```

**11.9** How many respondents want Python?
```python
def want_python(df):
    return int(has_language(df["LanguageDesireNextYear"], "Python").sum())
```

**11.10** Average number of desired languages per respondent.
```python
def avg_desired_count(df):
    return df["LanguageDesireNextYear"].dropna().str.split(";").apply(len).mean()
```

---

# 12. ETL: Hobbyists by Gender and Continent
Gender must be `MAN`, `WOMAN`, `OTHERS` (only an exact `Man` or `Woman` counts as MAN or WOMAN).

**12.1** `gender_category(value)`. `"Man"` → `"MAN"`, `"Woman"` → `"WOMAN"`, `"Man;Non-binary"` → `"OTHERS"`, `NaN` → `"OTHERS"`.
```python
def gender_category(value):
    if value == "Man":
        return "MAN"
    if value == "Woman":
        return "WOMAN"
    return "OTHERS"
```

**12.2** Number of hobbyists per gender category.
```python
def hobby_by_gender(df):
    hobbyists = df[df["Hobbyist"] == "Yes"]
    return hobbyists["Gender"].apply(gender_category).value_counts()
```

**12.3** Number of hobbyists per continent.
```python
def hobby_by_continent(df):
    return add_continent(df[df["Hobbyist"] == "Yes"]).groupby("continent").size()
```

**12.4** Crosstab: continents as rows, gender categories as columns, hobbyists only.
```python
def hobby_crosstab(df, value="Yes"):
    h = add_continent(df[df["Hobbyist"] == value])
    return pd.crosstab(h["continent"], h["Gender"].apply(gender_category))
```

**12.5** Percentage of respondents in each continent who code as a hobby.
```python
def hobby_pct_by_continent(df):
    d = add_continent(df)
    d = d.assign(h=d["Hobbyist"] == "Yes")
    return (d.groupby("continent")["h"].mean() * 100).round(2)
```

**12.6** Percentage of each gender category who code as a hobby.
```python
def hobby_pct_by_gender(df):
    d = df.assign(g=df["Gender"].apply(gender_category), h=df["Hobbyist"] == "Yes")
    return (d.groupby("g")["h"].mean() * 100).round(2)
```

**12.7** Same crosstab for **non**-hobbyists.
```python
non_hobby = hobby_crosstab(df, value="No")      # uses the value argument from 12.4
```

**12.8** Add a boolean column `hobby_flag` without changing the original DataFrame.
```python
def add_hobby_flag(df):
    return df.assign(hobby_flag=df["Hobbyist"] == "Yes")
```

**12.9** Continent with the most `WOMAN` hobbyists.
```python
def top_continent_women(df):
    return hobby_crosstab(df)["WOMAN"].idxmax()
```

**12.10** Crosstab that always has all 3 gender columns (fill 0).
```python
def hobby_table(df):
    return hobby_crosstab(df).reindex(columns=["MAN", "WOMAN", "OTHERS"], fill_value=0)
```

---

# 13. ETL: Job and Career Satisfaction by Gender and Continent
Columns: `JobSat`, `CareerSat`. Answers are `"Very satisfied"`, `"Slightly satisfied"`, `"Neither satisfied nor dissatisfied"`, `"Slightly dissatisfied"`, `"Very dissatisfied"`.
```python
SCORE = {
    "Very satisfied": 5, "Slightly satisfied": 4,
    "Neither satisfied nor dissatisfied": 3,
    "Slightly dissatisfied": 2, "Very dissatisfied": 1,
}
```

**13.1** Count of each `JobSat` answer per gender category.
```python
def jobsat_by_gender(df):
    return pd.crosstab(df["Gender"].apply(gender_category), df["JobSat"])
```

**13.2** Count of each `CareerSat` answer per continent.
```python
def careersat_by_continent(df):
    d = add_continent(df)
    return pd.crosstab(d["continent"], d["CareerSat"])
```

**13.3** Count of `JobSat` answers per continent **and** gender category.
```python
def jobsat_by_continent_gender(df):
    d = add_continent(df)
    d["gender_cat"] = d["Gender"].apply(gender_category)
    return d.groupby(["continent", "gender_cat", "JobSat"]).size()
```

**13.4** Percentage answering `"Very satisfied"` (JobSat) per continent.
```python
def pct_very_satisfied(df):
    d = add_continent(df).dropna(subset=["JobSat"])
    d = d.assign(v=d["JobSat"] == "Very satisfied")
    return (d.groupby("continent")["v"].mean() * 100).round(2)
```

**13.5** Average numeric JobSat score per gender category.
```python
def mean_score_by_gender(df):
    d = df.assign(score=df["JobSat"].map(SCORE), g=df["Gender"].apply(gender_category))
    return d.groupby("g")["score"].mean()
```

**13.6** Crosstab of `JobSat` against `CareerSat`.
```python
def sat_crosstab(df):
    return pd.crosstab(df["JobSat"], df["CareerSat"])
```

**13.7** Percentage dissatisfied (slightly or very) with their job, per gender category.
```python
def pct_dissatisfied(df):
    d = df.dropna(subset=["JobSat"])
    bad = d["JobSat"].isin(["Slightly dissatisfied", "Very dissatisfied"])
    return (bad.groupby(d["Gender"].apply(gender_category)).mean() * 100).round(2)
```

**13.8** Pivot table of mean JobSat score: continents as rows, gender categories as columns.
```python
def score_pivot(df):
    d = add_continent(df)
    d["gender_cat"] = d["Gender"].apply(gender_category)
    d["score"] = d["JobSat"].map(SCORE)
    return pd.pivot_table(d, values="score", index="continent",
                          columns="gender_cat", aggfunc="mean")
```

**13.9** Continent with the highest mean `CareerSat` score.
```python
def happiest_continent(df):
    d = add_continent(df).assign(score=df["CareerSat"].map(SCORE))
    return d.groupby("continent")["score"].mean().idxmax()
```

**13.10** Row percentages of JobSat per continent (each row sums to 100).
```python
def jobsat_percent(df):
    d = add_continent(df)
    return (pd.crosstab(d["continent"], d["JobSat"], normalize="index") * 100).round(1)
```

---

# 14. Notepad Tracker (Flask + git)
Use `tmp_path` folders when testing. The commit command passes a name and email, so it works on a fresh machine.
```python
import os
import subprocess

GIT = ["git", "-c", "user.name=Notepad", "-c", "user.email=notepad@local"]
```

**14.1** `save_note(path, content)` creates missing folders, writes the file, and returns the path.
```python
def save_note(path, content):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    return path
```

**14.2** `is_git_repo(directory)` returns True if `.git` exists in it.
```python
def is_git_repo(directory):
    return os.path.isdir(os.path.join(directory, ".git"))
```

**14.3** `ensure_repo(directory)` runs `git init` if needed; returns True if it created a repo.
```python
def ensure_repo(directory):
    if is_git_repo(directory):
        return False
    subprocess.run(["git", "-C", directory, "init"], capture_output=True)
    return True
```

**14.4** `commit_file(path, message)` stages the file and commits. Returns True if a commit was made, False if nothing changed.
```python
def commit_file(path, message):
    folder, name = os.path.split(path)
    ensure_repo(folder)
    subprocess.run(GIT + ["-C", folder, "add", name], capture_output=True)
    unchanged = subprocess.run(
        ["git", "-C", folder, "diff", "--cached", "--quiet"]).returncode == 0
    if unchanged:
        return False
    result = subprocess.run(GIT + ["-C", folder, "commit", "-m", message],
                            capture_output=True)
    return result.returncode == 0
```

**14.5** Flask `POST /save` with JSON `{path, content}`: return 400 if the path is not absolute; otherwise save and return `{"saved": true}`.
```python
from flask import Flask, jsonify, request

app = Flask(__name__)


@app.post("/save")
def save():
    data = request.get_json(silent=True) or {}
    path = data.get("path", "")
    if not os.path.isabs(path):
        return jsonify(error="Path must be absolute"), 400
    save_note(path, data.get("content", ""))
    return jsonify(saved=True)
```

**14.6** `Debouncer(delay, func)` with `call(*args)`: runs `func` only after `delay` seconds pass with no new call. (This is the "commit when the user stops writing" idea.)
```python
import threading


class Debouncer:
    def __init__(self, delay, func):
        self.delay, self.func, self._timer = delay, func, None

    def call(self, *args):
        if self._timer:
            self._timer.cancel()
        self._timer = threading.Timer(self.delay, self.func, args)
        self._timer.start()
```

**14.7** `list_notes(directory)` returns sorted names of `.txt` files.
```python
def list_notes(directory):
    return sorted(f for f in os.listdir(directory) if f.endswith(".txt"))
```

**14.8** `read_note(path)` returns the text, or `None` if the file doesn't exist.
```python
def read_note(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return None
```

**14.9** `make_message(path, now)` returns `"Update note.txt at 2026-09-29 10:30:00"`.
```python
from datetime import datetime


def make_message(path, now=None):
    now = now or datetime.now()
    return f"Update {os.path.basename(path)} at {now:%Y-%m-%d %H:%M:%S}"
```

**14.10** `get_history(path)` returns the git log lines (one per commit) for that file.
```python
def get_history(path):
    folder, name = os.path.split(path)
    out = subprocess.run(["git", "-C", folder, "log", "--oneline", "--", name],
                         capture_output=True, text=True).stdout
    return out.strip().splitlines()
```

---

# 15. XLSX → CSV Converter
```python
import os
import re
import pandas as pd
```

**15.1** `safe_name(name)` replaces `\ / : * ? " < > |` with `_`. `"Q1/Q2"` → `"Q1_Q2"`
```python
def safe_name(name):
    return re.sub(r'[\\/:*?"<>|]', "_", name).strip()
```

**15.2** `output_dir_name(path)` returns the file name without folder or extension. `"data/Sample_Data.xlsx"` → `"Sample_Data"`
```python
def output_dir_name(path):
    return os.path.splitext(os.path.basename(path))[0]
```

**15.3** `convert(path, out_root=".")` writes every sheet to `<out_root>/<file_name>/<sheet>.csv` and returns the list of written paths.
```python
def convert(path, out_root="."):
    sheets = pd.read_excel(path, sheet_name=None)
    folder = os.path.join(out_root, output_dir_name(path))
    os.makedirs(folder, exist_ok=True)
    written = []
    for name, df in sheets.items():
        target = os.path.join(folder, f"{safe_name(name)}.csv")
        df.to_csv(target, index=False)
        written.append(target)
    return written
```

**15.4** Same as 15.3 but skip empty sheets.
```python
def convert_non_empty(path, out_root="."):
    sheets = pd.read_excel(path, sheet_name=None)
    folder = os.path.join(out_root, output_dir_name(path))
    os.makedirs(folder, exist_ok=True)
    written = []
    for name, df in sheets.items():
        if df.empty:
            continue
        target = os.path.join(folder, f"{safe_name(name)}.csv")
        df.to_csv(target, index=False)
        written.append(target)
    return written
```

**15.5** `sheet_names(path)` returns the list of sheet names.
```python
def sheet_names(path):
    return pd.ExcelFile(path).sheet_names
```

**15.6** `google_export_url(link)` turns a Google Sheet link into its xlsx export link. `".../spreadsheets/d/ABC123/edit"` → `"https://docs.google.com/spreadsheets/d/ABC123/export?format=xlsx"`
```python
def google_export_url(link):
    match = re.search(r"/d/([\w-]+)", link)
    if not match:
        raise ValueError("Not a Google Sheets link")
    return f"https://docs.google.com/spreadsheets/d/{match.group(1)}/export?format=xlsx"
```

**15.7** `write_sheet_csv(df, path)` writes without the index column (the single header row is kept) and returns the number of data rows.
```python
def write_sheet_csv(df, path):
    df.to_csv(path, index=False)
    return len(df)
```

**15.8** Convert only the sheets whose names are in a given list.
```python
def convert_selected(path, wanted, out_root="."):
    sheets = pd.read_excel(path, sheet_name=list(wanted))
    folder = os.path.join(out_root, output_dir_name(path))
    os.makedirs(folder, exist_ok=True)
    for name, df in sheets.items():
        df.to_csv(os.path.join(folder, f"{safe_name(name)}.csv"), index=False)
    return sorted(sheets)
```

**15.9** Prefix files with the sheet position: `1_Sheet1.csv`, `2_Sheet2.csv`.
```python
def convert_numbered(path, out_root="."):
    sheets = pd.read_excel(path, sheet_name=None)
    folder = os.path.join(out_root, output_dir_name(path))
    os.makedirs(folder, exist_ok=True)
    for i, (name, df) in enumerate(sheets.items(), start=1):
        df.to_csv(os.path.join(folder, f"{i}_{safe_name(name)}.csv"), index=False)
```

**15.10** `rows_per_sheet(path)` returns `{sheet_name: row_count}`.
```python
def rows_per_sheet(path):
    return {name: len(df) for name, df in pd.read_excel(path, sheet_name=None).items()}
```

---

# 16. SQL Information Extraction (regex)
```python
import json
import re

SQL = """
-- get orders
CREATE PROCEDURE get_orders (IN p_customer_id INT, OUT p_total DECIMAL(10,2))
AS
BEGIN
    DECLARE @count INT;
    WITH recent AS (SELECT id FROM orders o JOIN customers c ON c.id = o.cid)
    SELECT COUNT(*) AS total FROM recent;
    UPDATE stats SET n = 1;
END
"""
```

**16.1** `get_procedure_name(sql)` → `"get_orders"` (or `None`).
```python
def get_procedure_name(sql):
    m = re.search(r"CREATE\s+(?:OR\s+REPLACE\s+)?PROCEDURE\s+([\w.]+)", sql, re.I)
    return m.group(1) if m else None
```

**16.2** `get_parameter_names(sql)` → `["p_customer_id", "p_total"]`
```python
def get_parameter_names(sql):
    m = re.search(r"PROCEDURE\s+[\w.]+\s*\((.*?)\)\s*(?:AS|BEGIN|LANGUAGE|$)", sql, re.I | re.S)
    if not m or not m.group(1).strip():
        return []
    names = []
    for part in re.split(r",(?![^(]*\))", m.group(1)):
        tokens = part.split()
        names.append(tokens[1] if tokens[0].upper() in ("IN", "OUT", "INOUT") else tokens[0])
    return names
```

**16.3** `get_tables(sql)` returns the sorted set of names after `FROM` or `JOIN`. For the sample: `["customers", "orders", "recent"]`
```python
def get_tables(sql):
    return sorted(set(re.findall(r"\b(?:FROM|JOIN)\s+([\w.]+)", sql, re.I)))
```

**16.4** `remove_comments(sql)` removes `-- ...` lines and `/* ... */` blocks.
```python
def remove_comments(sql):
    return re.sub(r"--.*?$|/\*.*?\*/", "", sql, flags=re.S | re.M)
```

**16.5** `get_declared_variables(sql)` → `["count"]` (handles `DECLARE @x INT` and `DECLARE x INT`).
```python
def get_declared_variables(sql):
    return re.findall(r"DECLARE\s+@?(\w+)\s+", sql, re.I)
```

**16.6** `count_selects(sql)` → number of `SELECT` keywords (case-insensitive).
```python
def count_selects(sql):
    return len(re.findall(r"\bSELECT\b", sql, re.I))
```

**16.7** `get_dml_types(sql)` → sorted set of `INSERT`, `UPDATE`, `DELETE`, `MERGE` found. Sample → `["UPDATE"]`
```python
def get_dml_types(sql):
    found = re.findall(r"\b(INSERT|UPDATE|DELETE|MERGE)\b", sql, re.I)
    return sorted({word.upper() for word in found})
```

**16.8** `get_aliases(sql)` returns names after `AS`, ignoring `BEGIN`. Sample → `["recent", "total"]`
```python
def get_aliases(sql):
    return [a for a in re.findall(r"\bAS\s+(\w+)", sql, re.I) if a.upper() != "BEGIN"]
```

**16.9** `write_json(data, path)` writes with `indent=2` and returns the path.
```python
def write_json(data, path):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    return path
```

**16.10** `get_cte_names(sql)` → `["recent"]`
```python
def get_cte_names(sql):
    return re.findall(r"(?:\bWITH|,)\s*(\w+)\s+AS\s*\(", sql, re.I)
```

---

# 17. Data Manipulation (JSON → MySQL → pandas)
Input JSON shape: `{"cols": ["name", "email", "postalZip", "phone"], "data": [[...], [...]]}`
```python
import re
import pandas as pd
```

**17.1** `load_df(data)` builds a DataFrame with the right column names.
```python
def load_df(data):
    return pd.DataFrame(data["data"], columns=data["cols"])
```

**17.2** `create_table_sql(table, cols)` returns `CREATE TABLE IF NOT EXISTS json_to_sql_table (`name` VARCHAR(255), `email` VARCHAR(255))` for `cols=["name", "email"]`.
```python
def create_table_sql(table, cols):
    columns = ", ".join(f"`{c}` VARCHAR(255)" for c in cols)
    return f"CREATE TABLE IF NOT EXISTS {table} ({columns})"
```

**17.3** `to_gmail(email)` keeps the part before `@` and ends the address with `gmail.com`. `"abc@yahoo.com"` → `"abc@gmail.com"`
```python
def to_gmail(email):
    return email.split("@")[0] + "@gmail.com"
```

**17.4** `zip_to_int(value)` removes letters and returns an int. `"AB123"` → `123`, `4500` → `4500`, `"ABC"` → `0`.
```python
def zip_to_int(value):
    digits = re.sub(r"\D", "", str(value))
    return int(digits) if digits else 0
```

**17.5** `clean_phone(value)` keeps only digits. `"(816) 530-4269"` → `"8165304269"`
```python
def clean_phone(value):
    return re.sub(r"\D", "", str(value))
```

**17.6** `encode_phone(value)` takes 2 digits at a time from the left. If the number is between 65 and 99, use `chr(number)`; otherwise use `"O"`. Ignore a leftover single digit. `"(816) 530-4269"` → `"QAOOE"`, `"1-811-920-9732"` → `"OO\\OI"`
```python
def encode_phone(value):
    digits = re.sub(r"\D", "", str(value))
    out = []
    for i in range(0, len(digits) - 1, 2):
        number = int(digits[i:i + 2])
        out.append(chr(number) if 65 <= number <= 99 else "O")
    return "".join(out)
```

**17.7** `rename_phone(df)` renames `phone` to `coded_phone_number` (returns a new DataFrame).
```python
def rename_phone(df):
    return df.rename(columns={"phone": "coded_phone_number"})
```

**17.8** `encode_digits(value, low, high, filler)` is the generic version: pairs in `[low, high]` become `chr(pair)`, others become `filler`. `encode_digits("7080", 70, 90, "X")` → `"FP"`
```python
def encode_digits(value, low=65, high=99, filler="O"):
    digits = re.sub(r"\D", "", str(value))
    out = []
    for i in range(0, len(digits) - 1, 2):
        number = int(digits[i:i + 2])
        out.append(chr(number) if low <= number <= high else filler)
    return "".join(out)
```
Check: 70 → `F`, 80 → `P`, so `"7080"` → `"FP"`.

**17.9** `clean_df(df)` applies every step (email, postalZip, phone encode, rename) and returns the new DataFrame.
```python
def clean_df(df):
    df = df.copy()
    df["email"] = df["email"].apply(to_gmail)
    df["postalZip"] = df["postalZip"].apply(zip_to_int)
    df["phone"] = df["phone"].apply(encode_phone)
    return df.rename(columns={"phone": "coded_phone_number"})
```

**17.10** `build_insert(table, cols)` returns the parameterised INSERT string. `build_insert("t", ["a", "b"])` → ``INSERT INTO t (`a`, `b`) VALUES (%s, %s)``
```python
def build_insert(table, cols):
    names = ", ".join(f"`{c}`" for c in cols)
    placeholders = ", ".join(["%s"] * len(cols))
    return f"INSERT INTO {table} ({names}) VALUES ({placeholders})"
```

---

## How to use this file
1. Cover the solution and write the function from the question and its example.
2. Turn the example into an `assert` and run it.
3. For the pandas topics (8-13), build a 4-5 row DataFrame by hand and check the result on paper first.
4. The PDF also asks for PEP8, logging, exception handling, a config file and unit tests. Add a docstring and a `try/except` where the exam question mentions files, network or the database.
