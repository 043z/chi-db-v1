#!/usr/bin/env python3
"""Build the Balanced Blended Space SQLite database.

Drops any existing balanced_blended_space.db, then applies schema.sql followed
by seed.sql. Prints row counts at the end as a sanity check.

Usage:
    python scripts/build_db.py
    python scripts/build_db.py --db custom.db --no-seed
"""
from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"
SCHEMA = ROOT / "sql" / "schema.sql"
SEED = ROOT / "sql" / "seed.sql"
PIPELINE_SCHEMA = ROOT / "sql" / "pipeline_schema.sql"
GITHUB_SCHEMA = ROOT / "sql" / "github_schema.sql"
GITHUB_SEED   = ROOT / "sql" / "github_seed.sql"
CHIIDS_SCHEMA = ROOT / "sql" / "chiids_schema.sql"
CHIIDS_SEED   = ROOT / "sql" / "chiids_seed.sql"
CHIIDS_IMPORT_SCHEMA = ROOT / "sql" / "chiids_import_schema.sql"
CHIIDS_IMPORT_SEED   = ROOT / "sql" / "chiids_import_seed.sql"
ACTIVITY_BUCKET      = ROOT / "sql" / "activity_bucket.sql"
WHERE_TO_FIND        = ROOT / "sql" / "where_to_find_links.sql"


def build(db_path: Path, seed: bool = True) -> None:
    if db_path.exists():
        db_path.unlink()
        print(f"removed existing {db_path}")

    con = sqlite3.connect(db_path)
    con.executescript(SCHEMA.read_text())
    print(f"applied {SCHEMA.name}")

    if seed:
        con.executescript(SEED.read_text())
        print(f"applied {SEED.name}")

    # Always apply the pipeline + github add-ons (idempotent)
    if PIPELINE_SCHEMA.exists():
        con.executescript(PIPELINE_SCHEMA.read_text())
        print(f"applied {PIPELINE_SCHEMA.name}")
        # Add columns introduced later if this is an upgrade of an older DB.
        for col, ddl in (
            ("source",      "ALTER TABLE pending_submissions ADD COLUMN source TEXT NOT NULL DEFAULT 'form'"),
            ("source_repo", "ALTER TABLE pending_submissions ADD COLUMN source_repo TEXT"),
        ):
            try:
                con.execute(ddl)
            except sqlite3.OperationalError as e:
                if "duplicate column" not in str(e).lower():
                    raise
    if GITHUB_SCHEMA.exists():
        con.executescript(GITHUB_SCHEMA.read_text())
        print(f"applied {GITHUB_SCHEMA.name}")
    if seed and GITHUB_SEED.exists():
        con.executescript(GITHUB_SEED.read_text())
        print(f"applied {GITHUB_SEED.name}")
    if CHIIDS_SCHEMA.exists():
        con.executescript(CHIIDS_SCHEMA.read_text())
        print(f"applied {CHIIDS_SCHEMA.name}")
        # Add CHIIDS-derived columns to projects if missing (idempotent).
        for ddl in (
            "ALTER TABLE projects ADD COLUMN lifecycle_stage_id INTEGER REFERENCES lifecycle_stages(stage_id)",
            "ALTER TABLE projects ADD COLUMN meta_project_type_id INTEGER REFERENCES meta_project_types(type_id)",
        ):
            try:
                con.execute(ddl)
            except sqlite3.OperationalError as e:
                if "duplicate column" not in str(e).lower():
                    raise
    if seed and CHIIDS_SEED.exists():
        con.executescript(CHIIDS_SEED.read_text())
        print(f"applied {CHIIDS_SEED.name}")
    if CHIIDS_IMPORT_SCHEMA.exists():
        con.executescript(CHIIDS_IMPORT_SCHEMA.read_text())
        print(f"applied {CHIIDS_IMPORT_SCHEMA.name}")
    if seed and CHIIDS_IMPORT_SEED.exists():
        con.executescript(CHIIDS_IMPORT_SEED.read_text())
        print(f"applied {CHIIDS_IMPORT_SEED.name}")

    # Ensure the projects.activity_bucket column exists (idempotent).
    try:
        con.execute("ALTER TABLE projects ADD COLUMN activity_bucket TEXT")
    except sqlite3.OperationalError as e:
        if "duplicate column" not in str(e).lower():
            raise

    if seed and ACTIVITY_BUCKET.exists():
        con.executescript(ACTIVITY_BUCKET.read_text())
        print(f"applied {ACTIVITY_BUCKET.name}")
    if seed and WHERE_TO_FIND.exists():
        con.executescript(WHERE_TO_FIND.read_text())
        print(f"applied {WHERE_TO_FIND.name}")

    counts = {}
    tables = [
        "departments", "categories", "tags", "researchers", "projects",
        "project_departments", "project_categories", "project_tags",
        "project_researchers", "project_links",
        "github_repos", "project_github_repos",
        "chiids_cornerstones", "chiids_layers", "chiids_concepts",
        "chiids_external_systems", "chiids_artifact_tags",
        "project_external_systems",
        "lifecycle_stages", "meta_project_types",
        "chiids_meta_projects", "chiids_teams", "chiids_roles", "chiids_people",
        "chiids_team_members", "chiids_policies",
        "chiids_tasks", "chiids_milestones", "chiids_resources",
        "chiids_research_opportunities", "chiids_applications",
        "chiids_documents", "chiids_media", "chiids_living_archive",
        "chiids_vcs_repos", "chiids_archives", "chiids_metrics",
        "chiids_communications", "chiids_public_engagement",
        "chiids_storage_locations", "chiids_backups",
        "project_chiids_aliases",
    ]
    for table in tables:
        try:
            row = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()
            counts[table] = row[0]
        except sqlite3.OperationalError:
            pass
    con.close()

    print("\nrow counts")
    for t, n in counts.items():
        print(f"  {t:<22} {n}")
    print(f"\nDB ready: {db_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB), help="output database path")
    parser.add_argument("--no-seed", action="store_true", help="schema only, skip seed")
    args = parser.parse_args()
    build(Path(args.db), seed=not args.no_seed)


if __name__ == "__main__":
    main()
