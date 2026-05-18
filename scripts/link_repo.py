#!/usr/bin/env python3
"""Manual linkage CLI for GitHub repos.

    list                              show repos and which project (if any) they map to
    unlinked                          repos with no project link yet
    link <repo_full_name> <project_id>     attach (marks as 'manual')
    unlink <repo_full_name>           remove all links for a repo
    set-status <repo_full_name> <Started|Finished|Never Started>
                                      override the heuristic status for a repo
    set-project-status <project_id> <status_name>
                                      override a project's status (e.g. after review)
"""
from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"

VALID_REPO_STATUSES = {"Started", "Finished", "Never Started", "Unknown"}


def connect(db: Path) -> sqlite3.Connection:
    con = sqlite3.connect(db)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    return con


def cmd_list(con):
    rows = con.execute("""
        SELECT r.full_name, r.activity_status, r.pushed_at,
               (SELECT p.title FROM projects p JOIN project_github_repos pgr USING(project_id)
                 WHERE pgr.repo_id=r.repo_id AND pgr.is_primary=1) AS project_title,
               (SELECT pgr.match_method FROM project_github_repos pgr
                 WHERE pgr.repo_id=r.repo_id AND pgr.is_primary=1) AS method
        FROM github_repos r ORDER BY r.full_name
    """).fetchall()
    for r in rows:
        proj = f"-> {r['project_title']} ({r['method']})" if r["project_title"] else "(unlinked)"
        print(f"  {r['full_name']:<55} [{r['activity_status'] or '?'}] {proj}")


def cmd_unlinked(con):
    rows = con.execute("""
        SELECT r.full_name, r.activity_status
        FROM github_repos r
        LEFT JOIN project_github_repos pgr ON pgr.repo_id = r.repo_id
        WHERE pgr.project_id IS NULL
        ORDER BY r.full_name
    """).fetchall()
    for r in rows:
        print(f"  {r['full_name']:<55} [{r['activity_status'] or '?'}]")
    print(f"\n{len(rows)} unlinked")


def cmd_link(con, repo_full_name, project_id):
    repo = con.execute("SELECT repo_id FROM github_repos WHERE full_name=?", (repo_full_name,)).fetchone()
    if not repo:
        sys.exit(f"no such repo: {repo_full_name}")
    proj = con.execute("SELECT title FROM projects WHERE project_id=?", (project_id,)).fetchone()
    if not proj:
        sys.exit(f"no such project: {project_id}")
    con.execute(
        "INSERT OR REPLACE INTO project_github_repos(project_id, repo_id, is_primary, match_method, confidence)"
        " VALUES (?,?,1,'manual',1.0)",
        (project_id, repo["repo_id"]),
    )
    con.commit()
    print(f"linked {repo_full_name} -> project #{project_id} ({proj['title']})")


def cmd_unlink(con, repo_full_name):
    cur = con.execute(
        "DELETE FROM project_github_repos WHERE repo_id=(SELECT repo_id FROM github_repos WHERE full_name=?)",
        (repo_full_name,),
    )
    con.commit()
    print(f"removed {cur.rowcount} link(s) for {repo_full_name}")


def cmd_set_status(con, repo_full_name, status):
    if status not in VALID_REPO_STATUSES:
        sys.exit(f"status must be one of {sorted(VALID_REPO_STATUSES)}")
    cur = con.execute(
        "UPDATE github_repos SET activity_status=?, activity_reason='manual override' WHERE full_name=?",
        (status, repo_full_name),
    )
    if cur.rowcount == 0:
        sys.exit(f"no such repo: {repo_full_name}")
    con.commit()
    print(f"{repo_full_name} -> {status}")


def cmd_set_project_status(con, project_id, status_name):
    row = con.execute("SELECT status_id FROM statuses WHERE name=?", (status_name,)).fetchone()
    if not row:
        sys.exit(f"no such status: {status_name}")
    cur = con.execute("UPDATE projects SET status_id=? WHERE project_id=?", (row["status_id"], project_id))
    if cur.rowcount == 0:
        sys.exit(f"no such project: {project_id}")
    con.commit()
    print(f"project #{project_id} status -> {status_name}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("unlinked")
    sl = sub.add_parser("link");          sl.add_argument("repo"); sl.add_argument("project_id", type=int)
    su = sub.add_parser("unlink");        su.add_argument("repo")
    ss = sub.add_parser("set-status");    ss.add_argument("repo"); ss.add_argument("status")
    sp = sub.add_parser("set-project-status"); sp.add_argument("project_id", type=int); sp.add_argument("status")
    args = parser.parse_args()

    con = connect(Path(args.db))
    try:
        if args.cmd == "list":               cmd_list(con)
        elif args.cmd == "unlinked":         cmd_unlinked(con)
        elif args.cmd == "link":             cmd_link(con, args.repo, args.project_id)
        elif args.cmd == "unlink":           cmd_unlink(con, args.repo)
        elif args.cmd == "set-status":       cmd_set_status(con, args.repo, args.status)
        elif args.cmd == "set-project-status": cmd_set_project_status(con, args.project_id, args.status)
    finally:
        con.close()


if __name__ == "__main__":
    main()
