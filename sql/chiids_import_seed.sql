-- =============================================================================
-- CHIIDS-aligned seed data (combined DB)
-- =============================================================================
-- Populates chiids_meta_projects with everything we can derive from the CHIIDS
-- README + the META-* repos we know about, plus the eight CHI storage
-- locations, the org roles, and auto-links BBS projects to their CHIIDS twin.
-- =============================================================================

BEGIN TRANSACTION;

-- ----- Org roles ------------------------------------------------------------
INSERT OR IGNORE INTO chiids_roles (name, description) VALUES
    ('Principal Investigator',   'Faculty lead of a meta-project.'),
    ('Co-PI',                    'Faculty co-lead.'),
    ('Project Lead',             'Day-to-day project lead.'),
    ('Technical Advisor',        'Subject-matter expert advising a team.'),
    ('Student Researcher',       'Student contributor.'),
    ('Emerging Scholar',         'Student in CHI emerging-scholar program.'),
    ('Collaborator',             'External or cross-org collaborator.'),
    ('Administrator',            'CHI admin staff.');

-- ----- Storage locations (per CHIIDS Sec 2.9 + README integration list) -----
INSERT OR IGNORE INTO chiids_storage_locations (name, kind, url, notes) VALUES
    ('GitHub',                'active',      'https://github.com/CHI-CityTech',                    'Code + Layer-3 execution repos.'),
    ('OneDrive',              'active',      NULL,                                                 'Active file storage for CHI participants.'),
    ('SharePoint',            'active',      NULL,                                                 'Document mgmt + research opportunities DB.'),
    ('OpenLab',               'publication', 'https://openlab.citytech.cuny.edu',                  'Public-facing City Tech site / WordPress.'),
    ('WordPress',             'publication', 'https://wordpress.com',                              'Public site host.'),
    ('OJS (CHI Publications)','publication', NULL,                                                 'Open Journal Systems for peer-reviewed output.'),
    ('Zenodo',                'archival',    'https://zenodo.org',                                 'DOI minting + long-term archive.'),
    ('Zotero',                'archival',    'https://www.zotero.org',                             'Citation libraries.'),
    ('WorldAnvil',            'publication', 'https://www.worldanvil.com',                         'Public world-building platform.'),
    ('OneDrive Backup',       'backup',      NULL,                                                 'Automated backup target for critical files.');

-- ----- META-* projects (Layer 1) --------------------------------------------
-- Source: the org README at https://github.com/CHI-CityTech + our github_repos.
INSERT OR IGNORE INTO chiids_meta_projects
    (slug, name, abbreviation, description, repo_url, site_url, meta_project_type_id, lifecycle_stage_id)
VALUES
    ('balanced-blended-space',
        'Balanced Blended Space', 'BBS',
        'Universal theoretical framework for combinative reality, integrating physical, virtual, and conceptual spaces.',
        'https://github.com/CHI-CityTech/META-Balanced-Blended-Space',
        'https://sites.google.com/view/balancedblendedspace/home',
        (SELECT type_id FROM meta_project_types WHERE name='Theory'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research')),
    ('blended-reality-performance-system',
        'Blended Reality Performance System', 'BRPS',
        'Modular test environment for the BBS framework in the performing arts.',
        'https://github.com/CHI-CityTech/META-Blended-Reality-Performance-System',
        NULL,
        (SELECT type_id FROM meta_project_types WHERE name='Engineering'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research')),
    ('blended-shadow-puppet',
        'Blended Shadow Puppet', 'BSP',
        'Shadow puppetry integrated with 21st-century technology. Part of the BBS project.',
        'https://github.com/CHI-CityTech/META-Blended-Shadow-Puppet',
        NULL,
        (SELECT type_id FROM meta_project_types WHERE name='Practice'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research')),
    ('collaborative-ai',
        'Collaborative AI', 'CAI',
        'Curriculum and partnership models for AI as a co-creative partner.',
        'https://github.com/CHI-CityTech/META-Collaborative-AI',
        NULL,
        (SELECT type_id FROM meta_project_types WHERE name='AI/Human Collaboration'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research')),
    ('chiids',
        'CHI Integrated Digital System', 'CHIIDS',
        'Structural framework that organizes all CHI meta-projects (Layer 0).',
        'https://github.com/CHI-CityTech/META-CHIIDS',
        NULL,
        (SELECT type_id FROM meta_project_types WHERE name='Infrastructure'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research')),
    ('unesco',
        'UNESCO Heritage Integration', 'UNESCO',
        'Investigations in the integration of UNESCO heritage.',
        'https://github.com/CHI-CityTech/META-UNESCO',
        NULL,
        (SELECT type_id FROM meta_project_types WHERE name='Practice'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research')),
    ('chiids-international',
        'International Collaboration', 'INTL',
        'Assets and designs promoting international collaboration with or via CHI.',
        'https://github.com/CHI-CityTech/META-International-collaboration',
        NULL,
        (SELECT type_id FROM meta_project_types WHERE name='Practice'),
        (SELECT stage_id FROM lifecycle_stages   WHERE name='Active Research'));

-- ----- Link our existing github_repos to chiids_vcs_repos --------------------
INSERT OR IGNORE INTO chiids_vcs_repos (provider, name, url, github_repo_id, meta_project_id)
SELECT 'github', r.name, r.html_url, r.repo_id,
       CASE r.name
            WHEN 'META-Balanced-Blended-Space'             THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='balanced-blended-space')
            WHEN 'META-Blended-Reality-Performance-System' THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='blended-reality-performance-system')
            WHEN 'META-Blended-Shadow-Puppet'              THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='blended-shadow-puppet')
            WHEN 'META-Collaborative-AI'                   THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='collaborative-ai')
            WHEN 'META-CHIIDS'                             THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='chiids')
            WHEN 'META-UNESCO'                             THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='unesco')
            WHEN 'META-International-collaboration'        THEN (SELECT meta_project_id FROM chiids_meta_projects WHERE slug='chiids-international')
            ELSE NULL
       END
FROM github_repos r;

-- ----- Auto-match BBS projects to CHIIDS meta-projects via slug/title --------
-- These are the obvious 1:1 matches; the rest can be added manually.
INSERT OR IGNORE INTO project_chiids_aliases (project_id, meta_project_id, match_method, confidence, notes)
SELECT p.project_id, mp.meta_project_id, 'seed', 1.0, 'Hand-curated 1:1 alias'
FROM projects p
JOIN chiids_meta_projects mp ON (
       (p.slug='bbs-theory'             AND mp.slug='balanced-blended-space')
    OR (p.slug='brps'                   AND mp.slug='blended-reality-performance-system')
    OR (p.slug='blended-shadow-puppet'  AND mp.slug='blended-shadow-puppet')
    OR (p.slug='collaborative-ai'       AND mp.slug='collaborative-ai')
    OR (p.slug='chiids-framework'       AND mp.slug='chiids')
    OR (p.slug='world-building'         AND mp.slug='blended-shadow-puppet')  -- WBP is under BSP
);

-- ----- Initial communications row, just so the table isn't empty
INSERT OR IGNORE INTO chiids_communications (meta_project_id, audience, channel, subject, body, url, occurred_at)
SELECT mp.meta_project_id, 'public', 'website', 'BBS public site',
       'The BBS public site on sites.google.com is the canonical public-engagement surface for BBS.',
       'https://sites.google.com/view/balancedblendedspace/home',
       NULL
FROM chiids_meta_projects mp WHERE mp.slug='balanced-blended-space';

INSERT OR IGNORE INTO chiids_public_engagement (meta_project_id, kind, title, url, occurred_at, notes)
SELECT mp.meta_project_id, 'website', 'BalancedBlendedSpace Google Site', 'https://sites.google.com/view/balancedblendedspace/home', NULL,
       'Primary public-facing site that this database catalogues.'
FROM chiids_meta_projects mp WHERE mp.slug='balanced-blended-space';

INSERT OR IGNORE INTO chiids_public_engagement (meta_project_id, kind, title, url, occurred_at, notes)
SELECT mp.meta_project_id, 'publication', 'BBS White Paper (CUNY Academic Works)',
       'https://academicworks.cuny.edu/ny_pubs/1239/', NULL,
       'Original BBS white paper.'
FROM chiids_meta_projects mp WHERE mp.slug='balanced-blended-space';

-- ----- Tag every chiids_meta_project as L1/Management ------------------------
INSERT OR IGNORE INTO chiids_artifact_tags (artifact_type, artifact_id, cornerstone_id, layer_id, concept_id, source, confidence)
SELECT 'project', a.project_id,
       (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='mgmt'),
       1,
       (SELECT concept_id FROM chiids_concepts WHERE code='project_1_n'),
       'auto-rule', 1.0
FROM project_chiids_aliases a;

COMMIT;
