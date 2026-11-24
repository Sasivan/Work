# Source Analysis and Retest Prediction

## Sources inspected

The retest was designed after opening the original Python assessment ZIPs:

- `test-1-fundamentals (2).zip`: `questions.ipynb`, `seed_data/generate_seed_core.py`, `seed_data/generate_seed_pandas.py`, and the actual CSV/XLSX/SQL fixtures.
- `test-1-fundamentals (3) sol.zip`: the solution-package README, requirements, and model-answer notebook.
- `test-2-etl (2).zip`: `questions.ipynb`, raw client CSV, raw jobs JSON, generator, and MySQL seeding script.
- `test-2-etl (3) sol.zip`: solution notebook, requirements, MySQL seed setup and Docker Compose file.

This report distinguishes source-derived facts from the retest's predictions.

## 1. What the two original tests actually cover

### Python Test 1

The original Test 1 has **16 questions / 160 points**, all worth 10 points each.

| Original questions | Source topics | Main capability assessed |
|---|---|---|
| Q1–Q3 | Order-preserving deduplication; ABCs; `map()`/lambda | Core Python, data structures and basic OOP |
| Q4 | Generator reads approximately 100,000 transaction rows and incrementally aggregates category totals/counts | Lazy iteration and memory discipline |
| Q5 | Regex extracts CREATE INDEX / CREATE UNIQUE INDEX statements with multi-column indexes | Structured-text parsing and careful capture groups |
| Q6 | Position-dependent alphabet encoding with wraparound | Translating a written algorithm into exact code |
| Q7–Q8 | Phone normalization; extracting digits and converting to int/None | String normalization and type conversion |
| Q9–Q10 | Specific exception handling/logging; TDD red-green-refactor and pure logic | Production coding standards and testability |
| Q11–Q14 | Repair survey dtypes; remote-work percentage; satisfaction by normalized employment type + continent; strict employment normalization | Pandas cleaning, group-level percentages and category bucketing |
| Q15–Q16 | Combine every Excel sheet with source_sheet; merge order/product data and aggregate customer revenue | Semi-structured data and DataFrame joins |

The original notebook explicitly warns that Q13 depends on the normalized category created for Q14, so the candidate must read ahead and build dependencies in the right order.

### Python Test 2

The original Test 2 has **8 questions / 80 points**, also 10 points each. These questions are not eight isolated scripts; they form one database-backed ETL pipeline.

| Original Q | Source requirement | Main capability assessed |
|---:|---|---|
| 1 | Config-driven SQLAlchemy connection; dual console/file logging; read lookup table | Configuration and operational logging |
| 2 | Extract raw CSV and JSON without cleaning; preserve malformed rows; log counts | Extract-only discipline and specific errors |
| 3 | Drop missing customer ID and non-numeric order amount; report retained/rejected rows | Data cleaning and data-quality reporting |
| 4 | Enrich cleaned customers from MySQL lookup using country_code | Lookup join and missing mapping validation |
| 5 | Create clean table and load with full-refresh or upsert strategy | Database persistence and idempotency |
| 6 | Read destination back and assert count and known values | Round-trip verification |
| 7 | Refactor into extract(), transform(), load(), main() | Pipeline architecture and stage contracts |
| 8 | Explain independent testability and maintainability | Written engineering reasoning |

The original solution-package README says database setup uses Docker and MySQL 8, with the Python Test 2 seed script recreating its database and seeding the `region_lookup` table. It emphasizes re-running seed scripts to reset state before each candidate.

## 2. Repeated examiner design patterns

### A. Questions state constraints explicitly

The test does not simply say “remove duplicates” or “clean the data.” It states first-seen ordering, exact category aliases, `None` behavior, missing-value sentinels, and whether invalid input should be skipped or raise. The implementation must satisfy the whole written contract, not merely the example.

### B. Test data is deliberately imperfect

The original fixtures intentionally include a large CSV, non-numeric sentinel strings, category aliases, multi-value categories, blank IDs, a malformed JSON amount, and heterogeneous Excel sheets. Data-quality handling is part of the question rather than an optional enhancement.

### C. Data dependencies matter

Some questions reuse a DataFrame, a cleaned column, a database connection, or records generated earlier. A disconnected answer that recomputes differently or uses stale data can fail even if its local syntax looks reasonable.

### D. Observable correctness matters

The prompts repeatedly ask candidates to print dtypes, report row counts, log kept/skipped counts, show category counts, query the lookup table, read rows back from MySQL, and assert known values. A working-looking code cell is not enough; it must demonstrate the result.

### E. Test 2 assesses operational behavior

The expected pipeline must handle failed inputs transparently, log to console and file, re-raise failures where required, and be safe to rerun. A SQL statement constructed as a string is not equivalent to a completed database load.

## 3. Retest structure: why 20 questions

The prior source tests contain 24 questions and take 2 hours plus 1.5 hours. The requested retest duration is 3 hours, so this practice paper compresses the coverage into 20 questions:

| Retest section | Questions | Marks | Time |
|---|---:|---:|---:|
| Core Python patterns | Q1–Q9 | 90 | 70 min |
| Pandas and file processing | Q10–Q14 | 50 | 45 min |
| Database-backed ETL | Q15–Q20 | 60 | 65 min |
| **Total** | **20** | **200** | **180 min** |

The 14:6 split is a compressed version of the source tests' 16:8 split. ETL questions are combined where the original Test 2 naturally has dependent steps: loading and read-back validation become one question, while refactoring remains a separate capstone question.

## 4. Qualitative likelihood ranking

These are reasoned predictions, not knowledge of the examiner's future paper.

| Confidence | Likely concept families | Evidence in source tests |
|---|---|---|
| Very high | Pandas coercion, grouped percentage reports, strict category normalization, merge/aggregation | Multiple dedicated Test 1 questions and generated dirty survey fixture |
| Very high | ETL extract → clean → enrich → load → validate | Entire Test 2 is this workflow |
| Very high | Idempotent MySQL load and round-trip assertions | Explicit Test 2 Q5–Q6 requirements |
| High | Generator and incremental aggregate | Dedicated large-file Test 1 Q4 |
| High | Regex parsing with multi-column structure | Dedicated Test 1 Q5 |
| High | Logging and specific exceptions | Test 1 Q9 and Test 2 Q1–Q4 |
| High | Multi-sheet Excel combination | Dedicated Test 1 Q15 |
| High | TDD, pure functions and modularity | Test 1 Q10 and Test 2 Q7–Q8 |
| Medium-high | OOP interface, map/lambda, custom encoding, string normalization | Dedicated Test 1 Q1–Q3/Q6–Q8 |

## 5. Why the retest questions use different scenarios

The practice test uses API events, asset tags, operations survey data, branch workbooks, service requests, clients/jobs and a new region lookup database. This avoids cloning the old question wording or sample values while preserving the competencies signaled by the source papers.

Examples:

- Transactions by category become API events by endpoint with error count and average latency.
- Regex parsing moves from SQL index statements to structured API audit log records with quoted messages and malformed-line counting.
- Phone/reference cleanup becomes asset-tag normalization and reference-number extraction.
- Developer survey fields become operations survey fields with a different workforce classification.
- Order/product revenue becomes service request/catalog charges by client.
- Customer/order ETL becomes client/job ETL, with a new MySQL database and region mapping.

## 6. Important limitations

No source can establish the exact questions that will appear tomorrow. The new paper is an evidence-informed mock using the original assessment design. The database-backed answer cells require Docker/MySQL 8 to execute; the non-database Python solutions are independently testable without MySQL. The Docker daemon is not available in the authoring environment, so live MySQL execution is not claimed here.
