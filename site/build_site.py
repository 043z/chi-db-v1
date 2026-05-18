#!/usr/bin/env python3
"""Build a static site that serves the SQLite DB via sql.js in the browser.

Writes everything under ./site/dist:
    dist/index.html            <- browse-anywhere page
    dist/balanced_blended_space.db   <- copy of the live DB
    dist/projects.csv          <- flat CSV export of v_project_overview

The hosted page uses sql.js (CDN) to query the DB client-side, so there's no
backend at all -- GitHub Pages serves the files and the browser does the rest.
"""
from __future__ import annotations

import csv
import shutil
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "balanced_blended_space.db"
DIST = ROOT / "site" / "dist"
TEMPLATE = ROOT / "site" / "index.html"


def export_csv(out_path: Path) -> int:
    con = sqlite3.connect(DB); con.row_factory = sqlite3.Row
    rows = con.execute("SELECT * FROM v_project_overview ORDER BY title").fetchall()
    con.close()
    if not rows:
        out_path.write_text("")
        return 0
    with out_path.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        for r in rows:
            w.writerow(dict(r))
    return len(rows)


def main() -> None:
    DIST.mkdir(parents=True, exist_ok=True)
    shutil.copy(DB, DIST / DB.name)
    shutil.copy(TEMPLATE, DIST / "index.html")
    n = export_csv(DIST / "projects.csv")
    print(f"built site at {DIST.relative_to(ROOT)}  ({n} projects exported to CSV)")


if __name__ == "__main__":
    main()
