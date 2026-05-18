-- =============================================================================
-- Pipeline schema add-on: staging table for submissions awaiting review
-- =============================================================================
-- Apply AFTER schema.sql. This adds the tables the ingestion + review scripts
-- depend on. Safe to re-run (uses IF NOT EXISTS).
-- =============================================================================

PRAGMA foreign_keys = ON;

-- One row per Google Form submission. Lifecycle: 'pending' -> 'approved' /
-- 'rejected' / 'duplicate'. Approved rows write a new row into `projects`
-- (and the related join tables) and record the resulting project_id.
CREATE TABLE IF NOT EXISTS pending_submissions (
    submission_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    -- Identity: a stable key from the source row so re-ingesting is idempotent
    source_row_hash      TEXT    UNIQUE NOT NULL,
    -- Where this submission came from: 'form' (Google Form) or 'github-scan'
    source               TEXT    NOT NULL DEFAULT 'form'
                                CHECK (source IN ('form','github-scan','manual')),
    -- For github-scan rows, the originating repo full_name (e.g. CHI-CityTech/META-CHIIDS)
    source_repo          TEXT,
    submitted_at         TEXT    NOT NULL,        -- ISO timestamp from the Form
    submitter_name       TEXT,
    submitter_email      TEXT,
    -- The proposed project fields
    title                TEXT    NOT NULL,
    summary              TEXT,
    description          TEXT,
    departments_raw      TEXT,                    -- semicolon-separated dept codes/names
    categories_raw       TEXT,                    -- semicolon-separated category names
    tags_raw             TEXT,                    -- comma-separated tags
    level                TEXT,                    -- "Beginning"/"Intermediate"/"Advanced"
    semester             TEXT,                    -- e.g. "Fall 2025"
    parent_project_slug  TEXT,                    -- optional, for sub-projects
    primary_url          TEXT,
    extra_links_raw      TEXT,                    -- newline-separated "label|url" pairs
    -- Review fields
    review_status        TEXT    NOT NULL DEFAULT 'pending'
                                CHECK (review_status IN ('pending','approved','rejected','duplicate')),
    review_notes         TEXT,
    reviewed_by          TEXT,
    reviewed_at          TEXT,
    -- Validation
    validation_errors    TEXT,                    -- JSON array of error strings; empty means clean
    -- Link to the final project once approved
    approved_project_id  INTEGER REFERENCES projects(project_id) ON DELETE SET NULL,
    created_at           TEXT    DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_submissions_status ON pending_submissions(review_status);
CREATE INDEX IF NOT EXISTS idx_submissions_submitted_at ON pending_submissions(submitted_at);
CREATE INDEX IF NOT EXISTS idx_submissions_source ON pending_submissions(source);
CREATE INDEX IF NOT EXISTS idx_submissions_source_repo ON pending_submissions(source_repo);

-- Audit log: every approve/reject action is recorded here.
CREATE TABLE IF NOT EXISTS review_log (
    log_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_id   INTEGER NOT NULL REFERENCES pending_submissions(submission_id) ON DELETE CASCADE,
    action          TEXT    NOT NULL CHECK (action IN ('approve','reject','mark_duplicate','reopen','edit')),
    reviewer        TEXT,
    notes           TEXT,
    created_at      TEXT    DEFAULT (datetime('now'))
);

-- Optional: track the last successful ingestion so the workflow can show what
-- it picked up.
CREATE TABLE IF NOT EXISTS ingestion_runs (
    run_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at      TEXT    DEFAULT (datetime('now')),
    finished_at     TEXT,
    rows_seen       INTEGER DEFAULT 0,
    rows_new        INTEGER DEFAULT 0,
    rows_invalid    INTEGER DEFAULT 0,
    source_url      TEXT,
    notes           TEXT
);
