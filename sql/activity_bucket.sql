-- =============================================================================
-- Activity bucket: every project gets exactly one of
--    Started | Finished | Never Started | Concept
-- =============================================================================
-- Rule:
--   1. If the project is linked to a GitHub repo, use that repo's
--      activity_status (Started / Finished / Never Started).
--   2. Otherwise:
--        status='Archived' or 'Completed'      -> Finished
--        status='Active'                       -> Concept   (no repo means it's not "running")
--        status='Proposed'                     -> Never Started
--        status='Concept'                      -> Concept
--        anything else                         -> Concept
--
-- The column is overwritten every time this file runs, so any manual change
-- you want to preserve should be applied AFTER this file is sourced.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- Reset to a known default so reruns are deterministic
UPDATE projects SET activity_bucket = NULL;

-- ---- Step 1: copy the repo's activity_status onto every linked project
UPDATE projects
   SET activity_bucket = (
        SELECT r.activity_status
          FROM project_github_repos pgr
          JOIN github_repos r ON r.repo_id = pgr.repo_id
         WHERE pgr.project_id = projects.project_id
           AND pgr.is_primary = 1
         LIMIT 1
   )
 WHERE EXISTS (
        SELECT 1 FROM project_github_repos pgr
         WHERE pgr.project_id = projects.project_id
   );

-- ---- Step 2: fill in everything that wasn't linked to a repo
UPDATE projects
   SET activity_bucket = (
        CASE (SELECT name FROM statuses WHERE status_id = projects.status_id)
            WHEN 'Archived'  THEN 'Finished'
            WHEN 'Completed' THEN 'Finished'
            WHEN 'Active'    THEN 'Concept'       -- the rule change you asked for
            WHEN 'Proposed'  THEN 'Never Started'
            WHEN 'Concept'   THEN 'Concept'
            WHEN 'Started'   THEN 'Concept'       -- only set by the linked path; un-link means re-classify
            WHEN 'Finished'  THEN 'Finished'
            WHEN 'Never Started' THEN 'Never Started'
            ELSE 'Concept'
        END
   )
 WHERE activity_bucket IS NULL;

-- ---- Safety net: anything that somehow slipped through becomes Concept
UPDATE projects SET activity_bucket = 'Concept' WHERE activity_bucket IS NULL;

-- ---- Constrain the column to the four valid values via a CHECK on a view
CREATE VIEW IF NOT EXISTS v_project_activity AS
SELECT
    p.project_id,
    p.title,
    p.activity_bucket,
    (SELECT name FROM statuses WHERE status_id = p.status_id)  AS status,
    r.full_name                                                AS repo,
    r.activity_status                                          AS repo_status,
    r.pushed_at                                                AS repo_last_push,
    CASE WHEN pgr.project_id IS NOT NULL THEN 1 ELSE 0 END     AS has_repo
FROM projects p
LEFT JOIN project_github_repos pgr ON pgr.project_id = p.project_id AND pgr.is_primary=1
LEFT JOIN github_repos r           ON r.repo_id      = pgr.repo_id;

CREATE VIEW IF NOT EXISTS v_activity_bucket_summary AS
SELECT activity_bucket, COUNT(*) AS n
FROM projects
GROUP BY activity_bucket
ORDER BY CASE activity_bucket
    WHEN 'Started'       THEN 1
    WHEN 'Finished'      THEN 2
    WHEN 'Never Started' THEN 3
    WHEN 'Concept'       THEN 4
    ELSE 5
END;
