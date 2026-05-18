#!/usr/bin/env python3
"""Sync repos from a GitHub organization into the BBS database.

What it does:
1.  Lists every repo under $BBS_GITHUB_ORG (default 'CHI-CityTech') via the
    public GitHub REST API.
2.  Upserts each repo into the `github_repos` table.
3.  Classifies each repo as 'Started' / 'Finished' / 'Never Started' using a
    heuristic based on archive flag, release count, push date, commit count,
    and size. The reasoning is stored in `activity_reason`.
4.  Auto-links each repo to the most similar existing project (by title/slug)
    via `project_github_repos`. Manual overrides are preserved.
5.  Updates each linked project's `status_id` to the matching status row
    ('Started'/'Finished'/'Never Started') -- unless the project already had a
    non-Proposed status assigned by a reviewer.

Auth:
    Optional. Set $GITHUB_TOKEN to raise the rate limit from 60 to 5000/hr.
    No token is required for public repos in low volume.

Usage:
    python3 scripts/sync_github.py
    python3 scripts/sync_github.py --org CHI-CityTech --db balanced_blended_space.db
"""
from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"
GITHUB_SCHEMA = ROOT / "sql" / "github_schema.sql"

GITHUB_API = "https://api.github.com"
USER_AGENT = "bbs-pipeline-sync (CHI-CityTech)"
ACTIVE_WINDOW = timedelta(days=365)   # within ~12 months counts as "Started"


# -------------------------- HTTP --------------------------------------------

def gh_get(url: str) -> tuple[int, dict | list]:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": USER_AGENT,
            **({"Authorization": f"Bearer {tok}"} if (tok := os.environ.get("GITHUB_TOKEN")) else {}),
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.status, json.loads(resp.read())


def list_org_repos(org: str) -> list[dict]:
    out: list[dict] = []
    page = 1
    while True:
        url = f"{GITHUB_API}/orgs/{org}/repos?per_page=100&type=public&page={page}"
        status, payload = gh_get(url)
        if not isinstance(payload, list):
            raise RuntimeError(f"unexpected payload from {url}: {payload!r}")
        if not payload:
            break
        out.extend(payload)
        if len(payload) < 100:
            break
        page += 1
        time.sleep(0.2)
    return out


def releases_count(full_name: str) -> int:
    try:
        _, payload = gh_get(f"{GITHUB_API}/repos/{full_name}/releases?per_page=1")
        return len(payload) if isinstance(payload, list) else 0
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return 0
        raise


def commits_count(full_name: str) -> int:
    """Return commit count on the default branch. We use the per_page=1 trick
    and read the 'Link' header to know the last page == total count."""
    req = urllib.request.Request(
        f"{GITHUB_API}/repos/{full_name}/commits?per_page=1",
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": USER_AGENT,
            **({"Authorization": f"Bearer {tok}"} if (tok := os.environ.get("GITHUB_TOKEN")) else {}),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            link = resp.headers.get("Link", "")
            if 'rel="last"' in link:
                m = re.search(r'[?&]page=(\d+)>; rel="last"', link)
                if m:
                    return int(m.group(1))
            body = json.loads(resp.read())
            return len(body) if isinstance(body, list) else 0
    except urllib.error.HTTPError as e:
        if e.code == 409:        # empty repo
            return 0
        if e.code == 404:
            return 0
        raise


# -------------------------- Heuristic ---------------------------------------

def classify(repo: dict, commits: int, releases: int) -> tuple[str, str]:
    """Return (activity_status, reason)."""
    name = repo["full_name"]

    if repo.get("archived"):
        return "Finished", "repo is archived"
    if releases > 0:
        return "Finished", f"{releases} release(s) tagged"

    if commits == 0 or repo.get("size", 0) == 0:
        return "Never Started", "no commits / empty repo"
    if commits <= 1:
        return "Never Started", "only initial commit (default scaffold)"

    pushed = repo.get("pushed_at")
    if pushed:
        try:
            pushed_dt = datetime.fromisoformat(pushed.replace("Z", "+00:00"))
            if datetime.now(timezone.utc) - pushed_dt <= ACTIVE_WINDOW:
                return "Started", f"recent activity (pushed {pushed[:10]})"
            return "Started", f"has {commits} commits but no push in >12 months"
        except Exception:
            pass

    return "Started", f"{commits} commits present"


# -------------------------- Linking -----------------------------------------

def normalize_for_match(s: str) -> str:
    s = s.lower()
    s = re.sub(r"^(meta|chi)[-_/ ]*", "", s)        # strip META- / CHI- prefixes
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    return s


def best_project_match(con: sqlite3.Connection, repo_name: str) -> tuple[int | None, float, str]:
    """Find the highest-similarity project for this repo name."""
    target = normalize_for_match(repo_name)
    candidates = con.execute(
        "SELECT project_id, title, slug FROM projects"
    ).fetchall()
    best_id = None
    best_score = 0.0
    method = "auto-fuzzy"
    for project_id, title, slug in candidates:
        for cand_str in filter(None, [title, slug]):
            score = difflib.SequenceMatcher(None, target, normalize_for_match(cand_str)).ratio()
            if score > best_score:
                best_score = score
                best_id = project_id
                method = "auto-slug" if cand_str == slug else "auto-fuzzy"
    return best_id, best_score, method


# -------------------------- Upsert ------------------------------------------

UPSERT_SQL = """
INSERT INTO github_repos (
    full_name, name, org, description, html_url, is_fork, is_archived,
    is_template, is_empty, has_releases, default_branch, primary_language,
    license, topics, stargazers_count, forks_count, open_issues_count,
    open_pulls_count, size_kb, pushed_at, created_at_remote, updated_at_remote,
    activity_status, activity_reason, last_synced_at
) VALUES (
    :full_name, :name, :org, :description, :html_url, :is_fork, :is_archived,
    :is_template, :is_empty, :has_releases, :default_branch, :primary_language,
    :license, :topics, :stargazers_count, :forks_count, :open_issues_count,
    :open_pulls_count, :size_kb, :pushed_at, :created_at_remote, :updated_at_remote,
    :activity_status, :activity_reason, datetime('now')
)
ON CONFLICT(full_name) DO UPDATE SET
    name              = excluded.name,
    description       = excluded.description,
    html_url          = excluded.html_url,
    is_fork           = excluded.is_fork,
    is_archived       = excluded.is_archived,
    is_template       = excluded.is_template,
    is_empty          = excluded.is_empty,
    has_releases      = excluded.has_releases,
    default_branch    = excluded.default_branch,
    primary_language  = excluded.primary_language,
    license           = excluded.license,
    topics            = excluded.topics,
    stargazers_count  = excluded.stargazers_count,
    forks_count       = excluded.forks_count,
    open_issues_count = excluded.open_issues_count,
    open_pulls_count  = excluded.open_pulls_count,
    size_kb           = excluded.size_kb,
    pushed_at         = excluded.pushed_at,
    updated_at_remote = excluded.updated_at_remote,
    activity_status   = excluded.activity_status,
    activity_reason   = excluded.activity_reason,
    last_synced_at    = datetime('now')
"""


def sync(con: sqlite3.Connection, org: str, link_threshold: float = 0.65) -> dict:
    con.executescript(GITHUB_SCHEMA.read_text())

    repos = list_org_repos(org)
    print(f"[github] org={org}: {len(repos)} public repos")

    status_id = {
        r[0]: r[1] for r in con.execute("SELECT name, status_id FROM statuses").fetchall()
    }

    counters = {"Started": 0, "Finished": 0, "Never Started": 0, "Unknown": 0}
    linked = 0
    promoted_status = 0

    for repo in repos:
        full_name = repo["full_name"]
        commits = commits_count(full_name) if not repo.get("archived") else 1
        rels = releases_count(full_name)
        activity_status, reason = classify(repo, commits, rels)
        counters[activity_status] = counters.get(activity_status, 0) + 1

        row = {
            "full_name": full_name,
            "name": repo["name"],
            "org": org,
            "description": repo.get("description"),
            "html_url": repo.get("html_url"),
            "is_fork": int(bool(repo.get("fork"))),
            "is_archived": int(bool(repo.get("archived"))),
            "is_template": int(bool(repo.get("is_template"))),
            "is_empty": int(commits == 0),
            "has_releases": int(rels > 0),
            "default_branch": repo.get("default_branch"),
            "primary_language": repo.get("language"),
            "license": (repo.get("license") or {}).get("spdx_id"),
            "topics": ",".join(repo.get("topics") or []),
            "stargazers_count": repo.get("stargazers_count", 0),
            "forks_count": repo.get("forks_count", 0),
            "open_issues_count": repo.get("open_issues_count", 0),
            "open_pulls_count": 0,
            "size_kb": repo.get("size", 0),
            "pushed_at": repo.get("pushed_at"),
            "created_at_remote": repo.get("created_at"),
            "updated_at_remote": repo.get("updated_at"),
            "activity_status": activity_status,
            "activity_reason": reason,
        }
        con.execute(UPSERT_SQL, row)
        repo_id = con.execute("SELECT repo_id FROM github_repos WHERE full_name=?", (full_name,)).fetchone()[0]

        # Skip linking for the org's profile/README repo
        if repo["name"] in {".github"}:
            continue

        # Already linked manually? Don't overwrite.
        existing = con.execute(
            "SELECT 1 FROM project_github_repos WHERE repo_id=? AND match_method='manual'",
            (repo_id,),
        ).fetchone()
        if existing:
            continue

        pid, score, method = best_project_match(con, repo["name"])
        if pid is None or score < link_threshold:
            continue
        con.execute(
            "INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)"
            " VALUES (?,?,?,?,?)",
            (pid, repo_id, 1, method, round(score, 3)),
        )
        linked += 1

        # Promote project status if it's still 'Proposed' (the seed default)
        # or 'Concept' / unset. Don't touch reviewer-managed statuses.
        cur_status = con.execute("SELECT status_id FROM projects WHERE project_id=?", (pid,)).fetchone()[0]
        if cur_status in (
            None,
            status_id.get("Proposed"),
            status_id.get("Concept"),
        ):
            new_status = status_id.get(activity_status)
            if new_status:
                con.execute("UPDATE projects SET status_id=? WHERE project_id=?", (new_status, pid))
                promoted_status += 1

    con.commit()
    print(f"[github] classified -> {counters}")
    print(f"[github] auto-linked {linked} repo(s) to projects; promoted {promoted_status} project status(es)")
    return {"counters": counters, "linked": linked, "promoted_status": promoted_status}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    parser.add_argument("--org", default=os.environ.get("BBS_GITHUB_ORG", "CHI-CityTech"))
    parser.add_argument("--threshold", type=float, default=0.65,
                        help="minimum fuzzy match score to auto-link (0..1)")
    args = parser.parse_args()

    con = sqlite3.connect(args.db)
    try:
        sync(con, args.org, link_threshold=args.threshold)
    finally:
        con.close()


if __name__ == "__main__":
    main()
