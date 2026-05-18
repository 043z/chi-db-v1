#!/usr/bin/env python3
"""Pull submissions from the published Google Sheet CSV and stage them.

Reads the Sheet CSV at $BBS_SHEET_CSV_URL (or --url), validates each row, and
inserts new rows into `pending_submissions`. Idempotent on a stable row hash
built from timestamp+email+title, so running this on a cron is safe.

Usage:
    BBS_SHEET_CSV_URL='https://docs.google.com/.../pub?output=csv' \
        python3 pipeline/ingest.py
    python3 pipeline/ingest.py --url https://... --db bbs.db
    python3 pipeline/ingest.py --file sample_submissions.csv   # offline test
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import re
import sqlite3
import sys
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"
PIPELINE_SCHEMA = ROOT / "sql" / "pipeline_schema.sql"

# ---- Field names -- must match the Form titles in FORM_SETUP.md ----------
F_TIMESTAMP   = "Timestamp"
F_SUBMITTER   = "Submitter name"
F_EMAIL       = "Submitter email"
F_TITLE       = "Project title"
F_SUMMARY     = "One-line summary"
F_DESCRIPTION = "Full description"
F_DEPARTMENTS = "Departments"
F_CATEGORIES  = "Categories"
F_TAGS        = "Tags"
F_LEVEL       = "Skill level"
F_SEMESTER    = "Semester"
F_PARENT      = "Parent project slug"
F_URL         = "Primary URL"
F_LINKS       = "Extra links"

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
URL_RE   = re.compile(r"^https?://", re.IGNORECASE)


def ensure_pipeline_schema(con: sqlite3.Connection) -> None:
    con.executescript(PIPELINE_SCHEMA.read_text())


def row_hash(timestamp: str, email: str, title: str) -> str:
    h = hashlib.sha256()
    h.update("|".join([timestamp.strip(), email.strip().lower(), title.strip().lower()]).encode("utf-8"))
    return h.hexdigest()


def split_multi(value: str) -> list[str]:
    if not value:
        return []
    parts = re.split(r"[;,]", value)
    return [p.strip() for p in parts if p.strip()]


def validate_row(con: sqlite3.Connection, row: dict) -> list[str]:
    errors: list[str] = []
    title = (row.get(F_TITLE) or "").strip()
    if not title:
        errors.append("missing Project title")
    elif len(title) > 200:
        errors.append("title longer than 200 chars")

    email = (row.get(F_EMAIL) or "").strip()
    if not email:
        errors.append("missing Submitter email")
    elif not EMAIL_RE.match(email):
        errors.append(f"invalid email format: {email!r}")

    # Departments
    depts = split_multi(row.get(F_DEPARTMENTS, ""))
    if not depts:
        errors.append("at least one department required")
    else:
        known = {r[0].upper() for r in con.execute("SELECT code FROM departments")} | \
                {r[0].lower() for r in con.execute("SELECT name FROM departments")}
        for d in depts:
            if d.upper() not in known and d.lower() not in known:
                errors.append(f"unknown department: {d!r}")

    # Categories
    cats = split_multi(row.get(F_CATEGORIES, ""))
    if cats:
        known_cats = {r[0].lower() for r in con.execute("SELECT name FROM categories")}
        for c in cats:
            if c.lower() not in known_cats:
                errors.append(f"unknown category: {c!r}")

    # Level
    level = (row.get(F_LEVEL) or "").strip()
    if level:
        known_levels = {r[0].lower() for r in con.execute("SELECT name FROM levels")}
        if level.lower() not in known_levels:
            errors.append(f"unknown level: {level!r}")

    # Parent slug
    parent = (row.get(F_PARENT) or "").strip()
    if parent:
        if not con.execute("SELECT 1 FROM projects WHERE slug=?", (parent,)).fetchone():
            errors.append(f"parent_project_slug not found: {parent!r}")

    # URLs
    if (url := (row.get(F_URL) or "").strip()) and not URL_RE.match(url):
        errors.append(f"primary URL doesn't look like http(s): {url!r}")
    for line in (row.get(F_LINKS) or "").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "|" not in line:
            errors.append(f"extra link missing '|' separator: {line!r}")
            continue
        _, link_url = line.split("|", 1)
        if not URL_RE.match(link_url.strip()):
            errors.append(f"extra link URL invalid: {link_url!r}")

    return errors


def load_csv(url_or_path: str, *, is_file: bool) -> list[dict]:
    if is_file:
        text = Path(url_or_path).read_text()
    else:
        with urllib.request.urlopen(url_or_path, timeout=30) as resp:
            text = resp.read().decode("utf-8")
    reader = csv.DictReader(io.StringIO(text))
    return list(reader)


def ingest(con: sqlite3.Connection, rows: list[dict], source: str) -> dict:
    ensure_pipeline_schema(con)

    cur = con.execute(
        "INSERT INTO ingestion_runs (source_url) VALUES (?)", (source,)
    )
    run_id = cur.lastrowid
    seen = new = invalid = 0

    for r in rows:
        seen += 1
        timestamp = (r.get(F_TIMESTAMP) or "").strip()
        email     = (r.get(F_EMAIL) or "").strip()
        title     = (r.get(F_TITLE) or "").strip()
        if not (timestamp and title):
            continue
        h = row_hash(timestamp, email, title)
        # Skip if already staged
        if con.execute("SELECT 1 FROM pending_submissions WHERE source_row_hash=?", (h,)).fetchone():
            continue
        errors = validate_row(con, r)
        if errors:
            invalid += 1

        con.execute("""
            INSERT INTO pending_submissions (
                source_row_hash, source, submitted_at, submitter_name, submitter_email,
                title, summary, description,
                departments_raw, categories_raw, tags_raw,
                level, semester, parent_project_slug,
                primary_url, extra_links_raw, validation_errors
            ) VALUES (?,'form',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            h, timestamp,
            (r.get(F_SUBMITTER) or "").strip() or None,
            email or None,
            title,
            (r.get(F_SUMMARY) or "").strip() or None,
            (r.get(F_DESCRIPTION) or "").strip() or None,
            (r.get(F_DEPARTMENTS) or "").strip() or None,
            (r.get(F_CATEGORIES) or "").strip() or None,
            (r.get(F_TAGS) or "").strip() or None,
            (r.get(F_LEVEL) or "").strip() or None,
            (r.get(F_SEMESTER) or "").strip() or None,
            (r.get(F_PARENT) or "").strip() or None,
            (r.get(F_URL) or "").strip() or None,
            (r.get(F_LINKS) or "").strip() or None,
            json.dumps(errors) if errors else None,
        ))
        new += 1

    con.execute(
        "UPDATE ingestion_runs SET finished_at=datetime('now'), rows_seen=?, rows_new=?, rows_invalid=? WHERE run_id=?",
        (seen, new, invalid, run_id),
    )
    con.commit()
    return {"run_id": run_id, "seen": seen, "new": new, "invalid": invalid}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    src = parser.add_mutually_exclusive_group()
    src.add_argument("--url", help="published-CSV URL of the Google Sheet")
    src.add_argument("--file", help="local CSV file (for testing)")
    args = parser.parse_args()

    source = args.url or os.environ.get("BBS_SHEET_CSV_URL")
    is_file = bool(args.file)
    if not (source or is_file):
        print("ERROR: set $BBS_SHEET_CSV_URL or pass --url/--file", file=sys.stderr)
        sys.exit(2)

    rows = load_csv(args.file or source, is_file=is_file)
    con = sqlite3.connect(args.db)
    try:
        result = ingest(con, rows, source or args.file)
    finally:
        con.close()
    print(f"[ingest] run #{result['run_id']}: seen={result['seen']} new={result['new']} invalid={result['invalid']}")


if __name__ == "__main__":
    main()
