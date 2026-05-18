-- =============================================================================
-- Balanced Blended Space (BBS) Research Projects -- SQLite Schema
-- Source: https://sites.google.com/view/balancedblendedspace/home
-- =============================================================================
-- Design notes
--   * Many-to-many between projects and departments (a project can sit in
--     several departments, since BBS research is explicitly interdisciplinary).
--   * Categories are orthogonal classifications (Theory / Practice / Meta-Project
--     / Department-Research / Semester-Cohort / etc.) and also m:n with projects.
--   * Tags are free-form keywords (AI, VR, Puppetry, Shadow, Hardware...) and
--     are m:n with projects. Tags differ from categories in that they are
--     lightweight, user-extensible, and not part of the navigation taxonomy.
--   * Levels (Beginning / Intermediate / Advanced) come from the COMD page and
--     can apply to any project, so they live in a small lookup table.
--   * Researchers are people who lead or contribute to a project; the join
--     table carries a role (lead, contributor, technical_advisor, etc.).
--   * Links and attachments are 1:n off projects (a project can have any
--     number of external URLs and file references).
--   * Foreign keys use ON DELETE CASCADE for the join tables so removing a
--     project cleans up its associations.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- Lookup / dimension tables
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS departments (
    department_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    code            TEXT    UNIQUE,                -- e.g. "ENT", "MTEC", "COMD"
    name            TEXT    NOT NULL UNIQUE,       -- e.g. "Entertainment Technology"
    slug            TEXT    UNIQUE,                -- URL-safe identifier
    url             TEXT,                          -- canonical department page URL
    description     TEXT,
    created_at      TEXT    DEFAULT (datetime('now')),
    updated_at      TEXT    DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS categories (
    category_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL UNIQUE,       -- "Theory","Practice","Meta-Project","Department Research","Semester Cohort","Sub-Project"
    description     TEXT
);

CREATE TABLE IF NOT EXISTS tags (
    tag_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL UNIQUE COLLATE NOCASE
);

CREATE TABLE IF NOT EXISTS levels (
    level_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL UNIQUE,       -- "Beginning","Intermediate","Advanced","Unspecified"
    sort_order      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS statuses (
    status_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL UNIQUE,       -- "Proposed","Active","Completed","Archived","Concept"
    description     TEXT
);

CREATE TABLE IF NOT EXISTS researchers (
    researcher_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name       TEXT    NOT NULL,
    email           TEXT,
    affiliation     TEXT,                          -- e.g. "City Tech", "External Collaborator"
    notes           TEXT,
    UNIQUE(full_name, affiliation)
);

CREATE TABLE IF NOT EXISTS link_types (
    link_type_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT    NOT NULL UNIQUE        -- "Project Page","Proposal","GitHub","Dropbox","Google Doc","Demo","Paper","Other"
);

-- -----------------------------------------------------------------------------
-- Core entity: projects
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS projects (
    project_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    title           TEXT    NOT NULL,
    slug            TEXT    UNIQUE,
    summary         TEXT,                          -- one-line description
    description     TEXT,                          -- full description / abstract
    status_id       INTEGER REFERENCES statuses(status_id) ON DELETE SET NULL,
    level_id        INTEGER REFERENCES levels(level_id)    ON DELETE SET NULL,
    parent_project_id INTEGER REFERENCES projects(project_id) ON DELETE SET NULL,  -- for sub-projects
    start_date      TEXT,                          -- ISO YYYY-MM-DD; nullable
    end_date        TEXT,
    semester        TEXT,                          -- e.g. "Fall 2024", "Spring 2025"
    primary_url     TEXT,                          -- canonical page on the BBS site
    is_meta_project INTEGER NOT NULL DEFAULT 0,    -- BSP, BRPS, World Building, etc.
    created_at      TEXT    DEFAULT (datetime('now')),
    updated_at      TEXT    DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- Many-to-many relationships
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS project_departments (
    project_id      INTEGER NOT NULL REFERENCES projects(project_id)       ON DELETE CASCADE,
    department_id   INTEGER NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    is_primary      INTEGER NOT NULL DEFAULT 0,    -- 1 if this is the "home" department
    PRIMARY KEY (project_id, department_id)
);

CREATE TABLE IF NOT EXISTS project_categories (
    project_id      INTEGER NOT NULL REFERENCES projects(project_id)     ON DELETE CASCADE,
    category_id     INTEGER NOT NULL REFERENCES categories(category_id)  ON DELETE CASCADE,
    PRIMARY KEY (project_id, category_id)
);

CREATE TABLE IF NOT EXISTS project_tags (
    project_id      INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    tag_id          INTEGER NOT NULL REFERENCES tags(tag_id)         ON DELETE CASCADE,
    PRIMARY KEY (project_id, tag_id)
);

CREATE TABLE IF NOT EXISTS project_researchers (
    project_id      INTEGER NOT NULL REFERENCES projects(project_id)       ON DELETE CASCADE,
    researcher_id   INTEGER NOT NULL REFERENCES researchers(researcher_id) ON DELETE CASCADE,
    role            TEXT,                          -- "Lead","Contributor","Technical Advisor","Student"
    PRIMARY KEY (project_id, researcher_id, role)
);

-- -----------------------------------------------------------------------------
-- Children of projects
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS project_links (
    link_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id      INTEGER NOT NULL REFERENCES projects(project_id)   ON DELETE CASCADE,
    link_type_id    INTEGER REFERENCES link_types(link_type_id)        ON DELETE SET NULL,
    label           TEXT,
    url             TEXT NOT NULL,
    is_canonical    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS project_attachments (
    attachment_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id      INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    file_name       TEXT    NOT NULL,
    file_path       TEXT,                          -- repo-relative or external
    mime_type       TEXT,
    description     TEXT
);

CREATE TABLE IF NOT EXISTS project_notes (
    note_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id      INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    body            TEXT    NOT NULL,
    author          TEXT,
    created_at      TEXT    DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_projects_title          ON projects(title);
CREATE INDEX IF NOT EXISTS idx_projects_status         ON projects(status_id);
CREATE INDEX IF NOT EXISTS idx_projects_level          ON projects(level_id);
CREATE INDEX IF NOT EXISTS idx_projects_parent         ON projects(parent_project_id);
CREATE INDEX IF NOT EXISTS idx_projects_semester       ON projects(semester);
CREATE INDEX IF NOT EXISTS idx_pd_department           ON project_departments(department_id);
CREATE INDEX IF NOT EXISTS idx_pc_category             ON project_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_pt_tag                  ON project_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_pr_researcher           ON project_researchers(researcher_id);
CREATE INDEX IF NOT EXISTS idx_links_project           ON project_links(project_id);

-- -----------------------------------------------------------------------------
-- Convenience views
-- -----------------------------------------------------------------------------

-- Project with its primary department, status, and level, comma-separated
-- departments / categories / tags for quick reporting.
CREATE VIEW IF NOT EXISTS v_project_overview AS
SELECT
    p.project_id,
    p.title,
    p.summary,
    p.semester,
    s.name  AS status,
    l.name  AS level,
    p.is_meta_project,
    p.primary_url,
    (SELECT GROUP_CONCAT(d.name, '; ')
        FROM project_departments pd
        JOIN departments d ON d.department_id = pd.department_id
        WHERE pd.project_id = p.project_id)             AS departments,
    (SELECT GROUP_CONCAT(c.name, '; ')
        FROM project_categories pc
        JOIN categories c ON c.category_id = pc.category_id
        WHERE pc.project_id = p.project_id)             AS categories,
    (SELECT GROUP_CONCAT(t.name, ', ')
        FROM project_tags pt
        JOIN tags t ON t.tag_id = pt.tag_id
        WHERE pt.project_id = p.project_id)             AS tags
FROM projects p
LEFT JOIN statuses s ON s.status_id = p.status_id
LEFT JOIN levels   l ON l.level_id  = p.level_id;

-- Cross-department overlap: projects belonging to 2+ departments.
CREATE VIEW IF NOT EXISTS v_cross_department_projects AS
SELECT
    p.project_id,
    p.title,
    COUNT(pd.department_id) AS department_count,
    GROUP_CONCAT(d.name, '; ') AS departments
FROM projects p
JOIN project_departments pd ON pd.project_id = p.project_id
JOIN departments d ON d.department_id = pd.department_id
GROUP BY p.project_id
HAVING department_count >= 2;
