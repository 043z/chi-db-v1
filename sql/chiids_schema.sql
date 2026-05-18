-- =============================================================================
-- CHI²DS (CHIIDS) taxonomy add-on
-- =============================================================================
-- This adds two orthogonal coordinate systems borrowed from the CHIIDS spec:
--
--   1. "Cornerstones" -- the four functional branches of the CHIIDS quadrant
--      diagram: Management, Communications, Storage, Integration.
--
--   2. "Layers" -- the four-layer model: Structural Framework (0),
--      Meta-Projects (1), Coordination (2), Execution (3).
--
-- Plus fine-grained "concepts" (one row per leaf box in the diagram) and a
-- generic m:n "artifact" join so any project / link / repo / submission can
-- be tagged with the CHIIDS coordinates it serves.
--
-- Source: https://github.com/CHI-CityTech/META-CHIIDS  (README + CHIIDS_V1 map)
-- Philosophy: "Integration over Creation" -- we do not duplicate CHIIDS' own
-- relational schema; we just give every artifact in our DB a CHIIDS coordinate
-- so the data here can be cross-referenced with their system later.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- ----- Cornerstones (4 rows) -------------------------------------------------
CREATE TABLE IF NOT EXISTS chiids_cornerstones (
    cornerstone_id   INTEGER PRIMARY KEY,
    code             TEXT NOT NULL UNIQUE,         -- 'mgmt','comm','store','int'
    name             TEXT NOT NULL,                -- 'Management','Communications',...
    diagram_number   INTEGER,                      -- 1..4 from the diagram
    description      TEXT
);

-- ----- Layers (4 rows) -------------------------------------------------------
CREATE TABLE IF NOT EXISTS chiids_layers (
    layer_id        INTEGER PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,          -- 'Structural Framework',...
    short_name      TEXT NOT NULL UNIQUE,          -- 'L0','L1','L2','L3'
    description     TEXT
);

-- ----- Concepts (one per leaf in the diagram) --------------------------------
-- e.g. 'Living Archive', 'Public Website', 'Project Documents', 'WorldAnvil'
CREATE TABLE IF NOT EXISTS chiids_concepts (
    concept_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    code            TEXT NOT NULL UNIQUE,          -- machine slug
    name            TEXT NOT NULL,                 -- human label from the diagram
    cornerstone_id  INTEGER REFERENCES chiids_cornerstones(cornerstone_id) ON DELETE SET NULL,
    diagram_section TEXT,                          -- '1','2.1','3.2','4', etc.
    description     TEXT
);

CREATE INDEX IF NOT EXISTS idx_concepts_cornerstone ON chiids_concepts(cornerstone_id);

-- ----- External systems known to CHIIDS -------------------------------------
-- The README explicitly names GitHub, OpenLab/WordPress, OJS, Zenodo,
-- Zotero, WorldAnvil, plus City Tech platforms. These live under Cornerstone
-- "Integration" (and several also feed Storage / Communications).
CREATE TABLE IF NOT EXISTS chiids_external_systems (
    system_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    code            TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    homepage_url    TEXT,
    description     TEXT
);

-- ----- Generic artifact tagging ---------------------------------------------
-- An "artifact" is any row anywhere in our DB that we want to give a CHIIDS
-- coordinate to. We don't reference foreign keys with hard FKs because the
-- target table varies; instead we record artifact_type + artifact_id and
-- let queries JOIN as needed. This is the standard polymorphic-tag pattern.
CREATE TABLE IF NOT EXISTS chiids_artifact_tags (
    tag_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    artifact_type   TEXT    NOT NULL CHECK (artifact_type IN (
                        'project','project_link','project_attachment','project_note',
                        'github_repo','pending_submission','researcher','tag','department'
                    )),
    artifact_id     INTEGER NOT NULL,
    cornerstone_id  INTEGER REFERENCES chiids_cornerstones(cornerstone_id) ON DELETE SET NULL,
    layer_id        INTEGER REFERENCES chiids_layers(layer_id)             ON DELETE SET NULL,
    concept_id      INTEGER REFERENCES chiids_concepts(concept_id)         ON DELETE SET NULL,
    confidence      REAL,                          -- 0..1; manual=1.0, auto-tag=lower
    source          TEXT NOT NULL DEFAULT 'manual' -- 'manual' | 'auto-rule' | 'sync'
                       CHECK (source IN ('manual','auto-rule','sync')),
    notes           TEXT,
    created_at      TEXT DEFAULT (datetime('now')),
    UNIQUE(artifact_type, artifact_id, cornerstone_id, layer_id, concept_id)
);

CREATE INDEX IF NOT EXISTS idx_artifact_tags_artifact   ON chiids_artifact_tags(artifact_type, artifact_id);
CREATE INDEX IF NOT EXISTS idx_artifact_tags_cornerstone ON chiids_artifact_tags(cornerstone_id);
CREATE INDEX IF NOT EXISTS idx_artifact_tags_layer       ON chiids_artifact_tags(layer_id);
CREATE INDEX IF NOT EXISTS idx_artifact_tags_concept     ON chiids_artifact_tags(concept_id);

-- ----- Lifecycle stages (from the CHIIDS README) ----------------------------
-- "from theoretical proposal through active research to long-term archival"
CREATE TABLE IF NOT EXISTS lifecycle_stages (
    stage_id        INTEGER PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    sort_order      INTEGER NOT NULL,
    description     TEXT
);

-- ----- Meta-project types (categorizing META-* projects) ---------------------
-- The README labels BBS as 'Theory', BRPS as 'Engineering',
-- CAI  as 'AI/Human Collaboration'. This is intrinsic to the meta-project.
CREATE TABLE IF NOT EXISTS meta_project_types (
    type_id         INTEGER PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    description     TEXT
);

-- ----- A simple "which external systems does a project use?" join ----------
CREATE TABLE IF NOT EXISTS project_external_systems (
    project_id      INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    system_id       INTEGER NOT NULL REFERENCES chiids_external_systems(system_id) ON DELETE CASCADE,
    notes           TEXT,
    PRIMARY KEY (project_id, system_id)
);

-- =============================================================================
-- Convenience views
-- =============================================================================

-- One row per project with its CHIIDS coordinates (deduplicated lists).
CREATE VIEW IF NOT EXISTS v_project_chiids AS
SELECT
    p.project_id,
    p.title,
    (SELECT GROUP_CONCAT(DISTINCT c.name)
       FROM chiids_artifact_tags t
       JOIN chiids_cornerstones c ON c.cornerstone_id = t.cornerstone_id
      WHERE t.artifact_type='project' AND t.artifact_id = p.project_id) AS cornerstones,
    (SELECT GROUP_CONCAT(DISTINCT l.short_name)
       FROM chiids_artifact_tags t
       JOIN chiids_layers l ON l.layer_id = t.layer_id
      WHERE t.artifact_type='project' AND t.artifact_id = p.project_id) AS layers,
    (SELECT GROUP_CONCAT(DISTINCT cc.name)
       FROM chiids_artifact_tags t
       JOIN chiids_concepts cc ON cc.concept_id = t.concept_id
      WHERE t.artifact_type='project' AND t.artifact_id = p.project_id) AS concepts
FROM projects p;

-- Coverage report: how many artifacts of each type live under each cornerstone.
CREATE VIEW IF NOT EXISTS v_chiids_coverage AS
SELECT
    cs.name                          AS cornerstone,
    t.artifact_type                  AS artifact_type,
    COUNT(*)                         AS n
FROM chiids_artifact_tags t
JOIN chiids_cornerstones cs ON cs.cornerstone_id = t.cornerstone_id
GROUP BY cs.cornerstone_id, t.artifact_type
ORDER BY cs.diagram_number, t.artifact_type;

-- Same but split by layer.
CREATE VIEW IF NOT EXISTS v_chiids_layer_coverage AS
SELECT
    l.short_name                     AS layer,
    l.name                           AS layer_name,
    t.artifact_type                  AS artifact_type,
    COUNT(*)                         AS n
FROM chiids_artifact_tags t
JOIN chiids_layers l ON l.layer_id = t.layer_id
GROUP BY l.layer_id, t.artifact_type
ORDER BY l.layer_id, t.artifact_type;
