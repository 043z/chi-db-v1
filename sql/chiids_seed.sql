-- =============================================================================
-- CHI²DS taxonomy seed -- every box in the diagram + every Layer + external
-- systems CHIIDS explicitly names, plus backfill tags for everything already
-- in the BBS database.
-- Apply AFTER chiids_schema.sql.
-- =============================================================================

BEGIN TRANSACTION;

-- ----- Cornerstones (the 4 quadrants of CHIIDS_V1.jpg) ----------------------
INSERT OR IGNORE INTO chiids_cornerstones (cornerstone_id, code, name, diagram_number, description) VALUES
    (1, 'mgmt',  'Management',     1, 'Plan and govern meta-projects and subprojects; assign tasks; align voluntary partners with CHI initiatives.'),
    (2, 'comm',  'Communications', 2, 'Real-time collaboration, status flow, and public engagement across teams and semesters.'),
    (3, 'store', 'Storage',        3, 'Documentation, deliverables, code, and media -- versioning, retrieval, and archival.'),
    (4, 'int',   'Integration',    4, 'Connectors to external systems: GitHub, OpenLab, Zotero, WorldAnvil, City Tech platforms.');

-- ----- Layers (Layer 0..3 from the README) ----------------------------------
INSERT OR IGNORE INTO chiids_layers (layer_id, name, short_name, description) VALUES
    (0, 'Structural Framework', 'L0', 'Schema, ontology, organizational rules. Lives in META-CHIIDS.'),
    (1, 'Meta-Projects',        'L1', 'Permanent meta-projects (BBS, BRPS, CAI...) under CHI-CityTech org.'),
    (2, 'Coordination',         'L2', 'Semester-based research assignments and tracking (StudentResearch repo).'),
    (3, 'Execution',            'L3', 'Individual team repositories where work actually happens.');

-- ----- Concepts: one per leaf in the diagram --------------------------------
INSERT OR IGNORE INTO chiids_concepts (code, name, cornerstone_id, diagram_section, description) VALUES
    -- 1. Management
    ('project_1_n',           'Project 1 ... Project n',     1, '1',   'Individual projects under a meta-project. Maps to our `projects` table.'),
    -- 2. Communications
    ('comm_internal',         'Internal Communication',      2, '2.1', 'Project Communication + Meta-Project Coordination.'),
    ('project_communication', 'Project Communication',       2, '2.1', 'Per-project chat / async threads.'),
    ('meta_proj_coordination','Meta-Project Coordination',   2, '2.1', 'Cross-team meta-project sync.'),
    ('extra_chi_comm',        'Extra-CHI communication',     2, '2.1', 'Communication with partners outside CHI.'),
    ('comm_public',           'Public Communication',        2, '2.2', 'Website + Social Media + Research Opportunities.'),
    ('website',               'Website',                     2, '2.2', 'Public-facing site (OpenLab/WordPress per CHIIDS).'),
    ('social_media',          'Social Media',                2, '2.2', 'Public posting channels.'),
    ('research_opportunities','Research Opportunities',      2, '2.2', 'Calls for student/faculty participation.'),
    -- 3. Storage
    ('doc_repository',        'Documentation Repository',    3, '3.1', 'Project documents organized for retrieval.'),
    ('project_documents',     'Project Documents',           3, '3.1', 'Individual deliverables/papers tied to a project.'),
    ('archiving',             'Archiving',                   3, '3.2', 'Long-term preservation of project outputs.'),
    ('living_archive',        'Living Archive',              3, '3.2', 'Continuously curated reference material.'),
    ('operational_archives',  'Operational Archives',        3, '3.2', 'Day-to-day artifacts kept for the team.'),
    ('project_archives',      'Project Archives',            3, '3.2', 'Per-project archival bundle.'),
    ('research_repository',   'Research Repository',         3, '3.2', 'Long-term store of research outputs.'),
    ('virtual_worlds',        'Virtual Worlds',              3, '3.2', 'Virtual environments produced by projects.'),
    ('version_control',       'Version Control',             3, '3.2', 'Git / GitHub history.'),
    ('meta_proj_assessment',  'Meta-Project Assessment',     3, '3.2', 'Periodic evaluation of meta-projects.'),
    -- 4. Integration
    ('external_systems',      'External Systems',            4, '4',   'Generic boundary between CHIIDS and outside systems.');

-- ----- Lifecycle stages (CHIIDS README: proposal -> active -> archival) ----
INSERT OR IGNORE INTO lifecycle_stages (stage_id, name, sort_order, description) VALUES
    (1, 'Proposal',        1, 'Theoretical proposal; not yet active.'),
    (2, 'Active Research', 2, 'Currently being worked on by a team.'),
    (3, 'Archival',        3, 'Long-term archival; work complete or paused.');

-- ----- Meta-project types (the README names three) --------------------------
INSERT OR IGNORE INTO meta_project_types (type_id, name, description) VALUES
    (1, 'Theory',                  'Foundational theoretical framework (e.g. BBS).'),
    (2, 'Engineering',             'Practical/engineering test platform (e.g. BRPS).'),
    (3, 'AI/Human Collaboration',  'Partnership models for human-AI co-creation (e.g. CAI).'),
    (4, 'Practice',                'Applied creative/performance project (e.g. BSP meta).'),
    (5, 'Infrastructure',          'Cross-cutting framework / system (e.g. CHIIDS itself).');

-- ----- External systems CHIIDS explicitly names -----------------------------
INSERT OR IGNORE INTO chiids_external_systems (code, name, homepage_url, description) VALUES
    ('github',         'GitHub',         'https://github.com',          'Source control + issue tracker; Layer-3 execution repos and metadata.'),
    ('openlab',        'OpenLab',        'https://openlab.citytech.cuny.edu', 'City Tech OpenLab public site / WordPress.'),
    ('worldanvil',     'WorldAnvil',     'https://www.worldanvil.com',  'Public world-building platform used by the BSP meta-project.'),
    ('zotero',         'Zotero',         'https://www.zotero.org',      'Citation library group.'),
    ('ojs',            'OJS',            'https://pkp.sfu.ca/ojs/',     'Open Journal Systems for CHI Publications.'),
    ('zenodo',         'Zenodo',         'https://zenodo.org',          'DOI minting and long-term archive.'),
    ('wordpress',      'WordPress',      'https://wordpress.com',       'Public-facing CHI website host.'),
    ('citytech',       'City Tech',      'https://www.citytech.cuny.edu', 'Institutional systems at NYC College of Technology.');

-- =============================================================================
-- NEW META-PROJECT ROWS DERIVED FROM THE CHIIDS README
-- =============================================================================

-- ---- Collaborative AI (CAI): named meta-project; AI/Human Collaboration type
INSERT OR IGNORE INTO projects (title, slug, summary, description, status_id, is_meta_project, primary_url)
VALUES (
    'Collaborative AI (CAI)',
    'collaborative-ai',
    'Meta-project: partnership models for human-AI co-creation.',
    'One of the three named meta-projects in the CHIIDS framework. Explores AI as a collaborative partner rather than a tool, across CHI research initiatives.',
    (SELECT status_id FROM statuses WHERE name='Active'),
    1,
    'https://github.com/CHI-CityTech/META-Collaborative-AI'
);

-- ---- CHIIDS Framework itself (Layer 0 / Infrastructure)
INSERT OR IGNORE INTO projects (title, slug, summary, description, status_id, is_meta_project, primary_url)
VALUES (
    'CHIIDS Framework',
    'chiids-framework',
    'Structural framework that organizes all CHI meta-projects (Layer 0).',
    'CHI Integrated Digital System. Defines schema, ontology, META-* Project Class pattern, and the cornerstones+layers model that every other CHI project conforms to. The BBS database is one component within this framework.',
    (SELECT status_id FROM statuses WHERE name='Active'),
    1,
    'https://github.com/CHI-CityTech/META-CHIIDS'
);

-- ---- Link the new META-CAI project to its GitHub repo (if seeded)
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-slug', 0.95
FROM projects p, github_repos r
WHERE p.slug='collaborative-ai' AND r.full_name='CHI-CityTech/META-Collaborative-AI';

-- ---- CHIIDS docs as project_links on the CHIIDS Framework project
INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='GitHub'), 'META-CHIIDS Repo', 'https://github.com/CHI-CityTech/META-CHIIDS', 1
FROM projects p WHERE p.slug='chiids-framework';

INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='Other'), 'Original Specification', 'https://github.com/CHI-CityTech/META-CHIIDS/blob/main/project/architecture/chiids_original_spec.md', 0
FROM projects p WHERE p.slug='chiids-framework';

INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='Other'), 'Repository Authority Model', 'https://github.com/CHI-CityTech/META-CHIIDS/blob/main/project/AUTHORITY-MODEL.md', 0
FROM projects p WHERE p.slug='chiids-framework';

INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='Other'), 'Developmental Roadmap', 'https://github.com/CHI-CityTech/META-CHIIDS/blob/main/project/ROADMAP.md', 0
FROM projects p WHERE p.slug='chiids-framework';

INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='Other'), 'Architecture Overview', 'https://github.com/CHI-CityTech/META-CHIIDS/blob/main/docs/architecture', 0
FROM projects p WHERE p.slug='chiids-framework';

INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='Other'), 'Glossary', 'https://github.com/CHI-CityTech/META-CHIIDS/blob/main/project/GLOSSARY.md', 0
FROM projects p WHERE p.slug='chiids-framework';

INSERT OR IGNORE INTO project_links (project_id, link_type_id, label, url, is_canonical)
SELECT p.project_id, (SELECT link_type_id FROM link_types WHERE name='GitHub'), 'StudentResearch (L2 Coordination)', 'https://github.com/CHI-CityTech/StudentResearch', 0
FROM projects p WHERE p.slug='chiids-framework';

-- ---- Meta-project type assignments (the README names these three explicitly)
UPDATE projects SET meta_project_type_id = (SELECT type_id FROM meta_project_types WHERE name='Theory')
 WHERE slug = 'bbs-theory';

UPDATE projects SET meta_project_type_id = (SELECT type_id FROM meta_project_types WHERE name='Engineering')
 WHERE slug = 'brps';

UPDATE projects SET meta_project_type_id = (SELECT type_id FROM meta_project_types WHERE name='AI/Human Collaboration')
 WHERE slug = 'collaborative-ai';

UPDATE projects SET meta_project_type_id = (SELECT type_id FROM meta_project_types WHERE name='Practice')
 WHERE slug IN ('blended-shadow-puppet','world-building');

UPDATE projects SET meta_project_type_id = (SELECT type_id FROM meta_project_types WHERE name='Infrastructure')
 WHERE slug = 'chiids-framework';

UPDATE projects SET meta_project_type_id = (SELECT type_id FROM meta_project_types WHERE name='Theory')
 WHERE slug = 'bbs-syntax';

-- ---- Lifecycle-stage backfill rule:
--      status 'Proposed' / 'Concept'  -> lifecycle 'Proposal'
--      status 'Active' / 'Started'    -> lifecycle 'Active Research'
--      status 'Completed' / 'Archived' / 'Finished' / 'Never Started' -> 'Archival'
-- (Done as a CASE so it's idempotent and any future status updates are honored.)
UPDATE projects
   SET lifecycle_stage_id = (
        CASE (SELECT name FROM statuses WHERE status_id = projects.status_id)
            WHEN 'Proposed'      THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Proposal')
            WHEN 'Concept'       THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Proposal')
            WHEN 'Active'        THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Active Research')
            WHEN 'Started'       THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Active Research')
            WHEN 'Completed'     THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Archival')
            WHEN 'Archived'      THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Archival')
            WHEN 'Finished'      THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Archival')
            WHEN 'Never Started' THEN (SELECT stage_id FROM lifecycle_stages WHERE name='Proposal')
            ELSE NULL
        END
   )
 WHERE lifecycle_stage_id IS NULL;

-- =============================================================================
-- BACKFILL: tag everything already in the BBS database with CHIIDS coordinates
-- =============================================================================

-- ---- Every project is, by definition, a Management/Layer-1 (or L3) artifact
-- Meta-projects + parents land in Layer 1; everything else lands in Layer 3.
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'project', p.project_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='mgmt'),
       CASE WHEN p.is_meta_project = 1 THEN 1 ELSE 3 END,
       (SELECT concept_id FROM chiids_concepts WHERE code='project_1_n'),
       'auto-rule', 1.0
FROM projects p;

-- ---- Every project_link goes under Storage / Documentation Repository
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'project_link', pl.link_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='store'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='project_documents'),
       'auto-rule', 1.0
FROM project_links pl;

-- ---- Every project_attachment also goes under Documentation Repository
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'project_attachment', a.attachment_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='store'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='project_documents'),
       'auto-rule', 1.0
FROM project_attachments a;

-- ---- Every github_repo is BOTH Integration (External Systems) and
--      Storage (Version Control), Layer 3.
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'github_repo', r.repo_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='int'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='external_systems'),
       'auto-rule', 1.0
FROM github_repos r;

INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'github_repo', r.repo_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='store'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='version_control'),
       'auto-rule', 1.0
FROM github_repos r;

-- ---- META-* repos are Layer 1, not Layer 3. Override.
UPDATE chiids_artifact_tags
   SET layer_id = 1
 WHERE artifact_type='github_repo'
   AND artifact_id IN (SELECT repo_id FROM github_repos WHERE name LIKE 'META-%');

-- ---- The CHI-CityTech.github.io repo and CHI-Admin etc. belong to L2 coord
UPDATE chiids_artifact_tags
   SET layer_id = 2
 WHERE artifact_type='github_repo'
   AND artifact_id IN (SELECT repo_id FROM github_repos
                        WHERE name IN ('CHI-CityTech.github.io','CHI-Admin','CHI-StudentResearch','CHI-Grants','CHI-Research-Template'));

-- ---- CHIIDS Framework project is Layer 0 (not the default L1)
UPDATE chiids_artifact_tags
   SET layer_id = 0
 WHERE artifact_type='project'
   AND artifact_id = (SELECT project_id FROM projects WHERE slug='chiids-framework');

-- ---- Site-builder (the sql.js page we publish to GitHub Pages) is Public
-- Communications. We don't have a row for it in projects, so represent it as
-- a project tagged 'BBS Theory' for now -- the real CHIIDS website would be
-- a separate artifact_type once it exists.
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence, notes)
SELECT 'project', p.project_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='comm'),
       2,
       (SELECT concept_id FROM chiids_concepts WHERE code='website'),
       'manual', 1.0,
       'BBS sql.js GitHub Pages site lives under BBS Theory project'
FROM projects p WHERE p.slug='bbs-theory';

-- ---- Pending submissions from the github-scan source are Storage/Doc-Repo
-- candidates (they came out of repo READMEs).
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'pending_submission', s.submission_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='store'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='project_documents'),
       'auto-rule', 0.9
FROM pending_submissions s
WHERE s.source = 'github-scan';

-- ---- Form submissions are Management candidates (proposed new projects)
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'pending_submission', s.submission_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='mgmt'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='project_1_n'),
       'auto-rule', 1.0
FROM pending_submissions s
WHERE s.source = 'form';

-- ---- Link projects to the external systems their URLs imply (best-effort).
INSERT OR IGNORE INTO project_external_systems (project_id, system_id, notes)
SELECT DISTINCT pl.project_id,
       CASE
         WHEN pl.url LIKE '%github.com%'       THEN (SELECT system_id FROM chiids_external_systems WHERE code='github')
         WHEN pl.url LIKE '%dropbox.com%'      THEN NULL  -- not in CHIIDS-named list
         WHEN pl.url LIKE '%docs.google.com%'  THEN NULL
         WHEN pl.url LIKE '%suno.com%'         THEN NULL
         WHEN pl.url LIKE '%openlab%'          THEN (SELECT system_id FROM chiids_external_systems WHERE code='openlab')
         WHEN pl.url LIKE '%worldanvil.com%'   THEN (SELECT system_id FROM chiids_external_systems WHERE code='worldanvil')
         WHEN pl.url LIKE '%zotero%'           THEN (SELECT system_id FROM chiids_external_systems WHERE code='zotero')
         WHEN pl.url LIKE '%zenodo%'           THEN (SELECT system_id FROM chiids_external_systems WHERE code='zenodo')
         WHEN pl.url LIKE '%academicworks%'    THEN NULL
         ELSE NULL
       END,
       pl.url
FROM project_links pl
WHERE CASE
        WHEN pl.url LIKE '%github.com%'     THEN (SELECT system_id FROM chiids_external_systems WHERE code='github')
        WHEN pl.url LIKE '%openlab%'        THEN (SELECT system_id FROM chiids_external_systems WHERE code='openlab')
        WHEN pl.url LIKE '%worldanvil.com%' THEN (SELECT system_id FROM chiids_external_systems WHERE code='worldanvil')
        WHEN pl.url LIKE '%zotero%'         THEN (SELECT system_id FROM chiids_external_systems WHERE code='zotero')
        WHEN pl.url LIKE '%zenodo%'         THEN (SELECT system_id FROM chiids_external_systems WHERE code='zenodo')
        ELSE NULL
      END IS NOT NULL;

-- ---- Also wire up the auto-extracted "external links" in github-scan submissions
-- (WorldAnvil URL from the BSP META README is a good example).
-- The data lives in pending_submissions.extra_links_raw; we can't easily parse
-- here in SQL, but we record a tag so the artifact shows up under Integration.
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence, notes)
SELECT 'pending_submission', s.submission_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='int'),
       3,
       (SELECT concept_id FROM chiids_concepts WHERE code='external_systems'),
       'auto-rule', 0.7,
       'extra_links_raw contains non-github external URLs'
FROM pending_submissions s
WHERE s.extra_links_raw IS NOT NULL
  AND s.extra_links_raw LIKE '%http%';

COMMIT;
