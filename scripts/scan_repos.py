#!/usr/bin/env python3
"""Scan inside every GitHub repo for project candidates.

For each repo already in `github_repos`, this fetches:
    - README.md (or README in any case)
    - any *.md / *.txt at the repo root
    - any *.md inside /docs

Each fetched document is parsed for:
    - H2 / H3 headings  -> candidate project titles
    - "interesting" bullet list items at depth 0 (e.g. "- Project X: ...")
    - obvious tag-like keywords (from a curated list + the words "AI", "VR",
      "AR", "shadow puppet", "unity", "unreal", "blockchain", ...)
    - external (non-github) http(s) links -> proposed project_links rows

Each candidate becomes a row in `pending_submissions` with:
    source       = 'github-scan'
    source_repo  = '<org>/<repo>'

A stable `source_row_hash` keeps the operation idempotent -- running on a
schedule never produces duplicates.

Usage:
    python3 scripts/scan_repos.py
    python3 scripts/scan_repos.py --db balanced_blended_space.db
    python3 scripts/scan_repos.py --fixture-dir fixtures/repo_scan_fixtures
        # offline test mode: reads pretend READMEs from a folder

Auth:
    Set $GITHUB_TOKEN to raise the rate limit from 60/hr to 5000/hr.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / "balanced_blended_space.db"

GITHUB_API = "https://api.github.com"
USER_AGENT = "bbs-pipeline-scan"

# Files we'll try to read at the repo root (case-insensitive match)
ROOT_DOC_PATTERNS = ("readme.md", "readme", "readme.txt", "readme.rst",
                     "projects.md", "projects.txt", "todo.md",
                     "roadmap.md", "status.md")
DOCS_DIR = "docs"

# Tags we recognize when they appear in body text (case-insensitive)
KNOWN_TAGS = {
    "ai": "AI", "llm": "LLM", "vr": "VR", "ar": "AR",
    "mixed reality": "Mixed Reality", "projection mapping": "Projection Mapping",
    "shadow puppet": "Shadow Puppetry", "shadow puppetry": "Shadow Puppetry",
    "unity": "Game", "unreal": "Game", "game": "Game",
    "3d print": "3D Printing", "3d-printed": "3D Printing", "3d-printing": "3D Printing",
    "robot": "Robotics", "robotics": "Robotics",
    "music": "Music", "audio": "Sound", "sound": "Sound", "foley": "Sound",
    "marketing": "Marketing", "branding": "Branding",
    "wearable": "Wearable", "textile": "Textile",
    "architecture": "Architecture", "stage design": "Stage Design",
    "performance": "Performance", "streaming": "Streaming",
    "cloud": "Cloud", "blockchain": "Software",
    "quantum": "Quantum", "autonomous vehicle": "Autonomous Vehicles",
    "world build": "World Building", "world-building": "World Building",
    "research": "Research", "workshop": "Workshop", "education": "Education",
    "cultural": "Cultural", "storytelling": "Storytelling",
    "theory": "Theory", "syntax": "Syntax",
    "interactive": "Interactive", "mobile": "Mobile",
}

# Patterns that suggest a heading/bullet IS a project (vs. a generic section)
PROJECT_HINT_RE = re.compile(
    r"\b(project|sub[- ]?project|initiative|repo(?:sitory)?|module|"
    r"experiment|study|prototype|component|system|tool|library|"
    r"workshop|curriculum|series|installation|performance|demo)\b",
    re.IGNORECASE,
)

# Headings / bullets we explicitly DO NOT want (boilerplate)
DENYLIST_RE = re.compile(
    r"^(table of contents|getting started|installation|setup|prerequisites|"
    r"usage|examples?|license|contact|contributing|references?|acknowledgements?|"
    r"requirements|dependencies|how to|how-to|quick start|configuration|"
    r"troubleshooting|faq|changelog|features|footer|"
    r"overview|about|introduction|background|"
    r"project (goals?|activities? overview|activities)|"
    r"goals?|key components?|components?|"
    r"world canon( development)?)\s*$",
    re.IGNORECASE,
)

HEADING_RE = re.compile(r"^(#{2,3})\s+(.+?)\s*#*$")           # H2 / H3
BULLET_RE  = re.compile(r"^[-*+]\s+(.+?)\s*$")                # top-level bullets only
URL_RE     = re.compile(r"https?://[^\s)<>\]\"']+", re.IGNORECASE)
GH_URL_RE  = re.compile(r"^https?://github\.com/", re.IGNORECASE)


# ----------------------------- HTTP -----------------------------------------

def _gh_request(url: str) -> dict | list:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": USER_AGENT,
            **({"Authorization": f"Bearer {tok}"} if (tok := os.environ.get("GITHUB_TOKEN")) else {}),
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def fetch_root_listing(full_name: str) -> list[dict]:
    try:
        data = _gh_request(f"{GITHUB_API}/repos/{full_name}/contents/")
    except urllib.error.HTTPError as e:
        if e.code in (403, 404):
            return []
        raise
    return data if isinstance(data, list) else []


def fetch_docs_listing(full_name: str) -> list[dict]:
    try:
        data = _gh_request(f"{GITHUB_API}/repos/{full_name}/contents/{DOCS_DIR}")
    except urllib.error.HTTPError as e:
        if e.code in (403, 404):
            return []
        raise
    return data if isinstance(data, list) else []


def fetch_file(full_name: str, path: str) -> str:
    try:
        data = _gh_request(f"{GITHUB_API}/repos/{full_name}/contents/{path}")
    except urllib.error.HTTPError as e:
        if e.code in (403, 404):
            return ""
        raise
    if isinstance(data, dict) and data.get("encoding") == "base64":
        try:
            return base64.b64decode(data["content"]).decode("utf-8", errors="replace")
        except Exception:
            return ""
    return ""


def select_root_docs(listing: list[dict]) -> list[str]:
    picks: list[str] = []
    for item in listing:
        if item.get("type") != "file":
            continue
        name = (item.get("name") or "").lower()
        if any(name == pat or (name.startswith("readme") and (name.endswith(".md") or name.endswith(".txt") or name.endswith(".rst") or "." not in name)) for pat in ROOT_DOC_PATTERNS):
            picks.append(item["path"])
    return picks


def select_docs_dir(listing: list[dict]) -> list[str]:
    out: list[str] = []
    for item in listing:
        if item.get("type") != "file":
            continue
        name = (item.get("name") or "").lower()
        if name.endswith(".md") or name.endswith(".txt") or name.endswith(".rst"):
            out.append(item["path"])
    return out


# ----------------------------- Parsing --------------------------------------

def clean_title(s: str) -> str:
    # Strip markdown links: [text](url) -> text
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)
    # Strip bold/italic markers
    s = re.sub(r"[*_`]+", "", s).strip()
    # Drop trailing parens and emoji-ish leading symbols
    s = re.sub(r"\s*[☀-➿\U0001F300-\U0001FAFF]+\s*", " ", s).strip()
    # Collapse whitespace
    s = re.sub(r"\s+", " ", s).strip()
    # For bullet patterns like "Title: description", keep just the title part.
    # Heuristic: if there's a colon AND the prefix is short and looks like a
    # title (<=10 words, mostly Title Case), drop everything after the colon.
    if ":" in s:
        prefix, _, _rest = s.partition(":")
        words = prefix.split()
        if 1 <= len(words) <= 10 and sum(1 for w in words if w[:1].isupper()) >= max(1, len(words)//2):
            s = prefix.strip()
    # Trim trailing punctuation
    s = re.sub(r"[\s\-:;,]+$", "", s).strip()
    return s


def looks_like_project(text: str) -> bool:
    t = text.strip()
    if not t or len(t) < 4 or len(t) > 200:
        return False
    if DENYLIST_RE.match(t):
        return False
    # Must either match the project-hint regex OR look like a Title Case multi-word
    if PROJECT_HINT_RE.search(t):
        return True
    words = t.split()
    if 2 <= len(words) <= 12 and sum(1 for w in words if w[:1].isupper()) >= max(2, len(words)//2):
        return True
    return False


def extract_tags(body: str) -> list[str]:
    found: set[str] = set()
    low = body.lower()
    for needle, tag in KNOWN_TAGS.items():
        if needle in low:
            found.add(tag)
    return sorted(found)


def extract_links(body: str) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for url in URL_RE.findall(body):
        # Drop trailing markdown punctuation like ")" or "."
        url = url.rstrip(").,;:!?'\"")
        if url in seen or GH_URL_RE.match(url):
            continue
        seen.add(url)
        out.append(url)
    return out[:10]


def parse_doc(body: str) -> list[dict]:
    """Return a list of candidate-project dicts."""
    candidates: list[dict] = []
    seen_titles: set[str] = set()
    body_tags = extract_tags(body)
    body_links = extract_links(body)

    for raw_line in body.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue
        h = HEADING_RE.match(line.lstrip())
        if h:
            title = clean_title(h.group(2))
            if looks_like_project(title) and title.lower() not in seen_titles:
                seen_titles.add(title.lower())
                candidates.append({"title": title, "kind": "heading"})
            continue
        # Only treat depth-0 bullets (no leading whitespace) as candidates
        if line[:1] in "-*+" and line[1:2] == " ":
            b = BULLET_RE.match(line)
            if b:
                title = clean_title(b.group(1))
                if looks_like_project(title) and title.lower() not in seen_titles:
                    seen_titles.add(title.lower())
                    candidates.append({"title": title, "kind": "bullet"})

    for c in candidates:
        c["tags"] = body_tags
        c["links"] = body_links
    return candidates


# ----------------------------- Staging --------------------------------------

INSERT_SQL = """
INSERT OR IGNORE INTO pending_submissions (
    source_row_hash, source, source_repo, submitted_at,
    submitter_name, submitter_email,
    title, summary, description,
    departments_raw, categories_raw, tags_raw,
    level, semester, parent_project_slug,
    primary_url, extra_links_raw, validation_errors
) VALUES (
    :hash, 'github-scan', :repo, datetime('now'),
    :submitter, NULL,
    :title, :summary, :description,
    NULL, 'Sub-Project', :tags_csv,
    NULL, NULL, NULL,
    :repo_url, :links_block, NULL
)
"""


def row_hash(repo: str, title: str) -> str:
    h = hashlib.sha256()
    h.update("|".join([repo.strip().lower(), title.strip().lower()]).encode("utf-8"))
    return h.hexdigest()


def stage_candidates(con: sqlite3.Connection, repo: dict, doc_path: str, candidates: list[dict]) -> int:
    n = 0
    repo_full = repo["full_name"]
    repo_url = repo.get("html_url") or f"https://github.com/{repo_full}"
    for c in candidates:
        title = c["title"]
        body_tags = c.get("tags") or []
        links = c.get("links") or []
        links_block = "\n".join(f"link|{u}" for u in links) if links else None
        con.execute(INSERT_SQL, {
            "hash": row_hash(repo_full, title),
            "repo": repo_full,
            "submitter": f"github-scan ({repo_full})",
            "title": title,
            "summary": f"Found inside {repo_full} ({doc_path}, {c.get('kind')})",
            "description": f"Auto-extracted from {repo_full}/{doc_path}. Review before approving.",
            "tags_csv": ", ".join(body_tags) if body_tags else None,
            "repo_url": repo_url,
            "links_block": links_block,
        })
        if con.total_changes:
            n += 1
    return n


# ----------------------------- Driver ---------------------------------------

def scan_one(con: sqlite3.Connection, repo: dict, fixture_dir: Path | None) -> tuple[int, int]:
    """Returns (docs_seen, candidates_added)."""
    full = repo["full_name"]
    docs_seen = added = 0

    def _process(doc_path: str, body: str) -> None:
        nonlocal docs_seen, added
        if not body:
            return
        docs_seen += 1
        before = con.total_changes
        cands = parse_doc(body)
        stage_candidates(con, repo, doc_path, cands)
        added += con.total_changes - before

    if fixture_dir is not None:
        # Offline fixture mode: look for <fixture_dir>/<org>__<name>__README.md
        slug = full.replace("/", "__")
        for fname in ("README.md", "README", "PROJECTS.md", "docs/README.md"):
            fp = fixture_dir / f"{slug}__{fname.replace('/','__')}"
            if fp.exists():
                _process(fname, fp.read_text())
        return docs_seen, added

    # Live GitHub mode
    root = fetch_root_listing(full)
    for path in select_root_docs(root):
        _process(path, fetch_file(full, path))
        time.sleep(0.1)
    for path in select_docs_dir(fetch_docs_listing(full)):
        _process(path, fetch_file(full, path))
        time.sleep(0.1)
    return docs_seen, added


def scan(con: sqlite3.Connection, fixture_dir: Path | None = None) -> dict:
    repos = con.execute(
        "SELECT repo_id, full_name, html_url FROM github_repos WHERE name != '.github'"
    ).fetchall()
    print(f"[scan] {len(repos)} repo(s) to scan")
    totals = {"repos": 0, "docs": 0, "added": 0}
    for row in repos:
        repo = {"repo_id": row[0], "full_name": row[1], "html_url": row[2]}
        try:
            docs, added = scan_one(con, repo, fixture_dir)
        except urllib.error.HTTPError as e:
            print(f"  ! {repo['full_name']}  HTTP {e.code}: {e.reason}")
            continue
        print(f"  - {repo['full_name']:<55} docs={docs} new_candidates={added}")
        totals["repos"] += 1
        totals["docs"] += docs
        totals["added"] += added
    con.commit()
    print(f"[scan] total: {totals}")
    return totals


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(DEFAULT_DB))
    parser.add_argument("--fixture-dir", help="offline-mode folder of fake READMEs")
    args = parser.parse_args()

    con = sqlite3.connect(args.db)
    try:
        scan(con, Path(args.fixture_dir) if args.fixture_dir else None)
    finally:
        con.close()


if __name__ == "__main__":
    main()
