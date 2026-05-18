-- =============================================================================
-- Initial GitHub seed for CHI-CityTech repos
-- =============================================================================
-- Snapshot of repos observed on https://github.com/CHI-CityTech (May 2026).
-- Statuses are first-pass heuristic guesses; sync_github.py will refresh
-- them with live data when it runs from GitHub Actions.
-- Apply AFTER github_schema.sql.
-- =============================================================================

BEGIN TRANSACTION;

-- ---- Repos --------------------------------------------------------------
INSERT OR IGNORE INTO github_repos (
    full_name, name, org, description, html_url,
    is_fork, is_archived, is_template, is_empty, has_releases,
    primary_language, license, stargazers_count, forks_count,
    open_issues_count, open_pulls_count, pushed_at,
    activity_status, activity_reason
) VALUES
    -- Active (recent pushes within ~12 months, commits + issues/PRs)
    ('CHI-CityTech/CHI-StudentResearch',                'CHI-StudentResearch','CHI-CityTech','Repository for student research proposals and activities across all CHI Meta-projects.','https://github.com/CHI-CityTech/CHI-StudentResearch',
        0,0,0,0,0,'Shell',NULL,0,2,43,0,'2026-05-15','Started','recent activity + 43 open issues'),
    ('CHI-CityTech/SEID-2364','SEID-2364','CHI-CityTech','Societal and Ethical Impacts of Data Science -- SEID 2364 at Modul University Vienna.','https://github.com/CHI-CityTech/SEID-2364',
        0,0,0,0,0,'Python',NULL,0,0,0,0,'2026-05-14','Started','recent activity (pushed 2026-05-14)'),
    ('CHI-CityTech/Unity-BSP','Unity-BSP','CHI-CityTech','The repository that has the Unity Project extension','https://github.com/CHI-CityTech/Unity-BSP',
        0,0,0,0,0,'C#',NULL,0,1,0,0,'2026-05-13','Started','recent activity (pushed 2026-05-13)'),
    ('CHI-CityTech/CHI-CityTech.github.io','CHI-CityTech.github.io','CHI-CityTech','For the CHI Website','https://github.com/CHI-CityTech/CHI-CityTech.github.io',
        0,0,0,0,0,'HTML',NULL,0,0,0,0,'2026-05-09','Started','recent activity (pushed 2026-05-09)'),
    ('CHI-CityTech/META-CHIIDS','META-CHIIDS','CHI-CityTech','Center for Holistic Integration Integrated Digital System','https://github.com/CHI-CityTech/META-CHIIDS',
        0,0,0,0,0,'JavaScript','MIT',0,0,5,0,'2026-05-03','Started','recent activity + open issues'),
    ('CHI-CityTech/Documentary','Documentary','CHI-CityTech','This repository stores assets and planning for documentary development','https://github.com/CHI-CityTech/Documentary',
        0,0,0,0,0,NULL,NULL,0,1,1,0,'2026-04-18','Started','recent activity (pushed 2026-04-18)'),
    ('CHI-CityTech/META-Collaborative-AI','META-Collaborative-AI','CHI-CityTech','Curriculum and materials for exploring AI as a partner rather than a tool.','https://github.com/CHI-CityTech/META-Collaborative-AI',
        0,0,0,0,0,NULL,NULL,1,0,0,0,'2026-04-07','Started','recent activity (pushed 2026-04-07)'),
    ('CHI-CityTech/AI-Curriculum','AI-Curriculum','CHI-CityTech','A repository to hold syllabi, instructional design, and other resources from CHI initiaitves','https://github.com/CHI-CityTech/AI-Curriculum',
        0,0,0,0,0,NULL,'CC0-1.0',0,0,0,0,'2026-03-25','Started','recent activity (pushed 2026-03-25)'),
    ('CHI-CityTech/BABS','BABS','CHI-CityTech','Bio-Aware Blended Spaces','https://github.com/CHI-CityTech/BABS',
        0,0,0,0,0,'Shell','MIT',0,1,41,0,'2026-03-18','Started','recent activity + 41 open issues'),
    ('CHI-CityTech/META-Blended-Reality-Performance-System','META-Blended-Reality-Performance-System','CHI-CityTech','A modular system designed to investigate Balanced Blended Space in the performing arts.','https://github.com/CHI-CityTech/META-Blended-Reality-Performance-System',
        0,0,0,0,0,NULL,NULL,1,0,23,0,'2026-03-11','Started','recent activity + 23 open issues'),
    ('CHI-CityTech/Blended-Shadow-Puppet-Theatre','Blended-Shadow-Puppet-Theatre','CHI-CityTech','Overarching repository for all projects supporting the theatrical component of the BSP project.','https://github.com/CHI-CityTech/Blended-Shadow-Puppet-Theatre',
        0,0,0,0,0,'AppleScript',NULL,0,0,0,0,'2026-03-10','Started','recent activity (pushed 2026-03-10)'),
    ('CHI-CityTech/.github','.github','CHI-CityTech','Org profile README','https://github.com/CHI-CityTech/.github',
        0,0,0,0,0,NULL,NULL,0,0,0,0,'2026-02-12','Started','org profile'),
    ('CHI-CityTech/Personalized-LLM','Personalized-LLM','CHI-CityTech','Optimizing small specialized LLMs for tasks within the Blended Shadow Puppet Universe.','https://github.com/CHI-CityTech/Personalized-LLM',
        0,0,0,0,0,'Shell','MIT',0,2,28,1,'2026-02-02','Started','recent activity + 28 open issues + 1 PR'),
    ('CHI-CityTech/CHI-Admin','CHI-Admin','CHI-CityTech','Materials used for CHI Administrative projects and activities','https://github.com/CHI-CityTech/CHI-Admin',
        0,0,0,0,0,'HTML',NULL,0,1,5,0,'2026-01-20','Started','recent activity + 5 open issues'),
    ('CHI-CityTech/Blended-Classroom','Blended-Classroom','CHI-CityTech','Developing Blended Environments for an integrated classroom in Blended Space','https://github.com/CHI-CityTech/Blended-Classroom',
        0,0,0,0,0,NULL,'MIT',0,0,0,0,'2026-01-18','Started','recent activity (pushed 2026-01-18)'),
    ('CHI-CityTech/AVMI-GVSC-SoundSystem','AVMI-GVSC-SoundSystem','CHI-CityTech','AVMI-GVSC10-2024 Project: Sound System Modeling, Simulation, and Integration.','https://github.com/CHI-CityTech/AVMI-GVSC-SoundSystem',
        0,0,0,0,0,'Python',NULL,0,0,3,1,'2025-12-17','Started','recent activity + open issues/PR'),
    ('CHI-CityTech/Shadow_puppet_Unreal','Shadow_puppet_Unreal','CHI-CityTech',NULL,'https://github.com/CHI-CityTech/Shadow_puppet_Unreal',
        0,0,0,0,0,NULL,NULL,0,0,6,0,'2025-12-11','Started','recent activity + 6 open issues'),
    ('CHI-CityTech/QuantumMusic','QuantumMusic','CHI-CityTech','Quantum computing applied to generating composer-consistent musical output.','https://github.com/CHI-CityTech/QuantumMusic',
        0,0,0,0,0,'Python',NULL,2,1,2,0,'2025-12-11','Started','recent activity + open issues'),
    ('CHI-CityTech/META-Balanced-Blended-Space','META-Balanced-Blended-Space','CHI-CityTech','Universal theoretical framework integrating physical, virtual, and conceptual spaces.','https://github.com/CHI-CityTech/META-Balanced-Blended-Space',
        0,0,0,0,0,NULL,'MIT',2,0,12,0,'2025-12-03','Started','recent activity + 12 open issues'),
    ('CHI-CityTech/META-Blended-Shadow-Puppet','META-Blended-Shadow-Puppet','CHI-CityTech','BSP Meta-project: shadow puppet tradition with 21st century technologies.','https://github.com/CHI-CityTech/META-Blended-Shadow-Puppet',
        0,0,0,0,0,NULL,NULL,2,6,36,0,'2025-11-30','Started','recent activity + 36 open issues + 6 forks'),
    ('CHI-CityTech/Shadows-and-Light','Shadows-and-Light','CHI-CityTech','Game development based on light/dark and foreground/background ambiguity.','https://github.com/CHI-CityTech/Shadows-and-Light',
        0,0,0,0,0,'Shell','MIT',0,0,13,0,'2025-11-24','Started','recent activity + 13 open issues'),
    ('CHI-CityTech/Physics-of-Everything','Physics-of-Everything','CHI-CityTech','Developing a course for non-physics majors.','https://github.com/CHI-CityTech/Physics-of-Everything',
        0,0,0,0,0,NULL,NULL,0,0,0,0,'2025-11-18','Started','recent activity (pushed 2025-11-18)'),
    ('CHI-CityTech/CHI-Research-Template','CHI-Research-Template','CHI-CityTech',NULL,'https://github.com/CHI-CityTech/CHI-Research-Template',
        0,0,1,0,0,'Shell','MIT',0,2,0,2,'2025-11-05','Started','template repo, recent activity'),
    ('CHI-CityTech/META-UNESCO','META-UNESCO','CHI-CityTech','Investigations in the integration of UNESCO heritage','https://github.com/CHI-CityTech/META-UNESCO',
        0,0,0,0,0,'Shell','MIT',0,0,1,0,'2025-10-30','Started','recent activity (pushed 2025-10-30)'),
    ('CHI-CityTech/Collaborative-AI-in-Healthcare','Collaborative-AI-in-Healthcare','CHI-CityTech',NULL,'https://github.com/CHI-CityTech/Collaborative-AI-in-Healthcare',
        0,0,0,0,0,'Shell','MIT',1,0,15,0,'2025-10-14','Started','recent activity + 15 open issues'),
    ('CHI-CityTech/CHI-Grants','CHI-Grants','CHI-CityTech','Materials related to research, acquisition, and management of CHI grant activities.','https://github.com/CHI-CityTech/CHI-Grants',
        0,0,0,0,0,'Python',NULL,0,0,0,0,'2025-10-07','Started','recent activity (pushed 2025-10-07)'),
    ('CHI-CityTech/Hammer','Hammer','CHI-CityTech','Reginald Fairly''s Spring 2025 project.','https://github.com/CHI-CityTech/Hammer',
        0,0,0,0,0,NULL,NULL,0,0,11,0,'2025-06-28','Started','11 open issues, no push since June 2025'),
    ('CHI-CityTech/META-International-collaboration','META-International-collaboration','CHI-CityTech','Assets and designs promoting international collaboration.','https://github.com/CHI-CityTech/META-International-collaboration',
        0,0,0,0,0,NULL,'MIT',0,0,0,0,'2025-06-06','Started','no push since June 2025'),
    ('CHI-CityTech/BBS-Personal-LLM','BBS-Personal-LLM','CHI-CityTech','Investigating personal LLMs deployed within Balanced Blended Space','https://github.com/CHI-CityTech/BBS-Personal-LLM',
        0,0,0,0,0,NULL,NULL,0,0,0,0,'2025-06-01','Started','no push since June 2025'),
    ('CHI-CityTech/Blended_Music','Blended_Music','CHI-CityTech','Research and music created as fused integrations between two or more musical traditions.','https://github.com/CHI-CityTech/Blended_Music',
        0,0,0,0,0,NULL,'MIT',0,0,0,0,'2025-05-31','Started','no push since May 2025');

-- ---- Auto-link to existing projects where the title matches ----------------
-- Each row here is a direct manual link recorded by sync_github.py-equivalent logic,
-- so they survive future syncs. Statuses on the linked projects update to match
-- the repo's activity_status (only if the project was still 'Proposed' / 'Concept').

-- QuantumMusic -> existing seed project
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-slug', 1.0
FROM projects p, github_repos r
WHERE p.title='Quantum Music' AND r.full_name='CHI-CityTech/QuantumMusic';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE title='Quantum Music'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Active'));

-- META-Balanced-Blended-Space -> BBS Theory
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-fuzzy', 0.85
FROM projects p, github_repos r
WHERE p.slug='bbs-theory' AND r.full_name='CHI-CityTech/META-Balanced-Blended-Space';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE slug='bbs-theory'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept'));

-- META-Blended-Reality-Performance-System -> BRPS
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-slug', 0.95
FROM projects p, github_repos r
WHERE p.slug='brps' AND r.full_name='CHI-CityTech/META-Blended-Reality-Performance-System';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE slug='brps'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Active'));

-- META-Blended-Shadow-Puppet -> Blended Shadow Puppet (BSP)
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-slug', 0.95
FROM projects p, github_repos r
WHERE p.slug='blended-shadow-puppet' AND r.full_name='CHI-CityTech/META-Blended-Shadow-Puppet';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE slug='blended-shadow-puppet'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Active'));

-- Personalized-LLM -> Personalized LLM
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-slug', 1.0
FROM projects p, github_repos r
WHERE p.slug='personalized-llm' AND r.full_name='CHI-CityTech/Personalized-LLM';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE slug='personalized-llm'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept'));

-- Blended-Shadow-Puppet-Theatre -> Blended Shadow Puppet Theatre (Spring 2025 cohort row)
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-fuzzy', 0.9
FROM projects p, github_repos r
WHERE p.title='Blended Shadow Puppet Theatre' AND r.full_name='CHI-CityTech/Blended-Shadow-Puppet-Theatre';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE title='Blended Shadow Puppet Theatre'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Active'));

-- Shadow_puppet_Unreal -> Balanced Blended Space -- Shadow Puppetry in Unreal
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-fuzzy', 0.78
FROM projects p, github_repos r
WHERE p.title='Balanced Blended Space -- Shadow Puppetry in Unreal' AND r.full_name='CHI-CityTech/Shadow_puppet_Unreal';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE title='Balanced Blended Space -- Shadow Puppetry in Unreal'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Active'));

-- Unity-BSP -> Unity Platform Development for BSP 2D Virtual Environment
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-fuzzy', 0.75
FROM projects p, github_repos r
WHERE p.title='Unity Platform Development for BSP 2D Virtual Environment' AND r.full_name='CHI-CityTech/Unity-BSP';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE title='Unity Platform Development for BSP 2D Virtual Environment'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Archived'));

-- AVMI-GVSC-SoundSystem -> Autonomous Vehicle Mobility Institute -- Audio Immersion in ATMOS
INSERT OR REPLACE INTO project_github_repos (project_id, repo_id, is_primary, match_method, confidence)
SELECT p.project_id, r.repo_id, 1, 'auto-fuzzy', 0.72
FROM projects p, github_repos r
WHERE p.title='Autonomous Vehicle Mobility Institute -- Audio Immersion in ATMOS'
  AND r.full_name='CHI-CityTech/AVMI-GVSC-SoundSystem';

UPDATE projects
SET status_id = (SELECT status_id FROM statuses WHERE name='Started')
WHERE title='Autonomous Vehicle Mobility Institute -- Audio Immersion in ATMOS'
  AND status_id IN (SELECT status_id FROM statuses WHERE name IN ('Proposed','Concept','Active'));

COMMIT;
