-- =============================================================================
-- "Where can this project be found?" -- backfill project_links for every
-- project that doesn't already have one, choosing the most specific URL we
-- already know about.
-- =============================================================================
-- Run AFTER activity_bucket.sql so projects.activity_bucket is populated.
-- Idempotent: skips projects that already have a canonical link, and the
-- 'Where to find' link_type itself is INSERT-OR-IGNORE.
--
-- URL precedence per project:
--   1. The linked GitHub repo's html_url, when present.
--   2. The project's own primary_url, when present.
--   3. The primary department's page URL (for department-research ideas).
--   4. The BBS site root, as a last-resort fallback.
--
-- The label encodes the activity bucket so a UI can render it like a badge:
--   "Started -- live repo"
--   "Finished -- archived deliverable"
--   "Concept -- where it's listed"
--   "Never Started -- proposal home"
-- =============================================================================

PRAGMA foreign_keys = ON;

-- Add a dedicated link type so these auto-generated links can be filtered.
INSERT OR IGNORE INTO link_types (name) VALUES ('Where to find');

-- ---------------------------------------------------------------------------
-- Step 1: Started -- always point to the linked GitHub repo
-- ---------------------------------------------------------------------------
INSERT INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id,
       (SELECT link_type_id FROM link_types WHERE name='Where to find'),
       'Started -- live repo',
       r.html_url,
       0
FROM projects p
JOIN project_github_repos pgr ON pgr.project_id=p.project_id AND pgr.is_primary=1
JOIN github_repos r           ON r.repo_id=pgr.repo_id
WHERE p.activity_bucket='Started'
  AND NOT EXISTS (
        SELECT 1 FROM project_links pl
        JOIN link_types lt ON lt.link_type_id=pl.link_type_id
         WHERE pl.project_id=p.project_id AND lt.name='Where to find'
  );

-- ---------------------------------------------------------------------------
-- Step 2: Finished -- prefer existing primary_url, then linked repo
-- ---------------------------------------------------------------------------
INSERT INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id,
       (SELECT link_type_id FROM link_types WHERE name='Where to find'),
       'Finished -- archived deliverable',
       COALESCE(
            p.primary_url,
            (SELECT r.html_url
               FROM project_github_repos pgr
               JOIN github_repos r ON r.repo_id=pgr.repo_id
              WHERE pgr.project_id=p.project_id AND pgr.is_primary=1
              LIMIT 1),
            'https://sites.google.com/view/balancedblendedspace/projects'
       ),
       0
FROM projects p
WHERE p.activity_bucket='Finished'
  AND NOT EXISTS (
        SELECT 1 FROM project_links pl
        JOIN link_types lt ON lt.link_type_id=pl.link_type_id
         WHERE pl.project_id=p.project_id AND lt.name='Where to find'
  );

-- ---------------------------------------------------------------------------
-- Step 3: Concept -- the project's existing primary_url, then linked repo,
--                    then a sensible department page if available, else
--                    the BBS site root.
-- ---------------------------------------------------------------------------
INSERT INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id,
       (SELECT link_type_id FROM link_types WHERE name='Where to find'),
       'Concept -- where it is listed',
       COALESCE(
            p.primary_url,
            (SELECT r.html_url
               FROM project_github_repos pgr
               JOIN github_repos r ON r.repo_id=pgr.repo_id
              WHERE pgr.project_id=p.project_id AND pgr.is_primary=1
              LIMIT 1),
            (SELECT d.url
               FROM project_departments pd
               JOIN departments d ON d.department_id=pd.department_id
              WHERE pd.project_id=p.project_id AND pd.is_primary=1
              ORDER BY d.url IS NULL
              LIMIT 1),
            'https://sites.google.com/view/balancedblendedspace/home'
       ),
       0
FROM projects p
WHERE p.activity_bucket='Concept'
  AND NOT EXISTS (
        SELECT 1 FROM project_links pl
        JOIN link_types lt ON lt.link_type_id=pl.link_type_id
         WHERE pl.project_id=p.project_id AND lt.name='Where to find'
  );

-- ---------------------------------------------------------------------------
-- Step 4: Never Started -- point to the department's research-ideas page
--                          (these projects came directly off those pages).
-- ---------------------------------------------------------------------------
INSERT INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id,
       (SELECT link_type_id FROM link_types WHERE name='Where to find'),
       'Never Started -- proposal home',
       COALESCE(
            (SELECT d.url
               FROM project_departments pd
               JOIN departments d ON d.department_id=pd.department_id
              WHERE pd.project_id=p.project_id AND pd.is_primary=1
              ORDER BY d.url IS NULL
              LIMIT 1),
            'https://sites.google.com/view/balancedblendedspace/projects/departments'
       ),
       0
FROM projects p
WHERE p.activity_bucket='Never Started'
  AND NOT EXISTS (
        SELECT 1 FROM project_links pl
        JOIN link_types lt ON lt.link_type_id=pl.link_type_id
         WHERE pl.project_id=p.project_id AND lt.name='Where to find'
  );

-- ---------------------------------------------------------------------------
-- Convenience view: "where can I find each project?" -- one row per project,
-- showing its bucket and the first 'Where to find' link.
-- ---------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_project_where_to_find AS
SELECT
    p.project_id,
    p.title,
    p.activity_bucket,
    (SELECT pl.url
       FROM project_links pl
       JOIN link_types lt ON lt.link_type_id=pl.link_type_id
      WHERE pl.project_id=p.project_id
        AND lt.name='Where to find'
      ORDER BY pl.link_id
      LIMIT 1)                                  AS where_to_find,
    (SELECT pl.label
       FROM project_links pl
       JOIN link_types lt ON lt.link_type_id=pl.link_type_id
      WHERE pl.project_id=p.project_id
        AND lt.name='Where to find'
      ORDER BY pl.link_id
      LIMIT 1)                                  AS label
FROM projects p;
