#!/usr/bin/env python3
"""Export the BBS database to CSV and JSON.

Writes one CSV per table into ./export/csv/ and one combined JSON document
(./export/bbs.json) keyed by table name.

Usage:
    python scripts/export.py
"""
from __future__ import annotations

import argparse
import csv
import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"
DEFAULT_OUT = ROOT / "export"

TABLES = [
    "departments", "categories", "tags", "levels", "statuses", "link_types",
    "researchers", "projects",
    "project_departments", "project_categories", "project_tags",
    "project_researchers", "project_links", "project_attachments", "project_notes",
]


def export(db_path: Path, out_dir: Path) -> None:
    csv_dir = out_dir / "csv"
    csv_dir.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row

    combined: dict[str, list[dict]] = {}
    for table in TABLES:
        rows = [dict(r) for r in con.execute(f"SELECT * FROM {table}").fetchall()]
        combined[table] = rows
        csv_path = csv_dir / f"{table}.csv"
        if not rows:
            csv_path.write_text("")
            continue
        with csv_path.open("w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print(f"wrote {csv_path.relative_to(ROOT)}  ({len(rows)} rows)")

    json_path = out_dir / "bbs.json"
    json_path.write_text(json.dumps(combined, indent=2, default=str))
    print(f"wrote {json_path.relative_to(ROOT)}")
    con.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    parser.add_argument("--out", default=str(DEFAULT_OUT))
    args = parser.parse_args()
    export(Path(args.db), Path(args.out))


if __name__ == "__main__":
    main()
