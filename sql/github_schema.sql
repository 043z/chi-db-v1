-- =============================================================================
-- GitHub integration schema add-on
-- =============================================================================
-- Adds the github_repos table, the project_github_repos join, and three new
-- status rows: 'Started', 'Finished', 'Never Started'. Apply AFTER schema.sql.
-- Idempotent (uses IF NOT EXISTS / INSERT OR IGNORE).
-- =============================================================================

PRAGMA foreign_keys = ON;

-- One row per GitHub repository under the watched organization.
CREATE TABLE IF NOT EXISTS github_repos (
    repo_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name            TEXT    NOT NULL UNIQUE,   -- e.g. "CHI-CityTech/QuantumMusic"
    name                 TEXT    NOT NULL,          -- "QuantumMusic"
    org                  TEXT    NOT NULL,          -- "CHI-CityTech"
    description          TEXT,
    html_url             TEXT,
    is_fork              INTEGER NOT NULL DEFAULT 0,
    is_archived          INTEGER NOT NULL DEFAULT 0,
    is_template          INTEGER NOT NULL DEFAULT 0,
    is_empty             INTEGER NOT NULL DEFAULT 0,
    has_releases         INTEGER NOT NULL DEFAULT 0,
    default_branch       TEXT,
    primary_language     TEXT,
    license              TEXT,
    topics               TEXT,                      -- comma-separated
    stargazers_count     INTEGER DEFAULT 0,
    forks_count          INTEGER DEFAULT 0,
    open_issues_count    INTEGER DEFAULT 0,
    open_pulls_count     INTEGER DEFAULT 0,
    size_kb              INTEGER DEFAULT 0,
    pushed_at            TEXT,
    created_at_remote    TEXT,
    updated_at_remote    TEXT,
    -- Heuristic-derived bucket
    activity_status      TEXT CHECK (activity_status IN ('Started','Finished','Never Started','Unknown'))
                            DEFAULT 'Unknown',
    activity_reason      TEXT,                      -- why the heuristic picked this bucket
    last_synced_at       TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_repos_status ON github_repos(activity_status);
CREATE INDEX IF NOT EXISTS idx_repos_pushed ON github_repos(pushed_at);

-- Project <-> Repo join. A project can have multiple repos, a repo can be
-- referenced by multiple projects. `is_primary` tags the canonical repo for
-- the project.
CREATE TABLE IF NOT EXISTS project_github_repos (
    project_id      INTEGER NOT NULL REFERENCES projects(project_id)     ON DELETE CASCADE,
    repo_id         INTEGER NOT NULL REFERENCES github_repos(repo_id)    ON DELETE CASCADE,
    is_primary      INTEGER NOT NULL DEFAULT 0,
    match_method    TEXT    DEFAULT 'auto-fuzzy',   -- 'auto-fuzzy' | 'auto-slug' | 'manual'
    confidence      REAL,                           -- 0..1 for auto matches
    PRIMARY KEY (project_id, repo_id)
);

CREATE INDEX IF NOT EXISTS idx_pgr_repo ON project_github_repos(repo_id);

-- Add three new status rows used by the GitHub status mapper. These are NEW
-- statuses; the existing 'Proposed' / 'Active' / 'Completed' / 'Archived' /
-- 'Concept' rows are untouched.
INSERT OR IGNORE INTO statuses (name, description) VALUES
    ('Started',       'Repo has commits and recent activity (within ~12 months)'),
    ('Finished',      'Repo is archived OR has a release tag'),
    ('Never Started', 'Empty repo / no real commits beyond default scaffold');

-- Convenience view: project + its primary repo + the repo's activity status.
CREATE VIEW IF NOT EXISTS v_project_with_repo AS
SELECT
    p.project_id,
    p.title,
    (SELECT name FROM statuses WHERE status_id = p.status_id) AS project_status,
    r.full_name             AS repo_full_name,
    r.html_url              AS repo_url,
    r.activity_status       AS repo_activity_status,
    r.pushed_at             AS repo_last_push,
    r.open_issues_count     AS open_issues,
    r.stargazers_count      AS stars
FROM projects p
LEFT JOIN project_github_repos pgr ON pgr.project_id = p.project_id AND pgr.is_primary = 1
LEFT JOIN github_repos r           ON r.repo_id      = pgr.repo_id;

-- Convenience view: every repo grouped by activity status.
CREATE VIEW IF NOT EXISTS v_repos_by_status AS
SELECT activity_status, COUNT(*) AS n
FROM github_repos
GROUP BY activity_status
ORDER BY n DESC;
