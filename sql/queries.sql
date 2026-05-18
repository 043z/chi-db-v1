-- =============================================================================
-- Balanced Blended Space (BBS) -- Example queries
-- =============================================================================
-- Run after schema.sql + seed.sql have been applied to balanced_blended_space.db.
-- =============================================================================

-- 1) Count projects per department -------------------------------------------
SELECT d.code, d.name, COUNT(pd.project_id) AS project_count
FROM departments d
LEFT JOIN project_departments pd ON pd.department_id = d.department_id
GROUP BY d.department_id
ORDER BY project_count DESC;

-- 2) All projects in a single department (e.g., ENT) -------------------------
SELECT p.title, p.semester, s.name AS status
FROM projects p
JOIN project_departments pd ON pd.project_id = p.project_id
JOIN departments d          ON d.department_id = pd.department_id
LEFT JOIN statuses s        ON s.status_id = p.status_id
WHERE d.code = 'ENT'
ORDER BY p.title;

-- 3) Cross-department projects (touch 2+ departments) ------------------------
SELECT * FROM v_cross_department_projects ORDER BY department_count DESC, title;

-- 4) Find projects tagged with 'AI' AND 'VR' ---------------------------------
SELECT p.title
FROM projects p
WHERE p.project_id IN (
        SELECT pt.project_id FROM project_tags pt
        JOIN tags t ON t.tag_id = pt.tag_id WHERE t.name='AI')
  AND p.project_id IN (
        SELECT pt.project_id FROM project_tags pt
        JOIN tags t ON t.tag_id = pt.tag_id WHERE t.name='VR')
ORDER BY p.title;

-- 5) Projects by COMD level --------------------------------------------------
SELECT l.name AS level, COUNT(*) AS n
FROM projects p
JOIN project_departments pd ON pd.project_id = p.project_id
JOIN departments d          ON d.department_id = pd.department_id
LEFT JOIN levels l          ON l.level_id = p.level_id
WHERE d.code='COMD'
GROUP BY l.level_id
ORDER BY l.sort_order;

-- 6) Researchers and how many cohort projects they lead ----------------------
SELECT r.full_name, COUNT(pr.project_id) AS leads
FROM researchers r
JOIN project_researchers pr ON pr.researcher_id = r.researcher_id
WHERE pr.role IN ('Lead','Student','Technical Advisor')
GROUP BY r.researcher_id
ORDER BY leads DESC, r.full_name;

-- 7) Full overview view -- everything joined together ------------------------
SELECT * FROM v_project_overview ORDER BY title LIMIT 25;

-- 8) Find all projects under a meta-project hierarchy (BSP + descendants) ----
WITH RECURSIVE descendants(project_id, title, depth) AS (
    SELECT project_id, title, 0
    FROM projects WHERE slug='blended-shadow-puppet'
    UNION ALL
    SELECT p.project_id, p.title, d.depth + 1
    FROM projects p
    JOIN descendants d ON p.parent_project_id = d.project_id
)
SELECT depth, title FROM descendants;

-- 9) Projects without any department (orphans) -------------------------------
SELECT p.project_id, p.title
FROM projects p
LEFT JOIN project_departments pd ON pd.project_id = p.project_id
WHERE pd.project_id IS NULL
ORDER BY p.title;

-- 10) Projects by semester ----------------------------------------------------
SELECT semester, COUNT(*) AS n
FROM projects
WHERE semester IS NOT NULL
GROUP BY semester
ORDER BY semester;

-- 11) Top tags by usage -------------------------------------------------------
SELECT t.name, COUNT(pt.project_id) AS uses
FROM tags t
LEFT JOIN project_tags pt ON pt.tag_id = t.tag_id
GROUP BY t.tag_id
ORDER BY uses DESC, t.name;

-- 12) Find a project with all its links ---------------------------------------
SELECT p.title, lt.name AS link_type, pl.label, pl.url
FROM projects p
JOIN project_links pl ON pl.project_id = p.project_id
LEFT JOIN link_types lt ON lt.link_type_id = pl.link_type_id
ORDER BY p.title;
