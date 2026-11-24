# Python Retest Workspace: Combined Test 1 + Test 2

**Duration:** 3 hours (180 minutes)  
**Questions:** 20  
**Maximum score:** 200 marks (10 marks per question)  
**Runtime target:** Python 3.10+ (recommended 3.11), pandas, SQLAlchemy 2.x, MySQL 8.0

This is a newly written practice retest based on the actual uploaded Python Test 1 and Test 2 question notebooks, their seeded files, and the solution-package README. It is not an official or guaranteed future paper. It preserves their tested concepts, sequencing, and notebook format while using new scenarios and data.

## What was learned from the source tests

The original materials contain:

- **Python Test 1:** 16 questions / 160 points. Q1–Q10 cover order-preserving deduplication, abstract classes, `map`/`lambda`, generators, regex parsing of SQL index definitions, custom encoding, string normalization, type coercion, exception handling/logging, and TDD. Q11–Q16 cover pandas dtype repair, grouped percentages, two-dimensional reports, strict category normalization, multi-sheet Excel combination, and DataFrame merge/aggregation.
- **Python Test 2:** 8 questions / 80 points. These form one connected MySQL-backed ETL: config-driven connection and persistent logging, raw extraction, cleaning, enrichment using a lookup table, re-run-safe database load, round-trip validation, pipeline refactoring, and a written explanation of modular ETL design.

The retest compresses those 24 source questions into **20 combined questions**. It uses 14 questions to cover the Test 1 skill families (9 core-Python questions plus 5 pandas/file questions) and 6 questions to cover Test 2's connected ETL stages. This allocation is a design choice based on the original 16:8 question ratio, not a claim about the examiner's exact future selection.

## Folder layout

```text
python_retest_3hr_official/
├── README.md
├── requirements.txt
├── notebooks/
│   └── questions.ipynb
├── answers/
│   └── model-answers.ipynb
├── rubric.md
├── docker/
│   └── docker-compose.yml
├── seed_data/
│   ├── generate_seed.py
│   ├── seed_mysql.py
│   └── data/
│       ├── api_events.csv
│       ├── operations_survey.csv
│       ├── api_audit.log
│       ├── branch_activity.xlsx
│       ├── service_requests.csv
│       ├── service_catalog.csv
│       ├── raw_clients.csv
│       ├── raw_jobs.json
│       └── region_lookup_reference.csv
├── src/
│   └── retest_helpers.py
└── tests/
    └── test_retest_helpers.py
```

## 1. Install dependencies

Run from this project folder:

```bash
python -m pip install -r requirements.txt
```

Make sure the Jupyter kernel uses the same Python interpreter where the packages were installed. If a notebook says `ModuleNotFoundError`, check the selected kernel before reinstalling packages.

## 2. Start MySQL 8 with Docker

Docker Desktop (or another Docker Engine) must be running.

```bash
cd docker
docker compose up -d
```

Wait until MySQL is healthy:

```bash
docker compose ps
```

The service exposes port **3307** on the host and uses the following disposable local credentials by default:

| Setting | Value |
|---|---|
| Host | `127.0.0.1` |
| Port | `3307` |
| User | `root` |
| Password | `PythonRetest_2026!` |
| Database | `python_retest` |

These are local practice credentials only. For a different password, set `MYSQL_ROOT_PASSWORD` before starting Compose and set the matching `PY_RETEST_DB_PASSWORD` for the notebook/seed script.

## 3. Seed the lookup database

Return to the project root, then run:

```bash
python seed_data/seed_mysql.py
```

The seed script recreates the disposable `python_retest` database and populates `region_lookup`. **It drops the existing `python_retest` database first**, so do not use this script with any real or valuable database.

## 4. Open the question notebook

From the project root:

```bash
jupyter lab
```

Open `notebooks/questions.ipynb`. The notebook includes a setup cell that locates `seed_data/data/` whether Jupyter is opened from the project root or the `notebooks/` directory.

Attempt the questions in order. Q10–Q14 use the survey/file fixtures. Q15–Q20 form a connected database-backed ETL workflow, so start Docker and run the seed script before reaching Q15.

## 5. Open the model answers

The instructor/self-study answer notebook is `answers/model-answers.ipynb`. It contains solutions in the same order as the questions. The MySQL sections require the Docker database and seed step above. Do not keep the answer notebook open during a timed attempt.

## 6. Run the optional pytest checks

The included test suite verifies the pure helper functions used by the reference solution:

```bash
python -m pytest -q
```

The 13 tests cover normalized-key deduplication, abstract classes, repeating-key encoding and wraparound, asset-tag normalization, numeric reference cleanup, positive-quantity validation, and exact category normalization. They are supporting checks, not extra questions or an official grading mechanism.

## 7. Regenerate the input fixtures

The committed files already exist under `seed_data/data/`. To regenerate them deterministically:

```bash
python seed_data/generate_seed.py
```

This replaces the generated CSV, JSON, audit-log and Excel fixtures with the same deterministic sample data.

## Assessment timing suggestion

| Section | Questions | Time |
|---|---:|---:|
| Core Python | Q1–Q9 | 70 minutes |
| Pandas and file processing | Q10–Q14 | 45 minutes |
| MySQL and ETL | Q15–Q20 | 65 minutes |
| **Total** | **20** | **180 minutes** |

## Environment limitations

The notebooks and datasets are supplied locally. The Python-only tasks can be attempted without Docker. Questions Q15–Q20 require a reachable MySQL 8 server with the supplied lookup database. The model-answer notebook has been syntax-checked; database-backed answers must be executed against the local Docker service after seeding.
