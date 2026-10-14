# Python Mastery Practice Question Bank (Tests 1 & 2)

**Diagnostic Focus:** Targeted remediation and reinforcement based on Test 1 (Fundamentals) and Test 2 (ETL Pipeline).

**Core Features:**

* **Major Topics Covered:** 12 targeted topic modules spanning core Python data structures, OOP, functional patterns, streaming, regex, pandas cleaning/transformations, production logging, and full ETL pipeline design.

* **Detailed Notes & Reference Examples:** Every topic includes theoretical concepts, common test anti-patterns, and a concrete **Topic Reference Example with Sample Input & Sample Output**.

* **100 Relatable Practice Questions:** 4 Strong Topics × 5 Questions (= 20) + 8 Weak Topics × 10 Questions (= 80), matching the difficulty level and scope of your tests.

* **Explicit Sample Input & Output for Every Question:** Every problem provides reproducible input data, expected return value, and an executable assertion.

# Part I: Strong Topic Reinforcement (20 Questions)

## Module 1: Order-Preserving Deduplication & Set Mechanics (5 Questions)

### 1. Conceptual Notes & Best Practices

In Test 1 Q1, you successfully recognized that `seen = set()` with a loop preserves the first-seen order while removing duplicates.

* **Core Concept:** Python sets provide O(1) average-time membership lookups (`x in seen`), but set iteration order is not guaranteed across implementations, nor does it maintain insertion order. `list(set(seq))` scrambles order.

* **Idiomatic Patterns:**

  1. *Tracking Set Loop:*

     ```python
     seen = set()
     deduped = [x for x in items if not (x in seen or seen.add(x))]
     
     ```

  2. *Dict Keys (Python 3.7+ guarantee):*

     ```python
     deduped = list(dict.fromkeys(items))  # C-speed, preserves insertion order
     
     ```

  3. *Un-hashable Items (Dicts, Lists):* When deduplicating complex structures (e.g. dictionaries by a primary key), store the extracted key in `seen`:

     ```python
     seen = set()
     deduped = [item for item in records if item['id'] not in seen and not seen.add(item['id'])]
     
     ```

### 2. Topic Reference Example

* **Scenario:** Remove duplicates from an integer stream while strictly maintaining original arrival order.

* **Sample Input:**

  ```python
  raw_ids = [9, 33, 61, 9, 4, 78, 33, 4, 99]
  
  ```

* **Solution Code:**

  ```python
  def dedup_preserve_order(items):
      seen = set()
      res = []
      for item in items:
          if item not in seen:
              seen.add(item)
              res.append(item)
      return res
  
  output = dedup_preserve_order(raw_ids)
  
  ```

* **Sample Output:**

  ```json
  [9, 33, 61, 4, 78, 99]
  
  ```

### Module 1 Practice Questions

#### Q1.1: Multi-Attribute Record Deduplication

* **Scenario:** An event streaming consumer receives raw payment event dictionaries. Due to network retries, duplicate events arrive with identical `tx_id` values.

* **Sample Input:**

  ```python
  raw_events = [
      {"tx_id": "TX101", "user_id": 9, "amount": 45.0},
      {"tx_id": "TX102", "user_id": 33, "amount": 120.5},
      {"tx_id": "TX101", "user_id": 9, "amount": 45.0},  # Duplicate
      {"tx_id": "TX103", "user_id": 61, "amount": 15.0},
      {"tx_id": "TX102", "user_id": 33, "amount": 120.5}   # Duplicate
  ]
  
  ```

* **Task:** Implement `dedup_events_by_id(events: list[dict]) -> list[dict]` that retains only the **first** occurrence of each transaction based on `tx_id`, preserving exact arrival order.

* **Sample Output:**

  ```json
  [
      {"tx_id": "TX101", "user_id": 9, "amount": 45.0},
      {"tx_id": "TX102", "user_id": 33, "amount": 120.5},
      {"tx_id": "TX103", "user_id": 61, "amount": 15.0}
  ]
  
  ```

* **Validation Check:**

  ```python
  res = dedup_events_by_id(raw_events)
  assert [r["tx_id"] for r in res] == ["TX101", "TX102", "TX103"]
  
  ```

#### Q1.2: Fast Case-Insensitive Tag Deduplication

* **Scenario:** User-submitted blog tags contain mixed casing.

* **Sample Input:**

  ```python
  raw_tags = ['Python', 'SQL', 'python', 'ETL', 'Sql', 'pandas', 'ETL']
  
  ```

* **Task:** Write `dedup_tags_case_insensitive(tags: list[str]) -> list[str]` that keeps the original casing of the **first-seen** version of each tag while filtering subsequent case-insensitive duplicates.

* **Sample Output:**

  ```text
  ['Python', 'SQL', 'ETL', 'pandas']
  
  ```

* **Validation Check:**

  ```python
  assert dedup_tags_case_insensitive(raw_tags) == ['Python', 'SQL', 'ETL', 'pandas']
  
  ```

#### Q1.3: Deduplication with Secondary Attribute Accumulation

* **Scenario:** An e-commerce cart synchronizer passes repeated order line items with updated quantities.

* **Sample Input:**

  ```python
  cart_items = [("item_A", 2), ("item_B", 1), ("item_A", 3), ("item_C", 5), ("item_B", 4)]
  
  ```

* **Task:** Write `dedup_and_accumulate(items: list[tuple[str, int]]) -> list[tuple[str, int]]` that preserves the original encounter order of distinct item names, but sums up their quantities.

* **Sample Output:**

  ```text
  [("item_A", 5), ("item_B", 5), ("item_C", 5)]
  
  ```

* **Validation Check:**

  ```python
  assert dedup_and_accumulate(cart_items) == [("item_A", 5), ("item_B", 5), ("item_C", 5)]
  
  ```

#### Q1.4: Sliding Window Consecutive Deduplication

* **Scenario:** An IoT sensor stream experiences bouncing where identical readings repeat in immediate bursts.

* **Sample Input:**

  ```python
  readings = [10, 10, 12, 14, 14, 10, 15, 15, 12]
  
  ```

* **Task:** Write `dedup_consecutive(readings: list[int]) -> list[int]` that removes immediate consecutive duplicates only (e.g. `[10, 10, 12]` becomes `[10, 12]`, but a later `10` is preserved).

* **Sample Output:**

  ```json
  [10, 12, 14, 10, 15, 12]
  
  ```

* **Validation Check:**

  ```python
  assert dedup_consecutive(readings) == [10, 12, 14, 10, 15, 12]
  
  ```

#### Q1.5: Composite Key Deduplication on Nested Records

* **Scenario:** Tenant user-permission assignments arrive with duplicate records across `(tenant_id, user_id)`.

* **Sample Input:**

  ```python
  assignments = [
      {"tenant": "T1", "user": "U100", "role": "admin"},
      {"tenant": "T2", "user": "U100", "role": "viewer"},
      {"tenant": "T1", "user": "U100", "role": "editor"},  # Duplicate (T1, U100)
      {"tenant": "T1", "user": "U200", "role": "admin"}
  ]
  
  ```

* **Task:** Write `dedup_by_composite_key(records: list[dict], keys: list[str]) -> list[dict]` that retains the first encounter of each composite key combination.

* **Sample Output:**

  ```json
  [
      {"tenant": "T1", "user": "U100", "role": "admin"},
      {"tenant": "T2", "user": "U100", "role": "viewer"},
      {"tenant": "T1", "user": "U200", "role": "admin"}
  ]
  
  ```

* **Validation Check:**

  ```python
  assert len(dedup_by_composite_key(assignments, ["tenant", "user"])) == 3
  
  ```

## Module 2: Object-Oriented Hierarchies, Abstract Base Classes & Polymorphism (5 Questions)

### 1. Conceptual Notes & Best Practices

In Test 1 Q2, your abstract base class structure functioned, but you caught generic `Exception` instead of `TypeError`, and used f-strings unnecessarily for static strings.

* **Core Concept:** Python's `abc.ABC` and `@abstractmethod` decorator enforce interface compliance. If any subclass fails to implement all abstract methods, attempting instantiation raises `TypeError` immediately.

* **Naming Conventions:** Classes must strictly follow `PascalCase` (`BaseExtractor`, `Circle`), never `snake_case` or lowercase (`shape`, `circle`).

* **Specific Exception Catching:** Testing that an abstract class cannot be instantiated must specifically catch `TypeError`:

  ```python
  try:
      Shape()
  except TypeError as e:
      print("Correctly caught TypeError:", e)
  
  ```

### 2. Topic Reference Example

* **Scenario:** Enforce that all geometric shape classes implement an `area()` calculation.

* **Sample Input:**

  ```python
  from abc import ABC, abstractmethod
  
  class Shape(ABC):
      @abstractmethod
      def area(self) -> float:
          pass
  
  class Circle(Shape):
      def __init__(self, radius: float):
          self.radius = radius
      def area(self) -> float:
          return 3.14159 * (self.radius ** 2)
  
  ```

* **Sample Output:**

  ```python
  c = Circle(10.0)
  print(round(c.area(), 2))
  # Sample Output: 314.16
  # Instantiating Shape() raises TypeError: Can't instantiate abstract class Shape with abstract method area
  
  ```

### Module 2 Practice Questions

#### Q2.1: Strict Abstract Base Class Enforcement

* **Scenario:** Build an extensible ETL source extractor hierarchy.

* **Sample Input:**

  ```python
  from abc import ABC, abstractmethod
  # Classes to implement: BaseExtractor, CsvExtractor, JsonExtractor
  
  ```

* **Task:** Define `BaseExtractor(ABC)` with:

  1. An `@abstractmethod` named `extract(self) -> list[dict]`.

  2. A concrete method `validate_source(self) -> bool` returning `True`.
     Implement `CsvExtractor` and `JsonExtractor`. Demonstrate that calling `BaseExtractor()` directly raises `TypeError`.

* **Sample Output:**

  ```python
  csv_ext = CsvExtractor()
  csv_ext.validate_source() # Output: True
  # BaseExtractor() -> raises TypeError
  
  ```

* **Validation Check:**

  ```python
  import pytest
  with pytest.raises(TypeError):
      BaseExtractor()
  
  ```

#### Q2.2: Polymorphic Customer Tier Discount Calculator

* **Scenario:** Orders apply different discount logic based on loyalty tiers (`StandardTier`, `VipTier`).

* **Sample Input:**

  ```python
  standard_user = StandardTier()
  vip_user = VipTier()
  order_amount = 200.0
  
  ```

* **Task:** Implement `CustomerTier(ABC)` with abstract method `apply_discount(self, total: float) -> float`.

  * `StandardTier` applies 0% discount.

  * `VipTier` applies 15% discount for orders > 100, otherwise 5%.

* **Sample Output:**

  ```text
  standard_user.apply_discount(200.0) # Output: 200.0
  vip_user.apply_discount(200.0)      # Output: 170.0
  
  ```

* **Validation Check:**

  ```python
  assert standard_user.apply_discount(150.0) == 150.0
  assert vip_user.apply_discount(200.0) == 170.0
  assert vip_user.apply_discount(50.0) == 47.5
  
  ```

#### Q2.3: Abstract Context Manager for Pipeline Connections

* **Scenario:** External database connectors must guarantee connection teardown.

* **Sample Input:**

  ```python
  with MockDBClient("mysql://localhost") as client:
      status = client.query("SELECT 1")
  
  ```

* **Task:** Create `AbstractDBClient(ABC)` defining `__enter__` and `__exit__`. Declare abstract methods `connect()` and `disconnect()`. Create concrete `MockDBClient` that records connection state transitions.

* **Sample Output:**

  ```text
  # Logs:
  # "[CONNECTED] mysql://localhost"
  # "[DISCONNECTED] Connection closed"
  
  ```

* **Validation Check:** Verify `client.is_connected` is `False` after exiting `with` block.

#### Q2.4: Abstract Property Protocol Definition

* **Scenario:** Storage drivers must declare a protocol identifier string property.

* **Sample Input:**

  ```python
  drivers = [S3Driver(), LocalDriver()]
  
  ```

* **Task:** Define `StorageDriver(ABC)` with `@property` and `@abstractmethod` for `protocol_name`. Implement `S3Driver` (`"s3"`) and `LocalDriver` (`"file"`). Verify that a class missing the property raises `TypeError`.

* **Sample Output:**

  ```text
  [d.protocol_name for d in drivers] # Output: ['s3', 'file']
  
  ```

* **Validation Check:** `assert S3Driver().protocol_name == "s3"`

#### Q2.5: Template Method Pattern in Data Pipeline

* **Scenario:** Enforce consistent execution flow (`clean` then `persist`) across different pipeline file handlers.

* **Sample Input:**

  ```python
  raw_stream = [-5, 10, -2, 30]
  
  ```

* **Task:** Define `PipelineRunner(ABC)` with concrete `run(self, data)`. It must call `cleaned = self.clean(data)` and then `return self.persist(cleaned)`. Declare `clean` and `persist` as abstract methods. Implement `PositiveSumPipeline` where `clean` removes negatives and `persist` returns sum.

* **Sample Output:**

  ```text
  PositiveSumPipeline().run(raw_stream) # Output: 40
  
  ```

* **Validation Check:** `assert PositiveSumPipeline().run([-5, 10, -2, 30]) == 40`

## Module 3: Functional Transformations: `map()`, `lambda` & Comprehensions (5 Questions)

### 1. Conceptual Notes & Best Practices

In Test 1 Q3, you correctly generated cubes with `map(lambda x: x**3, range(5, 26))`, but in explanations made universal claims about list comprehensions having lower time complexity.

* **Performance Reality:** Both `map()` and list comprehensions evaluate elements in O(N) linear time. In Python, list comprehensions avoid Python-level bytecode function call overhead of `lambda` expressions, but `map()` with a built-in C function (like `map(int, strings)`) is often faster.

* **Readability Principle:** If a lambda is complex or requires conditional branching, a list comprehension is preferred for readability. If you want lazy evaluation, use a generator expression `(x**3 for x in ...)`.

### 2. Topic Reference Example

* **Scenario:** Clean and square a list of integer strings.

* **Sample Input:**

  ```python
  raw_numbers = ["1", "2", "3", "4", "5"]
  
  ```

* **Solution Code:**

  ```python
  squares = list(map(lambda x: int(x) ** 2, raw_numbers))
  
  ```

* **Sample Output:**

  ```json
  [1, 4, 9, 16, 25]
  
  ```

### Module 3 Practice Questions

#### Q3.1: Parsing Currency Strings via Functional Chaining

* **Scenario:** Financial data contains raw currency strings with currency symbols and spaces.

* **Sample Input:**

  ```python
  raw_prices = ["$12.50", " $100.00 ", "$4.99", "$0.50", "$2,450.00"]
  
  ```

* **Task:** Use `map()` with a lambda or helper function to strip `$`, spaces, and commas, returning clean `float` values.

* **Sample Output:**

  ```json
  [12.5, 100.0, 4.99, 0.5, 2450.0]
  
  ```

* **Validation Check:**

  ```python
  assert list(clean_currency_map(raw_prices)) == [12.5, 100.0, 4.99, 0.5, 2450.0]
  
  ```

#### Q3.2: Filtering and Transforming Active User Records

* **Scenario:** Extract usernames of active users who achieved a passing score.

* **Sample Input:**

  ```python
  users = [
      {"user": "Alice", "score": 85, "active": True},
      {"user": "Bob", "score": 42, "active": False},
      {"user": "Charlie", "score": 93, "active": True},
      {"user": "David", "score": 71, "active": True}
  ]
  
  ```

* **Task:**

  1. Write an implementation using `filter()` and `map()` to extract uppercase usernames of only active users with scores >= 80.

  2. Write an identical implementation using a single list comprehension.

* **Sample Output:**

  ```text
  ['ALICE', 'CHARLIE']
  
  ```

* **Validation Check:** Both functions must return `['ALICE', 'CHARLIE']`.

#### Q3.3: Matrix Flattening with Type Coercion

* **Scenario:** Flatten a nested 2D matrix while converting valid numeric strings to integers and discarding invalid/null values.

* **Sample Input:**

  ```python
  grid = [[1, "2", 3], [4, "invalid", 6], ["7", 8, None]]
  
  ```

* **Task:** Using a list comprehension, flatten the matrix into a 1D list of integers.

* **Sample Output:**

  ```json
  [1, 2, 3, 4, 6, 7, 8]
  
  ```

* **Validation Check:** `assert flatten_and_coerce(grid) == [1, 2, 3, 4, 6, 7, 8]`

#### Q3.4: Lazy Stream Evaluation with Generator Expressions

* **Scenario:** Generate cubes of even integers from 1 to 1,000,000 without allocating a full list in memory.

* **Sample Input:** `range(1, 1000001)`

* **Task:** Write a generator expression `even_cubes_gen(n)` that yields even cubes up to n. Check memory footprint using `sys.getsizeof()`.

* **Sample Output:** First 3 yielded values:

  ```text
  8, 64, 216
  
  ```

* **Validation Check:** Generator object memory size must be < 250 bytes.

#### Q3.5: Inverted Index Construction via Dict Comprehension

* **Scenario:** Convert a category-to-products mapping into a product-to-category inverted lookup index.

* **Sample Input:**

  ```python
  categories = {
      "tech": ["laptop", "phone"],
      "apparel": ["shirt", "shoes"]
  }
  
  ```

* **Task:** Use a dictionary comprehension to invert the map into `{item: category}`.

* **Sample Output:**

  ```json
  {
      "laptop": "tech",
      "phone": "tech",
      "shirt": "apparel",
      "shoes": "apparel"
  }
  
  ```

* **Validation Check:** `assert invert_categories(categories)["laptop"] == "tech"`

## Module 4: Relational Merging & Line-Item Aggregations (5 Questions)

### 1. Conceptual Notes & Best Practices

In Test 1 Q16, you correctly performed `pd.merge()` on `product_id` and computed `line_total = quantity * unit_price`, but failed to compute total revenue because you used `.agg(["mean", "std"])` instead of `.sum()`.

* **Aggregation Intent:**

  * "Total revenue" = `.sum()`

  * "Average order value" = `.mean()`

  * "Dispersion" = `.std()`

* **Best Practice:** When grouping by an ID, specify `as_index=False` or reset the index, and explicitly rename the aggregated column:

  ```text
  df.groupby("customer_id", as_index=False)["line_total"].sum().rename(columns={"line_total": "total_revenue"})
  
  ```

### 2. Topic Reference Example

* **Scenario:** Merge orders and products, compute line totals, and aggregate total revenue per customer.

* **Sample Input:**

  ```python
  import pandas as pd
  orders = pd.DataFrame([
      {"order_id": 1, "customer_id": "C1", "product_id": "P1", "quantity": 2},
      {"order_id": 2, "customer_id": "C1", "product_id": "P2", "quantity": 1}
  ])
  products = pd.DataFrame([
      {"product_id": "P1", "unit_price": 50.0},
      {"product_id": "P2", "unit_price": 20.0}
  ])
  
  ```

* **Solution Code:**

  ```python
  merged = orders.merge(products, on="product_id", how="inner")
  merged["line_total"] = merged["quantity"] * merged["unit_price"]
  rev = merged.groupby("customer_id", as_index=False)["line_total"].sum()
  
  ```

* **Sample Output:**

  ```text
    customer_id  line_total
  0          C1       120.0
  
  ```

### Module 4 Practice Questions

#### Q4.1: Customer Revenue Calculation with Renamed Outputs

* **Scenario:** Calculate total spend and total unit count per customer.

* **Sample Input:**

  ```python
  orders_df = pd.DataFrame([
      {"order_id": 101, "customer_id": "C1", "product_id": "P01", "quantity": 2},
      {"order_id": 102, "customer_id": "C2", "product_id": "P02", "quantity": 1},
      {"order_id": 103, "customer_id": "C1", "product_id": "P03", "quantity": 4}
  ])
  products_df = pd.DataFrame([
      {"product_id": "P01", "unit_price": 45.00},
      {"product_id": "P02", "unit_price": 25.00},
      {"product_id": "P03", "unit_price": 10.00}
  ])
  
  ```

* **Task:** Merge orders and products on `product_id`, calculate `line_total`, group by `customer_id`, and produce a DataFrame with columns `customer_id`, `total_spend`, and `total_items`.

* **Sample Output:**

  ```text
    customer_id  total_spend  total_items
  0          C1        130.0            6
  1          C2         25.0            1
  
  ```

* **Validation Check:**

  ```csv
  res = calculate_customer_spend(orders_df, products_df)
  assert res.loc[res["customer_id"] == "C1", "total_spend"].iloc[0] == 130.0
  
  ```

#### Q4.2: Category-Level Gross Profit Margin Analysis

* **Scenario:** Analyze profitability by product category.

* **Sample Input:**

  ```python
  orders_df = pd.DataFrame([
      {"order_id": 1, "product_id": "P1", "quantity": 2},
      {"order_id": 2, "product_id": "P2", "quantity": 3}
  ])
  products_df = pd.DataFrame([
      {"product_id": "P1", "category": "Office", "unit_price": 50.0, "cost_price": 30.0},
      {"product_id": "P2", "category": "Tech", "unit_price": 100.0, "cost_price": 60.0}
  ])
  
  ```

* **Task:** Merge datasets, calculate `profit = (unit_price - cost_price) * quantity`, and aggregate total profit by `category`.

* **Sample Output:**

  ```text
    category  gross_profit
  0   Office          40.0
  1     Tech         120.0
  
  ```

* **Validation Check:** Office gross profit must equal 40.0, Tech must equal 120.0.

#### Q4.3: Preserving Unsold Products via Right/Outer Joins

* **Scenario:** Find all products that have never been ordered, reporting their sales as 0.

* **Sample Input:**

  ```python
  orders_df = pd.DataFrame([{"order_id": 1, "product_id": "P1", "quantity": 5}])
  products_df = pd.DataFrame([
      {"product_id": "P1", "product_name": "Keyboard"},
      {"product_id": "P2", "product_name": "Webcam"}
  ])
  
  ```

* **Task:** Perform an outer or right join. Ensure `quantity` for unsold items is filled with `0` (not `NaN`), and return `product_id`, `product_name`, `units_sold`.

* **Sample Output:**

  ```text
    product_id product_name  units_sold
  0         P1     Keyboard           5
  1         P2       Webcam           0
  
  ```

* **Validation Check:**

  ```csv
  res = get_all_product_sales(orders_df, products_df)
  assert res.loc[res["product_id"] == "P2", "units_sold"].iloc[0] == 0
  
  ```

#### Q4.4: Enforcing Merge Cardinality with Validation

* **Scenario:** An inventory replenishment table must merge with a supplier catalog where supplier SKU must be unique.

* **Sample Input:**

  ```python
  inventory = pd.DataFrame([{"sku": "SKU1", "qty": 10}, {"sku": "SKU2", "qty": 5}])
  catalog = pd.DataFrame([{"sku": "SKU1", "vendor": "V1"}, {"sku": "SKU1", "vendor": "V2"}]) # Duplicate!
  
  ```

* **Task:** Perform `pd.merge(..., validate="many_to_one")`. Wrap in a `try ... except pd.errors.MergeError` block, logging an informative error message and returning an empty DataFrame if duplicate keys exist in the catalog.

* **Sample Output:**

  ```text
  # Logs: "Merge validation failed: catalog contains duplicate SKUs"
  # Returns: Empty DataFrame
  
  ```

* **Validation Check:** Catch `pd.errors.MergeError` successfully.

#### Q4.5: Filtering Top Spending Customers

* **Scenario:** Identify VIP customers who have spent over \$100 across all orders.

* **Sample Input:** Orders and products yielding customer spends: C1 = \$130, C2 = $45, C3 = $250.

* **Task:** Calculate customer spend, filter for `total_spend > 100.0`, and sort descending by `total_spend`.

* **Sample Output:**

  ```text
    customer_id  total_spend
  0          C3        250.0
  1          C1        130.0
  
  ```

* **Validation Check:** Resulting DataFrame must contain only C3 and C1 in that exact order.

# Part II: High-Priority Weak Topic Mastery (80 Questions)

## Module 5: Pandas Non-Destructive Data Cleaning, Sentinel Values & Coercion (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 1 Q11 and Test 2 Q3, you encountered several critical anti-patterns:

1. **Destructive Global Assignment:** Running `for i in df["col"]: df["col"] = 0` sets the **entire column** to 0 on the first iteration.

2. **Element-Level String Comparisons:** Comparing `type(x) not in ["int", "float"]` fails because `type(10)` is `<class 'int'>` (a type object), not the string `"int"`.

3. **Coercion Without Filtering:** `pd.to_numeric(s, errors="coerce")` replaces invalid entries with `NaN`, but does **not drop the rows**. You must explicitly construct a boolean mask (`~s.isna()`) to filter out invalid records.

4. **Preventing `SettingWithCopyWarning`:** Always call `.copy()` when slicing DataFrames to ensure downstream column modifications happen on independent data buffers.

### 2. Topic Reference Example

* **Scenario:** Clean a dirty numeric column containing sentinel strings (`"unknown"`, `"N/A"`), log dropped records, and return a clean numeric DataFrame.

* **Sample Input:**

  ```python
  import pandas as pd
  df = pd.DataFrame({
      "item": ["A", "B", "C", "D"],
      "cost": ["15.50", "unknown", "N/A", "42.00"]
  })
  
  ```

* **Solution Code:**

  ```python
  clean_series = df["cost"].replace(["unknown", "N/A"], pd.NA)
  numeric_cost = pd.to_numeric(clean_series, errors="coerce")
  valid_mask = numeric_cost.notna()
  
  df_clean = df.loc[valid_mask].copy()
  df_clean["cost"] = numeric_cost.loc[valid_mask]
  
  ```

* **Sample Output:**

  ```text
    item   cost
  0    A  15.50
  3    D  42.00
  
  ```

### Module 5 Practice Questions

#### Q5.1: Non-Destructive Sentinel Replacement

* **Scenario:** Survey salaries contain strings `"unknown"` and `"N/A"`. Replace them without modifying valid salary figures.

* **Sample Input:**

  ```python
  df = pd.DataFrame({"id": [1, 2, 3], "salary": ["85000", "unknown", "120000"]})
  
  ```

* **Task:** Replace sentinel strings with `pd.NA` and coerce `salary` to `Float64` without using a `for` loop.

* **Sample Output:**

  ```text
     id    salary
  0   1   85000.0
  1   2      <NA>
  2   3  120000.0
  
  ```

* **Validation Check:** `assert df_clean["salary"].isna().sum() == 1`

#### Q5.2: Dual Column Coercion & Coordinated Null Dropping

* **Scenario:** A developer dataset has dirty entries in both `age` and `salary`.

* **Sample Input:**

  ```python
  df = pd.DataFrame({
      "emp": ["E1", "E2", "E3"],
      "age": ["29", "unknown", "N/A"],
      "salary": ["95000", "N/A", "missing"]
  })
  
  ```

* **Task:** Coerce `age` to numeric nullable integer and `salary` to float. Drop rows where **both** `age` and `salary` are null.

* **Sample Output:**

  ```text
    emp   age   salary
  0  E1    29  95000.0
  
  ```

* **Validation Check:** Rows where both values are null are dropped; rows with at least one valid field are retained.

#### Q5.3: Coercion with Dropped Row Counting

* **Scenario:** An orders batch must identify and drop non-numeric order totals while reporting exact counts.

* **Sample Input:**

  ```python
  orders = pd.DataFrame({"order_id": [1, 2, 3, 4], "total": ["25.00", "free", "99.50", "corrupted"]})
  
  ```

* **Task:** Coerce `total` to float. Return `(clean_df, dropped_count)`.

* **Sample Output:**

  ```text
  # clean_df:
  #    order_id  total
  # 0         1   25.0
  # 2         3   99.5
  # dropped_count: 2
  
  ```

* **Validation Check:** `assert dropped_count == 2 and len(clean_df) == 2`

#### Q5.4: Boundary Capping and Negative Value Filtering

* **Scenario:** A sensor stream reports negative values on hardware errors and occasional extreme spikes.

* **Sample Input:**

  ```python
  readings = pd.DataFrame({"sensor": ["S1", "S2", "S3", "S4"], "val": [45.2, -99.0, 520.0, 12.5]})
  
  ```

* **Task:** Filter out values <= 0 and cap values > 100.0 to exactly 100.0.

* **Sample Output:**

  ```text
    sensor    val
  0     S1   45.2
  2     S3  100.0
  3     S4   12.5
  
  ```

* **Validation Check:** `assert readings_clean["val"].max() == 100.0 and (readings_clean["val"] > 0).all()`

#### Q5.5: Vectorized Accounting String Sanitization

* **Scenario:** Financial exports represent negative amounts in accounting parentheses: `"(250.00)"`.

* **Sample Input:**

  ```python
  s = pd.Series(["$1,250.00", " $450.50 ", "(250.00)", "$0.00"])
  
  ```

* **Task:** Clean the series into float values using vectorized `.str` methods without iterating. `"(250.00)"` must become `-250.0`.

* **Sample Output:**

  ```text
  0    1250.0
  1     450.5
  2    -250.0
  3       0.0
  dtype: float64
  
  ```

* **Validation Check:** `assert list(clean_currency_series(s)) == [1250.0, 450.5, -250.0, 0.0]`

#### Q5.6: Batch Column Sanitization with Missing Ratio Logging

* **Scenario:** Sanitize multiple numeric columns and detect high-null rate anomalies.

* **Sample Input:**

  ```python
  df = pd.DataFrame({
      "c1": ["10", "20", "bad"],
      "c2": ["bad", "bad", "30"],
      "name": ["A", "B", "C"]
  })
  
  ```

* **Task:** Coerce columns in `["c1", "c2"]` to numeric. Log a warning for any column whose null rate exceeds 50%.

* **Sample Output:**

  ```text
  # Logs warning: "Column c2 exceeds 50% null threshold (66.7% null)"
  # Returns df with c1, c2 as float64
  
  ```

* **Validation Check:** Verify `df["c1"].dtype == "float64"` and `df["c2"].dtype == "float64"`.

#### Q5.7: Preventing SettingWithCopyWarning

* **Scenario:** A slice of pending payments must have a late penalty added.

* **Sample Input:**

  ```python
  payments = pd.DataFrame({"id": [1, 2], "status": ["PAID", "PENDING"], "fee": [0.0, 0.0]})
  
  ```

* **Task:** Filter for `status == "PENDING"`, add $10.0$ to `fee` without triggering `SettingWithCopyWarning`, and update the original DataFrame.

* **Sample Output:**

  ```text
    id   status   fee
  0  1     PAID   0.0
  1  2  PENDING  10.0
  
  ```

* **Validation Check:** Code must execute with 0 warnings emitted.

#### Q5.8: Schema Precondition Validation

* **Scenario:** An ETL pipeline requires a strict set of columns before beginning transformation.

* **Sample Input:**

  ```csv
  df = pd.DataFrame({"customer_id": [1], "email": ["a@b.com"]})
  required = {"customer_id", "email", "country_code"}
  
  ```

* **Task:** Write `verify_schema(df, required)` that checks presence and raises `KeyError` listing missing columns sorted alphabetically.

* **Sample Output:**

  ```text
  # KeyError: "Missing required column(s): ['country_code']"
  
  ```

* **Validation Check:** Catch `KeyError` with message matching `'country_code'`.

#### Q5.9: Coercing Mixed Truthiness Flags

* **Scenario:** Survey responses contain mixed string representations of boolean answers.

* **Sample Input:**

  ```python
  s = pd.Series([1, "True", "false", "yes", "NO", "unknown"])
  
  ```

* **Task:** Map truthy tokens to `True`, falsy tokens to `False`, and unmapped strings to `pd.NA`.

* **Sample Output:**

  ```text
  0     True
  1     True
  2    False
  3     True
  4    False
  5     <NA>
  dtype: boolean
  
  ```

* **Validation Check:** Series dtype must be pandas `boolean` with 1 null.

#### Q5.10: Consolidated Compensation Cleanser

* **Scenario:** Consolidate survey compensation data into total earnings.

* **Sample Input:**

  ```python
  df = pd.DataFrame({
      "emp_id": ["E1", "E2"],
      "salary": ["80000", "corrupt"],
      "bonus": ["5000", "2000"]
  })
  
  ```

* **Task:** Coerce `salary` and `bonus` to float, drop rows where `salary` is `NaN`, compute `total = salary + bonus.fillna(0.0)`.

* **Sample Output:**

  ```text
    emp_id   salary   bonus    total
  0     E1  80000.0  5000.0  85000.0
  
  ```

* **Validation Check:** `assert df_clean["total"].iloc[0] == 85000.0 and len(df_clean) == 1`

## Module 6: Categorical Normalization, `.map()`, and Cross-Tabulations (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 1 Q13 and Q14:

1. **`.loc` Indexing Bug:** Iterating over values and running `df.loc[i, "col"] = "OTHER"` looks up the label `i` in the DataFrame index, NOT the current row!

2. **Missing Normalization Helpers:** Clean values with a standalone function:

   ```python
   def normalize_role(val):
       if pd.isna(val): return "OTHER"
       clean = str(val).strip().lower()
       if clean in {"dev", "developer", "engineer"}: return "ENGINEER"
       return "OTHER"
   df["clean_role"] = df["raw_role"].map(normalize_role)
   
   ```

3. **Cross-Tabulation Normalization:** `pd.crosstab(..., normalize="index") * 100` calculates percentage distributions across rows so that each row totals 100%.

### 2. Topic Reference Example

* **Scenario:** Normalize raw contract roles into standard buckets and compute satisfaction percentages.

* **Sample Input:**

  ```python
  df = pd.DataFrame({
      "role": ["full-time", "FT", "contractor", "intern"],
      "satisfaction": ["HIGH", "HIGH", "LOW", "MED"]
  })
  
  ```

* **Solution Code:**

  ```python
  def map_role(r):
      s = str(r).strip().lower()
      if s in {"full-time", "ft"}: return "EMPLOYEE"
      if s in {"contractor", "contract"}: return "CONTRACTOR"
      return "OTHER"
  
  df["clean_role"] = df["role"].map(map_role)
  dist = pd.crosstab(df["clean_role"], df["satisfaction"], normalize="index").mul(100).round(1)
  
  ```

* **Sample Output:**

  ```text
  satisfaction  HIGH   LOW   MED
  clean_role                  
  CONTRACTOR     0.0 100.0   0.0
  EMPLOYEE     100.0   0.0   0.0
  OTHER          0.0   0.0 100.0
  
  ```

### Module 6 Practice Questions

#### Q6.1: Clean Role Normalization with `.map()`

* **Scenario:** Map raw employment strings to `EMPLOYEE`, `CONTRACTOR`, or `OTHER`.

* **Sample Input:**

  ```python
  s = pd.Series(["Full-time", "  ft ", "CONTRACT", "freelancer", "Part-Time", "Employee"])
  
  ```

* **Task:** Implement `normalize_role(val: str) -> str` and map series into a new series containing only the three canonical buckets.

* **Sample Output:**

  ```text
  0      EMPLOYEE
  1      EMPLOYEE
  2    CONTRACTOR
  3    CONTRACTOR
  4         OTHER
  5      EMPLOYEE
  dtype: object
  
  ```

* **Validation Check:** Value counts must be: EMPLOYEE: 3, CONTRACTOR: 2, OTHER: 1.

#### Q6.2: Two-Dimensional Row-Normalized Cross-Tabulation

* **Scenario:** Measure satisfaction category percentages per role and region.

* **Sample Input:**

  ```python
  df = pd.DataFrame({
      "role": ["EMPLOYEE", "EMPLOYEE", "CONTRACTOR", "CONTRACTOR"],
      "region": ["NA", "NA", "EU", "EU"],
      "rating": ["HIGH", "LOW", "HIGH", "HIGH"]
  })
  
  ```

* **Task:** Compute `pd.crosstab([df["role"], df["region"]], df["rating"], normalize="index") * 100`.

* **Sample Output:**

  ```text
  rating             HIGH   LOW
  role       region            
  CONTRACTOR EU     100.0   0.0
  EMPLOYEE   NA      50.0  50.0
  
  ```

* **Validation Check:** Every row in the cross-tabulation table must sum to 100.0%.

#### Q6.3: Support Ticket Channel Categorization

* **Scenario:** Categorize mixed contact channel strings into `DIGITAL` vs `VOICE` vs `OTHER`.

* **Sample Input:**

  ```python
  channels = pd.Series(["email", "EMAIL", " chat ", "Phone", "web", "voice", "unknown"])
  
  ```

* **Task:** Map `{"email", "chat", "web"}` -> `DIGITAL`, `{"phone", "voice"}` -> `VOICE`, others -> `OTHER`.

* **Sample Output:**

  ```text
  0    DIGITAL
  1    DIGITAL
  2    DIGITAL
  3      VOICE
  4    DIGITAL
  5      VOICE
  6      OTHER
  dtype: object
  
  ```

* **Validation Check:** Value counts: DIGITAL: 4, VOICE: 2, OTHER: 1.

#### Q6.4: Graceful Missing Code Fallbacks with `.get()`

* **Scenario:** Map full country names to ISO 2-letter codes with fallback.

* **Sample Input:**

  ```python
  countries = ["United States", "  canada ", "Germany", "Unknown Land"]
  lookup = {"united states": "US", "canada": "CA", "germany": "DE"}
  
  ```

* **Task:** Write a mapper using `.get(val, "XX")` that strips and lowercases before lookup.

* **Sample Output:**

  ```text
  ['US', 'CA', 'DE', 'XX']
  
  ```

* **Validation Check:** `assert map_countries(countries) == ['US', 'CA', 'DE', 'XX']`

#### Q6.5: Grouped Proportions vs Percentages

* **Scenario:** Compute remote work proportion and percentage by department.

* **Sample Input:**

  ```python
  df = pd.DataFrame({
      "dept": ["IT", "IT", "HR", "HR"],
      "remote": [True, True, True, False]
  })
  
  ```

* **Task:** Group by `dept` and produce both `remote_proportion` (e.g. `1.0`, `0.5`) and `remote_pct` (`100.0`, `50.0`).

* **Sample Output:**

  ```text
     dept  remote_proportion  remote_pct
  0    HR                0.5        50.0
  1    IT                1.0       100.0
  
  ```

* **Validation Check:** Verify IT has 100.0% and HR has 50.0%.

#### Q6.6: Multi-Level Aggregation Index Flattening

* **Scenario:** Flatten grouped column hierarchies into clean single snake_case names.

* **Sample Input:**

  ```python
  df = pd.DataFrame({"team": ["A", "A", "B"], "pts": [10, 20, 30]})
  grouped = df.groupby("team").agg({"pts": ["mean", "max"]})
  
  ```

* **Task:** Flatten MultiIndex columns into `["pts_mean", "pts_max"]` and reset index.

* **Sample Output:**

  ```text
    team  pts_mean  pts_max
  0    A      15.0       20
  1    B      30.0       30
  
  ```

* **Validation Check:** Columns must be a simple Index: `['team', 'pts_mean', 'pts_max']`.

#### Q6.7: Continuous Age Binning with `pd.cut()`

* **Scenario:** Segment employee ages into discrete generations/brackets.

* **Sample Input:**

  ```python
  ages = pd.Series([19, 25, 34, 45, 62])
  
  ```

* **Task:** Bin into `["18-25", "26-40", "41-60", "60+"]` with bins `[18, 25, 40, 60, 100]`, including the lowest value (`include_lowest=True`).

* **Sample Output:**

  ```text
  0    18-25
  1    18-25
  2    26-40
  3    41-60
  4      60+
  dtype: category
  
  ```

* **Validation Check:** First two entries must be in `"18-25"`.

#### Q6.8: US State Code Standardization

* **Scenario:** Standardize mixed full state names and abbreviations to 2-letter uppercase postal codes.

* **Sample Input:**

  ```python
  raw_states = ["California", "ca", "CA ", "Texas", "tx", "Invalid"]
  
  ```

* **Task:** Normalize to uppercase 2-letter codes (`CA`, `TX`), mapping invalid states to `"OTHER"`.

* **Sample Output:**

  ```text
  ['CA', 'CA', 'CA', 'TX', 'TX', 'OTHER']
  
  ```

* **Validation Check:** All three California variations map to `'CA'`.

#### Q6.9: Frequency Encoding of High-Cardinality Categories

* **Scenario:** Replace zip codes with their proportion frequency in the dataset.

* **Sample Input:**

  ```python
  zips = pd.Series(["90210", "90210", "10001", "90210", "30301"])
  
  ```

* **Task:** Calculate the relative frequency of each code and map it back to the series.

* **Sample Output:**

  ```text
  0    0.6
  1    0.6
  2    0.2
  3    0.6
  4    0.2
  dtype: float64
  
  ```

* **Validation Check:** `90210` must map to `0.6` (3 out of 5).

#### Q6.10: Memory Optimization via Categorical Casting

* **Scenario:** Reduce memory consumption of repetitive string status columns.

* **Sample Input:**

  ```python
  df = pd.DataFrame({"status": ["PENDING", "COMPLETED", "FAILED", "COMPLETED"] * 10000})
  
  ```

* **Task:** Convert `status` to `category` dtype and compare memory usage before and after using `.memory_usage()`.

* **Sample Output:**

  ```text
  # Memory reduction: > 70% decrease in memory consumption
  
  ```

* **Validation Check:** Verify `df["status"].dtype.name == "category"`.

## Module 7: Memory-Efficient Streaming, Generators & Multi-Sheet Excel Merging (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 1 Q4 and Q15:

1. **The `readlines()` Trap:** Calling `f.readlines()` reads the **entire file into memory** at once. If the file is 10GB, this crashes the process. A true generator must iterate directly over the file or reader:

   ```python
   def stream_csv(path):
       with open(path, "r", newline="", encoding="utf-8") as f:
           for row in csv.DictReader(f):
               yield row
   
   ```

2. **Proper CSV Parsing:** Never split CSV lines manually on commas (`line.split(',')`), because fields with commas inside quotes (`"Smith, John"`) will break. Use Python's built-in `csv.reader` or `csv.DictReader`.

3. **Multi-Sheet Excel Consolidation:** `pd.read_excel(path, sheet_name=None)` returns `{sheet_name: DataFrame}`. To merge properly:

   ```python
   frames = []
   for name, df in sheets.items():
       df["source_sheet"] = name
       frames.append(df)
   combined = pd.concat(frames, ignore_index=True)
   
   ```

### 2. Topic Reference Example

* **Scenario:** Incrementally sum transaction amounts by category using a generator without holding all rows in memory.

* **Sample Input:** A CSV file `tx.csv` with:

  ```csv
  category,amount
  Tech,100.0
  Office,20.0
  Tech,50.0
  
  ```

* **Solution Code:**

  ```python
  import csv
  from collections import defaultdict
  
  def stream_records(filepath):
      with open(filepath, "r", newline="", encoding="utf-8") as f:
          for row in csv.DictReader(f):
              yield row
  
  totals = defaultdict(float)
  for row in stream_records("tx.csv"):
      totals[row["category"]] += float(row["amount"])
  
  ```

* **Sample Output:**

  ```text
  dict(totals) # {'Tech': 150.0, 'Office': 20.0}
  
  ```

### Module 7 Practice Questions

#### Q7.1: Streaming CSV Category Aggregation

* **Scenario:** A 5GB CSV transaction export contains millions of lines.

* **Sample Input:**

  ```csv
  tx_id,category,amount
  T1,Electronics,120.00
  T2,Groceries,45.50
  T3,Electronics,80.00
  
  ```

* **Task:** Implement `stream_transactions(path)` as a generator yielding dictionaries. Compute total revenue per category incrementally.

* **Sample Output:**

  ```json
  {"Electronics": 200.0, "Groceries": 45.5}
  
  ```

* **Validation Check:** Verify total for Electronics is $200.00$ without calling `list()` on the generator.

#### Q7.2: Chunked Processing with Pandas

* **Scenario:** Process large datasets in batches of 2 rows using `chunksize`.

* **Sample Input:** CSV containing 6 rows with column `amount`: `[10, 20, 30, 40, 50, 60]`.

* **Task:** Use `pd.read_csv(..., chunksize=2)` to calculate grand total sum without loading the full DataFrame.

* **Sample Output:**

  ```json
  210.0
  
  ```

* **Validation Check:** Sum across all chunks must equal $210.0$.

#### Q7.3: Dynamic Multi-Sheet Excel Combiner

* **Scenario:** Combine multiple regional sheets (`North`, `South`) from an Excel workbook into one CSV.

* **Sample Input:**

  * Sheet "North": `site_id`, `cost`

  * Sheet "South": `site_id`, `cost`, `manager`

* **Task:** Read all sheets dynamically, add `source_sheet` column to each, concatenate, and save to CSV.

* **Sample Output:**

  ```text
    site_id    cost manager source_sheet
  0     N-1  120000     NaN        North
  1     S-1   85000     Lee        South
  
  ```

* **Validation Check:** Column `source_sheet` exists with values `"North"` and `"South"`.

#### Q7.4: Chained Generator Pipeline

* **Scenario:** Build an ETL stream: read lines -> filter positive amounts -> compute tax.

* **Sample Input:** `[{"id": 1, "amt": -10}, {"id": 2, "amt": 100}, {"id": 3, "amt": 200}]`

* **Task:** Chain three generators: `stream_rows`, `filter_positives`, and `apply_tax` (adds 10% tax).

* **Sample Output:**

  ```json
  [{"id": 2, "amt": 100, "total": 110.0}, {"id": 3, "amt": 200, "total": 220.0}]
  
  ```

* **Validation Check:** All processed items have positive amounts and correct 10% tax.

#### Q7.5: Handling Quoted Fields with Newlines in CSV

* **Scenario:** Customer reviews contain embedded commas and newlines inside quotes.

* **Sample Input:**

  ```text
  id,review
  1,"Great product,
  fast shipping"
  2,"Average"
  
  ```

* **Task:** Demonstrate that `csv.DictReader` correctly yields 2 records, while naive `line.split(',')` fails.

* **Sample Output:**

  ```text
  # Record 1 review: 'Great product,\nfast shipping'
  
  ```

* **Validation Check:** Exactly 2 records are parsed.

#### Q7.6: Memory Measurement with `tracemalloc`

* **Scenario:** Prove that a generator uses drastically less peak memory than `f.readlines()`.

* **Sample Input:** A generated text file with 10,000 lines.

* **Task:** Use `tracemalloc` to benchmark peak memory of reading via list vs generator iteration.

* **Sample Output:**

  ```text
  # Peak memory readlines: ~850 KB
  # Peak memory generator: ~1.5 KB
  
  ```

* **Validation Check:** Generator peak memory must be < 10% of `readlines()` peak memory.

#### Q7.7: Generator Teardown Guarantees

* **Scenario:** Ensure database/file resources are released even if consumer breaks early from generator.

* **Sample Input:** Loop that breaks after reading 1 item from a 100-item generator.

* **Task:** Use `try ... finally` inside a generator to set `is_closed = True` when caller terminates early.

* **Sample Output:**

  ```text
  # "Resource closed successfully" logged upon break
  
  ```

* **Validation Check:** Verify `is_closed` is `True` after break.

#### Q7.8: Stream Batcher Generator

* **Scenario:** Batch an arbitrary stream of records into micro-batches of size N for bulk API posting.

* **Sample Input:** Stream of integers `range(1, 8)` with batch size 3.

* **Task:** Write `batch_stream(iterable, batch_size: int)` yielding lists.

* **Sample Output:**

  ```json
  [[1, 2, 3], [4, 5, 6], [7]]
  
  ```

* **Validation Check:** Final batch contains remaining elements.

#### Q7.9: Online Streaming Statistics (Welford's Algorithm)

* **Scenario:** Compute running mean and variance of continuous float metrics without storing historical elements.

* **Sample Input:** Stream of values: `[10.0, 20.0, 30.0, 40.0]`.

* **Task:** Implement `RunningStats` with `add(val)` maintaining `count` and `mean`.

* **Sample Output:**

  ```text
  # After 4 additions: count=4, mean=25.0
  
  ```

* **Validation Check:** `assert stats.mean == 25.0`

#### Q7.10: Imputing Missing Columns During Multi-Sheet Excel Ingestion

* **Scenario:** Regional Excel sheets occasionally omit optional columns like `notes`.

* **Sample Input:** Sheet 1 has columns `['id', 'sales']`; Sheet 2 has `['id', 'sales', 'notes']`.

* **Task:** Read all sheets, add `source_sheet`, impute missing `notes` with `""` on Sheet 1, and concatenate.

* **Sample Output:**

  ```text
  # Combined DataFrame has 'notes' populated with empty strings for Sheet 1
  
  ```

* **Validation Check:** No `NaN` values in `notes` column.

## Module 8: String Sanitization, Modular Arithmetic & Regex SQL Extraction (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 1 Q5, Q6, Q7, and Q8:

1. **Regex SQL Parsing:** Use `re.compile()` with named capture groups `(?P<group_name>...)` and `.finditer()` to extract structured metadata from raw text.

2. **Modular Alphabet Wraparound:** Shifting letters by position requires modulo 26 arithmetic:

   ```python
   shifted = (ord(char) - ord('a') + shift) % 26 + ord('a')
   
   ```

   Without `% 26`, shifting past `'z'` produces symbols like `'{', '|', '}'`.

3. **Robust Phone Sanitization:** Stripping non-digits is only step 1. You must strip leading country codes (`1` for 10-digit North American numbers) and assert that exactly 10 digits remain.

4. **Digit-Only Extraction:** Filter with `char.isdigit()`, join, cast to `int`, or return `None` if empty.

### 2. Topic Reference Example

* **Scenario:** Extract table and column names from SQL `CREATE INDEX` statements using regex.

* **Sample Input:**

  ```python
  sql = "CREATE UNIQUE INDEX idx_user ON customers (email, user_id);"
  
  ```

* **Solution Code:**

  ```python
  import re
  pattern = re.compile(
      r"CREATE\s+(?P<unique>UNIQUE\s+)?INDEX\s+(?P<idx>\w+)\s+ON\s+(?P<table>\w+)\s*\((?P<cols>[^)]+)\)",
      re.IGNORECASE
  )
  m = pattern.search(sql)
  meta = {
      "index": m.group("idx"),
      "table": m.group("table"),
      "columns": [c.strip() for c in m.group("cols").split(",")],
      "unique": bool(m.group("unique"))
  }
  
  ```

* **Sample Output:**

  ```text
  {
      "index": "idx_user",
      "table": "customers",
      "columns": ["email", "user_id"],
      "unique": True
  }
  
  ```

### Module 8 Practice Questions

#### Q8.1: Regex SQL Index Metadata Extractor

* **Scenario:** Parse database migration scripts for index definitions.

* **Sample Input:**

  ```sql
  CREATE INDEX idx_orders_date ON orders (order_date);
  CREATE UNIQUE INDEX idx_cust_email ON customers (email, tenant_id);
  
  ```

* **Task:** Extract all indexes into a list of dictionaries with keys `index_name`, `table`, `columns`, and `unique` (boolean).

* **Sample Output:**

  ```text
  [
      {"index_name": "idx_orders_date", "table": "orders", "columns": ["order_date"], "unique": False},
      {"index_name": "idx_cust_email", "table": "customers", "columns": ["email", "tenant_id"], "unique": True}
  ]
  
  ```

* **Validation Check:** Second index must have `unique == True` and 2 columns.

#### Q8.2: Caesar Shift with Position Wraparound

* **Scenario:** Implement `rotate_encode(word: str) -> str`. Shift each lowercase character forward by its 1-based index in the word, wrapping around after `'z'`.

* **Sample Input:**

  ```python
  word = "xyz" # x(pos 1) -> y, y(pos 2) -> a, z(pos 3) -> c
  
  ```

* **Task:** Return encoded string with proper modulo 26 arithmetic.

* **Sample Output:**

  ```json
  "yac"
  
  ```

* **Validation Check:** `assert rotate_encode("xyz") == "yac"` and `assert rotate_encode("abc") == "bdf"`

#### Q8.3: Canonical Phone Number Formatter

* **Scenario:** Normalize messy North American phone numbers to `XXX XXX XXXX`.

* **Sample Input:**

  ```python
  samples = ["(555) 123-4567", "+1 555 123 4567", "555.123.4567", "invalid", "12345"]
  
  ```

* **Task:** Strip non-digits, drop leading country code `1` if 11 digits, validate 10 digits remain, and format as `XXX XXX XXXX`. Return `None` for invalid numbers.

* **Sample Output:**

  ```text
  ['555 123 4567', '555 123 4567', '555 123 4567', None, None]
  
  ```

* **Validation Check:** First three numbers must normalize to identical strings.

#### Q8.4: Reference Code Digit Sanitizer

* **Scenario:** Extract numeric ticket IDs from dirty reference codes.

* **Sample Input:**

  ```python
  codes = ["A-4471", "  90210  ", "REF#8823", "n/a", "---"]
  
  ```

* **Task:** Implement `clean_reference_code(val)` to return integer of digits, or `None` if no digits exist.

* **Sample Output:**

  ```text
  [4471, 90210, 8823, None, None]
  
  ```

* **Validation Check:** `assert [clean_reference_code(c) for c in codes] == [4471, 90210, 8823, None, None]`

#### Q8.5: Regex Parsing of `CREATE TABLE` Columns

* **Scenario:** Extract column names from standard DDL statements.

* **Sample Input:**

  ```sql
  CREATE TABLE items (item_id INT PRIMARY KEY, name VARCHAR(50), price DECIMAL(10,2));
  
  ```

* **Task:** Use regex to extract the table name (`items`) and column names (`['item_id', 'name', 'price']`).

* **Sample Output:**

  ```json
  {"table": "items", "columns": ["item_id", "name", "price"]}
  
  ```

* **Validation Check:** Columns list must contain exactly 3 clean column names.

#### Q8.6: Atbash Symmetric Character Cipher

* **Scenario:** Implement the Atbash mirror cipher (`'a'` <-> `'z'`, `'b'` <-> `'y'`).

* **Sample Input:**

  ```python
  text = "abc"
  
  ```

* **Task:** Write `atbash(text: str) -> str` using character code math without a hardcoded lookup dictionary.

* **Sample Output:**

  ```json
  "zyx"
  
  ```

* **Validation Check:** `assert atbash("abc") == "zyx"` and `assert atbash("zyx") == "abc"`

#### Q8.7: URL Parameter Extractor via Regex

* **Scenario:** Parse query string parameters from URLs without using `urllib`.

* **Sample Input:**

  ```python
  url = "https://api.domain.com/v1/orders?cust_id=101&status=pending&limit=50"
  
  ```

* **Task:** Use `re.findall()` to return a dictionary of parameters.

* **Sample Output:**

  ```json
  {"cust_id": "101", "status": "pending", "limit": "50"}
  
  ```

* **Validation Check:** Parsed dictionary must contain 3 key-value pairs.

#### Q8.8: Email Masking for Data Privacy

* **Scenario:** Obfuscate personal emails for public logging.

* **Sample Input:**

  ```python
  emails = ["john.doe@example.com", "alice@work.co.uk", "x@test.org"]
  
  ```

* **Task:** Mask username so only first character remains: `j***@example.com`, `a***@work.co.uk`.

* **Sample Output:**

  ```json
  ["j***@example.com", "a***@work.co.uk", "x***@test.org"]
  
  ```

* **Validation Check:** Domain names must remain intact and username masked.

#### Q8.9: CamelCase to snake_case Identifier Converter

* **Scenario:** Convert Java/C# DTO properties to Python snake_case.

* **Sample Input:**

  ```json
  ["CustomerId", "OrderDate", "TotalAmountUSD"]
  
  ```

* **Task:** Use `re.sub()` to convert names to lowercase snake_case.

* **Sample Output:**

  ```json
  ["customer_id", "order_date", "total_amount_usd"]
  
  ```

* **Validation Check:** `assert camel_to_snake("CustomerId") == "customer_id"`

#### Q8.10: Structured Key-Value Log Parser

* **Scenario:** Parse structured key-value tokens from application logs.

* **Sample Input:**

  ```python
  log = "2026-10-12 [INFO] duration_ms=45 status=200 user=john_doe"
  
  ```

* **Task:** Extract key-value pairs into a dictionary, casting integer values automatically.

* **Sample Output:**

  ```json
  {"duration_ms": 45, "status": 200, "user": "john_doe"}
  
  ```

* **Validation Check:** `res["duration_ms"]` must be integer `45`.

## Module 9: Production Logging, Specific Exception Handling & Testability (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 1 Q9 and Test 2 Q1:

1. **Logging Misconfigurations:** `logging.basicConfig(level=Warning)` is invalid syntax (must be `logging.WARNING`). Setting up loggers repeatedly inside functions resets handlers or prevents writing to the persistent `FileHandler("etl_run.log")`.

2. **Never Swallow Exceptions in ETL:** Writing `except Exception as e: logger.warning("error:", e)` without re-raising hides fatal pipeline breaks. Downstream jobs will assume incomplete data is valid!

3. **Specific vs Broad Exceptions:** Catch exact expected exceptions (`FileNotFoundError`, `pd.errors.ParserError`, `SQLAlchemyError`) before catching general exceptions, and always use `logger.exception()` to preserve stack traces.

4. **Validation Assertions:** Test loaded databases against source records by querying the database and checking that `len(db_rows) == len(source_records)` and checking specific sample field values.

### 2. Topic Reference Example

* **Scenario:** Read a required config file, log attempt and errors, and ensure exceptions re-raise cleanly.

* **Sample Input:** Path `config.json` (assume missing).

* **Solution Code:**

  ```python
  import logging
  
  logger = logging.getLogger("etl_pipeline")
  
  def load_config_safely(path: str):
      logger.info("Attempting to load configuration from: %s", path)
      try:
          with open(path, "r", encoding="utf-8") as f:
              return f.read()
      except FileNotFoundError:
          logger.exception("Mandatory config file missing: %s", path)
          raise
  
  ```

* **Sample Output:**

  ```text
  [INFO] Attempting to load configuration from: config.json
  [ERROR] Mandatory config file missing: config.json (with traceback)
  # Re-raises FileNotFoundError
  
  ```

### Module 9 Practice Questions

#### Q9.1: Dual Console and Persistent File Logger Setup

* **Scenario:** Configure a central pipeline logger that writes to stdout and `etl_run.log`.

* **Sample Input:** Call `setup_logger("etl_run.log")`.

* **Task:** Configure the logger with both `StreamHandler` and `FileHandler`, formatting with timestamp, level, and message. Ensure multiple calls do not add duplicate handlers.

* **Sample Output:**

  ```text
  2026-10-12 14:00:00 [INFO] Central logger initialized.
  
  ```

* **Validation Check:** File `etl_run.log` exists and contains log entries.

#### Q9.2: Targeted File Reader with Specific Error Catches

* **Scenario:** Read a list of files where some may be missing and others corrupted.

* **Sample Input:** `paths = ["good.txt", "missing.txt", "corrupt.bin"]`

* **Task:** Implement `read_files(paths)` with separate `except` blocks for `FileNotFoundError` and `UnicodeDecodeError`, logging the specific file path in each error.

* **Sample Output:**

  ```text
  [WARNING] File missing: missing.txt
  [ERROR] Encoding failed: corrupt.bin
  # Returns contents of good.txt in list
  
  ```

* **Validation Check:** Successful files are returned in a list; errors are logged with file context.

#### Q9.3: Database Exception Logging with Tracebacks

* **Scenario:** Catch database constraint violations and log full diagnostic traces.

* **Sample Input:** Insert query violating a `FOREIGN KEY` constraint.

* **Task:** Wrap query execution in `try ... except SQLAlchemyError`. Use `logger.exception()` and re-raise.

* **Sample Output:**

  ```text
  [ERROR] Database insert failed for statement: INSERT INTO orders ... (full stack trace)
  
  ```

* **Validation Check:** `SQLAlchemyError` is re-raised after logging.

#### Q9.4: Multi-Level Logging in Record Processing

* **Scenario:** Process records, applying `INFO`, `WARNING`, and `ERROR` levels appropriately.

* **Sample Input:** `[{"id": 1, "amt": 50}, {"id": 2, "amt": -10}, {"id": 3, "amt": "corrupt"}]`

* **Task:** Log `INFO` for normal records, `WARNING` for negative amounts dropped, and `ERROR` for non-numeric corrupt amounts.

* **Sample Output:**

  ```text
  [INFO] Processed record 1
  [WARNING] Dropping record 2: negative amount -10
  [ERROR] Invalid record 3: non-numeric amount 'corrupt'
  
  ```

* **Validation Check:** Verify logs contain each level appropriately.

#### Q9.5: Round-Trip Row Count and Field Assertions

* **Scenario:** Validate that database table `clean_customers` exactly matches loaded records.

* **Sample Input:** `source_df` (50 rows) and `db_df` read from SQL database.

* **Task:** Write assertions verifying:

  1. `len(db_df) == len(source_df)`

  2. Columns match exactly

  3. Customer `"C1"` has identical email in both DataFrames.

* **Sample Output:**

  ```json
  "Round-trip validation passed: 50 rows verified."
  
  ```

* **Validation Check:** Assertions pass when data matches and raise informative `AssertionError` if counts differ.

#### Q9.6: Custom ETL Exception Hierarchy

* **Scenario:** Distinguish extraction failures from transformation failures in pipeline monitoring.

* **Sample Input:** Raising `TransformationError("Invalid country code")`.

* **Task:** Implement `ETLError(Exception)` base class with subclasses `ExtractionError`, `TransformationError`, and `LoadError`.

* **Sample Output:**

  ```text
  isinstance(TransformationError(), ETLError) # Output: True
  
  ```

* **Validation Check:** Catching `ETLError` catches all three custom subclasses.

#### Q9.7: Stage Execution Time Context Manager

* **Scenario:** Benchmark individual transformation stages automatically.

* **Sample Input:**

  ```python
  with time_stage("cleaning"):
      time.sleep(0.5)
  
  ```

* **Task:** Implement `@contextmanager` logging start and completion time in seconds.

* **Sample Output:**

  ```text
  [INFO] Starting stage: cleaning
  [INFO] Finished stage: cleaning in 0.50s
  
  ```

* **Validation Check:** Elapsed time is calculated and logged.

#### Q9.8: Safe Division Function with Warning Suppression

* **Scenario:** Calculate metrics like `revenue / clicks` where clicks may be zero.

* **Sample Input:** `divide_safely(100.0, 0.0)`

* **Task:** Return `0.0` or `np.nan` on zero denominator, logging a `DEBUG` message instead of raising `ZeroDivisionError`.

* **Sample Output:**

  ```json
  0.0
  
  ```

* **Validation Check:** Zero denominator returns `0.0` without crashing.

#### Q9.9: Pre- and Post-Condition Pipeline Contracts

* **Scenario:** Enforce data contracts at function entry and exit.

* **Sample Input:** Input DataFrame to `enrich_orders()`.

* **Task:** Assert input DataFrame has `['order_id', 'amount']`, and assert output DataFrame contains new column `'tax'` with zero nulls.

* **Sample Output:**

  ```text
  # Successfully returns enriched DataFrame with tax column
  
  ```

* **Validation Check:** Missing input column triggers immediate `AssertionError`.

#### Q9.10: Integration Testing with Pytest Temporary Directory

* **Scenario:** Test a CSV cleaning function using temporary files.

* **Sample Input:** Writing a mock dirty CSV into pytest's `tmp_path`.

* **Task:** Write a complete test function `test_clean_csv(tmp_path)` that runs `clean_csv()` and asserts file existence and row count.

* **Sample Output:**

  ```text
  test_clean_csv PASSED
  
  ```

* **Validation Check:** Test runs and passes under `pytest`.

## Module 10: End-to-End ETL Pipeline Architecture, SQL Execution & Rerun-Safety (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 2 Q4, Q5, Q6, and Q7:

1. **Explicit Data Flow:** Never rely on global variables (`df1`, `df2`). Functions must accept their data as arguments and return transformed results:

   ```python
   def extract() -> tuple[pd.DataFrame, pd.DataFrame]: ...
   def transform(cust, orders, engine) -> pd.DataFrame: ...
   def load(df, engine) -> None: ...
   
   ```

2. **Executing SQL:** Defining `query = "CREATE TABLE ..."` does nothing until executed:

   ```python
   with engine.begin() as conn:
       conn.execute(text(create_sql))
   
   ```

3. **Idempotency (Rerun Safety):** Running a batch pipeline twice must not duplicate records. Use `CREATE TABLE IF NOT EXISTS` followed by `TRUNCATE TABLE` inside a transaction before appending the new clean records.

### 2. Topic Reference Example

* **Scenario:** Build an idempotent loader that creates a destination table if missing and reloads it cleanly.

* **Sample Input:** `df = pd.DataFrame([{"id": "U1", "name": "Alice"}])`

* **Solution Code:**

  ```sql
  from sqlalchemy import create_engine, text
  
  engine = create_engine("sqlite:///:memory:")
  
  def load_idempotent(df, engine, table_name="clean_customers"):
      create_sql = text("""
          CREATE TABLE IF NOT EXISTS clean_customers (
              id VARCHAR(20) PRIMARY KEY,
              name VARCHAR(100)
          )
      """)
      with engine.begin() as conn:
          conn.execute(create_sql)
          conn.execute(text("DELETE FROM clean_customers"))
          df.to_sql("clean_customers", conn, if_exists="append", index=False)
  
  ```

* **Sample Output:** Running `load_idempotent` twice results in exactly 1 row in the table, not 2.

### Module 10 Practice Questions

#### Q10.1: Decoupled `extract()` Function

* **Scenario:** Ingest customers CSV and orders JSON independently.

* **Sample Input:** `cust_csv_path`, `orders_json_path`

* **Task:** Write `extract(c_path, o_path) -> tuple[pd.DataFrame, pd.DataFrame]` that returns raw DataFrames without dropping any records, logging rows extracted from each.

* **Sample Output:**

  ```csv
  (raw_customers_df, raw_orders_df)
  # Log: "Extracted 50 customers, 100 orders"
  
  ```

* **Validation Check:** Return type is a 2-tuple of DataFrames.

#### Q10.2: Defensive Cleaning Stage

* **Scenario:** Clean customers (drop missing IDs) and orders (coerce non-numeric amounts).

* **Sample Input:** Raw DataFrames containing 1 missing customer ID and 1 invalid order amount.

* **Task:** Implement `clean_stage(cust_df, orders_df)` returning cleaned copies with bad rows removed.

* **Sample Output:**

  ```text
  # clean_cust has 49 rows; clean_orders has 99 rows
  
  ```

* **Validation Check:** Invalid rows are removed and kept/skipped counts logged.

#### Q10.3: Reference Lookup Enrichment Stage

* **Scenario:** Join cleaned customers with a database region lookup table.

* **Sample Input:** `clean_cust` (country codes US, CA) and `region_lookup` table.

* **Task:** Implement `enrich_customers(cust_df, engine)` that reads `region_lookup` via SQL, merges on `country_code`, and asserts zero nulls in `region_name`.

* **Sample Output:**

  ```text
  # DataFrame containing columns: [customer_id, name, country_code, region_name]
  
  ```

* **Validation Check:** Missing region matches raise `ValueError`.

#### Q10.4: Idempotent Database Table Loader

* **Scenario:** Load enriched customers into SQLite/MySQL safely.

* **Sample Input:** Enriched customer DataFrame.

* **Task:** Implement `load_clean_customers(df, engine)` using `CREATE TABLE IF NOT EXISTS` and `TRUNCATE TABLE` (or `DELETE FROM`) inside `engine.begin()`.

* **Sample Output:**

  ```json
  "Loaded 49 customer records into clean_customers"
  
  ```

* **Validation Check:** Calling the loader twice leaves exactly 49 rows in the table.

#### Q10.5: Pipeline Orchestrator Function (`main()`)

* **Scenario:** Orchestrate extract, transform, and load in a master controller.

* **Sample Input:** Config dictionary with database URLs and file paths.

* **Task:** Implement `run_pipeline(config)` with logs before and after each stage.

* **Sample Output:**

  ```text
  [INFO] Starting EXTRACT
  [INFO] Finished EXTRACT
  [INFO] Starting TRANSFORM
  [INFO] Finished TRANSFORM
  [INFO] Starting LOAD
  [INFO] Finished LOAD
  [INFO] Pipeline completed successfully
  
  ```

* **Validation Check:** Pipeline runs end-to-end and returns exit code 0.

#### Q10.6: Database Round-Trip Verification Audit

* **Scenario:** Audit the loaded table against the source DataFrame.

* **Sample Input:** Target table `clean_customers` and `expected_df`.

* **Task:** Read table via `pd.read_sql()`, assert matching row count, and assert sample record email matches.

* **Sample Output:**

  ```json
  "Audit passed: 49 rows verified with 100% field parity on key samples."
  
  ```

* **Validation Check:** Assertions succeed on identical data and fail on row mismatch.

#### Q10.7: Parameterized Bulk Insert Execution

* **Scenario:** Insert records efficiently using SQLAlchemy dictionary parameter lists.

* **Sample Input:** `records = [{"id": 1, "name": "A"}, {"id": 2, "name": "B"}]`

* **Task:** Execute `INSERT INTO t (id, name) VALUES (:id, :name)` passing the list of dicts.

* **Sample Output:**

  ```text
  2 rows inserted via single parameterized call
  
  ```

* **Validation Check:** Rows appear in database table.

#### Q10.8: Transaction Rollback on Failure

* **Scenario:** A batch insert fails midway due to a duplicate primary key.

* **Sample Input:** 3 records where the 3rd record has a duplicate key.

* **Task:** Demonstrate that `with engine.begin()` rolls back records 1 and 2 when record 3 fails.

* **Sample Output:**

  ```text
  # Table row count after failure: 0
  
  ```

* **Validation Check:** Zero rows remain in table after exception.

#### Q10.9: Schema Evolution Alignment

* **Scenario:** A vendor CSV introduces an unexpected column and omits an optional column.

* **Sample Input:** `df` has columns `['id', 'name', 'extra_col']`; target requires `['id', 'name', 'status']`.

* **Task:** Implement `align_schema(df, target_cols)` to drop extra columns and fill missing columns with `None`.

* **Sample Output:**

  ```text
  # Output DataFrame has exact columns: ['id', 'name', 'status']
  
  ```

* **Validation Check:** `list(df_aligned.columns) == target_cols`

#### Q10.10: Upsert Incremental Sync

* **Scenario:** Perform an incremental upsert (update existing, insert new).

* **Sample Input:** Existing table with `(ID=1, status='OLD')`; incoming batch has `(ID=1, status='NEW')` and `(ID=2, status='NEW')`.

* **Task:** Implement upsert logic using temporary staging tables and SQL `INSERT OR REPLACE` (or `ON DUPLICATE KEY UPDATE`).

* **Sample Output:**

  ```text
  # ID 1 updated to 'NEW', ID 2 inserted
  
  ```

* **Validation Check:** Table has 2 rows, both with `status == 'NEW'`.

## Module 11: Mutation Traps, Iterator Lifecycles & Data Structure Integrity (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 2 Q3 and Q4:

1. **Mutating During Iteration:** Calling `list.remove(x)` inside `for x in list:` shifts index pointers, causing the loop to skip the immediate next element! Always create a new list using a comprehension: `[x for x in items if x != target]`.

2. **Consuming Result Iterators:** Database cursors and generator objects are single-use streams. Running `set(data)` or `list(data)` consumes the cursor; any subsequent loop over `data` will find 0 elements!

3. **Data Structure Type Integrity:** A list of dictionaries `[{"a": 1}]` is NOT a DataFrame. Writing `data["a"]` raises `TypeError: list indices must be integers or slices, not str`. Use list comprehensions or wrap in `pd.DataFrame(data)`.

### 2. Topic Reference Example

* **Scenario:** Demonstrate the iteration removal bug and its correct resolution.

* **Sample Input:**

  ```python
  bad_list = [10, 20, 20, 30]
  
  ```

* **Solution Code:**

  ```python
  # BUGGY:
  for x in bad_list:
      if x == 20: bad_list.remove(x)
  # bad_list is now [10, 20, 30]! The second 20 was skipped.
  
  # CORRECT:
  good_list = [10, 20, 20, 30]
  fixed = [x for x in good_list if x != 20]
  
  ```

* **Sample Output:**

  ```text
  fixed # [10, 30]
  
  ```

### Module 11 Practice Questions

#### Q11.1: Demonstrating and Fixing the Loop Mutation Trap

* **Scenario:** Remove all occurrences of number `20` from a list with consecutive duplicates.

* **Sample Input:** `[10, 20, 20, 30, 20, 40]`

* **Task:** Demonstrate the bug with `.remove()` in a loop, then provide the correct non-mutating list comprehension.

* **Sample Output:**

  ```json
  [10, 30, 40]
  
  ```

* **Validation Check:** Output contains zero occurrences of `20`.

#### Q11.2: Exhausting Generator / Cursor Iterators

* **Scenario:** A developer checks `len(list(cursor))` before looping over `cursor`.

* **Sample Input:** A database cursor yielding 3 rows.

* **Task:** Show why the subsequent loop iterates 0 times, and provide the correct solution using `.fetchall()`.

* **Sample Output:**

  ```text
  # Rows processed: 3
  
  ```

* **Validation Check:** All 3 rows are processed.

#### Q11.3: Safe Filtering of Dictionaries in Lists

* **Scenario:** Filter a list of user dictionaries without mutating the original list.

* **Sample Input:** `users = [{"id": 1, "active": True}, {"id": 2, "active": False}]`

* **Task:** Return active users in a new list while asserting that `users` retains both elements.

* **Sample Output:**

  ```text
  [{"id": 1, "active": True}]
  
  ```

* **Validation Check:** `assert len(users) == 2 and len(active) == 1`

#### Q11.4: List of Dicts vs DataFrame Attribute Access

* **Scenario:** A developer receives `data = list(csv.DictReader(f))` and runs `data["col"]`.

* **Sample Input:** `data = [{"code": "US"}, {"code": "CA"}]`

* **Task:** Catch the resulting `TypeError`, and provide two correct ways to access the column (comprehension vs DataFrame).

* **Sample Output:**

  ```text
  # Way 1 (list): ['US', 'CA']
  # Way 2 (df): Series of ['US', 'CA']
  
  ```

* **Validation Check:** Both extraction methods yield identical values.

#### Q11.5: Deep vs Shallow Copy in Nested Dictionaries

* **Scenario:** Clone a nested configuration dictionary without shared memory references.

* **Sample Input:** `cfg = {"db": {"host": "localhost", "port": 5432}}`

* **Task:** Demonstrate that `cfg.copy()` modifies the original when updating `host`, and show how `copy.deepcopy()` prevents this.

* **Sample Output:**

  ```text
  # With deepcopy, mutating clone leaves original cfg["db"]["host"] == "localhost"
  
  ```

* **Validation Check:** Original nested dict is unmodified.

#### Q11.6: Splitting Iterators with `itertools.tee`

* **Scenario:** Send a generator stream to two independent consumers without re-reading from disk.

* **Sample Input:** Generator yielding `[1, 2, 3, 4, 5]`.

* **Task:** Use `itertools.tee(gen, 2)` to consume the stream twice independently.

* **Sample Output:**

  ```text
  Consumer 1 sum: 15, Consumer 2 max: 5
  
  ```

* **Validation Check:** Both consumers successfully read all elements.

#### Q11.7: Default Mutable Argument Trap

* **Scenario:** A function uses `def add_item(item, target=[]):`.

* **Sample Input:** Calling `add_item(1)` followed by `add_item(2)`.

* **Task:** Demonstrate that `target` accumulates items across calls, and implement the standard `target=None` idiom.

* **Sample Output:**

  ```text
  # Bad: [1, 2] on second call
  # Fixed: [2] on second call
  
  ```

* **Validation Check:** Repeated calls with default arguments return independent single-element lists.

#### Q11.8: Preserving Insertion Order with Composite Keys

* **Scenario:** Deduplicate tuples by first element while preserving encounter order.

* **Sample Input:** `[("b", 1), ("a", 2), ("b", 3), ("c", 4)]`

* **Task:** Deduplicate by key (first item), keeping the first encounter.

* **Sample Output:**

  ```text
  [("b", 1), ("a", 2), ("c", 4)]
  
  ```

* **Validation Check:** Key `"b"` retains value `1`.

#### Q11.9: Safe Dictionary Key Deletion During Iteration

* **Scenario:** Remove keys with `None` values from a dictionary.

* **Sample Input:** `d = {"a": 1, "b": None, "c": 3}`

* **Task:** Demonstrate that iterating over `d` while calling `del d[k]` raises `RuntimeError`, and provide a safe dictionary comprehension alternative.

* **Sample Output:**

  ```json
  {"a": 1, "c": 3}
  
  ```

* **Validation Check:** Clean dictionary has no `None` values.

#### Q11.10: Tuple Immutability and Nested Mutable State

* **Scenario:** A tuple contains a list: `t = (1, [2, 3])`.

* **Sample Input:** `t[1].append(4)`

* **Task:** Demonstrate that the list inside the tuple can be mutated while `id(t)` remains constant, and explain why `hash(t)` raises `TypeError`.

* **Sample Output:**

  ```text
  t is now (1, [2, 3, 4])
  hash(t) -> TypeError: unhashable type: 'list'
  
  ```

* **Validation Check:** Catch `TypeError` when attempting `hash(t)`.

## Module 12: Architectural Reasoning, TDD Cycles & Clean Code Explanations (10 Questions)

### 1. Conceptual Notes & Deep Dive

In Test 1 Q10 and Test 2 Q8:

* Both questions required structured written explanations in **4–6 complete sentences**.

* Submissions lost marks by providing 1–2 fragmented bullet points naming concepts without explaining **why** or **how** they work.

* **Four-Step Answer Architecture:**

  1. *Definition Sentence:* State the core principle clearly.

  2. *Mechanism Sentence(s):* Explain step-by-step how it operates (e.g. Red -> Green -> Refactor).

  3. *Engineering Impact:* Explain why this matters (e.g. deterministic failure triage, preventing silent corruption).

  4. *Concrete Example:* Briefly ground the principle in a real-world scenario (e.g. isolating database queries from data parsing).

### 2. Topic Reference Example

* **Prompt:** In 4–6 sentences, explain the red-green-refactor cycle of Test-Driven Development (TDD) and why separating I/O operations from pure business logic makes unit testing significantly easier.

* **Sample Input / Question Context:** Question 10 from Test 1.

* **Sample Output / Model Answer Benchmark:**

  > Test-Driven Development structures software implementation around the three-phase red-green-refactor cycle. In the red phase, developers write a unit test defining desired functionality and observe it fail, confirming the test is valid and not a false positive. During the green phase, they implement the minimum code necessary to make the test pass. The refactor phase then allows code cleanup and architectural improvement while automated tests guarantee no regression. Separating I/O operations—such as disk access, database calls, and network requests—from pure business logic is essential because pure logic can be tested deterministically in memory with known inputs and expected outputs. This isolation avoids the maintenance overhead of complex mocking and ensures unit test suites execute in milliseconds.

### Module 12 Practice Questions

#### Q12.1: Benefits of Modular ETL over Monolithic Scripts

* **Prompt:** In 4–6 sentences, explain why decomposing an ETL pipeline into distinct `extract()`, `transform()`, and `load()` functions makes systems easier to maintain and debug compared to a single monolithic script.

* **Sample Input:** Refactoring a 500-line sequential ETL script into decoupled stages.

* **Sample Output Benchmark:** Must explain: (1) single responsibility, (2) isolated unit testability of transformation rules without database mocks, (3) failure domain localization, and (4) independent scaling/reusability of stages.

#### Q12.2: Idempotency in Batch Data Engineering

* **Prompt:** In 4–6 sentences, define what idempotency means in data engineering and explain how techniques like `TRUNCATE-and-reload` or primary-key upserts guarantee data consistency during automated pipeline retries.

* **Sample Input:** A failed batch job that is retried 3 times by an orchestrator like Airflow.

* **Sample Output Benchmark:** Must define mathematical idempotency (f(f(x)) = f(x)), explain the danger of duplicate append rows upon network timeouts, and demonstrate how transactions enforce clean state.

#### Q12.3: Vectorization vs Iteration in Pandas

* **Prompt:** In 4–6 sentences, explain why vectorized operations in pandas are drastically faster than iterating through rows with `for` loops or `.iterrows()`. Include in your explanation how underlying C-level contiguous memory arrays contribute to performance.

* **Sample Input:** Comparing row-by-row iteration vs `df['a'] + df['b']` across 1,000,000 rows.

* **Sample Output Benchmark:** Must contrast Python dynamic type-checking overhead per element with NumPy contiguous memory buffers and SIMD CPU vector register execution.

#### Q12.4: Purpose and Mechanics of Python Context Managers

* **Prompt:** In 4–6 sentences, explain how the `with` statement and Python's context manager protocol (`__enter__` and `__exit__`) prevent resource leaks in database and file handling, even when unhandled exceptions occur.

* **Sample Input:** Managing database connection pools and file descriptors under sudden process exceptions.

* **Sample Output Benchmark:** Must detail the automated invocation of `__exit__`, handling exception arguments, and guaranteeing that network sockets and OS file handles close deterministically.

#### Q12.5: Defensive Data Contracts and Schema Validation

* **Prompt:** In 4–6 sentences, explain the role of upstream schema validation in production ETL pipelines. Detail what risks arise when pipelines silently accept malformed data or coerce corrupted values without logging warnings.

* **Sample Input:** An ingestion pipeline receiving unexpected null values in a required foreign key column.

* **Sample Output Benchmark:** Must define silent data corruption, explain downstream data pollution, and justify why "failing fast" with structured error logs prevents reporting discrepancies.

#### Q12.6: Generators vs Lists for High-Throughput Ingestion

* **Prompt:** In 4–6 sentences, explain the mechanical differences between eager evaluation (e.g. returning a `list` from `f.readlines()`) and lazy evaluation (using `yield` with `csv.DictReader`). Explain how this impacts memory scalability.

* **Sample Input:** Parsing a 20 GB compressed web server access log on a container with 2 GB RAM.

* **Sample Output Benchmark:** Must contrast O(N) full heap allocation with O(1) constant-buffer streaming, explaining why lazy evaluation prevents memory exhaustion.

#### Q12.7: Single Responsibility Principle in Transformation Logic

* **Prompt:** In 4–6 sentences, explain how the Single Responsibility Principle applies to data transformations. Explain why mixing extraction, data type casting, and reporting aggregations into one function creates brittle code.

* **Sample Input:** A single 100-line function `get_report()` that connects to MySQL, parses dates, and computes monthly customer churn.

* **Sample Output Benchmark:** Must explain tight coupling, combinatorial test explosion, and how changes in upstream database drivers force rewriting analytical logic.

#### Q12.8: Production Logging Levels and Operational Observability

* **Prompt:** In 4–6 sentences, explain how distinct logging levels (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`) should be employed across an automated ETL pipeline to support effective monitoring and post-incident debugging.

* **Sample Input:** Designing telemetry for an automated nightly billing ETL pipeline.

* **Sample Output Benchmark:** Must assign clear pipeline scenarios: row metrics (`INFO`), dropped invalid rows (`WARNING`), connection retries (`ERROR`), and process-halting crashes (`CRITICAL`).

#### Q12.9: The Risk of Swallowing Exceptions in Batch Processing

* **Prompt:** In 4–6 sentences, explain why catching generic `Exception` without re-raising or properly failing a batch job can cause "silent data corruption". Provide a concrete example of how downstream analytics are impacted.

* **Sample Input:** An empty `except Exception: pass` block surrounding a database load stage.

* **Sample Output Benchmark:** Must illustrate a failed write resulting in empty tables, downstream dashboard jobs calculating zero revenue, and executives making business decisions on corrupted metrics.

#### Q12.10: Pure Functions and Unit Testing Without Mocks

* **Prompt:** In 4–6 sentences, explain what a pure function is in Python and why writing pure transformation functions drastically reduces the need for mocking external dependencies during testing.

* **Sample Input:** Refactoring a function that reads from SQL and writes to disk into a function that takes a DataFrame and returns a DataFrame.

* **Sample Output Benchmark:** Must define pure functions (deterministic output, zero side effects), and explain how passing in-memory test DataFrames eliminates the need to mock databases or file systems.

# Part III: Standalone Reusable Datasets & Fixture Catalog

This section compiles all datasets used throughout the question bank into copy-pasteable Python fixtures and an automated local file generator script.

## 1. Standalone Python Fixture Module (`practice_datasets.py`)

```sql
"""
Standalone Data Fixtures for Python Practice Question Bank (Tests 1 & 2)
"""

import json
from pathlib import Path
import pandas as pd

# =====================================================================
# MODULE 1 & 3: RAW LISTS & STREAM DICTIONARIES
# =====================================================================
MODULE_1_TRANSACTIONS = [
    {"tx_id": "TX101", "user_id": 9, "amount": 45.0, "status": "COMPLETED"},
    {"tx_id": "TX102", "user_id": 33, "amount": 120.5, "status": "COMPLETED"},
    {"tx_id": "TX103", "user_id": 61, "amount": 15.0, "status": "FAILED"},
    {"tx_id": "TX101", "user_id": 9, "amount": 45.0, "status": "COMPLETED"},
    {"tx_id": "TX104", "user_id": 4, "amount": 90.0, "status": "COMPLETED"},
    {"tx_id": "TX105", "user_id": 78, "amount": 310.0, "status": "COMPLETED"},
    {"tx_id": "TX102", "user_id": 33, "amount": 120.5, "status": "DUPLICATE_SUBMISSION"},
    {"tx_id": "TX106", "user_id": 99, "amount": 80.0, "status": "COMPLETED"},
]

MODULE_1_TAGS = ['Python', 'SQL', 'python', 'ETL', 'Sql', 'pandas', 'ETL']

MODULE_3_CURRENCIES = ["$12.50", " $100.00 ", "$4.99", "$0.50", "$2,450.00"]

# =====================================================================
# MODULE 4: RELATIONAL MERGE FIXTURES
# =====================================================================
MODULE_4_ORDERS = pd.DataFrame([
    {"order_id": 101, "customer_id": "C1", "product_id": "P01", "quantity": 2},
    {"order_id": 102, "customer_id": "C2", "product_id": "P02", "quantity": 1},
    {"order_id": 103, "customer_id": "C1", "product_id": "P03", "quantity": 4},
    {"order_id": 104, "customer_id": "C3", "product_id": "P01", "quantity": 1},
    {"order_id": 105, "customer_id": "C2", "product_id": "P03", "quantity": 2},
])

MODULE_4_PRODUCTS = pd.DataFrame([
    {"product_id": "P01", "product_name": "Keyboard", "unit_price": 45.00, "cost_price": 30.0, "category": "Electronics"},
    {"product_id": "P02", "product_name": "Mouse", "unit_price": 25.00, "cost_price": 15.0, "category": "Electronics"},
    {"product_id": "P03", "product_name": "Cable", "unit_price": 10.00, "cost_price": 4.0, "category": "Accessories"},
    {"product_id": "P04", "product_name": "Monitor", "unit_price": 200.00, "cost_price": 140.0, "category": "Electronics"},
])

# =====================================================================
# MODULE 5: MESSY SURVEY DATA
# =====================================================================
MODULE_5_SURVEY = pd.DataFrame({
    "emp_id": ["E101", "E102", "E103", "E104", "E105", "E106", "E107", "E108"],
    "age": [28, "unknown", 34, "42", "N/A", 23, "31", None],
    "salary": ["75000", "unknown", "120000", "88000.50", "corrupt", "45000", "95000", "0"],
    "bonus": ["5000", "0", "15000", "unknown", "2500", "N/A", "10000", "1200"],
    "department": ["IT", "HR", "IT", "Finance", "HR", "IT", "Marketing", "IT"]
})

# =====================================================================
# MODULE 6: CATEGORICAL SURVEY ROLES
# =====================================================================
MODULE_6_ROLES = pd.DataFrame({
    "response_id": range(1, 13),
    "role_raw": [
        "Full-time", "  ft ", "CONTRACT", "freelancer", "Part-Time", 
        "full time", "Contractor", "Employee", "unknown", "FT", "intern", "FREELANCE"
    ],
    "region": ["NA", "EU", "NA", "APAC", "EU", "NA", "APAC", "EU", "NA", "EU", "NA", "APAC"],
    "satisfaction": ["HIGH", "MED", "HIGH", "LOW", "MED", "HIGH", "LOW", "HIGH", "LOW", "MED", "MED", "HIGH"]
})

# =====================================================================
# MODULE 8: PHONE NUMBERS & SQL INDEX SCHEMA
# =====================================================================
MODULE_8_PHONES = [
    "(555) 123-4567", "555.123.4567", "+1 555 123 4567", 
    "5551234567", "+1-555-123-4567", "15551234567", "invalid_phone", "(555) 123-456"
]

MODULE_8_SQL = '''-- Database Migration Script
CREATE TABLE users (id INT PRIMARY KEY, email VARCHAR(100));
CREATE INDEX idx_user_email ON users (email);
CREATE UNIQUE INDEX idx_user_id_email ON users (id, email);
CREATE INDEX IF NOT EXISTS idx_users_signup ON users (`signup_date`);
CREATE UNIQUE INDEX `idx_orders_ref` ON `orders` (`order_ref`, `tenant_id`);
'''

# =====================================================================
# MODULE 10: COMPLETE ETL PIPELINE FIXTURES
# =====================================================================
MODULE_10_CUSTOMERS_CSV = '''customer_id,name,email,country_code
C01,Alice Johnson,alice@example.com,US
C02,Bob Smith,bob@example.com,CA
C03,Carlos Gomez,carlos@example.com,MX
C04,David Lee,david@example.com,US
,Missing ID,no_id@example.com,US
'''

MODULE_10_ORDERS_JSON = '''[
    {"order_id": "O101", "customer_id": "C01", "order_date": "2026-01-10", "amount": "150.00"},
    {"order_id": "O102", "customer_id": "C02", "order_date": "2026-01-12", "amount": "invalid_amt"},
    {"order_id": "O103", "customer_id": "C01", "order_date": "2026-01-15", "amount": "45.50"},
    {"order_id": "O104", "customer_id": "C04", "order_date": "2026-01-18", "amount": "200.00"}
]'''

MODULE_10_LOOKUP = pd.DataFrame([
    {"country_code": "US", "region_name": "North America"},
    {"country_code": "CA", "region_name": "North America"},
    {"country_code": "MX", "region_name": "Latin America"}
])

```

## 2. Automated File Generator Script

Save and run this script to automatically populate a local folder `practice_data/` with all necessary file assets:

```python
def bootstrap_practice_environment(target_dir="practice_data"):
    path = Path(target_dir)
    path.mkdir(parents=True, exist_ok=True)
    
    (path / "raw_customers.csv").write_text(MODULE_10_CUSTOMERS_CSV, encoding="utf-8")
    (path / "raw_orders.json").write_text(MODULE_10_ORDERS_JSON, encoding="utf-8")
    (path / "schema_migration.sql").write_text(MODULE_8_SQL, encoding="utf-8")
    MODULE_4_ORDERS.to_csv(path / "orders.csv", index=False)
    MODULE_4_PRODUCTS.to_csv(path / "products.csv", index=False)
    MODULE_5_SURVEY.to_csv(path / "developer_survey.csv", index=False)
    MODULE_10_LOOKUP.to_csv(path / "region_lookup.csv", index=False)
    
    with pd.ExcelWriter(path / "regional_operations.xlsx") as writer:
        pd.DataFrame({
            "site_id": ["N-1", "N-2"], "headcount": [45, 60], "operating_cost": [120000, 150000]
        }).to_excel(writer, sheet_name="North", index=False)
        pd.DataFrame({
            "site_id": ["S-1", "S-2"], "headcount": [30, 40], "operating_cost": [85000, 110000], "manager": ["Lee", "Gomez"]
        }).to_excel(writer, sheet_name="South", index=False)
        
    print(f"All practice datasets bootstrapped in: {path.resolve()}")

if __name__ == "__main__":
    bootstrap_practice_environment()

```

# Practice Question Index Summary

| Module | Topic Domain | Category | Question Count | Primary Diagnostic Focus | 
| ----- | ----- | ----- | ----- | ----- | 
| **Module 1** | Order-Preserving Deduplication | Strong | 5 | Set hashing, preservation of first encounters, unhashable records | 
| **Module 2** | OOP & Abstract Base Classes | Strong | 5 | `@abstractmethod`, `TypeError` trapping, template method pattern | 
| **Module 3** | Functional Transformations | Strong | 5 | `map()`, `lambda`, list comprehensions, lazy generators | 
| **Module 4** | Relational Merging & Line Totals | Strong | 5 | Inner/outer joins, `sum()` aggregation, margin analysis | 
| **Module 5** | Pandas Cleaning & Sentinel Values | Weak | 10 | Non-destructive replacement, `to_numeric(errors='coerce')`, boolean masking | 
| **Module 6** | Categorical Normalization & Crosstab | Weak | 10 | `.map()`, clean mapping functions, `crosstab(normalize='index')`, % metrics | 
| **Module 7** | Streaming, Generators & Multi-Sheet Excel | Weak | 10 | Incremental generators, `csv.DictReader`, multi-sheet `pd.concat` | 
| **Module 8** | String Sanitization, Wraparound & Regex | Weak | 10 | Regex named groups, modulo 26 alphabet wrap, phone standardization | 
| **Module 9** | Production Logging & Assertions | Weak | 10 | Dual stream/file handlers, specific catches, re-raising, assertions | 
| **Module 10** | End-to-End ETL Pipeline Architecture | Weak | 10 | Decoupled functions, rerun-safety, parameterized SQL, DB audits | 
| **Module 11** | Mutation Traps & Data Structures | Weak | 10 | Loop-time mutation, iterator exhaustion, list-of-dicts vs DataFrame | 
| **Module 12** | Architectural Explanations & TDD | Weak | 10 | Structured 4-6 sentence reasoning, TDD cycles, clean data engineering | 
| **TOTAL** | **Comprehensive Python Bank** |  | **100** | **Full coverage of Test 1 and Test 2 competencies** | 
