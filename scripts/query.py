#!/usr/bin/env python3
"""Convenience queries against the BBS database.

Examples
--------
    python scripts/query.py departments
    python scripts/query.py projects --department COMD
    python scripts/query.py projects --tag AI
    python scripts/query.py crossdept
    python scripts/query.py search --term "puppet"
    python scripts/query.py show 42         # full overview for project_id=42
"""
from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"


def connect(db: Path) -> sqlite3.Connection:
    con = sqlite3.connect(db)
    con.row_factory = sqlite3.Row
    return con


def cmd_departments(con: sqlite3.Connection) -> None:
    rows = con.execute("""
        SELECT d.code, d.name, COUNT(pd.project_id) AS n
        FROM departments d
        LEFT JOIN project_departments pd ON pd.department_id = d.department_id
        GROUP BY d.department_id
        ORDER BY n DESC, d.name
    """).fetchall()
    for r in rows:
        print(f"  {r['code']:<5} {r['name']:<40} {r['n']:>4}")


def cmd_projects(con: sqlite3.Connection, department: str | None, tag: str | None,
                 semester: str | None, status: str | None) -> None:
    sql = """
        SELECT DISTINCT p.project_id, p.title, p.semester,
               (SELECT name FROM statuses WHERE status_id=p.status_id) AS status
        FROM projects p
        LEFT JOIN project_departments pd ON pd.project_id=p.project_id
        LEFT JOIN departments d          ON d.department_id=pd.department_id
        LEFT JOIN project_tags pt        ON pt.project_id=p.project_id
        LEFT JOIN tags t                 ON t.tag_id=pt.tag_id
        WHERE 1=1
    """
    args: list = []
    if department:
        sql += " AND d.code = ?"
        args.append(department.upper())
    if tag:
        sql += " AND t.name = ? COLLATE NOCASE"
        args.append(tag)
    if semester:
        sql += " AND p.semester = ?"
        args.append(semester)
    if status:
        sql += " AND (SELECT name FROM statuses WHERE status_id=p.status_id) = ?"
        args.append(status)
    sql += " ORDER BY p.title"
    rows = con.execute(sql, args).fetchall()
    if not rows:
        print("(no projects match)")
        return
    for r in rows:
        sem = f"  [{r['semester']}]" if r["semester"] else ""
        st = f"  ({r['status']})" if r["status"] else ""
        print(f"  #{r['project_id']:<4} {r['title']}{sem}{st}")
    print(f"\n{len(rows)} project(s)")


def cmd_crossdept(con: sqlite3.Connection) -> None:
    rows = con.execute("SELECT * FROM v_cross_department_projects ORDER BY department_count DESC, title").fetchall()
    for r in rows:
        print(f"  #{r['project_id']:<4} ({r['department_count']} depts) {r['title']}")
        print(f"        {r['departments']}")


def cmd_search(con: sqlite3.Connection, term: str) -> None:
    rows = con.execute(
        "SELECT project_id, title FROM projects WHERE title LIKE ? OR description LIKE ? ORDER BY title",
        (f"%{term}%", f"%{term}%"),
    ).fetchall()
    for r in rows:
        print(f"  #{r['project_id']:<4} {r['title']}")
    print(f"\n{len(rows)} match(es)")


def cmd_show(con: sqlite3.Connection, project_id: int) -> None:
    p = con.execute("SELECT * FROM v_project_overview WHERE project_id=?", (project_id,)).fetchone()
    if not p:
        print(f"no project with id={project_id}")
        return
    print(f"[{p['project_id']}] {p['title']}")
    if p["summary"]:    print(f"  summary    : {p['summary']}")
    if p["semester"]:   print(f"  semester   : {p['semester']}")
    if p["status"]:     print(f"  status     : {p['status']}")
    if p["level"]:      print(f"  level      : {p['level']}")
    if p["departments"]:print(f"  departments: {p['departments']}")
    if p["categories"]: print(f"  categories : {p['categories']}")
    if p["tags"]:       print(f"  tags       : {p['tags']}")
    if p["primary_url"]:print(f"  url        : {p['primary_url']}")
    links = con.execute("""
        SELECT lt.name AS type, pl.label, pl.url
        FROM project_links pl
        LEFT JOIN link_types lt ON lt.link_type_id=pl.link_type_id
        WHERE pl.project_id=?
        ORDER BY pl.is_canonical DESC""", (project_id,)).fetchall()
    if links:
        print("  links:")
        for ln in links:
            print(f"    - [{ln['type']}] {ln['label'] or ln['url']}  -> {ln['url']}")
    researchers = con.execute("""
        SELECT r.full_name, pr.role
        FROM project_researchers pr
        JOIN researchers r ON r.researcher_id=pr.researcher_id
        WHERE pr.project_id=?""", (project_id,)).fetchall()
    if researchers:
        print("  researchers:")
        for r in researchers:
            print(f"    - {r['full_name']} ({r['role']})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("departments")
    p_projects = sub.add_parser("projects")
    p_projects.add_argument("--department")
    p_projects.add_argument("--tag")
    p_projects.add_argument("--semester")
    p_projects.add_argument("--status")
    sub.add_parser("crossdept")
    p_search = sub.add_parser("search")
    p_search.add_argument("--term", required=True)
    p_show = sub.add_parser("show")
    p_show.add_argument("project_id", type=int)

    args = parser.parse_args()
    con = connect(Path(args.db))
    try:
        if args.cmd == "departments":
            cmd_departments(con)
        elif args.cmd == "projects":
            cmd_projects(con, args.department, args.tag, args.semester, args.status)
        elif args.cmd == "crossdept":
            cmd_crossdept(con)
        elif args.cmd == "search":
            cmd_search(con, args.term)
        elif args.cmd == "show":
            cmd_show(con, args.project_id)
    finally:
        con.close()


if __name__ == "__main__":
    main()
