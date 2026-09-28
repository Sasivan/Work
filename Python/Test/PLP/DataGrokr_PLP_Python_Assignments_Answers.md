# DataGrokr PLP --- Python Weekly Assignments with Answers

# Week 1 --- Python Beginner

## Q1 --- Data Types, Variables, Operators & Type Conversion

Write a Python program that accepts a user's name and age as string
inputs.

### (a) Convert the age to an integer and calculate the year they were born

``` python
name = input("Enter your name: ")
age = input("Enter your age: ")

age_int = int(age)
birth_year = 2025 - age_int

print("Name:", name)
print("Birth Year:", birth_year)
```

### (b) Check if the age is even or odd using the modulo operator

``` python
if age_int % 2 == 0:
    print("Even")
else:
    print("Odd")
```

### (c) Print the age as a float divided by the life expectancy of 80

``` python
result = float(age_int) / 80
print(f"{result:.4f}")
```

### (d) Use type() to print the data type of each value

``` python
print("Name type:", type(name).__name__)
print("Age before conversion type:", type(age).__name__)
print("Age after conversion type:", type(age_int).__name__)
```

### (e) Predict the output

``` python
x = '15'
y = int(x)
z = float(y) / 4

print(type(x).__name__, y * 2, round(z, 2), y % 2 == 0)
```

**Output**

``` text
str 30 3.75 False
```

------------------------------------------------------------------------

## Q2 --- Lists, Tuples, Sets & Dictionaries

Given:

``` python
scores = [85, 92, 78, 92, 88, 78, 95, 88, 70, 92]
```

### (a) Remove duplicates using a set

``` python
unique_scores = set(scores)

print(unique_scores)
```

### (b) Build a dictionary mapping each unique score to its count

``` python
counts = {
    score: scores.count(score)
    for score in set(scores)
}

print(counts)
```

### (c) Sort the dictionary by score in ascending order

``` python
sorted_counts = dict(sorted(counts.items()))

print(sorted_counts)
```

### (d) Use a tuple to store and print the (min, max, count)

``` python
summary = (min(scores), max(scores), len(scores))

print(summary)
```

### (e) Predict the output

``` python
nums = [4, 7, 4, 2, 7, 9]

unique = set(nums)
counts = {n: nums.count(n) for n in unique}

print(sorted(counts.items()))
```

**Output**

``` text
[(2, 1), (4, 2), (7, 2), (9, 1)]
```

------------------------------------------------------------------------

## Q3 --- Control Flow: if/elif, for/while Loops

### (a) Print the first 15 Fibonacci numbers using a while loop

Stop early if any number exceeds 1000.

``` python
a = 0
b = 1
count = 0

while count < 15:
    if a > 1000:
        break

    print(a)
    a, b = b, a + b
    count += 1
```

### (b) Label each printed number

Labels: - Small: less than 10 - Medium: 10 to 100 - Large: greater than
100

``` python
a = 0
b = 1
count = 0

while count < 15:
    if a > 1000:
        break

    if a < 10:
        label = "Small"
    elif a <= 100:
        label = "Medium"
    else:
        label = "Large"

    print(a, "-", label)

    a, b = b, a + b
    count += 1
```

### (c) Print a multiplication table from 1 to 5 for 7

``` python
for i in range(1, 6):
    print(f"7 x {i} = {7 * i}")
```

### (d) Predict the output

``` python
result = []

for i in range(1, 6):
    if i % 2 == 0:
        result.append(i * i)

print(result)

x = 10

while x > 0:
    x -= 3
    print(x)
```

**Output**

``` text
[4, 16]
7
4
1
-2
```

------------------------------------------------------------------------

## Q4 --- Functions: Arguments, Return Values & Defaults

### (a) Calculate percentage

``` python
def calculate_grade(score, total=100, passing=50):
    percentage = (score / total) * 100
    return percentage
```

### (b) Return a tuple containing percentage and grade

``` python
def calculate_grade(score, total=100, passing=50):
    if score < 0 or score > total:
        raise ValueError("Score must be between 0 and total")

    percentage = (score / total) * 100

    if percentage >= 90:
        grade = "A"
    elif percentage >= 75:
        grade = "B"
    elif percentage >= 60:
        grade = "C"
    elif percentage >= passing:
        grade = "D"
    else:
        grade = "F"

    return percentage, grade
```

### (c) Raise ValueError for invalid scores

``` python
if score < 0 or score > total:
    raise ValueError("Score must be between 0 and total")
```

### (d) Four test calls

``` python
print(calculate_grade(95))
print(calculate_grade(80))
print(calculate_grade(65))
print(calculate_grade(40))

try:
    print(calculate_grade(110))
except ValueError as e:
    print(e)
```

### (e) Predict the output

``` python
def grade(s, t=100, p=50):
    pct = (s / t) * 100
    return 'Pass' if pct >= p else 'Fail'

print(grade(45))
print(grade(60, 150))
print(grade(80, p=90))
```

**Output**

``` text
Fail
Fail
Fail
```

------------------------------------------------------------------------

## Q5 --- String Operations & File I/O

The input file uses:

``` text
Name,Score
```

### (a) Read and print each student's name in uppercase followed by score

``` python
with open("students.txt", "r") as file:
    for line in file:
        name, score = line.strip().split(",")

        print(name.upper(), score)
```

### (b) Calculate and print the class average

``` python
students = []

with open("students.txt", "r") as file:
    for line in file:
        name, score = line.strip().split(",")
        students.append((name, int(score)))

scores = [score for name, score in students]

average = sum(scores) / len(scores)

print("Class Average:", round(average, 1))
```

### (c) Identify the student with the highest score

``` python
highest = max(students, key=lambda x: x[1])

print("Highest Score:", highest[0], highest[1])
```

### (d) Append a summary line

Use string methods such as `strip()`, `split()`, and `upper()`.

``` python
with open("students.txt", "a") as file:
    summary = f"Class Average: {average:.1f} | Total Students: {len(students)}"
    file.write("\n" + summary)
```

### (e) Predict the output

``` python
data = 'Alice,85\nBob,92\nCarol,78'

lines = data.strip().split('\n')

scores = [
    int(l.split(',')[1])
    for l in lines
]

print(max(scores), round(sum(scores) / len(scores), 1))
```

**Output**

``` text
92 85.0
```

------------------------------------------------------------------------

## Q6 --- Exception Handling: try/except/finally

### (a) Create safe_divide() handling ZeroDivisionError and TypeError

``` python
def safe_divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        return "Cannot divide by zero"
    except TypeError:
        return "Invalid data types"
```

### (b) Create read_student_file() with FileNotFoundError and finally

``` python
def read_student_file(filename):
    try:
        with open(filename, "r") as file:
            return file.read()
    except FileNotFoundError:
        print("File not found")
    finally:
        print("File operation complete")
```

### (c) Main block with successful and failing calls

``` python
if __name__ == "__main__":
    print(safe_divide(10, 2))
    print(safe_divide(10, 0))
    print(safe_divide("10", 2))

    read_student_file("students.txt")
    read_student_file("missing.txt")
```

### (d) Predict the output

``` python
def safe_div(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        return 'Zero!'
    finally:
        print('Done')

print(safe_div(10, 2))
print(safe_div(5, 0))
```

**Output**

``` text
Done
5.0
Done
Zero!
```

# Week 2 --- Python Intermediate

## Q1 --- List/Dict Comprehensions, lambda, map, filter

Given:

``` python
numbers = [3, 7, 12, 19, 24, 31, 40, 47, 56, 63]
```

### (a) List comprehension: all odd numbers squared

``` python
odd_squared = [x ** 2 for x in numbers if x % 2 != 0]

print(odd_squared)
```

### (b) filter() with lambda: numbers divisible by 4

``` python
divisible_by_4 = list(
    filter(lambda x: x % 4 == 0, numbers)
)

print(divisible_by_4)
```

### (c) map() with lambda: zero-pad each number to 3 digits

``` python
padded = list(
    map(lambda x: str(x).zfill(3), numbers)
)

print(padded)
```

### (d) Dict comprehension: number mapped to even/odd

``` python
number_types = {
    x: "even" if x % 2 == 0 else "odd"
    for x in numbers
}

print(number_types)
```

### (e) Predict the output

``` python
nums = [1, 2, 3, 4, 5, 6]

odd_sq = [
    x ** 2
    for x in nums
    if x % 2 != 0
]

div2 = list(
    filter(lambda x: x % 2 == 0, nums)
)

padded = list(
    map(lambda x: str(x).zfill(3), nums[:3])
)

print(odd_sq, div2, padded)
```

**Output**

``` text
[1, 9, 25] [2, 4, 6] ['001', '002', '003']
```

------------------------------------------------------------------------

## Q2 --- OOP: Classes, **init**, Inheritance & Polymorphism

### (a) Create the LibraryItem base class

``` python
class LibraryItem:
    def __init__(self, title, author, year):
        self.title = title
        self.author = author
        self.year = year

    def describe(self):
        return f"{self.title} by {self.author} ({self.year})"
```

### (b) Create Book and override describe()

``` python
class Book(LibraryItem):
    def __init__(self, title, author, year, pages, genre):
        super().__init__(title, author, year)
        self.pages = pages
        self.genre = genre

    def describe(self):
        return (
            f"Book: {self.title}, "
            f"{self.author}, {self.year}, "
            f"{self.pages} pages, {self.genre}"
        )
```

### (c) Create Magazine and override describe()

``` python
class Magazine(LibraryItem):
    def __init__(self, title, author, year, issue_number, is_monthly):
        super().__init__(title, author, year)
        self.issue_number = issue_number
        self.is_monthly = is_monthly

    def describe(self):
        return (
            f"Magazine: {self.title}, "
            f"Issue {self.issue_number}, "
            f"Monthly: {self.is_monthly}"
        )
```

### (d) Demonstrate polymorphism

``` python
items = [
    Book("Python Basics", "John", 2025, 300, "Programming"),
    Magazine("Tech Monthly", "Jane", 2025, 12, True)
]

for item in items:
    print(item.describe())
```

### (e) Predict the output

``` python
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return f'{self.name} speaks'


class Dog(Animal):
    def speak(self):
        return f'{self.name} says Woof!'


for a in [Animal('Cat'), Dog('Rex')]:
    print(a.speak())
```

**Output**

``` text
Cat speaks
Rex says Woof!
```

------------------------------------------------------------------------

## Q3 --- Decorators & Context Managers

### (a) Create @log_call

``` python
def log_call(func):
    def wrapper(*args, **kwargs):
        print(f"Calling {func.__name__}...")
        result = func(*args, **kwargs)
        print("Done.")
        return result

    return wrapper


@log_call
def sum_to_n(n):
    return sum(range(1, n + 1))


print(sum_to_n(5))
```

### (b) Create @retry(times=3)

``` python
import random


def retry(times=3):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for attempt in range(times):
                try:
                    return func(*args, **kwargs)
                except Exception:
                    if attempt == times - 1:
                        raise

        return wrapper

    return decorator


@retry(times=3)
def random_operation():
    if random.random() < 0.5:
        raise Exception("Random failure")

    return "Success"


print(random_operation())
```

### (c) Create custom TempFile context manager

``` python
import os


class TempFile:
    def __init__(self, filename):
        self.filename = filename

    def __enter__(self):
        self.file = open(self.filename, "w+")
        return self.file

    def __exit__(self, exc_type, exc_value, traceback):
        self.file.close()

        if os.path.exists(self.filename):
            os.remove(self.filename)


with TempFile("temp.txt") as file:
    file.write("Line 1\n")
    file.write("Line 2\n")
    file.write("Line 3\n")

    file.seek(0)
    print(file.read())
```

### (d) Predict the output

``` python
def double(func):
    def wrapper(x):
        return func(x) * 2

    return wrapper


@double
def square(n):
    return n * n


print(square(3))
print(square(5))
```

**Output**

``` text
18
50
```

------------------------------------------------------------------------

## Q4 --- pandas: read_csv, groupby, merge + numpy basics

### (a) Read both CSV files and merge on student_id

``` python
import pandas as pd

students = pd.read_csv("students.csv")
scores = pd.read_csv("scores.csv")

merged = pd.merge(
    students,
    scores,
    on="student_id"
)

print(merged)
```

### (b) Average score per subject and per student

``` python
subject_average = (
    merged.groupby("subject")["score"]
    .mean()
)

student_average = (
    merged.groupby("student_id")["score"]
    .mean()
)

print(subject_average)
print(student_average)
```

### (c) Add grade column

``` python
def get_grade(score):
    if score >= 85:
        return "A"
    elif score >= 70:
        return "B"
    elif score >= 55:
        return "C"
    else:
        return "F"


merged["grade"] = merged["score"].apply(get_grade)

print(merged)
```

### (d) Calculate mean, standard deviation and 75th percentile

``` python
import numpy as np

all_scores = merged["score"].to_numpy()

print("Mean:", np.mean(all_scores))
print("Standard deviation:", np.std(all_scores))
print("75th percentile:", np.percentile(all_scores, 75))
```

### (e) Predict the output

``` python
import pandas as pd

data = {
    'name': ['A', 'B', 'A', 'B'],
    'score': [80, 90, 70, 85]
}

df = pd.DataFrame(data)

result = df.groupby('name')['score'].mean()

print(result.to_dict())
```

**Output**

``` text
{'A': 75.0, 'B': 87.5}
```

------------------------------------------------------------------------

## Q5 --- Modules, Packages & Virtual Environments

### (a) Create virtual environment, activate it, install packages and export requirements

``` powershell
python -m venv plp_env
```

Activate on Windows PowerShell:

``` powershell
.\plp_env\Scripts\Activate.ps1
```

Install packages:

``` powershell
pip install pandas requests
```

Export installed packages:

``` powershell
pip freeze > requirements.txt
```

### (b) Package structure

``` text
gradebook/
│
├── __init__.py
├── student.py
└── report.py
│
└── main.py
```

`student.py`

``` python
class Student:
    def __init__(self, name):
        self.name = name
```

`report.py`

``` python
def generate_report(students):
    return f"Number of students: {len(students)}"
```

`__init__.py`

``` python
from .student import Student
from .report import generate_report

__all__ = ["Student", "generate_report"]
```

### (c) Write generate_report() and use it from main.py

`main.py`

``` python
from gradebook import Student, generate_report

students = [
    Student("Priya"),
    Student("Ravi")
]

print(generate_report(students))
```

### (d) Predict the output

``` python
from gradebook import Student

s = Student('Priya')

print(
    s.name,
    type(s).__name__,
    isinstance(s, Student)
)
```

**Output**

``` text
Priya Student True
```

------------------------------------------------------------------------

## Q6 --- Exception Patterns & Clean Code

### (a) Rename parameters and add a docstring

``` python
from typing import Optional


def safe_divide(
    dividend: float,
    divisor: float
) -> Optional[float]:
    """
    Divide dividend by divisor.

    Args:
        dividend: The number being divided.
        divisor: The number to divide by.

    Returns:
        The division result, or None if division fails.

    Raises:
        TypeError: If the values have invalid types.
    """
```

### (b) Handle ZeroDivisionError and TypeError separately

``` python
def safe_divide(
    dividend: float,
    divisor: float
) -> Optional[float]:
    try:
        return dividend / divisor

    except ZeroDivisionError:
        print("Cannot divide by zero")
        return None

    except TypeError:
        print("Invalid data types")
        return None
```

### (c) Add type hints

``` python
def safe_divide(
    dividend: float,
    divisor: float
) -> Optional[float]:
    try:
        return dividend / divisor
    except ZeroDivisionError:
        print("Cannot divide by zero")
        return None
    except TypeError:
        print("Invalid data types")
        return None
```

### (d) Create batch_divide()

``` python
import logging

logging.basicConfig(level=logging.WARNING)


def batch_divide(pairs: list[tuple]):
    results = []

    for dividend, divisor in pairs:
        try:
            result = safe_divide(dividend, divisor)

            if result is not None:
                results.append(result)
            else:
                logging.warning(
                    "Skipping pair: %s, %s",
                    dividend,
                    divisor
                )

        except Exception as e:
            logging.warning("Skipping pair: %s", e)

    return results
```

### (e) Predict the output

``` python
from typing import Optional


def safe_divide(a: float, b: float) -> Optional[float]:
    try:
        return a / b
    except ZeroDivisionError:
        print('Zero error')
        return None


results = [
    safe_divide(10, 2),
    safe_divide(6, 0),
    safe_divide(9, 3)
]

print(results)
```

**Output**

``` text
Zero error
[5.0, None, 3.0]
```

# Week 3 --- Python Advanced

## Q1 --- Generators & Iterators

### (a) Create fibonacci_gen()

``` python
def fibonacci_gen():
    a = 0
    b = 1

    while True:
        yield a
        a, b = b, a + b
```

### (b) Create take(n, gen)

``` python
def take(n, gen):
    result = []

    for _ in range(n):
        result.append(next(gen))

    return result
```

### (c) Create squares_gen(limit)

``` python
def squares_gen(limit):
    for i in range(limit + 1):
        yield i * i
```

### (d) Print the first 10 Fibonacci numbers that are also perfect squares

``` python
import math


def fibonacci_gen():
    a = 0
    b = 1

    while True:
        yield a
        a, b = b, a + b


def is_perfect_square(number):
    root = math.isqrt(number)
    return root * root == number


fib = fibonacci_gen()

found = 0

while found < 10:
    number = next(fib)

    if is_perfect_square(number):
        print(number)
        found += 1
```

### (e) Predict the output

``` python
def countdown(n):
    while n > 0:
        yield n
        n -= 1


gen = countdown(5)

print(next(gen))
print(next(gen))
print(list(gen))
```

**Output**

``` text
5
4
[3, 2, 1]
```

------------------------------------------------------------------------

## Q2 --- pytest: Test Cases, Fixtures & Assertions

Given `calculator.py` containing:

``` python
def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    return a * b


def divide(a, b):
    return a / b
```

### (a) Create a fixture named sample_values

`test_calculator.py`

``` python
import pytest

from calculator import (
    add,
    subtract,
    multiply,
    divide
)


@pytest.fixture
def sample_values():
    return {
        "a": 10,
        "b": 5,
        "expected_sum": 15
    }
```

### (b) Test add using the fixture

``` python
def test_add_positive(sample_values):
    assert add(
        sample_values["a"],
        sample_values["b"]
    ) == sample_values["expected_sum"]
```

### (c) Parametrized multiply test

``` python
@pytest.mark.parametrize(
    "a, b, expected",
    [
        (2, 3, 6),
        (4, 5, 20),
        (0, 10, 0),
        (-2, 4, -8)
    ]
)
def test_multiply(a, b, expected):
    assert multiply(a, b) == expected
```

### (d) Test exceptions and edge case

``` python
def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)


def test_divide_zero():
    assert divide(0, 5) == 0.0
```

### (e) Predict the output

``` python
def divide(a, b):
    if b == 0:
        raise ZeroDivisionError('Cannot divide by zero')

    return a / b


try:
    print(divide(10, 2))
    print(divide(5, 0))
except ZeroDivisionError as e:
    print(f'Caught: {e}')
```

**Output**

``` text
5.0
Caught: Cannot divide by zero
```

------------------------------------------------------------------------

## Q3 --- JSON & API Interaction

The API is:

``` text
https://jsonplaceholder.typicode.com/posts
```

### (a) Fetch all 100 posts and handle exceptions

``` python
import requests


url = "https://jsonplaceholder.typicode.com/posts"

try:
    response = requests.get(url, timeout=5)
    response.raise_for_status()

    posts = response.json()

except requests.exceptions.ConnectionError:
    print("Connection error")
    posts = []

except ValueError:
    print("JSON decode error")
    posts = []
```

### (b) Print title and body of posts 1, 25, 50 and 100

``` python
for post_id in [1, 25, 50, 100]:
    post = posts[post_id - 1]

    print("Title:", post["title"])
    print("Body:", post["body"])
    print()
```

### (c) Filter posts where body contains more than 5 words

``` python
long_posts = [
    post
    for post in posts
    if len(post["body"].split()) > 5
]

print("Count:", len(long_posts))
```

### (d) Build userId → post titles and save as JSON

``` python
import json

posts_by_user = {}

for post in posts:
    user_id = post["userId"]

    posts_by_user.setdefault(user_id, [])
    posts_by_user[user_id].append(post["title"])


with open("posts_by_user.json", "w") as file:
    json.dump(posts_by_user, file, indent=2)
```

### (e) Predict the output

``` python
import json

data = '[{"id":1,"title":"Hello"},{"id":2,"title":"World"}]'

posts = json.loads(data)

titles = {
    p['id']: p['title'].upper()
    for p in posts
}

print(titles)
print(json.dumps(titles))
```

**Output**

``` text
{1: 'HELLO', 2: 'WORLD'}
{"1": "HELLO", "2": "WORLD"}
```

------------------------------------------------------------------------

## Q4 --- ETL Pipeline: API → pandas → File Output

### (a) Extract users and posts

``` python
import requests


def fetch_data():
    users_response = requests.get(
        "https://jsonplaceholder.typicode.com/users",
        timeout=5
    )

    posts_response = requests.get(
        "https://jsonplaceholder.typicode.com/posts",
        timeout=5
    )

    users_response.raise_for_status()
    posts_response.raise_for_status()

    return users_response.json(), posts_response.json()
```

### (b) Create users DataFrame and add word_count

``` python
import pandas as pd


users, posts = fetch_data()

users_df = pd.DataFrame(users)
posts_df = pd.DataFrame(posts)

posts_df["word_count"] = (
    posts_df["body"]
    .apply(lambda x: len(x.split()))
)
```

### (c) Merge on userId/id

``` python
merged = posts_df.merge(
    users_df,
    left_on="userId",
    right_on="id",
    suffixes=("_post", "_user")
)
```

### (d) Filter word_count \> 30 and add category

``` python
filtered = merged[
    merged["word_count"] > 30
].copy()


def category(word_count):
    if word_count < 10:
        return "Short"
    elif word_count <= 30:
        return "Medium"
    else:
        return "Long"


filtered["category"] = (
    filtered["word_count"]
    .apply(category)
)
```

### (e) Load the result and create main()

``` python
import os


def main():
    users, posts = fetch_data()

    users_df = pd.DataFrame(users)
    posts_df = pd.DataFrame(posts)

    posts_df["word_count"] = (
        posts_df["body"]
        .apply(lambda x: len(x.split()))
    )

    merged = posts_df.merge(
        users_df,
        left_on="userId",
        right_on="id",
        suffixes=("_post", "_user")
    )

    result = merged[
        merged["word_count"] > 30
    ].copy()

    result["category"] = (
        result["word_count"]
        .apply(category)
    )

    os.makedirs("output", exist_ok=True)

    result.to_csv(
        "output/etl_result.csv",
        index=False
    )

    print(
        f"Users: {len(users_df)}, "
        f"Posts: {len(posts_df)}, "
        f"Result: {len(result)}"
    )


if __name__ == "__main__":
    main()
```

### (f) Predict the output

``` python
import pandas as pd

posts = [
    {'userId': 1, 'body': 'hello world foo bar'},
    {'userId': 1, 'body': 'hi'},
    {'userId': 2, 'body': 'a b c d e f g h'}
]

df = pd.DataFrame(posts)

df['wc'] = df['body'].apply(
    lambda x: len(x.split())
)

print(df['wc'].tolist())
print(len(df[df['wc'] > 3]))
```

**Output**

``` text
[4, 1, 8]
2
```

------------------------------------------------------------------------

## Q5 --- Comprehensions & Functional Patterns

Given at least 6 employee dictionaries across 3 departments.

Example data:

``` python
emps = [
    {"name": "A", "dept": "Engineering", "salary": 80000},
    {"name": "B", "dept": "HR", "salary": 55000},
    {"name": "C", "dept": "Engineering", "salary": 75000},
    {"name": "D", "dept": "Sales", "salary": 65000},
    {"name": "E", "dept": "HR", "salary": 70000},
    {"name": "F", "dept": "Sales", "salary": 90000}
]
```

### (a) Engineering employee names

``` python
engineering_names = [
    e["name"]
    for e in emps
    if e["dept"] == "Engineering"
]

print(engineering_names)
```

### (b) Dictionary of employees earning more than 60000

``` python
high_earners = {
    e["name"]: e["salary"]
    for e in emps
    if e["salary"] > 60000
}

print(high_earners)
```

### (c) Unique departments using set comprehension

``` python
departments = {
    e["dept"]
    for e in emps
}

print(departments)
```

### (d) Total payroll using reduce and top 3 earners using sorted + lambda

``` python
from functools import reduce


total_payroll = reduce(
    lambda total, employee:
        total + employee["salary"],
    emps,
    0
)

top_3 = sorted(
    emps,
    key=lambda e: e["salary"],
    reverse=True
)[:3]

print("Total payroll:", total_payroll)
print("Top 3:", top_3)
```

### (e) Predict the output

``` python
from functools import reduce

emps = [
    {'name': 'A', 'dept': 'Eng', 'salary': 80000},
    {'name': 'B', 'dept': 'HR', 'salary': 55000},
    {'name': 'C', 'dept': 'Eng', 'salary': 75000}
]

eng = [
    e['name']
    for e in emps
    if e['dept'] == 'Eng'
]

total = reduce(
    lambda acc, e: acc + e['salary'],
    emps,
    0
)

print(eng, total)
```

**Output**

``` text
['A', 'C'] 210000
```

------------------------------------------------------------------------

## Q6 --- Project Structure & Code Quality

### (a) Directory layout

``` text
student_tracker/
│
├── models.py
├── database.py
├── reports.py
├── __init__.py
└── main.py
```

### (b) Define Student dataclass

`models.py`

``` python
from dataclasses import dataclass


@dataclass
class Student:
    name: str
    scores: list[float]

    @property
    def average(self) -> float:
        return sum(self.scores) / len(self.scores)
```

### (c) Expose Student and load_students()

`__init__.py`

``` python
import json

from .models import Student


def load_students(filepath: str) -> list[Student]:
    with open(filepath, "r") as file:
        data = json.load(file)

    return [
        Student(
            student["name"],
            student["scores"]
        )
        for student in data
    ]


__all__ = [
    "Student",
    "load_students"
]
```

### (d) Import and use load_students() with error handling

`main.py`

``` python
from student_tracker import load_students


def main():
    try:
        students = load_students("students.json")

        for student in students:
            print(
                student.name,
                round(student.average, 2)
            )

    except FileNotFoundError:
        print("Student file not found")

    except (ValueError, KeyError) as e:
        print("Invalid student data:", e)


if __name__ == "__main__":
    main()
```

### (e) Predict the output

``` python
from dataclasses import dataclass
from typing import List


@dataclass
class Student:
    name: str
    scores: List[float]

    @property
    def average(self):
        return sum(self.scores) / len(self.scores)


s = Student(
    'Ravi',
    [80, 90, 70, 85]
)

print(
    s.name,
    round(s.average, 1),
    isinstance(s, Student)
)
```

**Output**

``` text
Ravi 81.2 True
```
