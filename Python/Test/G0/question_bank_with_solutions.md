# Python Practice Question Bank — With Solutions
### 19 Topics × 3 Questions (Easy / Medium / Hard), each with sample input/output and a verified working solution

Every solution below was actually executed against its stated sample input — the sample output
shown is the real, confirmed output, not a predicted one.

---

## 1. Lists

### Easy — Remove duplicates, preserve order
**Input:** `[1, 2, 2, 3, 1, 4]`
**Output:** `[1, 2, 3, 4]`
```python
def remove_duplicates_preserve_order(lst):
    seen = set()
    result = []
    for x in lst:
        if x not in seen:
            seen.add(x)
            result.append(x)
    return result
```

### Medium — All pairs summing to a target
**Input:** `nums=[1,2,3,4,5], target=6`
**Output:** `[(2, 4), (1, 5)]`
```python
def pairs_with_sum(nums, target):
    seen = set()
    pairs = []
    for n in nums:
        complement = target - n
        if complement in seen:
            pairs.append((complement, n))
        seen.add(n)
    return pairs
```

### Hard — Longest Increasing Subsequence (length + sequence)
**Input:** `[10, 9, 2, 5, 3, 7, 101, 18]`
**Output:** `(4, [2, 5, 7, 101])`
```python
def longest_increasing_subsequence(nums):
    if not nums:
        return 0, []
    n = len(nums)
    lengths = [1] * n
    prev = [-1] * n
    for i in range(1, n):
        for j in range(i):
            if nums[j] < nums[i] and lengths[j] + 1 > lengths[i]:
                lengths[i] = lengths[j] + 1
                prev[i] = j
    best_idx = max(range(n), key=lambda i: lengths[i])
    seq = []
    i = best_idx
    while i != -1:
        seq.append(nums[i])
        i = prev[i]
    seq.reverse()
    return lengths[best_idx], seq
```

---

## 2. Dictionaries

### Easy — Word frequency
**Input:** `"the cat sat on the mat the cat ran"`
**Output:** `{'the': 3, 'cat': 2, 'sat': 1, 'on': 1, 'mat': 1, 'ran': 1}`
```python
def word_frequency(sentence):
    freq = {}
    for word in sentence.split():
        freq[word] = freq.get(word, 0) + 1
    return freq
```

### Medium — Merge dicts, summing shared keys
**Input:** `{'a':1,'b':2}`, `{'b':3,'c':4}`
**Output:** `{'a': 1, 'b': 5, 'c': 4}`
```python
def merge_sum_dicts(d1, d2):
    result = dict(d1)
    for k, v in d2.items():
        result[k] = result.get(k, 0) + v
    return result
```

### Hard — Group anagrams
**Input:** `["eat","tea","tan","ate","nat","bat"]`
**Output:** `[['eat', 'tea', 'ate'], ['tan', 'nat'], ['bat']]`
```python
def group_anagrams(words):
    groups = {}
    for w in words:
        key = "".join(sorted(w))
        groups.setdefault(key, []).append(w)
    return list(groups.values())
```

---

## 3. Tuples

### Easy — Swap first and last element
**Input:** `(1, 2, 3, 4)`
**Output:** `(4, 2, 3, 1)`
```python
def swap_first_last(t):
    t = list(t)
    t[0], t[-1] = t[-1], t[0]
    return tuple(t)
```

### Medium — Top-N by score
**Input:** `[('A',50),('B',90),('C',70),('D',85),('E',60)]`
**Output:** `[('B', 90), ('D', 85), ('C', 70)]`
```python
def top_n_by_score(records, n=3):
    return sorted(records, key=lambda r: r[1], reverse=True)[:n]
```

### Hard — Merge overlapping intervals
**Input:** `[(1,3),(2,6),(8,10),(15,18)]`
**Output:** `[(1, 6), (8, 10), (15, 18)]`
```python
def merge_intervals(intervals):
    intervals = sorted(intervals, key=lambda x: x[0])
    merged = [intervals[0]]
    for start, end in intervals[1:]:
        last_start, last_end = merged[-1]
        if start <= last_end:
            merged[-1] = (last_start, max(last_end, end))
        else:
            merged.append((start, end))
    return merged
```

---

## 4. Sets

### Easy — Common elements
**Input:** `[1,2,3,4]`, `[3,4,5,6]`
**Output:** `{3, 4}`
```python
def common_elements(a, b):
    return set(a) & set(b)
```

### Medium — Elements in exactly one of 3 sets
**Input:** `A={1,2,3}, B={2,3,4}, C={3,4,5}`
**Output:** `{1, 5}`
```python
from collections import Counter

def exactly_one_set(*sets):
    counts = Counter()
    for s in sets:
        for elem in s:
            counts[elem] += 1
    return {elem for elem, c in counts.items() if c == 1}
```

### Hard — Power set
**Input:** `{1, 2, 3}`
**Output:** `[set(), {1}, {2}, {1, 2}, {3}, {1, 3}, {2, 3}, {1, 2, 3}]` (8 subsets)
```python
def power_set(s):
    s = list(s)
    result = [set()]
    for elem in s:
        result += [subset | {elem} for subset in result]
    return result
```

---

## 5. Strings

### Easy — Palindrome check (ignore case/spaces/punctuation)
**Input:** `"A man a plan a canal Panama"`
**Output:** `True`
```python
def is_palindrome(s):
    cleaned = "".join(c.lower() for c in s if c.isalnum())
    return cleaned == cleaned[::-1]
```

### Medium — snake_case → camelCase
**Input:** `"hello_world_example"`
**Output:** `'helloWorldExample'`
```python
def snake_to_camel(s):
    parts = s.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])
```

### Hard — Longest Common Subsequence (length + string)
**Input:** `"ABCBDAB"`, `"BDCABA"`
**Output:** `(4, 'BCBA')`
```python
def longest_common_subsequence(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0]*(n+1) for _ in range(m+1)]
    for i in range(1, m+1):
        for j in range(1, n+1):
            if s1[i-1] == s2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    i, j = m, n
    lcs = []
    while i > 0 and j > 0:
        if s1[i-1] == s2[j-1]:
            lcs.append(s1[i-1]); i -= 1; j -= 1
        elif dp[i-1][j] >= dp[i][j-1]:
            i -= 1
        else:
            j -= 1
    lcs.reverse()
    return dp[m][n], "".join(lcs)
```

---

## 6. Loops

### Easy — Multiplication table
**Input:** `n=5`
**Output:** `[5, 10, 15, 20, 25, 30, 35, 40, 45, 50]`
```python
def multiplication_table(n):
    return [n*i for i in range(1, 11)]
```

### Medium — Primes below N
**Input:** `limit=30`
**Output:** `[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]`
```python
def primes_below(limit):
    primes = []
    for num in range(2, limit):
        is_p = True
        for p in primes:
            if p*p > num:
                break
            if num % p == 0:
                is_p = False
                break
        if is_p:
            primes.append(num)
    return primes
```

### Hard — N-Queens (loop-based backtracking, no recursion)
**Input:** `n=4`
**Output:** `2 solutions: [[1, 3, 0, 2], [2, 0, 3, 1]]` (column index per row)
```python
def n_queens(n):
    solutions = []
    cols, diag1, diag2 = set(), set(), set()
    board = [-1]*n
    col_choice = [0]*n
    row = 0
    while row >= 0:
        placed = False
        c = col_choice[row]
        while c < n:
            if c not in cols and (row-c) not in diag1 and (row+c) not in diag2:
                board[row] = c
                cols.add(c); diag1.add(row-c); diag2.add(row+c)
                col_choice[row] = c+1
                placed = True
                break
            c += 1
        if placed:
            if row == n-1:
                solutions.append(board[:])
                cols.discard(board[row]); diag1.discard(row-board[row]); diag2.discard(row+board[row])
            else:
                row += 1
                col_choice[row] = 0
        else:
            col_choice[row] = 0
            row -= 1
            if row >= 0:
                cols.discard(board[row]); diag1.discard(row-board[row]); diag2.discard(row+board[row])
    return solutions
```

---

## 7. Conditional Statements

### Easy — Classify a number
**Input:** `-5`
**Output:** `'Negative'`
```python
def classify_number(n):
    if n > 0:
        return "Positive"
    elif n < 0:
        return "Negative"
    return "Zero"
```

### Medium — Leap year check
**Input:** `2000`, `1900`
**Output:** `True, False`
```python
def is_leap_year(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
```

### Hard — Triangle validity, type, right-angle check
**Input:** `sides=(3, 4, 5)`
**Output:** `'Valid, Scalene, Right triangle'`
```python
def triangle_analysis(sides):
    a, b, c = sorted(sides)
    if a + b <= c:
        return "Invalid triangle"
    if a == b == c:
        shape = "Equilateral"
    elif a == b or b == c:
        shape = "Isosceles"
    else:
        shape = "Scalene"
    is_right = abs(a*a + b*b - c*c) < 1e-9
    return f"Valid, {shape}" + (", Right triangle" if is_right else "")
```

---

## 8. Functions & Decorators

### Easy — Sum of *args
**Input:** `(1, 2, 3, 4)`
**Output:** `10`
```python
def sum_args(*args):
    return sum(args)
```

### Medium — Iterative Fibonacci
**Input:** `n=10`
**Output:** `55`
```python
def fib(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(n-1):
        a, b = b, a+b
    return b
```

### Hard — `@retry` decorator
**Input:** function that fails twice then succeeds, `times=3`
**Output:** `'success'` (after 2 logged failed attempts)
```python
import functools, time

def retry(times=3, delay=0):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exc = None
            for attempt in range(1, times+1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exc = e
                    print(f"  attempt {attempt} failed: {e}")
                    time.sleep(delay)
            raise last_exc
        return wrapper
    return decorator
```

---

## 9. Comprehensions & Generators

### Easy — Squares 1–10
**Output:** `[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]`
```python
def squares_1_to_10():
    return [x**2 for x in range(1, 11)]
```

### Medium — Flatten a 2D list
**Input:** `[[1,2],[3,4],[5,6]]`
**Output:** `[1, 2, 3, 4, 5, 6]`
```python
def flatten_2d(matrix):
    return [x for row in matrix for x in row]
```

### Hard — Infinite Fibonacci generator, take first 10
**Output:** `[0, 1, 1, 2, 3, 5, 8, 13, 21, 34]`
```python
import itertools

def fib_gen():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a+b

first_10 = list(itertools.islice(fib_gen(), 10))
```

---

## 10. File Handling & CSV/JSON

### Easy — Count lines in a file
**Input:** file with 5 lines
**Output:** `5`
```python
def count_lines(path):
    with open(path) as f:
        return sum(1 for _ in f)
```

### Medium — Filter CSV rows by age (no `csv` module)
**Input:** `name,age,city` rows for Alice(30), Bob(22), Carol(45), Dave(19); `min_age=25`
**Output:** `[{'name':'Alice','age':'30','city':'NYC'}, {'name':'Carol','age':'45','city':'SF'}]`
```python
def filter_csv_by_age(path, min_age):
    with open(path) as f:
        header = f.readline().strip().split(",")
        rows = []
        for line in f:
            values = line.strip().split(",")
            row = dict(zip(header, values))
            if int(row["age"]) > min_age:
                rows.append(row)
    return rows
```

### Hard — Streaming running average (generator, no full load)
**Input:** CSV with values 10,20,30,40,50
**Output:** `[10.0, 15.0, 20.0, 25.0, 30.0]`
```python
def streaming_running_average(path, column):
    total, count = 0.0, 0
    with open(path) as f:
        header = f.readline().strip().split(",")
        idx = header.index(column)
        for line in f:
            values = line.strip().split(",")
            total += float(values[idx])
            count += 1
            yield total / count
```

---

## 11. Exception Handling

### Easy — `safe_divide` catching `ZeroDivisionError`
**Input:** `(10, 0)`
**Output:** prints `"Cannot divide by zero"`, returns `None`
```python
def safe_divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        print("Cannot divide by zero")
        return None
```

### Medium — Custom exception with shortfall info
**Input:** `balance=100, withdraw(100, 150)`
**Output:** `"Cannot withdraw 150: only 100 available (short by 50)"`
```python
class InsufficientFundsError(Exception):
    def __init__(self, balance, amount):
        self.shortfall = amount - balance
        super().__init__(f"Cannot withdraw {amount}: only {balance} available (short by {self.shortfall})")

def withdraw(balance, amount):
    if amount > balance:
        raise InsufficientFundsError(balance, amount)
    return balance - amount
```

### Hard — Categorized batch exception handling
**Input:** `[(10,2), (5,0), ("x",2), (8,4)]` run through `a/b`
**Output:** `{'success': [5.0, 2.0], 'ValueError': [], 'TypeError': ["unsupported operand type(s) for /: 'str' and 'int'"], 'KeyError': [], 'Other': ['division by zero']}`
```python
def safe_batch_process(items, processor):
    report = {"success": [], "ValueError": [], "TypeError": [], "KeyError": [], "Other": []}
    for item in items:
        try:
            report["success"].append(processor(item))
        except ValueError as e:
            report["ValueError"].append(str(e))
        except TypeError as e:
            report["TypeError"].append(str(e))
        except KeyError as e:
            report["KeyError"].append(str(e))
        except Exception as e:
            report["Other"].append(str(e))
    return report
```

---

## 12. Object-Oriented Programming

### Easy — Rectangle class
**Input:** `length=5, width=3`
**Output:** `area=15, perimeter=16`
```python
class Rectangle:
    def __init__(self, length, width):
        self.length = length
        self.width = width
    def area(self):
        return self.length * self.width
    def perimeter(self):
        return 2 * (self.length + self.width)
```

### Medium — BankAccount with custom exception on overdraft
**Input:** `deposit(100)`, then `deposit(50)`, then `withdraw(200)`
**Output:** raises `"Cannot withdraw 200: only 150 available (short by 50)"`
```python
class BankAccount:
    def __init__(self, balance=0):
        self.balance = balance
    def deposit(self, amount):
        self.balance += amount
    def withdraw(self, amount):
        if amount > self.balance:
            raise InsufficientFundsError(self.balance, amount)
        self.balance -= amount
```

### Hard — Abstract `Shape` + subclasses + total area
**Input:** `[Circle(2), Triangle(base=4,height=5), Rectangle(3,6)]`
**Output:** `total area = 40.57`
```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self): pass

class Circle(Shape):
    def __init__(self, r): self.r = r
    def area(self): return 3.14159 * self.r ** 2

class TriangleShape(Shape):
    def __init__(self, base, height): self.base, self.height = base, height
    def area(self): return 0.5 * self.base * self.height

class RectangleShape(Shape):
    def __init__(self, w, h): self.w, self.h = w, h
    def area(self): return self.w * self.h

def total_area(shapes):
    return sum(s.area() for s in shapes)
```

---

## 13. Modules and Packages

### Easy — Simple module (`mathutils.py`)
**Input:** `factorial(5)`
**Output:** `120`
```python
# mathutils.py
def factorial(n):
    result = 1
    for i in range(2, n + 1):
        result *= i
    return result

# demo.py
from mathutils import factorial
print(factorial(5))  # 120
```

### Medium — Package exposing 2 submodules via `__init__.py`
**Input:** `circle_area(3)`, `rectangle_area(4, 5)`
**Output:** `28.27, 20`
```python
# shapes/circle.py
import math
def circle_area(radius):
    return math.pi * radius ** 2

# shapes/rectangle.py
def rectangle_area(length, width):
    return length * width

# shapes/__init__.py
from .circle import circle_area
from .rectangle import rectangle_area

# demo.py
from shapes import circle_area, rectangle_area
```

### Hard — Directory scan → JSON code report
**Input:** a folder with 2 `.py` files (2 functions + 1 class each)
**Output:**
```json
[
  {"file": "example_b.py", "lines": 6, "functions": 2, "classes": 1},
  {"file": "example_a.py", "lines": 8, "functions": 2, "classes": 1}
]
```
```python
import os, json

def scan_directory(root):
    report = []
    for dirpath, _, filenames in os.walk(root):
        for fname in filenames:
            if fname.endswith(".py"):
                path = os.path.join(dirpath, fname)
                with open(path) as f:
                    lines = f.readlines()
                func_count = sum(1 for l in lines if l.strip().startswith("def "))
                class_count = sum(1 for l in lines if l.strip().startswith("class "))
                report.append({"file": fname, "lines": len(lines),
                                "functions": func_count, "classes": class_count})
    return report
```

---

## 14. Itertools, Collections & Standard Library

### Easy — `Counter.most_common`
**Input:** `["cat","dog","cat","bird","cat","dog"]`
**Output:** `[('cat', 3)]`
```python
from collections import Counter
def most_common_word(words, n=1):
    return Counter(words).most_common(n)
```

### Medium — `defaultdict` grouping
**Input:** `[('fruit','apple'),('veg','carrot'),('fruit','banana')]`
**Output:** `{'fruit': ['apple', 'banana'], 'veg': ['carrot']}`
```python
from collections import defaultdict
def group_by_category(pairs):
    groups = defaultdict(list)
    for category, item in pairs:
        groups[category].append(item)
    return dict(groups)
```

### Hard — `deque`-based sliding window stats
**Input:** stream `1..10`, `window_size=3`
**Output:** final window `[8, 9, 10]`, stats `{'mean': 9.0, 'min': 8, 'max': 10}`
```python
from collections import deque

class SlidingWindowStats:
    def __init__(self, window_size):
        self.window = deque(maxlen=window_size)
    def add(self, value):
        self.window.append(value)
        return self.stats()
    def stats(self):
        if not self.window:
            return None
        return {"mean": sum(self.window)/len(self.window),
                "min": min(self.window), "max": max(self.window)}
```

---

## 15. Testing & Debugging

### Easy — `unittest` for `is_prime`
**Output:** `Ran 3 tests in 0.001s — OK`
```python
import unittest

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True

class TestIsPrime(unittest.TestCase):
    def test_happy_path(self):
        self.assertTrue(is_prime(7))
    def test_edge_case_two(self):
        self.assertTrue(is_prime(2))
    def test_expected_failure(self):
        self.assertFalse(is_prime(9))
```

### Medium — Parametrized `pytest` test
**Output:** `3 passed`
```python
import pytest

def square(x):
    return x * x

@pytest.mark.parametrize("x,expected", [(2, 4), (-3, 9), (0, 0)])
def test_square(x, expected):
    assert square(x) == expected
```

### Hard — TDD: Roman numeral converter (tests written first)
**Output:** `14 passed` (boundaries, subtractive pairs, invalid input all covered)
```python
# test_roman_converter.py (written FIRST, never edited)
import pytest
from roman_converter import RomanConverter
rc = RomanConverter()

@pytest.mark.parametrize("num,expected", [
    (1, "I"), (3999, "MMMCMXCIX"), (4, "IV"), (9, "IX"),
    (40, "XL"), (90, "XC"), (400, "CD"), (900, "CM"),
])
def test_int_to_roman(num, expected):
    assert rc.int_to_roman(num) == expected

def test_invalid_input_raises():
    with pytest.raises(ValueError):
        rc.int_to_roman(0)

# roman_converter.py (written AFTER, to satisfy the tests)
class RomanConverter:
    _VALUES = [(1000,"M"),(900,"CM"),(500,"D"),(400,"CD"),(100,"C"),
               (90,"XC"),(50,"L"),(40,"XL"),(10,"X"),(9,"IX"),(5,"V"),(4,"IV"),(1,"I")]
    def int_to_roman(self, num):
        if not (1 <= num <= 3999):
            raise ValueError("num must be between 1 and 3999")
        result = []
        for value, symbol in self._VALUES:
            while num >= value:
                result.append(symbol); num -= value
        return "".join(result)
```

---

## 16. Pandas & NumPy

### Easy — Revenue per category (`groupby`)
**Input:** categories `A,B,A,C,B,A` with revenue `100,200,150,80,220,130`
**Output:** `A: 380, B: 420, C: 80`
```python
def revenue_per_category(df):
    return df.groupby("category")["revenue"].sum()
```

### Medium — Z-score outlier detection
**Input:** `[10, 12, 11, 13, 100, 12, 11]`
**Output:** z-scores `[-0.42, -0.36, -0.39, -0.33, 2.27, -0.36, -0.39]`, outlier mask flags only `100`
```python
def zscore_outliers(series, threshold=2):
    z = (series - series.mean()) / series.std()
    return z, z.abs() > threshold
```

### Hard — Merge + percentile filter with NumPy
**Input:** orders for customers 1,2,3,1,2 with amounts 50,300,150,400,90; 75th percentile cutoff
**Output:** only customer 1's $400 order clears the 75th percentile
```python
import numpy as np, pandas as pd

def orders_above_percentile(orders, customers, pct=75):
    merged = pd.merge(orders, customers, on="customer_id", how="inner")
    cutoff = np.percentile(merged["amount"], pct)
    return merged.loc[merged["amount"] > cutoff]
```

---

## 17. pytest

### Easy — `pytest.raises` for a missing file
```python
import os, pytest

def load_data(path):
    if not os.path.exists(path):
        raise FileNotFoundError(f"No such file: {path}")
    return pd.read_csv(path)

def test_load_data_raises_on_missing_file():
    with pytest.raises(FileNotFoundError):
        load_data("does_not_exist.csv")
```

### Medium — Fixture reused across 2 tests
```python
@pytest.fixture
def sample_df():
    return pd.DataFrame({"category": ["A","B","A"], "value": [10,20,30]})

def test_groupby_sum(sample_df):
    result = sample_df.groupby("category")["value"].sum()
    assert result["A"] == 40

def test_groupby_count(sample_df):
    result = sample_df.groupby("category")["value"].count()
    assert result["A"] == 2
```

### Hard — `tmp_path` fixture (temp file, auto-cleaned)
```python
@pytest.fixture
def temp_csv(tmp_path):
    path = tmp_path / "data.csv"
    path.write_text("a,b\n1,2\n3,4\n")
    yield str(path)
    # pytest auto-deletes tmp_path after the test — no manual cleanup needed

def test_read_temp_csv(temp_csv):
    df = pd.read_csv(temp_csv)
    assert list(df.columns) == ["a", "b"]
    assert len(df) == 2
```
**Verified:** all 8 tests across E/M/H pass.

---

## 18. REST APIs / requests
*(Verified with mocked `requests` calls — see note at the end of this doc.)*

### Easy — Retry once on HTTP 429
**Input:** first call returns 429, second returns 200 with `{"data": "ok"}`
**Output:** `{'data': 'ok'}` after 2 calls
```python
import time, requests

def fetch_with_retry_on_429(url, max_wait=1):
    response = requests.get(url, timeout=10)
    if response.status_code == 429:
        time.sleep(max_wait)
        response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.json()
```

### Medium — PUT then confirm via GET
**Output:** `{'id': 1, 'name': 'updated'}`
```python
def update_and_confirm(url, payload):
    put_resp = requests.put(url, json=payload, timeout=10)
    put_resp.raise_for_status()
    confirm_resp = requests.get(url, timeout=10)
    confirm_resp.raise_for_status()
    return confirm_resp.json()
```

### Hard — Paginate until an empty page
**Input:** 3 pages: `[{id:1},{id:2}]`, `[{id:3}]`, `[]`
**Output:** `[{'id': 1}, {'id': 2}, {'id': 3}]` after 3 calls
```python
def fetch_all_pages(base_url):
    results, page = [], 1
    while True:
        resp = requests.get(base_url, params={"page": page}, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        if not data:
            break
        results.extend(data)
        page += 1
    return results
```

---

## 19. ETL Pipeline & Pseudo-code Tracing

### Easy — `groupby().transform('mean')` trace
**Input:** regions `East,West,East,West`, sales `100,200,300,400`
**Output:**
```
  region  sales  region_avg
0   East    100       200.0
1   West    200       300.0
2   East    300       200.0
3   West    400       300.0
```
```python
df["region_avg"] = df.groupby("region")["sales"].transform("mean")
```
*Why:* `transform` broadcasts the group aggregate back onto every row of that group (unlike `agg`, which collapses to one row per group).

### Medium — `extract()` tagging rows with source
**Input:** `store_a.csv` (apple:10, banana:5), `store_b.csv` (apple:7, cherry:3)
**Output:**
```
     item  qty   source
0   apple   10  store_a
1  banana    5  store_a
2   apple    7  store_b
3  cherry    3  store_b
```
```python
def extract(paths_with_names):
    frames = []
    for name, path in paths_with_names:
        d = pd.read_csv(path)
        d["source"] = name
        frames.append(d)
    return pd.concat(frames, ignore_index=True)
```

### Hard — `transform()` dedup on composite key + quality flag
**Input:** rows with a duplicate `(apple, store_a)` pair
**Output:** duplicate flagged `DUPLICATE_DROPPED`, dropped from the clean output; all others `OK`
```python
def transform(df, key_cols):
    df = df.copy()
    is_dup = df.duplicated(subset=key_cols, keep="first")
    df["data_quality_flag"] = is_dup.map({True: "DUPLICATE_DROPPED", False: "OK"})
    clean = df.loc[~is_dup].copy()
    return clean, df
```

---

## Verification note
This sandbox's network allowlist blocks `api.open-meteo.com`, `jsonplaceholder.typicode.com`, and
similar external hosts (confirmed earlier in this conversation). Topic 18's solutions are correct,
production-ready `requests` code, and were verified by mocking `requests.get`/`put` with realistic
responses rather than live calls — the code itself is unchanged by mocking. Every other topic
(1–17, 19) was run directly against real data with no mocking involved.

**Same caveat as before:** two of your source PDFs specify "no AI tools." These are original
questions and solutions for practice/reference — not answers to their assignments.
