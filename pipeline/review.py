#!/usr/bin/env python3
"""Reviewer CLI for pending project submissions.

Sub-commands
------------
    list                            Show pending submissions (id + title + errors).
    show <submission_id>            Full detail for one submission.
    approve <submission_id>         Promote into projects + join tables.
    reject  <submission_id> [-r ..] Mark as rejected.
    duplicate <submission_id>       Mark as duplicate (no project created).

Examples
--------
    python3 pipeline/review.py list
    python3 pipeline/review.py show 7
    python3 pipeline/review.py approve 7 --reviewer alice
    python3 pipeline/review.py reject 8 --reviewer alice -r "Out of scope"
"""
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"


def connect(db: Path) -> sqlite3.Connection:
    con = sqlite3.connect(db)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    return con


def slugify(title: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    return s[:80] or "project"


def split_multi(value: str | None) -> list[str]:
    if not value:
        return []
    return [p.strip() for p in re.split(r"[;,]", value) if p.strip()]


def get_or_create_tag(con: sqlite3.Connection, name: str) -> int:
    row = con.execute("SELECT tag_id FROM tags WHERE name = ? COLLATE NOCASE", (name,)).fetchone()
    if row:
        return row[0]
    cur = con.execute("INSERT INTO tags(name) VALUES (?)", (name,))
    return cur.lastrowid


def get_or_create_researcher(con: sqlite3.Connection, full_name: str, email: str | None) -> int:
    row = con.execute("SELECT researcher_id FROM researchers WHERE full_name = ?", (full_name,)).fetchone()
    if row:
        if email:
            con.execute("UPDATE researchers SET email = COALESCE(email, ?) WHERE researcher_id = ?",
                        (email, row[0]))
        return row[0]
    cur = con.execute(
        "INSERT INTO researchers(full_name, email, affiliation) VALUES (?, ?, ?)",
        (full_name, email, "Submitted via form"),
    )
    return cur.lastrowid


def cmd_list(con: sqlite3.Connection, source: str | None = None) -> None:
    sql = """
        SELECT submission_id, submitted_at, submitter_name, title,
               validation_errors, departments_raw, source, source_repo
        FROM pending_submissions
        WHERE review_status = 'pending'
    """
    args: list = []
    if source:
        sql += " AND source = ?"
        args.append(source)
    sql += " ORDER BY submitted_at"
    rows = con.execute(sql, args).fetchall()
    if not rows:
        print("(no pending submissions)")
        return
    for r in rows:
        errs = ""
        if r["validation_errors"]:
            errs = f"  [!] {len(json.loads(r['validation_errors']))} validation issue(s)"
        src_tag = ""
        if r["source"] and r["source"] != "form":
            src_tag = f" <{r['source']}>"
            if r["source_repo"]:
                src_tag = f" <{r['source']}: {r['source_repo']}>"
        print(f"  #{r['submission_id']:<4} {r['submitted_at']}  {r['submitter_name'] or '-':<25} {r['title']}{src_tag}{errs}")
        if r["departments_raw"]:
            print(f"        departments: {r['departments_raw']}")
    print(f"\n{len(rows)} pending")


def cmd_show(con: sqlite3.Connection, sid: int) -> None:
    r = con.execute("SELECT * FROM pending_submissions WHERE submission_id=?", (sid,)).fetchone()
    if not r:
        sys.exit(f"no submission #{sid}")
    for k in r.keys():
        v = r[k]
        if k == "validation_errors" and v:
            v = "\n      - " + "\n      - ".join(json.loads(v))
        print(f"  {k:<20} {v}")


def cmd_approve(con: sqlite3.Connection, sid: int, reviewer: str | None, notes: str | None) -> None:
    r = con.execute("SELECT * FROM pending_submissions WHERE submission_id=?", (sid,)).fetchone()
    if not r:
        sys.exit(f"no submission #{sid}")
    if r["review_status"] != "pending":
        sys.exit(f"submission #{sid} already {r['review_status']!r}")

    title = r["title"]
    # Ensure slug uniqueness
    base = slugify(title)
    slug, n = base, 1
    while con.execute("SELECT 1 FROM projects WHERE slug=?", (slug,)).fetchone():
        n += 1
        slug = f"{base}-{n}"

    # status / level lookups
    status_id = con.execute("SELECT status_id FROM statuses WHERE name='Proposed'").fetchone()[0]
    level_id = None
    if r["level"]:
        row = con.execute("SELECT level_id FROM levels WHERE name=? COLLATE NOCASE", (r["level"],)).fetchone()
        if row:
            level_id = row[0]

    parent_id = None
    if r["parent_project_slug"]:
        row = con.execute("SELECT project_id FROM projects WHERE slug=?", (r["parent_project_slug"],)).fetchone()
        if row:
            parent_id = row[0]

    # Insert project
    cur = con.execute("""
        INSERT INTO projects (title, slug, summary, description, status_id, level_id,
                              parent_project_id, semester, primary_url)
        VALUES (?,?,?,?,?,?,?,?,?)
    """, (
        title, slug, r["summary"], r["description"], status_id, level_id,
        parent_id, r["semester"], r["primary_url"],
    ))
    project_id = cur.lastrowid

    # Departments
    for code in split_multi(r["departments_raw"]):
        row = con.execute(
            "SELECT department_id FROM departments WHERE code=? COLLATE NOCASE OR name=? COLLATE NOCASE",
            (code, code),
        ).fetchone()
        if row:
            con.execute(
                "INSERT OR IGNORE INTO project_departments(project_id, department_id, is_primary) VALUES (?,?,?)",
                (project_id, row[0], 1 if split_multi(r["departments_raw"])[0].lower() == code.lower() else 0),
            )

    # Categories
    for cname in split_multi(r["categories_raw"]):
        row = con.execute("SELECT category_id FROM categories WHERE name=? COLLATE NOCASE", (cname,)).fetchone()
        if row:
            con.execute(
                "INSERT OR IGNORE INTO project_categories(project_id, category_id) VALUES (?,?)",
                (project_id, row[0]),
            )

    # Tags (auto-create)
    for t in split_multi(r["tags_raw"]):
        tid = get_or_create_tag(con, t)
        con.execute("INSERT OR IGNORE INTO project_tags(project_id, tag_id) VALUES (?,?)", (project_id, tid))

    # Researcher
    if r["submitter_name"]:
        rid = get_or_create_researcher(con, r["submitter_name"], r["submitter_email"])
        con.execute(
            "INSERT OR IGNORE INTO project_researchers(project_id, researcher_id, role) VALUES (?,?,?)",
            (project_id, rid, "Submitter"),
        )

    # Extra links
    other_link_type = con.execute("SELECT link_type_id FROM link_types WHERE name='Other'").fetchone()
    other_link_type_id = other_link_type[0] if other_link_type else None
    for line in (r["extra_links_raw"] or "").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "|" not in line:
            continue
        label, url = [s.strip() for s in line.split("|", 1)]
        con.execute(
            "INSERT INTO project_links(project_id, link_type_id, label, url, is_canonical) VALUES (?,?,?,?,?)",
            (project_id, other_link_type_id, label, url, 0),
        )

    # Mark submission approved
    con.execute("""
        UPDATE pending_submissions
        SET review_status='approved', reviewed_by=?, reviewed_at=datetime('now'),
            review_notes=?, approved_project_id=?
        WHERE submission_id=?
    """, (reviewer, notes, project_id, sid))
    con.execute(
        "INSERT INTO review_log(submission_id, action, reviewer, notes) VALUES (?,?,?,?)",
        (sid, "approve", reviewer, notes),
    )
    con.commit()
    print(f"approved #{sid} -> project_id={project_id} ({title})")


def cmd_reject(con: sqlite3.Connection, sid: int, reviewer: str | None, reason: str | None,
               action: str = "reject") -> None:
    new_status = "duplicate" if action == "mark_duplicate" else "rejected"
    if not con.execute("SELECT 1 FROM pending_submissions WHERE submission_id=?", (sid,)).fetchone():
        sys.exit(f"no submission #{sid}")
    con.execute("""
        UPDATE pending_submissions
        SET review_status=?, reviewed_by=?, reviewed_at=datetime('now'), review_notes=?
        WHERE submission_id=?
    """, (new_status, reviewer, reason, sid))
    con.execute(
        "INSERT INTO review_log(submission_id, action, reviewer, notes) VALUES (?,?,?,?)",
        (sid, action, reviewer, reason),
    )
    con.commit()
    print(f"{action}d #{sid}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    sub = parser.add_subparsers(dest="cmd", required=True)
    s_list = sub.add_parser("list")
    s_list.add_argument("--source", choices=["form", "github-scan", "manual"], help="filter by source")
    s_show = sub.add_parser("show");        s_show.add_argument("sid", type=int)
    s_app  = sub.add_parser("approve");     s_app.add_argument("sid", type=int); s_app.add_argument("--reviewer"); s_app.add_argument("--notes")
    s_rej  = sub.add_parser("reject");      s_rej.add_argument("sid", type=int); s_rej.add_argument("--reviewer"); s_rej.add_argument("-r","--reason")
    s_dup  = sub.add_parser("duplicate");   s_dup.add_argument("sid", type=int); s_dup.add_argument("--reviewer"); s_dup.add_argument("-r","--reason")
    args = parser.parse_args()

    con = connect(Path(args.db))
    try:
        if args.cmd == "list":      cmd_list(con, getattr(args, "source", None))
        elif args.cmd == "show":    cmd_show(con, args.sid)
        elif args.cmd == "approve": cmd_approve(con, args.sid, args.reviewer, args.notes)
        elif args.cmd == "reject":  cmd_reject(con, args.sid, args.reviewer, args.reason, "reject")
        elif args.cmd == "duplicate": cmd_reject(con, args.sid, args.reviewer, args.reason, "mark_duplicate")
    finally:
        con.close()


if __name__ == "__main__":
    main()
