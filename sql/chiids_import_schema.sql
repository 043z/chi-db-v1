-- =============================================================================
-- CHIIDS-aligned tables imported into the BBS database (one combined DB).
-- =============================================================================
-- These tables mirror the nine data-type clusters defined in the CHIIDS
-- engineering specification (Sections 2.1-2.9 of chiids_original_spec.md
-- at https://github.com/CHI-CityTech/META-CHIIDS). They are prefixed `chiids_`
-- so they live side-by-side with the BBS tables without collisions.
--
-- A `project_chiids_aliases` table links BBS `projects.project_id` to the
-- CHIIDS meta-project canonical identifier. Nothing in BBS gets overwritten.
--
-- A later GitHub-Actions step can replace the seeded data here with the live
-- contents of META-CHIIDS/database/seed_data.sql -- but the schema itself is
-- stable.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- =============================================================================
-- 2.1 CHI System Setup and Organization
-- =============================================================================

-- The CHI meta-projects catalog (Layer 1). Each row is a permanent project
-- under the CHI-CityTech organization (e.g. BBS, BRPS, BSP, CAI, UNESCO...).
CREATE TABLE IF NOT EXISTS chiids_meta_projects (
    meta_project_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    slug              TEXT NOT NULL UNIQUE,
    name              TEXT NOT NULL,
    abbreviation      TEXT,
    description       TEXT,
    repo_url          TEXT,
    site_url          TEXT,
    meta_project_type_id INTEGER REFERENCES meta_project_types(type_id) ON DELETE SET NULL,
    lifecycle_stage_id   INTEGER REFERENCES lifecycle_stages(stage_id) ON DELETE SET NULL,
    created_at        TEXT DEFAULT (datetime('now'))
);

-- CHI teams (working groups attached to a meta-project)
CREATE TABLE IF NOT EXISTS chiids_teams (
    team_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    name              TEXT NOT NULL,
    description       TEXT
);

-- Organizational roles people can hold inside CHI
CREATE TABLE IF NOT EXISTS chiids_roles (
    role_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name              TEXT NOT NULL UNIQUE,
    description       TEXT
);

-- People (org-level; ties to existing `researchers` via researcher_id)
CREATE TABLE IF NOT EXISTS chiids_people (
    person_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name         TEXT NOT NULL,
    email             TEXT,
    affiliation       TEXT,
    researcher_id     INTEGER REFERENCES researchers(researcher_id) ON DELETE SET NULL,
    notes             TEXT,
    UNIQUE(full_name, affiliation)
);

CREATE TABLE IF NOT EXISTS chiids_team_members (
    membership_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id           INTEGER NOT NULL REFERENCES chiids_teams(team_id)   ON DELETE CASCADE,
    person_id         INTEGER NOT NULL REFERENCES chiids_people(person_id) ON DELETE CASCADE,
    role_id           INTEGER REFERENCES chiids_roles(role_id) ON DELETE SET NULL,
    semester          TEXT DEFAULT '',
    UNIQUE (team_id, person_id, semester)
);

CREATE TABLE IF NOT EXISTS chiids_policies (
    policy_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name              TEXT NOT NULL,
    description       TEXT,
    document_url      TEXT
);

-- =============================================================================
-- 2.2 Project Management Data
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_tasks (
    task_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    project_id        INTEGER REFERENCES projects(project_id) ON DELETE SET NULL,
    title             TEXT NOT NULL,
    description       TEXT,
    status            TEXT CHECK (status IN ('open','in_progress','blocked','done','cancelled')) DEFAULT 'open',
    due_date          TEXT,
    assigned_to       INTEGER REFERENCES chiids_people(person_id) ON DELETE SET NULL,
    created_at        TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chiids_milestones (
    milestone_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    name              TEXT NOT NULL,
    target_date       TEXT,
    achieved_date     TEXT,
    notes             TEXT
);

CREATE TABLE IF NOT EXISTS chiids_resources (
    resource_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    kind              TEXT NOT NULL CHECK (kind IN ('budget','personnel','equipment','space','grant','other')),
    name              TEXT NOT NULL,
    allocation        REAL,
    unit              TEXT,
    notes             TEXT
);

-- =============================================================================
-- 2.3 Research Opportunities Dataset
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_research_opportunities (
    opportunity_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    title             TEXT NOT NULL,
    description       TEXT,
    modality          TEXT,
    discipline        TEXT,
    deadline          TEXT,
    eligibility       TEXT,
    created_at        TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chiids_applications (
    application_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    opportunity_id    INTEGER REFERENCES chiids_research_opportunities(opportunity_id) ON DELETE CASCADE,
    applicant_id      INTEGER REFERENCES chiids_people(person_id) ON DELETE SET NULL,
    status            TEXT CHECK (status IN ('submitted','review','accepted','rejected','withdrawn')) DEFAULT 'submitted',
    submitted_at      TEXT DEFAULT (datetime('now')),
    notes             TEXT
);

-- =============================================================================
-- 2.4 Documentation and Reports
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_documents (
    document_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    project_id        INTEGER REFERENCES projects(project_id) ON DELETE SET NULL,
    kind              TEXT CHECK (kind IN ('research_note','tech_spec','progress_report','deliverable','final_report','other')) DEFAULT 'other',
    title             TEXT NOT NULL,
    description       TEXT,
    url               TEXT,
    created_at        TEXT DEFAULT (datetime('now'))
);

-- =============================================================================
-- 2.5 Media Data
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_media (
    media_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    project_id        INTEGER REFERENCES projects(project_id) ON DELETE SET NULL,
    kind              TEXT CHECK (kind IN ('image','video','audio','3d_model','document','other')) DEFAULT 'other',
    title             TEXT,
    url               TEXT,
    license           TEXT,
    notes             TEXT,
    created_at        TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chiids_living_archive (
    entry_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    initiative        TEXT,
    contributor       TEXT,
    title             TEXT,
    body              TEXT,
    media_id          INTEGER REFERENCES chiids_media(media_id) ON DELETE SET NULL,
    created_at        TEXT DEFAULT (datetime('now'))
);

-- =============================================================================
-- 2.6 Version Control Data
-- =============================================================================
-- This dovetails with our existing `github_repos`. The new table here records
-- non-GitHub VCS endpoints (GitLab, Bitbucket, SharePoint version history).

CREATE TABLE IF NOT EXISTS chiids_vcs_repos (
    vcs_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    provider          TEXT NOT NULL CHECK (provider IN ('github','gitlab','bitbucket','sharepoint','other')),
    name              TEXT NOT NULL,
    url               TEXT,
    github_repo_id    INTEGER REFERENCES github_repos(repo_id) ON DELETE SET NULL,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL
);

-- =============================================================================
-- 2.7 Archival Data
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_archives (
    archive_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    project_id        INTEGER REFERENCES projects(project_id) ON DELETE SET NULL,
    kind              TEXT CHECK (kind IN ('living','operational','project','research','virtual_world','version_control','assessment')) NOT NULL,
    title             TEXT,
    storage_url       TEXT,
    archived_at       TEXT DEFAULT (datetime('now')),
    metadata          TEXT
);

CREATE TABLE IF NOT EXISTS chiids_metrics (
    metric_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    name              TEXT NOT NULL,
    value             REAL,
    unit              TEXT,
    measured_at       TEXT DEFAULT (datetime('now')),
    notes             TEXT
);

-- =============================================================================
-- 2.8 Communication and Engagement Data
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_communications (
    comm_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    audience          TEXT CHECK (audience IN ('internal','public','extra_chi','partners')) NOT NULL,
    channel           TEXT,
    subject           TEXT,
    body              TEXT,
    url               TEXT,
    occurred_at       TEXT
);

CREATE TABLE IF NOT EXISTS chiids_public_engagement (
    engagement_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    meta_project_id   INTEGER REFERENCES chiids_meta_projects(meta_project_id) ON DELETE SET NULL,
    kind              TEXT CHECK (kind IN ('website','social','event','press','publication','other')) NOT NULL,
    title             TEXT,
    url               TEXT,
    occurred_at       TEXT,
    audience_size     INTEGER,
    notes             TEXT
);

-- =============================================================================
-- 2.9 Data Storage and Backup
-- =============================================================================

CREATE TABLE IF NOT EXISTS chiids_storage_locations (
    location_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    name              TEXT NOT NULL UNIQUE,        -- 'OneDrive','SharePoint','Zenodo',...
    kind              TEXT CHECK (kind IN ('active','backup','archival','publication')) NOT NULL,
    url               TEXT,
    notes             TEXT
);

CREATE TABLE IF NOT EXISTS chiids_backups (
    backup_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id       INTEGER REFERENCES chiids_storage_locations(location_id) ON DELETE SET NULL,
    description       TEXT,
    last_run_at       TEXT,
    next_run_at       TEXT,
    bytes             INTEGER
);

-- =============================================================================
-- Bridge: link BBS projects to CHIIDS meta-projects (the whole point of the
-- merge -- nothing on either side is overwritten)
-- =============================================================================

CREATE TABLE IF NOT EXISTS project_chiids_aliases (
    project_id        INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    meta_project_id   INTEGER NOT NULL REFERENCES chiids_meta_projects(meta_project_id) ON DELETE CASCADE,
    match_method      TEXT NOT NULL CHECK (match_method IN ('auto-slug','auto-fuzzy','manual','seed')) DEFAULT 'auto-fuzzy',
    confidence        REAL,
    notes             TEXT,
    PRIMARY KEY (project_id, meta_project_id)
);

CREATE INDEX IF NOT EXISTS idx_aliases_meta ON project_chiids_aliases(meta_project_id);

-- =============================================================================
-- Convenience views
-- =============================================================================

-- Every meta-project in CHIIDS with its BBS counterpart (if any)
CREATE VIEW IF NOT EXISTS v_chiids_meta_projects_with_bbs AS
SELECT
    mp.meta_project_id, mp.slug, mp.name, mp.abbreviation,
    (SELECT name FROM meta_project_types WHERE type_id = mp.meta_project_type_id) AS type,
    (SELECT name FROM lifecycle_stages   WHERE stage_id = mp.lifecycle_stage_id)  AS lifecycle,
    p.project_id AS bbs_project_id,
    p.title      AS bbs_title,
    a.match_method,
    a.confidence
FROM chiids_meta_projects mp
LEFT JOIN project_chiids_aliases a ON a.meta_project_id = mp.meta_project_id
LEFT JOIN projects p               ON p.project_id      = a.project_id
ORDER BY mp.slug;

-- Combined "everything we know about meta-projects" feed
CREATE VIEW IF NOT EXISTS v_combined_meta_projects AS
SELECT
    'chiids' AS source,
    mp.slug, mp.name, mp.abbreviation, mp.repo_url, mp.site_url,
    (SELECT name FROM meta_project_types WHERE type_id = mp.meta_project_type_id) AS type,
    (SELECT name FROM lifecycle_stages   WHERE stage_id = mp.lifecycle_stage_id)  AS lifecycle
FROM chiids_meta_projects mp
UNION ALL
SELECT
    'bbs' AS source,
    p.slug, p.title, NULL, p.primary_url, p.primary_url,
    (SELECT name FROM meta_project_types WHERE type_id = p.meta_project_type_id) AS type,
    (SELECT name FROM lifecycle_stages   WHERE stage_id = p.lifecycle_stage_id)  AS lifecycle
FROM projects p
WHERE p.is_meta_project = 1;
