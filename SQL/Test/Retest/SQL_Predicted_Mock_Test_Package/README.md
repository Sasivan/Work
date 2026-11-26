# SQL Predicted Mock Assessment — MySQL 8.0

This is a self-practice assessment built from the recurring patterns in the supplied SQL Test 1 and SQL Test 2 notebooks, with the Python Retest's 4 + 4 + 3 section structure used as a guide.

**This is a predicted practice paper, not an official assessment or a guarantee of future questions.** It intentionally changes the business examples while reusing the underlying SQL concepts.

## Assessment format

| Part | Questions | Marks | Main skills |
|---|---:|---:|---|
| A — Core SQL | 1–4 | 32 | DDL, DML, joins, deduplication |
| B — Advanced SQL | 5–8 | 32 | Self-joins, distinct ranking, relational division, date spine |
| C — ETL / reporting | 9–11 | 36 | Staging cleanup, stored procedures, star schema, SCD2 |
| **Total** | **11** | **100** | **Suggested time: 3 hours** |

Questions 1–8 are 8 points each. Questions 9–11 are 12 points each. The `questions.ipynb` has blank work cells; no answers are included in the practice ZIP.

## Folder layout

```text
SQL_Predicted_Mock_Test_Package/
  README.md
  requirements.txt
  docker/docker-compose.yml
  seed/seed_mysql.py
  questions.ipynb
  reference_original/
    sql_test_1/       # original question notebook + both seed scripts
    sql_test_2/       # original ETL notebook + seed script
```

## 1. Create a Python environment (Windows PowerShell)

Open PowerShell in this folder:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

If PowerShell blocks activation, use this for the current terminal only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

Use the same Python environment for the Jupyter kernel. In VS Code, select the `.venv` interpreter before opening `questions.ipynb`.

## 2. Start MySQL with Docker Desktop

Start Docker Desktop first. In this package's root folder, run:

```powershell
docker compose -f docker/docker-compose.yml up -d
```

Check Docker is running:

```powershell
docker info
```

Wait until the container is healthy:

```powershell
docker inspect -f "{{.State.Health.Status}}" sql_mock_mysql
```

Repeat until the result is `healthy`. MySQL may need several seconds on its first start.

## 3. Load the databases and seed data

Run this from the package root:

```powershell
python seed/seed_mysql.py
```

The seed script creates five disposable databases:

| Database | Starting state | Used for |
|---|---|---|
| `sql_mock_core` | Empty | Questions 1–3: create and populate your own tables |
| `sql_mock_select` | Seeded | Questions 4–8: independent SELECT problems |
| `sql_mock_staging` | Seeded messy raw tables | Question 9: ETL source |
| `sql_mock_intermediate` | Empty | Questions 9–10: cleaned tables |
| `sql_mock_reporting` | Empty | Questions 10–11: star schema and SCD2 |

**Important:** `python seed/seed_mysql.py` drops and recreates these five databases. Run it only against this local mock container, never against a real database. Run it again whenever you want a clean attempt.

## 4. Open the question notebook

```powershell
jupyter lab
```

Open `questions.ipynb`. You can also open it directly in VS Code with the Jupyter extension.

- Run the setup cell first.
- Questions 1–3 use `sql_mock_core` and build on each other.
- Questions 4–8 use pre-seeded independent scenarios in `sql_mock_select`.
- Questions 9–11 use SQLAlchemy engines for the three ETL databases.
- Use `%%sql` for ordinary SQL. Use a normal Python cell with SQLAlchemy for `CREATE PROCEDURE` and `CALL` statements because stored procedure bodies contain internal semicolons.

## 5. Reset and stop the environment

To reset for a fresh attempt, rerun:

```powershell
python seed/seed_mysql.py
```

To stop the MySQL container:

```powershell
docker compose -f docker/docker-compose.yml down
```

To remove the container **and its mock database volume** (this deletes the local MySQL data volume):

```powershell
docker compose -f docker/docker-compose.yml down -v
```

## Connection details

- Host: `localhost`
- Port: `3308`
- User: `root`
- Password: `InternTest_2026!`
- MySQL: `8.0`

The mock package uses host port **3308** so it does not conflict with the original SQL assessment container, which uses port 3307. The original reference seed scripts still use port 3307 and are included for reference only. These are disposable local-test credentials; do not use them outside this local exercise.

## What to practise after the mock

Review the separate `SQL_Test_1_and_2_Combined_Easy_Solutions.md` and `SQL_Question_Bank_50_Easy_Solutions.md` files for worked solutions and more variations. The original source notebooks and their seed scripts are included in `reference_original/` for additional practice.
