"""Generate deterministic input fixtures for the 3-hour Python retest."""
from __future__ import annotations

import csv
import json
import random
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"
DATA.mkdir(parents=True, exist_ok=True)
rng = random.Random(20261124)


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def make_api_events() -> None:
    endpoints = ["/api/orders", "/api/customers", "/api/products", "/api/payments", "/api/reports"]
    rows = []
    start = datetime(2026, 9, 1, 0, 0, 0)
    for i in range(1, 100_001):
        endpoint = rng.choice(endpoints)
        status = rng.choices([200, 201, 400, 404, 500, 502], [60, 8, 8, 10, 9, 5])[0]
        duration = round(rng.uniform(8, 1800), 2)
        # A small number of bad fields force defensive conversion.
        if i % 9973 == 0:
            duration = "unknown"
        if i % 15401 == 0:
            status = "bad-status"
        rows.append({
            "event_id": i,
            "endpoint": endpoint,
            "status_code": status,
            "duration_ms": duration,
            "event_time": (start + timedelta(seconds=i * 17)).isoformat(sep=" "),
        })
    write_csv(DATA / "api_events.csv", ["event_id", "endpoint", "status_code", "duration_ms", "event_time"], rows)


def make_survey() -> None:
    employment = [
        "Permanent", "PERMANENT", "staff", "full time", "FT",
        "contractor", "agency", "freelance", "vendor",
        "staff;vendor", "intern", "student", "", None, "unknown",
    ]
    sizes = ["Small (1-50)", "Medium (51-500)", "Large (500+)"]
    regions = ["North", "South", "East", "West", "Central"]
    satisfaction = ["Very satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very dissatisfied"]
    rows = []
    for i in range(1, 801):
        exp = rng.randint(0, 35)
        pay = rng.randint(28000, 210000)
        if i % 61 == 0:
            exp = "unknown"
        if i % 73 == 0:
            pay = "unknown"
        rows.append({
            "respondent_id": i,
            "years_experience": exp,
            "annual_pay": pay,
            "remote_work": rng.choice(["Yes", "No"]),
            "team_size": rng.choice(sizes),
            "engagement_type_raw": rng.choice(employment),
            "region": rng.choice(regions),
            "job_satisfaction": rng.choice(satisfaction),
        })
    write_csv(DATA / "operations_survey.csv", list(rows[0]), rows)


def make_services() -> None:
    services = [
        {"service_code": "SV-01", "service_name": "Onboarding", "hourly_rate": 42.50},
        {"service_code": "SV-02", "service_name": "Data Migration", "hourly_rate": 85.00},
        {"service_code": "SV-03", "service_name": "Integration", "hourly_rate": 96.00},
        {"service_code": "SV-04", "service_name": "Support", "hourly_rate": 55.00},
        {"service_code": "SV-05", "service_name": "Training", "hourly_rate": 62.00},
    ]
    clients = list(range(1001, 1041))
    requests = []
    for i in range(1, 181):
        requests.append({
            "request_id": i,
            "client_id": rng.choice(clients),
            "service_code": rng.choice([s["service_code"] for s in services]),
            "hours": rng.randint(1, 16),
        })
    write_csv(DATA / "service_requests.csv", list(requests[0]), requests)
    write_csv(DATA / "service_catalog.csv", list(services[0]), services)


def make_workbook() -> None:
    branch_summary = pd.DataFrame({
        "branch": ["North", "South", "East", "West"],
        "quarter": ["Q1", "Q1", "Q2", "Q2"],
        "revenue": [48250.75, 39810.20, 52630.00, 41290.50],
    })
    asset_register = pd.DataFrame({
        "asset_tag": ["LT-1001", "LT-1002", "PR-2010", "SC-3015"],
        "asset_type": ["Laptop", "Laptop", "Printer", "Scanner"],
        "assigned_team": ["Data", "Ops", "Finance", "Support"],
        "replacement_year": [2027, 2028, 2026, 2029],
    })
    service_levels = pd.DataFrame({
        "service": ["Onboarding", "Migration", "Integration", "Support"],
        "target_hours": [24, 72, 48, 8],
        "priority": ["Normal", "High", "High", "Critical"],
    })
    with pd.ExcelWriter(DATA / "branch_activity.xlsx", engine="openpyxl") as writer:
        branch_summary.to_excel(writer, sheet_name="Branch Summary", index=False)
        asset_register.to_excel(writer, sheet_name="Asset Register", index=False)
        service_levels.to_excel(writer, sheet_name="Service Levels", index=False)


def make_audit_log() -> None:
    levels = ["DEBUG", "INFO", "WARNING", "ERROR"]
    actions = ["LOGIN", "EXPORT", "UPDATE", "DELETE", "DOWNLOAD"]
    objects = ["dashboard", "report:monthly", "client:C104", "asset:LT-0047", "payment:P201"]
    lines = []
    start = datetime(2026, 11, 1, 8, 0, 0)
    for i in range(1, 151):
        stamp = (start + timedelta(minutes=i * 3)).strftime("%Y-%m-%dT%H:%M:%SZ")
        level = rng.choice(levels)
        actor = f"U{rng.randint(100, 145)}"
        action = rng.choice(actions)
        obj = rng.choice(objects)
        message = rng.choice([
            "user action completed", "permission check passed", "record updated successfully",
            "request took longer than expected", "export file generated with warnings",
        ])
        lines.append(f'{stamp} {level} actor={actor} action={action} object={obj} message="{message}"')
    # A few malformed lines must be counted/skipped by the parser.
    lines[18] = "this line is not a valid audit record"
    lines[67] = "2026-11-02 ERROR actor= action=DELETE object=client:C1 message=missing-quotes"
    lines[121] = "2026/11/03 INFO actor=U112 action=LOGIN object=dashboard message="
    (DATA / "api_audit.log").write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_etl_files() -> None:
    countries = [
        ("IN", "South Asia"), ("SG", "Southeast Asia"), ("AU", "Oceania"),
        ("GB", "Europe"), ("DE", "Europe"), ("CA", "North America"),
        ("US", "North America"), ("ZA", "Africa"),
    ]
    write_csv(DATA / "region_lookup_reference.csv", ["country_code", "region_name"], [
        {"country_code": c, "region_name": r} for c, r in countries
    ])
    names = ["Aarav Mehta", "Mia Carter", "Noah Fischer", "Sara Khan", "Ishaan Rao", "Liam Brown", "Ava Wilson", "Kabir Shah", "Emma Davis", "Arjun Nair", "Olivia Martin", "Ethan Lee", "Zoya Ali", "Lucas Smith", "Anaya Patel", "Mason Clark", "Diya Bose", "Jack Taylor", "Ira Sen", "Leo White", "Myra Das", "Ryan Hall", "Tara Kapoor", "Adam Green", "Nina Roy", "Owen Scott", "Riya Jain", "Eli Baker", "Aisha Ahmed", "Theo Moore"]
    emails = [n.lower().replace(" ", ".") + "@example.test" for n in names]
    client_rows = []
    codes = [c for c, _ in countries]
    for i, name in enumerate(names, start=1):
        client_rows.append({
            "client_id": f"C{i:04d}",
            "name": name,
            "email": emails[i-1],
            "country_code": codes[(i - 1) % len(codes)],
        })
    # Deliberately incomplete export row: no client identifier.
    client_rows[11]["client_id"] = ""
    write_csv(DATA / "raw_clients.csv", ["client_id", "name", "email", "country_code"], client_rows)

    jobs = []
    for i in range(1, 71):
        jobs.append({
            "job_id": i,
            "client_id": f"C{rng.choice([client_no for client_no in range(1, 31) if client_no != 12]):04d}",
            "job_date": (datetime(2026, 1, 1) + timedelta(days=rng.randint(0, 300))).date().isoformat(),
            "amount": round(rng.uniform(45, 3500), 2),
        })
    jobs[36]["amount"] = "N/A"
    (DATA / "raw_jobs.json").write_text(json.dumps(jobs, indent=2), encoding="utf-8")


def main() -> None:
    make_api_events()
    make_survey()
    make_services()
    make_workbook()
    make_audit_log()
    make_etl_files()
    print(f"Generated retest fixtures in {DATA}")


if __name__ == "__main__":
    main()
