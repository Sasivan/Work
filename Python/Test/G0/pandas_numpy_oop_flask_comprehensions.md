# Pandas · NumPy · OOP · Flask · Comprehensions
## 50 Questions with Datasets, Verified Input/Output, and Solutions
### (10 each — 3 Easy · 5 Medium · 2 Hard)

Every solution below was executed for real in a sandbox — the outputs shown are the actual,
confirmed results, not predictions.

---

# 📊 PANDAS
### Shared dataset — `employees.csv`
```csv
emp_id,name,department,salary,hire_date,city
1,Alice Rao,Engineering,95000,2019-03-14,Austin
2,Bob Smith,Engineering,88000,2020-07-01,Austin
3,Carol Lee,Sales,72000,2018-11-23,Chicago
4,Dave Kumar,Sales,,2021-05-10,Chicago
5,Eve Torres,Marketing,68000,2022-01-15,Miami
6,Frank Chen,Engineering,102000,2017-09-05,Austin
7,Grace Patel,Sales,79000,2019-12-01,Chicago
8,Hank Davis,Marketing,71000,2020-03-20,Miami
9,Ivy Wilson,Engineering,91000,2021-08-11,Austin
10,Jack Brown,Sales,,2022-02-28,Chicago
11,Alice Rao,Engineering,95000,2019-03-14,Austin
12,Karen White,Marketing,74000,2018-06-19,Miami
```
*(Note: rows 1 & 11 are an intentional duplicate; rows 4 & 10 have missing salary — built in on purpose for the dedup/null questions below.)*

### Easy 1 — shape / dtypes / nulls
```python
df = pd.read_csv("employees.csv")
print(df.shape)          # (12, 6)
print(df.dtypes)         # salary: float64 (others: int64/object)
print(df.isnull().sum()) # salary: 2, everything else: 0
```
**Output:** `shape: (12, 6)` · `salary` has 2 nulls, all other columns 0.

### Easy 2 — Filter rows above a threshold
```python
df[df["salary"] > 80000][["name","salary"]]
```
**Output:**
```
        name    salary
   Alice Rao   95000.0
   Bob Smith   88000.0
  Frank Chen  102000.0
  Ivy Wilson   91000.0
   Alice Rao   95000.0
```

### Easy 3 — Drop vs fill missing values
```python
dropped = df.dropna(subset=["salary"])
filled = df.copy()
filled["salary"] = filled["salary"].fillna(0)
```
**Output:** `dropna` → 10 rows (was 12). `fillna(0)` → 0 nulls remaining, same row count.

### Medium 4 — Merge: inner vs left
**Input:** extra table `{department: [Engineering, Sales, HR], budget: [500000, 300000, 150000]}`
```python
inner = pd.merge(df, dept_budget, on="department", how="inner")
left  = pd.merge(df, dept_budget, on="department", how="left")
```
**Output:** `inner` → 9 rows (Marketing has no budget row, so it's dropped; HR never matches any employee). `left` → all 12 rows kept; Marketing rows get `budget = NaN`.

### Medium 5 — Multiple aggregations in one `groupby`
```python
df.groupby("department")["salary"].agg(["sum","mean","count"])
```
**Output:**
```
                  sum     mean  count
Engineering  471000.0  94200.0      5
Marketing    213000.0  71000.0      3
Sales        151000.0  75500.0      2
```

### Medium 6 — `pivot_table` (long → wide)
```python
df.pivot_table(index="department", columns="city", values="salary", aggfunc="mean")
```
**Output:**
```
city          Austin  Chicago    Miami
Engineering  94200.0      NaN      NaN
Marketing        NaN      NaN  71000.0
Sales            NaN  75500.0      NaN
```

### Medium 7 — Row-wise `.apply()`
```python
df["salary_band"] = df.apply(
    lambda row: "High" if pd.notna(row["salary"]) and row["salary"] > 85000 else "Standard",
    axis=1)
```
**Output:** Alice/Bob/Frank → `"High"`; Carol/Dave(NaN) → `"Standard"`.
*Why it's slower:* `.apply(axis=1)` runs one Python function call per row instead of a vectorized, C-level NumPy operation — for large DataFrames, prefer `np.where()` or boolean masks.

### Medium 8 — Detect & drop duplicates on a subset
```python
dupes = df[df.duplicated(subset=["name","department"], keep=False)]
deduped = df.drop_duplicates(subset=["name","department"], keep="first")
```
**Output:** Duplicate found: `Alice Rao / Engineering` (rows `emp_id` 1 and 11). After dedup: 11 rows (was 12).

### Hard 9 — Rolling 7-day average, grouped, with date gaps
**Input:**
```
date         category  amount
2024-01-01   A         100
2024-01-02   A         150
2024-01-05   A         200
2024-01-06   A         120
2024-01-01   B          80
2024-01-03   B          90
2024-01-07   B          60
```
```python
for cat, group in df.groupby("category"):
    g = group.set_index("date").sort_index()
    g["rolling_7d_avg"] = g["amount"].rolling("7D").mean()
```
**Output:**
```
date        category  amount  rolling_7d_avg
2024-01-01  A         100     100.00
2024-01-02  A         150     125.00
2024-01-05  A         200     150.00
2024-01-06  A         120     142.50
2024-01-01  B          80      80.00
2024-01-03  B          90      85.00
2024-01-07  B          60      76.67
```
*(Using a `'7D'` time-based window instead of a fixed row count correctly handles the gap between `01-02` and `01-05`.)*

### Hard 10 — Memory footprint reduction
```python
before = df.memory_usage(deep=True).sum()
optimized = df.copy()
optimized["department"] = optimized["department"].astype("category")
optimized["city"] = optimized["city"].astype("category")
optimized["salary"] = pd.to_numeric(optimized["salary"], downcast="float")
after = optimized.memory_usage(deep=True).sum()
```
**Output:** `before: 3753 bytes → after: 2715 bytes` — **27.7% reduction** (bigger on real-world datasets with more repeated string values).

---

# 🔢 NUMPY
### Sample data used inline per question (arrays shown below)

### Easy 1 — mean / median / std
**Input:** `[12, 15, 11, 20, 18, 25, 10]`
```python
np.mean(arr), np.median(arr), np.std(arr)
```
**Output:** `mean=15.857, median=15.0, std=5.05`

### Easy 2 — Reshape 1D → 2D
**Input:** `np.arange(1, 13)`
```python
matrix = flat.reshape(3, 4)
```
**Output:**
```
[[ 1  2  3  4]
 [ 5  6  7  8]
 [ 9 10 11 12]]
```

### Easy 3 — Element-wise ops
**Input:** `a=[1,2,3,4], b=[10,20,30,40]`
```python
a + b, a * b
```
**Output:** `a+b = [11,22,33,44]`, `a*b = [10,40,90,160]`

### Medium 4 — Broadcasting
**Input:** `mat = [[1,2,3],[4,5,6],[7,8,9]]`, `row = [10,20,30]`
```python
mat + row
```
**Output:**
```
[[11 22 33]
 [14 25 36]
 [17 28 39]]
```
*(the 1D row is stretched across every row of `mat` without copying data.)*

### Medium 5 — Boolean indexing
**Input:** `[5, 15, 8, 22, 3, 30, 12]`, threshold `> 10`
```python
data[data > 10]
```
**Output:** `[15, 22, 30, 12]`

### Medium 6 — Dot product & matrix multiplication
**Input:** `v1=[1,2,3], v2=[4,5,6]`; `m1=[[1,2],[3,4]], m2=[[5,6],[7,8]]`
```python
np.dot(v1, v2)   # dot product
m1 @ m2          # matrix multiplication
```
**Output:** dot product `= 32`; matrix product `= [[19,22],[43,50]]`

### Medium 7 — View vs copy
```python
view_slice = original[1:4]        # shares memory
copy_slice = original[1:4].copy() # independent
view_slice[0] = 999
```
**Output:** modifying `view_slice[0]` changed `original` too (`[1, 999, 3, 4, 5]`) — proving a slice is a *view*, not a copy. `.copy()` breaks that link.

### Medium 8 — `np.where()`
**Input:** `temps = [65, 72, 90, 55, 88, 95]`
```python
np.where(temps > 85, "Hot", "Normal")
```
**Output:** `['Normal' 'Normal' 'Hot' 'Normal' 'Hot' 'Hot']`

### Hard 9 — Vectorize a custom op, and where `np.vectorize` doesn't actually help
```python
vec_op = np.vectorize(custom_op)
vec_op(sample)  # correct, but internally still a Python loop per element
native = np.where(sample % 2 == 0, sample**2+3*sample-1, sample**2-3*sample+1)  # true vectorization
```
**Output:** both give `[-1, 9, 1, 27, 11, 53]` for `[1,2,3,4,5,6]` — same result, but `np.vectorize` is *not* faster than a plain loop at scale because it still calls the Python function once per element. Real speed requires rewriting the logic as array-native NumPy ops (the `np.where` version).

### Hard 10 — Rolling window with `as_strided` (no loops, no pandas)
**Input:** `stream = [1,2,3,4,5,6,7,8]`, window=3
```python
def rolling_window_view(arr, window):
    stride = arr.strides[0]
    shape = (arr.shape[0]-window+1, window)
    return np.lib.stride_tricks.as_strided(arr, shape=shape, strides=(stride, stride))
```
**Output:**
```
[[1. 2. 3.]
 [2. 3. 4.]
 [3. 4. 5.]
 [4. 5. 6.]
 [5. 6. 7.]
 [6. 7. 8.]]
rolling means: [2. 3. 4. 5. 6. 7.]
```
⚠️ `as_strided` creates *overlapping views into the same memory* — never write to the result array, only read from it, or you'll silently corrupt data in unexpected places.

---

# 🧱 OOP

### Easy 1 — Class vs instance attribute
```python
class Employee:
    company = "DataGrokr"   # class attribute (shared)
    def __init__(self, name):
        self.name = name    # instance attribute (unique)
```
**Output:** `e1.company` and `e2.company` both `"DataGrokr"` initially. Changing `Employee.company = "NewCorp"` updates it for **both** instances — proving it's shared, not per-object.

### Easy 2 — Simple class
```python
class Car:
    def __init__(self, make, model):
        self.make, self.model = make, model
    def describe(self):
        return f"{self.make} {self.model}"
```
**Input:** `Car("Toyota", "Corolla")` → **Output:** `"Toyota Corolla"`

### Easy 3 — Why `self` is required
**Output:** Two independent `Counter()` instances, `c1.increment()` called twice, `c2.increment()` once → `c1.count = 2`, `c2.count = 1`. `self` is what lets each instance keep separate state using the same method code.

### Medium 4 — Overriding vs "overloading"
```python
class Dog(Animal):
    def speak(self):   # overrides Animal.speak()
        return "Woof!"
```
**Output:** `Dog().speak() → "Woof!"`. Python has no true overloading — defining `speak(self, a)` and `speak(self, a, b)` in the same class just means the second definition silently replaces the first.

### Medium 5 — 4 pillars of OOP
**Output (explained):** Encapsulation (bundling + `_`/`__` naming), Inheritance (`class Child(Parent)`), Polymorphism (same method name, different subclass behavior — demonstrated by `Dog.speak()` above), Abstraction (`abc.ABC` + `@abstractmethod` hides implementation details).

### Medium 6 — `__str__` vs `__repr__`
```python
def __str__(self):  return f"({self.x}, {self.y})"
def __repr__(self): return f"Point(x={self.x}, y={self.y})"
```
**Output:** `str(p) / print(p)` → `"(3, 4)"`. `repr(p)` → `"Point(x=3, y=4)"`. `print()`/`str()` call `__str__` (human-readable); the interactive shell and debuggers call `__repr__` (unambiguous, ideally `eval`-able).

### Medium 7 — `super()`
```python
class Derived(Base):
    def __init__(self, name, extra):
        super().__init__(name)  # runs Base.__init__
        self.extra = extra
```
**Input:** `Derived("test", 42)` → **Output:** `name="test", extra=42`

### Medium 8 — `@classmethod` vs `@staticmethod`
```python
@classmethod
def margherita(cls): return cls(["mozzarella","basil"])  # alt constructor, needs cls
@staticmethod
def is_valid_topping(t): return t in {"cheese","basil",...}  # no cls/self needed
```
**Output:** `Pizza.margherita().toppings → ['mozzarella','basil']`; `Pizza.is_valid_topping('pepperoni') → True`

### Hard 9 — Singleton via metaclass + thread-safety
```python
class SingletonMeta(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]
```
**Output:** `Logger() is Logger() → True`. A naive `__new__`-based singleton (checking `if instance is None`) isn't thread-safe because two threads can both pass that check before either finishes constructing the object — producing two different "singleton" instances. Fix: wrap the creation in `threading.Lock()`.

### Hard 10 — MRO / diamond inheritance
```python
class D(B, C):  # B(A), C(A) — diamond
    pass
```
**Output:** `D.__mro__ → [D, B, C, A, object]`. `D().greet() → "B"` — Python's C3 linearization resolves the diamond left-to-right through the parent list, so `B`'s `greet()` wins over `C`'s.

---

# 🌐 FLASK
*(All routes below were tested with real HTTP-style requests via Flask's test client — status codes and JSON bodies shown are actual server responses.)*

### Easy 1 — Minimal route
```python
@app.route("/")
def hello():
    return "Hello, World!"
```
**Request:** `GET /` → **Response:** `200 "Hello, World!"`

### Easy 2 — Route with URL parameter
```python
@app.route("/user/<username>")
def show_user(username):
    return f"User: {username}"
```
**Request:** `GET /user/alice` → **Response:** `200 "User: alice"`

### Easy 3 — Debug mode
```python
if __name__ == "__main__":
    app.run(debug=True)
```
*(Enables the interactive debugger + auto-reload on code changes. Never use in production.)*

### Medium 4 — GET vs POST on the same route
```python
@app.route("/items", methods=["GET", "POST"])
def items():
    if request.method == "GET":
        return jsonify({"action": "list_items"})
    return jsonify({"action": "created", "item": request.get_json()}), 201
```
**Request:** `GET /items` → `200 {"action": "list_items"}`
**Request:** `POST /items {"name": "Widget"}` → `201 {"action": "created", "item": {"name": "Widget"}}`

### Medium 5 — `jsonify()`
```python
@app.route("/api/status")
def status():
    return jsonify({"status": "ok", "version": "1.0"})
```
**Request:** `GET /api/status` → `200 {"status": "ok", "version": "1.0"}`

### Medium 6 — query params / form data / JSON body
```python
if request.method == "GET":
    return jsonify({"query_params": dict(request.args)})
if request.is_json:
    return jsonify({"json_body": request.get_json()})
```
**Request:** `GET /echo?q=test&limit=5` → `200 {"query_params": {"q": "test", "limit": "5"}}`
**Request:** `POST /echo {"key": "value"}` → `200 {"json_body": {"key": "value"}}`

### Medium 7 — Blueprints
```python
bp = Blueprint("api", __name__, url_prefix="/api/v1")
@bp.route("/ping")
def ping(): return jsonify({"pong": True})
app.register_blueprint(bp)
```
**Request:** `GET /api/v1/ping` → `200 {"pong": true}`

### Medium 8 — Custom error handlers
```python
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not Found", "code": 404}), 404
```
**Request:** `GET /does-not-exist` → `404 {"error": "Not Found", "code": 404}`

### Hard 9 — JWT auth middleware
```python
def jwt_required(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Missing or malformed Authorization header"}), 401
        token = auth_header.split(" ", 1)[1]
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid token"}), 401
        request.user = payload["username"]
        return f(*args, **kwargs)
    return wrapper
```
**Full verified flow:**
1. `GET /protected` (no token) → `401 {"error": "Missing or malformed Authorization header"}`
2. `POST /login {"username": "alice", "password": "secret"}` → `200 {"token": "eyJhbGci..."}`
3. `GET /protected` with `Authorization: Bearer <token>` → `200 {"message": "Hello, alice! This is protected data."}`
4. `GET /protected` with a garbage token → `401 {"error": "Invalid token"}`

### Hard 10 — Flask-SQLAlchemy one-to-many relationship
```python
class Author(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    books = db.relationship("Book", backref="author", lazy=True)

class Book(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    author_id = db.Column(db.Integer, db.ForeignKey("author.id"), nullable=False)
```
**Input:** 2 authors, 3 books (2 for Asimov, 1 for Le Guin)
**Output:** `GET /authors` →
```json
[
  {"id": 1, "name": "Isaac Asimov", "books": ["Foundation", "I, Robot"]},
  {"id": 2, "name": "Ursula K. Le Guin", "books": ["The Dispossessed"]}
]
```
*(In a real project, replace `db.create_all()` with Alembic/Flask-Migrate migrations for schema versioning.)*

---

# 🔁 COMPREHENSIONS
### Shared sample inputs used per question

### Easy 1 — Squares
```python
[x**2 for x in range(1,11)]
```
**Output:** `[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]`

### Easy 2 — Filter evens
**Input:** `[3,8,12,5,17,20,9,4]`
```python
[x for x in nums if x % 2 == 0]
```
**Output:** `[8, 12, 20, 4]`

### Easy 3 — Dict comprehension: word → length
**Input:** `["apple","kiwi","banana","fig"]`
```python
{w: len(w) for w in words}
```
**Output:** `{'apple': 5, 'kiwi': 4, 'banana': 6, 'fig': 3}`

### Medium 4 — Flatten 2D (ragged rows)
**Input:** `[[1,2,3],[4,5],[6,7,8,9]]`
```python
[x for row in matrix for x in row]
```
**Output:** `[1, 2, 3, 4, 5, 6, 7, 8, 9]`

### Medium 5 — Unique vowels in a sentence
**Input:** `"The Quick Brown Fox Jumps Over"`
```python
{c for c in sentence.lower() if c in "aeiou"}
```
**Output:** `{'i', 'e', 'o', 'u'}`

### Medium 6 — Even/odd label (if/else expression)
**Input:** `range(1,8)`
```python
["even" if x % 2 == 0 else "odd" for x in range(1,8)]
```
**Output:** `['odd', 'even', 'odd', 'even', 'odd', 'even', 'odd']`

### Medium 7 — Invert a dict
**Input:** `{"a":1, "b":2, "c":3}`
```python
{v: k for k, v in original.items()}
```
**Output:** `{1: 'a', 2: 'b', 3: 'c'}`

### Medium 8 — Lazy generator of primes
```python
prime_gen = (n for n in range(2, 50) if is_prime(n))
```
**Output:** `[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]` — computed lazily, one value at a time, until materialized with `list()`.

### Hard 9 — Pythagorean triples, single nested comprehension
**Input:** `N=20`
```python
[(a,b,c) for a in range(1,N+1) for b in range(a,N+1) for c in range(b,N+1) if a*a+b*b==c*c]
```
**Output:** `[(3,4,5), (5,12,13), (6,8,10), (8,15,17), (9,12,15), (12,16,20)]`

### Hard 10 — Transpose + filter rows by sum, comprehension-only
**Input:** `[[1,2,3],[10,20,30],[4,5,6],[100,200,300]]`, threshold `50`
```python
filtered_rows = [row for row in matrix if sum(row) <= threshold]
transposed = [[row[i] for row in filtered_rows] for i in range(len(filtered_rows[0]))]
```
**Output:** rows kept (sum ≤ 50): `[[1,2,3], [4,5,6]]` → transposed: `[[1,4], [2,5], [3,6]]`

---

## Verification note
Every solution in this document was executed in a sandboxed environment against the stated
sample input, and the output shown is the real result — including the Flask routes (tested via
Flask's built-in test client, simulating actual HTTP requests/responses) and the JWT auth flow
(tested end-to-end: unauthenticated request → login → token issuance → authenticated request →
invalid-token rejection).
