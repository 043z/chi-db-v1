-- =============================================================================
-- Balanced Blended Space (BBS) -- Seed data
-- =============================================================================
-- Populates: departments, categories, levels, statuses, link_types, researchers,
--            projects and all the m:n join tables, scraped from
--            https://sites.google.com/view/balancedblendedspace/
-- Run AFTER schema.sql.
-- =============================================================================

BEGIN TRANSACTION;

-- -----------------------------------------------------------------------------
-- Lookup tables
-- -----------------------------------------------------------------------------

INSERT INTO levels (name, sort_order) VALUES
    ('Unspecified',  0),
    ('Beginning',    1),
    ('Intermediate', 2),
    ('Advanced',     3);

INSERT INTO statuses (name, description) VALUES
    ('Proposed',  'Idea posted on the BBS site as a potential project'),
    ('Active',    'Currently in development'),
    ('Completed', 'Finished work product exists'),
    ('Archived',  'Past semester / no longer worked on'),
    ('Concept',   'Theoretical / framework piece, not a buildable artifact');

INSERT INTO categories (name, description) VALUES
    ('Theory',              'Foundational theoretical work (BBS framework, white papers)'),
    ('Syntax',              'Formal language / grammar for describing BBS pathways'),
    ('Practice',            'Practice platforms such as BRPS'),
    ('Meta-Project',        'Umbrella initiatives spanning departments (BSP, World Building...)'),
    ('Department Research', 'Departmental project ideas listed under a single department'),
    ('Semester Cohort',     'Concrete student/researcher project in a named semester'),
    ('Sub-Project',         'Child component of a parent project'),
    ('Wicked Problem',      'Theory subtopic'),
    ('Collaborating with AI','Theory subtopic');

INSERT INTO link_types (name) VALUES
    ('Project Page'),
    ('Proposal'),
    ('GitHub'),
    ('Dropbox'),
    ('Google Doc'),
    ('Google Drive'),
    ('Demo'),
    ('Paper'),
    ('Music'),
    ('Other');

-- -----------------------------------------------------------------------------
-- Departments
-- -----------------------------------------------------------------------------
INSERT INTO departments (code, name, slug, url) VALUES
    ('ENT',  'Entertainment Technology',           'entertainment-technology-ent',         'https://sites.google.com/view/balancedblendedspace/projects/departments/entertainment-technology-ent'),
    ('MTEC', 'Emerging Media Technology',          'emerging-media-technology-mtec',       'https://sites.google.com/view/balancedblendedspace/projects/departments/emerging-media-technology-mtec'),
    ('MUS',  'Music Technology',                   'music-technology',                     'https://sites.google.com/view/balancedblendedspace/projects/departments/music-technology'),
    ('CST',  'Computer Systems Technology',        'computer-systems-technology-cst',      'https://sites.google.com/view/balancedblendedspace/projects/departments/computer-systems-technology-cst'),
    ('MKT',  'Business / Marketing',               'business-marketing-mkt',               'https://sites.google.com/view/balancedblendedspace/projects/departments/business-marketing-mkt'),
    ('COMD', 'Communication Design',               'communication-design-comd',            'https://sites.google.com/view/balancedblendedspace/projects/departments/communication-design-comd'),
    ('ENG',  'English',                            'english-eng',                          'https://sites.google.com/view/balancedblendedspace/projects/departments/english-eng'),
    ('FAS',  'Business / Fashion Technology',      'business-fashion-technology',          'https://sites.google.com/view/balancedblendedspace/projects/departments/business-fashion-technology'),
    ('ARCH', 'Architectural Technology',           'architectural-technology-arch',        'https://sites.google.com/view/balancedblendedspace/projects/departments/architectural-technology-arch'),
    ('MECH', 'Mechanical Engineering Technology',  'mechanical-engineering-technology-mech','https://sites.google.com/view/balancedblendedspace/projects/departments/mechanical-engineering-technology-mech'),
    ('HUM',  'Humanities',                         'humanities-hum',                       'https://sites.google.com/view/balancedblendedspace/projects/departments/humanities-hum'),
    ('SOC',  'Social Sciences',                    'social-sciences-soc',                  'https://sites.google.com/view/balancedblendedspace/projects/departments/social-sciences-soc'),
    ('CET',  'Computer Engineering Technology',    'computer-engineering-technology',      'https://sites.google.com/view/balancedblendedspace/projects/departments/computer-engineering-technology');

-- -----------------------------------------------------------------------------
-- Tags (common BBS themes; more can be added)
-- -----------------------------------------------------------------------------
INSERT INTO tags (name) VALUES
    ('AI'), ('Shadow Puppetry'), ('VR'), ('AR'), ('Mixed Reality'),
    ('Projection Mapping'), ('Music'), ('Sound'), ('Performance'),
    ('Mechanical'), ('3D Printing'), ('Robotics'),
    ('Web'), ('Mobile'), ('Game'), ('Interactive'),
    ('Education'), ('Cultural'), ('Storytelling'),
    ('Marketing'), ('Branding'), ('Wearable'), ('Textile'),
    ('Architecture'), ('Stage Design'),
    ('Research'), ('Workshop'), ('Streaming'),
    ('Hardware'), ('Software'), ('Cloud'),
    ('Quantum'), ('Audio'), ('Autonomous Vehicles'),
    ('LLM'), ('World Building'), ('Theory'), ('Syntax');

-- -----------------------------------------------------------------------------
-- Researchers (named contributors from Fall 2024 / Spring 2025)
-- -----------------------------------------------------------------------------
INSERT INTO researchers (full_name, affiliation) VALUES
    ('Edward Gonzalez',  'City Tech'),
    ('Anthony Navarro',  'City Tech'),
    ('Tshari Yancey',    'City Tech'),
    ('Samuel Cheung',    'City Tech'),
    ('Hugo Sanchez',     'City Tech'),
    ('Zixuan Wu',        'City Tech'),
    ('Priya Begum',      'City Tech'),
    ('Cordell Lane',     'City Tech'),
    ('John Powell',      'City Tech'),
    ('Oleg Berman',      'Technical Advisor'),
    ('Alyssa Burtsev',   'City Tech'),
    ('Mellisa Demolari', 'City Tech'),
    ('Elizabeth Frias',  'City Tech'),
    ('Houke Gao',        'City Tech'),
    ('Stefanie Rivera',  'City Tech'),
    ('Frederick Bianchi','Co-author (BBS Paper)');

-- =============================================================================
-- PROJECTS
-- =============================================================================
-- Naming convention: theory + meta-projects come first, then department research
-- lists, then semester-specific cohort projects. Department-research items are
-- inserted department by department. Each list-item on a department page
-- becomes one row (status="Proposed", category="Department Research").
-- =============================================================================

-- ----- Theory / Syntax / Practice (top-level framework pieces) ----------------
INSERT INTO projects (title, slug, summary, description, status_id, level_id, is_meta_project, primary_url) VALUES
    ('BBS Theory', 'bbs-theory',
        'Universal framework describing Combinative Reality.',
        'Original white paper co-authored with Frederick Bianchi and ChatGPT-4, introducing the Balanced Blended Space (BBS) framework for navigating physical, virtual, and conceptual realities and cognitive vs. computational intelligences.',
        (SELECT status_id FROM statuses WHERE name='Concept'),
        (SELECT level_id  FROM levels   WHERE name='Advanced'),
        1, 'https://sites.google.com/view/balancedblendedspace/theory'),

    ('BBS Syntax', 'bbs-syntax',
        'Formal syntax to describe mediation pathways across spaces.',
        'Source-Vector-Destination grammar plus graph-theory + signal-flowchart representations for describing every possible mediation pathway in BBS.',
        (SELECT status_id FROM statuses WHERE name='Active'),
        (SELECT level_id  FROM levels   WHERE name='Advanced'),
        1, 'https://sites.google.com/view/balancedblendedspace/syntax'),

    ('Blended Reality Performance System (BRPS)', 'brps',
        'Test platform for the BBS framework in performance contexts.',
        'Modular system enabling real-time synchronization between physical and virtual performers, AI collaborators, projection mapping, and multi-sensory audience interaction.',
        (SELECT status_id FROM statuses WHERE name='Active'),
        (SELECT level_id  FROM levels   WHERE name='Advanced'),
        1, 'https://sites.google.com/view/balancedblendedspace/blended-reality-performance-system');

-- ----- Top-level Meta / Project Hubs ------------------------------------------
INSERT INTO projects (title, slug, summary, description, status_id, is_meta_project, primary_url) VALUES
    ('Blended Shadow Puppet (BSP)', 'blended-shadow-puppet',
        'Meta-project: shadow puppetry as a case study for BBS.',
        'Articulated Puppet Construction: design and 3D print a fully articulated Javanese shadow puppet with laser-cut joints. Umbrella for BSP-related sub-projects.',
        (SELECT status_id FROM statuses WHERE name='Active'),
        1, 'https://sites.google.com/view/balancedblendedspace/projects/blended-shadow-puppet'),

    ('World Building Project (WBP)', 'world-building',
        'Repository of historical, cultural, and geographic material grounding BSP.',
        'Cross-disciplinary world-building library for BSP, with sub-categories: History, Geography, Society, Science & Technology, Art & Culture. Sub-fields include Political/Military/Cultural/Economic/Social/Religious/Tech history; Physical/Climate/Bio/Human/Political/Cultural geography; Political Science, Economics, Sociology, Cultural Studies, Anthropology, Philosophy, Religion & Theology, Magical Systems; Physics, Chemistry, Biology, Earth Sciences, Astronomy, Engineering, Medicine, Technology & Innovation, Environmental Science; and a large Art & Culture cluster (Shadow Puppetry, Oral Storytelling, Poetry, Theatre, Carvings & Glyphs, Textile Narratives, Fashion & Attire, Dance, Pantomime, Music, Ceremonial Performance, Sculpture & Iconography, Painted Frescoes, Heraldry, Cartographic Storytelling, Architecture, Ritual Objects, Sports, Games, Calligraphy & Manuscripts, Symbolic Tattoos, Iconography).',
        (SELECT status_id FROM statuses WHERE name='Active'),
        1, 'https://sites.google.com/view/balancedblendedspace/projects/blended-shadow-puppet/world-building'),

    ('AI Image Generators Evaluation', 'ai-image-generators-evaluation',
        'Comparative evaluation of AI image generators across three prompts.',
        'Investigation led by Priya Begum into AI image generation capabilities. Contains four sub-pages: Prompt 1, Prompt 2, Prompt 3, and AI Generator Rankings.',
        (SELECT status_id FROM statuses WHERE name='Active'),
        1, 'https://sites.google.com/view/balancedblendedspace/projects/ai-image-generators-evaluation'),

    ('Fall 2024 Research', 'fall-2024-research',
        'Research & design semester for BBS / BSP / BRPS.',
        'Fall 2024 semester cohort: clarified the definition of balanced blended virtual environment in the BSP context and advanced the BRPS.',
        (SELECT status_id FROM statuses WHERE name='Archived'),
        1, 'https://sites.google.com/view/balancedblendedspace/projects/fall-2024-research'),

    ('Spring 2025 Research', 'spring-2025-research',
        'Spring 2025 cohort: Quantum Music, BRPS, ATMOS audio, SeaChange 360, Shadow Puppetry in Unreal, BSP Theatre, World Building, CHI Digital Infrastructure, International Collaboration.',
        'Spring 2025 collection of active student/researcher projects extending BBS, BSP, and BRPS.',
        (SELECT status_id FROM statuses WHERE name='Active'),
        1, 'https://sites.google.com/view/balancedblendedspace/projects/spring-2025-research'),

    ('Personalized LLM', 'personalized-llm',
        'Exploring the shift from monolithic LLMs to personalized models.',
        'Creative/philosophical project: sestina "The Central Machine" reflecting on the transition from one central machine to distributed, personalized LLM utility.',
        (SELECT status_id FROM statuses WHERE name='Concept'),
        1, 'https://sites.google.com/view/balancedblendedspace/projects/personalized-llm');

-- ----- AI Image Generators Evaluation sub-pages -------------------------------
INSERT INTO projects (title, slug, summary, parent_project_id, status_id, primary_url) VALUES
    ('AI Image Generators -- Prompt 1', 'ai-image-prompt-1', 'Comparative test, prompt 1',
        (SELECT project_id FROM projects WHERE slug='ai-image-generators-evaluation'),
        (SELECT status_id FROM statuses WHERE name='Completed'),
        'https://sites.google.com/view/balancedblendedspace/projects/ai-image-generators-evaluation/prompt-1'),
    ('AI Image Generators -- Prompt 2', 'ai-image-prompt-2', 'Comparative test, prompt 2',
        (SELECT project_id FROM projects WHERE slug='ai-image-generators-evaluation'),
        (SELECT status_id FROM statuses WHERE name='Completed'),
        'https://sites.google.com/view/balancedblendedspace/projects/ai-image-generators-evaluation/prompt-2'),
    ('AI Image Generators -- Prompt 3', 'ai-image-prompt-3', 'Comparative test, prompt 3',
        (SELECT project_id FROM projects WHERE slug='ai-image-generators-evaluation'),
        (SELECT status_id FROM statuses WHERE name='Completed'),
        'https://sites.google.com/view/balancedblendedspace/projects/ai-image-generators-evaluation/prompt-3'),
    ('AI Image Generator Rankings', 'ai-image-rankings', 'Final ranked comparison of evaluated generators',
        (SELECT project_id FROM projects WHERE slug='ai-image-generators-evaluation'),
        (SELECT status_id FROM statuses WHERE name='Completed'),
        'https://sites.google.com/view/balancedblendedspace/projects/ai-image-generators-evaluation/ai-generator-rankings');

-- =============================================================================
-- DEPARTMENT-RESEARCH PROJECT IDEAS
-- =============================================================================

-- Helper trick: insert into projects then add to project_departments
-- For brevity we use multi-row inserts and tie via a temp variable using
-- last_insert_rowid() patterns. Each idea becomes a row with category
-- "Department Research" and status "Proposed".

-- ----- Entertainment Technology (ENT) -----------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Advanced Puppet Entertainment Control System',                                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Dynamic Front Projection Techniques for Puppetry',                                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Scenic Element Animation -- Motion Control',                                        (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Automated Scenic Transitions for Puppetry Performances',                            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Virtual and Physical Puppet Synchronization System',                                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Driven Puppet Movement Control System',                                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Virtual Reality Puppetry Performance System',                                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Dynamic Lighting Design for Shadow Puppetry Performances',                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Sound Design and Foley Creation for Interactive Puppetry',                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Projection Mapping and Real-Time Visual Effects Integration',                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Immersive Soundscapes for Virtual Shadow Puppetry Environments',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Lighting Systems Controlled by Puppet Movements',                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Modular Prop Design for Shadow Puppetry Performances',                              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Automated Scenery Transitions for Live Puppetry',                                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Symbolic Visual Elements for Interactive Narrative Design',                         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Thematic Spin-off Projects Based on Core Narratives',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Gesture-Controlled Projection Systems for Puppetry Performances',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Augmented Reality (AR) Props and Scenic Design',                                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Live Puppetry Performances Integrated with Digital Media Broadcasts',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Puppetry Performances with Mobile Audience Input',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Hybrid Performances Combining Live and Virtual Audience Experiences',      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Multi-Camera Live-Streaming of Puppetry Performances for Global Audiences',         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Development of a Virtual Puppetry Studio for Remote Collaboration',                 (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Multi-Location Puppetry Performances Linked via Real-Time Video',       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing a Mixed Reality Experience for Physical and Digital Audiences',           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Streaming Platform for Real-Time Puppetry Storytelling',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Augmented Reality Puppetry Game for Mobile Devices',                                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Interactive Puppetry-Based Performances for Gaming Platforms',             (SELECT status_id FROM statuses WHERE name='Proposed'));

-- Tag all ENT items as Department Research + attach to ENT department
INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Advanced Puppet Entertainment Control System',
        'Dynamic Front Projection Techniques for Puppetry',
        'Scenic Element Animation -- Motion Control',
        'Automated Scenic Transitions for Puppetry Performances',
        'Virtual and Physical Puppet Synchronization System',
        'AI-Driven Puppet Movement Control System',
        'Virtual Reality Puppetry Performance System',
        'Dynamic Lighting Design for Shadow Puppetry Performances',
        'Sound Design and Foley Creation for Interactive Puppetry',
        'Projection Mapping and Real-Time Visual Effects Integration',
        'Immersive Soundscapes for Virtual Shadow Puppetry Environments',
        'Interactive Lighting Systems Controlled by Puppet Movements',
        'Modular Prop Design for Shadow Puppetry Performances',
        'Automated Scenery Transitions for Live Puppetry',
        'Symbolic Visual Elements for Interactive Narrative Design',
        'Designing Thematic Spin-off Projects Based on Core Narratives',
        'Gesture-Controlled Projection Systems for Puppetry Performances',
        'Augmented Reality (AR) Props and Scenic Design',
        'Live Puppetry Performances Integrated with Digital Media Broadcasts',
        'Interactive Puppetry Performances with Mobile Audience Input',
        'Creating Hybrid Performances Combining Live and Virtual Audience Experiences',
        'Multi-Camera Live-Streaming of Puppetry Performances for Global Audiences',
        'Development of a Virtual Puppetry Studio for Remote Collaboration',
        'Interactive Multi-Location Puppetry Performances Linked via Real-Time Video',
        'Designing a Mixed Reality Experience for Physical and Digital Audiences',
        'Interactive Streaming Platform for Real-Time Puppetry Storytelling',
        'Augmented Reality Puppetry Game for Mobile Devices',
        'Creating Interactive Puppetry-Based Performances for Gaming Platforms'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='ENT'), 1
    FROM projects p
    WHERE p.title IN (
        'Advanced Puppet Entertainment Control System',
        'Dynamic Front Projection Techniques for Puppetry',
        'Scenic Element Animation -- Motion Control',
        'Automated Scenic Transitions for Puppetry Performances',
        'Virtual and Physical Puppet Synchronization System',
        'AI-Driven Puppet Movement Control System',
        'Virtual Reality Puppetry Performance System',
        'Dynamic Lighting Design for Shadow Puppetry Performances',
        'Sound Design and Foley Creation for Interactive Puppetry',
        'Projection Mapping and Real-Time Visual Effects Integration',
        'Immersive Soundscapes for Virtual Shadow Puppetry Environments',
        'Interactive Lighting Systems Controlled by Puppet Movements',
        'Modular Prop Design for Shadow Puppetry Performances',
        'Automated Scenery Transitions for Live Puppetry',
        'Symbolic Visual Elements for Interactive Narrative Design',
        'Designing Thematic Spin-off Projects Based on Core Narratives',
        'Gesture-Controlled Projection Systems for Puppetry Performances',
        'Augmented Reality (AR) Props and Scenic Design',
        'Live Puppetry Performances Integrated with Digital Media Broadcasts',
        'Interactive Puppetry Performances with Mobile Audience Input',
        'Creating Hybrid Performances Combining Live and Virtual Audience Experiences',
        'Multi-Camera Live-Streaming of Puppetry Performances for Global Audiences',
        'Development of a Virtual Puppetry Studio for Remote Collaboration',
        'Interactive Multi-Location Puppetry Performances Linked via Real-Time Video',
        'Designing a Mixed Reality Experience for Physical and Digital Audiences',
        'Interactive Streaming Platform for Real-Time Puppetry Storytelling',
        'Augmented Reality Puppetry Game for Mobile Devices',
        'Creating Interactive Puppetry-Based Performances for Gaming Platforms'
    );

-- ----- Emerging Media Technology (MTEC) ---------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Interactive Digital Shadow Puppetry Games',                                         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Real-Time Virtual Shadow Puppetry Portal',                                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('VR-Based Puppetry World Exploration',                                               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Augmented Reality Shadow Puppet Applications',                                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Online Educational Tools for Shadow Puppetry',                                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Mobile Apps for Creating Virtual Shadow Puppet Shows',                              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('3D-Printed Modular Puppetry Kits for Customizable Performances',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Experimenting with Fabrication Materials for Shadow Puppetry',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Moire Pattern Generating Puppets',                                                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Audience Engagement Tools for Shadow Puppetry',                         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AR-Based Immersive Puppetry Environment Moire and Transformative Scenery Elements', (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Exploration of Integration with Virtual World Equivalents',                         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Augmented and Virtual Reality Integration for Puppetry Performances',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Development of Mobile Augmented Reality Puppetry Apps',                             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Driven Interactive Puppetry Performances in Virtual Worlds',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Multi-Sensory Digital Puppetry Experiences for VR',                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Real-Time Audience Interaction Through Smart Devices in Puppetry',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Development of Collaborative Virtual Puppetry Story Platforms',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Augmented Reality Puppetry Stories for Educational Platforms',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Puppetry Storytelling Through Social Media Platforms',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Crowd-Sourced Puppetry Narratives for Online Communities',                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Driven Dynamic Puppetry Worlds with Player Control in Video Games',              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Puppetry Characters for Interactive Virtual Theme Parks',                (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Interactive Digital Shadow Puppetry Games','Real-Time Virtual Shadow Puppetry Portal',
        'VR-Based Puppetry World Exploration','Augmented Reality Shadow Puppet Applications',
        'Online Educational Tools for Shadow Puppetry','Mobile Apps for Creating Virtual Shadow Puppet Shows',
        '3D-Printed Modular Puppetry Kits for Customizable Performances',
        'Experimenting with Fabrication Materials for Shadow Puppetry','Moire Pattern Generating Puppets',
        'Interactive Audience Engagement Tools for Shadow Puppetry',
        'AR-Based Immersive Puppetry Environment Moire and Transformative Scenery Elements',
        'Exploration of Integration with Virtual World Equivalents',
        'Augmented and Virtual Reality Integration for Puppetry Performances',
        'Development of Mobile Augmented Reality Puppetry Apps',
        'AI-Driven Interactive Puppetry Performances in Virtual Worlds',
        'Designing Multi-Sensory Digital Puppetry Experiences for VR',
        'Real-Time Audience Interaction Through Smart Devices in Puppetry',
        'Development of Collaborative Virtual Puppetry Story Platforms',
        'Augmented Reality Puppetry Stories for Educational Platforms',
        'Interactive Puppetry Storytelling Through Social Media Platforms',
        'Crowd-Sourced Puppetry Narratives for Online Communities',
        'AI-Driven Dynamic Puppetry Worlds with Player Control in Video Games',
        'Developing Puppetry Characters for Interactive Virtual Theme Parks'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='MTEC'), 1
    FROM projects p
    WHERE p.title IN (
        'Interactive Digital Shadow Puppetry Games','Real-Time Virtual Shadow Puppetry Portal',
        'VR-Based Puppetry World Exploration','Augmented Reality Shadow Puppet Applications',
        'Online Educational Tools for Shadow Puppetry','Mobile Apps for Creating Virtual Shadow Puppet Shows',
        '3D-Printed Modular Puppetry Kits for Customizable Performances',
        'Experimenting with Fabrication Materials for Shadow Puppetry','Moire Pattern Generating Puppets',
        'Interactive Audience Engagement Tools for Shadow Puppetry',
        'AR-Based Immersive Puppetry Environment Moire and Transformative Scenery Elements',
        'Exploration of Integration with Virtual World Equivalents',
        'Augmented and Virtual Reality Integration for Puppetry Performances',
        'Development of Mobile Augmented Reality Puppetry Apps',
        'AI-Driven Interactive Puppetry Performances in Virtual Worlds',
        'Designing Multi-Sensory Digital Puppetry Experiences for VR',
        'Real-Time Audience Interaction Through Smart Devices in Puppetry',
        'Development of Collaborative Virtual Puppetry Story Platforms',
        'Augmented Reality Puppetry Stories for Educational Platforms',
        'Interactive Puppetry Storytelling Through Social Media Platforms',
        'Crowd-Sourced Puppetry Narratives for Online Communities',
        'AI-Driven Dynamic Puppetry Worlds with Player Control in Video Games',
        'Developing Puppetry Characters for Interactive Virtual Theme Parks'
    );

-- ----- Music Technology (MUS) -------------------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Blending Physical and Virtual Instruments for Puppetry Performances',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Soundtrack Composition for Shadow Puppetry Games and Performances',                 (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Music Systems for Puppetry Performances',                               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Music Technology for Synchronizing Sound with Puppet Movements',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Immersive Audio Systems for Augmented Reality Puppetry',                            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Interactive Audio Systems for Puppetry-Based Concerts',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Composing Adaptive Soundtracks for Real-Time Puppetry Performances',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing AI-Composed Music for Digital Puppetry Experiences',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Immersive 3D Audio for Puppetry Performances in VR',                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Collaborating on Mixed Reality Music and Puppetry Performances',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Music Compositions That Respond to Puppetry Movements',                 (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Real-Time Soundscapes for Interactive Public Puppetry Shows',             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Music-Driven Puppetry Performances for Online Streaming Platforms',        (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Integrating Foley Sound Effects into Puppetry Narratives for Live Shows',           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Music Technology for Puppetry-Based Educational Performances',            (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Blending Physical and Virtual Instruments for Puppetry Performances',
        'Soundtrack Composition for Shadow Puppetry Games and Performances',
        'Interactive Music Systems for Puppetry Performances',
        'Music Technology for Synchronizing Sound with Puppet Movements',
        'Immersive Audio Systems for Augmented Reality Puppetry',
        'Designing Interactive Audio Systems for Puppetry-Based Concerts',
        'Composing Adaptive Soundtracks for Real-Time Puppetry Performances',
        'Developing AI-Composed Music for Digital Puppetry Experiences',
        'Creating Immersive 3D Audio for Puppetry Performances in VR',
        'Collaborating on Mixed Reality Music and Puppetry Performances',
        'Interactive Music Compositions That Respond to Puppetry Movements',
        'Designing Real-Time Soundscapes for Interactive Public Puppetry Shows',
        'Creating Music-Driven Puppetry Performances for Online Streaming Platforms',
        'Integrating Foley Sound Effects into Puppetry Narratives for Live Shows',
        'Designing Music Technology for Puppetry-Based Educational Performances'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='MUS'), 1
    FROM projects p
    WHERE p.title IN (
        'Blending Physical and Virtual Instruments for Puppetry Performances',
        'Soundtrack Composition for Shadow Puppetry Games and Performances',
        'Interactive Music Systems for Puppetry Performances',
        'Music Technology for Synchronizing Sound with Puppet Movements',
        'Immersive Audio Systems for Augmented Reality Puppetry',
        'Designing Interactive Audio Systems for Puppetry-Based Concerts',
        'Composing Adaptive Soundtracks for Real-Time Puppetry Performances',
        'Developing AI-Composed Music for Digital Puppetry Experiences',
        'Creating Immersive 3D Audio for Puppetry Performances in VR',
        'Collaborating on Mixed Reality Music and Puppetry Performances',
        'Interactive Music Compositions That Respond to Puppetry Movements',
        'Designing Real-Time Soundscapes for Interactive Public Puppetry Shows',
        'Creating Music-Driven Puppetry Performances for Online Streaming Platforms',
        'Integrating Foley Sound Effects into Puppetry Narratives for Live Shows',
        'Designing Music Technology for Puppetry-Based Educational Performances'
    );

-- ----- Computer Systems Technology (CST) --------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('API Integration for Virtual and Physical Systems in Shadow Puppetry',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Integration of AI Resources for Enhanced Puppetry Interaction',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Software for Easier Replication of Shadow Puppet Performances',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Powered Visual and Auditory Response Systems',                                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Real-Time Capture and Feedback System for Puppet Interaction',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Backend Systems for Interactive Shadow Puppetry Games',                             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Synchronization Protocols Between Virtual and Physical Worlds',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Cloud-Based Real-Time Collaboration for Global Puppetry Performances',              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Virtual Community Platforms for Puppet Performance Sharing',                        (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Blockchain Solutions for Copyright Protection of Digital Puppetry Assets',          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating a Cloud-Hosted Digital Puppetry Archive with Community Access',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing a Distributed Digital Platform for International Puppetry Collaboration',(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Driven Real-Time Language Translation for Global Puppetry Performances',         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Integration of AI-Generated Puppetry Narratives into Live Shows',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Cross-Platform Data Synchronization for Digital Puppetry Streaming',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Virtual Audience Feedback System with Real-Time Puppetry Performance Adjustment',   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Data Analytics for Tracking and Enhancing Audience Engagement with Puppetry',       (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'API Integration for Virtual and Physical Systems in Shadow Puppetry',
        'Integration of AI Resources for Enhanced Puppetry Interaction',
        'Software for Easier Replication of Shadow Puppet Performances',
        'AI-Powered Visual and Auditory Response Systems',
        'Real-Time Capture and Feedback System for Puppet Interaction',
        'Backend Systems for Interactive Shadow Puppetry Games',
        'Synchronization Protocols Between Virtual and Physical Worlds',
        'Cloud-Based Real-Time Collaboration for Global Puppetry Performances',
        'Virtual Community Platforms for Puppet Performance Sharing',
        'Blockchain Solutions for Copyright Protection of Digital Puppetry Assets',
        'Creating a Cloud-Hosted Digital Puppetry Archive with Community Access',
        'Developing a Distributed Digital Platform for International Puppetry Collaboration',
        'AI-Driven Real-Time Language Translation for Global Puppetry Performances',
        'Integration of AI-Generated Puppetry Narratives into Live Shows',
        'Cross-Platform Data Synchronization for Digital Puppetry Streaming',
        'Virtual Audience Feedback System with Real-Time Puppetry Performance Adjustment',
        'Data Analytics for Tracking and Enhancing Audience Engagement with Puppetry'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='CST'), 1
    FROM projects p
    WHERE p.title IN (
        'API Integration for Virtual and Physical Systems in Shadow Puppetry',
        'Integration of AI Resources for Enhanced Puppetry Interaction',
        'Software for Easier Replication of Shadow Puppet Performances',
        'AI-Powered Visual and Auditory Response Systems',
        'Real-Time Capture and Feedback System for Puppet Interaction',
        'Backend Systems for Interactive Shadow Puppetry Games',
        'Synchronization Protocols Between Virtual and Physical Worlds',
        'Cloud-Based Real-Time Collaboration for Global Puppetry Performances',
        'Virtual Community Platforms for Puppet Performance Sharing',
        'Blockchain Solutions for Copyright Protection of Digital Puppetry Assets',
        'Creating a Cloud-Hosted Digital Puppetry Archive with Community Access',
        'Developing a Distributed Digital Platform for International Puppetry Collaboration',
        'AI-Driven Real-Time Language Translation for Global Puppetry Performances',
        'Integration of AI-Generated Puppetry Narratives into Live Shows',
        'Cross-Platform Data Synchronization for Digital Puppetry Streaming',
        'Virtual Audience Feedback System with Real-Time Puppetry Performance Adjustment',
        'Data Analytics for Tracking and Enhancing Audience Engagement with Puppetry'
    );

-- ----- Business / Marketing (MKT) ---------------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Marketing Campaign for Virtual and Physical Shadow Puppetry Performances',          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Audience Engagement Strategy for Interactive Puppetry Events',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Merchandise Development for Shadow Puppetry Spin-offs',                             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Global Marketing Campaigns for Interactive Digital Puppetry',                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Crowdfunding Campaigns for Large-Scale Puppetry Performances',             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Cross-Platform Promotion Strategy for Puppetry-Based Interactive Media',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Social Media Marketing Strategies for Augmented Reality Puppetry',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Marketing Campaigns Targeting Younger Audiences Through Puppetry Apps',             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Influencer-Based Marketing for Interactive Puppetry Games and Experiences',         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Promotional Campaigns for Global Digital Puppetry Collaborations',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Brand Partnerships Using Puppetry Characters for Digital Ads',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Marketing Experiences Using Puppetry-Based Games',                      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Leveraging Puppetry Narratives for Cause-Based Marketing Campaigns',                (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Marketing Campaign for Virtual and Physical Shadow Puppetry Performances',
        'Audience Engagement Strategy for Interactive Puppetry Events',
        'Merchandise Development for Shadow Puppetry Spin-offs',
        'Global Marketing Campaigns for Interactive Digital Puppetry',
        'Creating Crowdfunding Campaigns for Large-Scale Puppetry Performances',
        'Cross-Platform Promotion Strategy for Puppetry-Based Interactive Media',
        'Social Media Marketing Strategies for Augmented Reality Puppetry',
        'Marketing Campaigns Targeting Younger Audiences Through Puppetry Apps',
        'Influencer-Based Marketing for Interactive Puppetry Games and Experiences',
        'Promotional Campaigns for Global Digital Puppetry Collaborations',
        'Brand Partnerships Using Puppetry Characters for Digital Ads',
        'Interactive Marketing Experiences Using Puppetry-Based Games',
        'Leveraging Puppetry Narratives for Cause-Based Marketing Campaigns'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='MKT'), 1
    FROM projects p
    WHERE p.title IN (
        'Marketing Campaign for Virtual and Physical Shadow Puppetry Performances',
        'Audience Engagement Strategy for Interactive Puppetry Events',
        'Merchandise Development for Shadow Puppetry Spin-offs',
        'Global Marketing Campaigns for Interactive Digital Puppetry',
        'Creating Crowdfunding Campaigns for Large-Scale Puppetry Performances',
        'Cross-Platform Promotion Strategy for Puppetry-Based Interactive Media',
        'Social Media Marketing Strategies for Augmented Reality Puppetry',
        'Marketing Campaigns Targeting Younger Audiences Through Puppetry Apps',
        'Influencer-Based Marketing for Interactive Puppetry Games and Experiences',
        'Promotional Campaigns for Global Digital Puppetry Collaborations',
        'Brand Partnerships Using Puppetry Characters for Digital Ads',
        'Interactive Marketing Experiences Using Puppetry-Based Games',
        'Leveraging Puppetry Narratives for Cause-Based Marketing Campaigns'
    );

-- ----- Communication Design (COMD) -- with explicit levels --------------------
-- Beginning level
INSERT INTO projects (title, level_id, status_id) VALUES
    ('Create Digital Posters for Hybrid Performances',          (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Basic Logo Design for Project Sub-Groups',                (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Simple Character Concepts for Puppetry Projects',  (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design a Consistent Style Guide for Puppetry Projects',   (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Basic Web Page Layouts',                           (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Assist with User Interface Elements for Mobile Apps',     (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Basic Social Media Posts for Project Updates',     (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research Audience Engagement for Social Media',           (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Simple Infographics for Project Communication',    (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Edit Short Video Clips for Performance Documentation',    (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Capture Basic Video Footage for Behind-the-Scenes Content',(SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Animated GIFs for Social Media',                   (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research Visual Styles for Puppetry Design',              (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research Simple Storytelling Techniques',                 (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Write Short Promotional Copy for Performances',           (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design and Animate Simple 2D Character Movements',        (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Motion Graphics for Simple Project Intros',        (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Collect Basic Data on User Interactions',                 (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Basic Reports on Audience Engagement',             (SELECT level_id FROM levels WHERE name='Beginning'),(SELECT status_id FROM statuses WHERE name='Proposed'));

-- Intermediate level
INSERT INTO projects (title, level_id, status_id) VALUES
    ('Develop and Maintain Visual Identity Systems for the Shadow Puppetry Canon',(SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Visual Identity for AI-Driven Collaborative Projects',                (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Logo and Branding Design for Sub-Projects',                                  (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Motion Graphics for Puppetry-Based Narratives',                       (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop Interactive Web Experiences for Puppetry Narratives',                (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Interactive Motion Design Assets for AR/VR Experiences',              (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Plan and Execute Campaigns for Virtual Puppetry Events',                     (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Self-Referential Marketing Campaigns Highlighting BSP Projects',             (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop Cross-Platform Marketing Campaigns for Shadow Puppetry Performances',(SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Storyboarding for Puppetry Narratives',                                      (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Character and Environment Designs for the Puppetry World',            (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Illustrate a Graphic Novel Based on Puppetry Narratives',                    (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop a User-Friendly Repository for Canonical Media',                     (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('UX/UI Development for Puppetry-Based Educational Platforms',                 (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Mobile Interfaces for Puppetry-Driven Apps',                          (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Short Films and Animations Based on Puppetry Stories',                (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Title Sequences for Puppetry-Based Performances',                     (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop Motion Design for Social Media',                                     (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Packaging for Puppetry-Related Merchandise',                          (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Publication Design for Digital and Print Media',                             (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design E-books with Shadow Puppet Illustrations and Animations',             (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Analyze Web Traffic and UX for Puppetry Websites',                           (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop User Engagement Tracking for Puppetry Platforms',                    (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Rich Media for AI-Enhanced Performance Systems',                             (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop Interactive AR/VR Experiences for Puppetry Performances',            (SELECT level_id FROM levels WHERE name='Intermediate'),(SELECT status_id FROM statuses WHERE name='Proposed'));

-- Advanced level
INSERT INTO projects (title, level_id, status_id) VALUES
    ('Develop Branding for Blended Reality Performance System (BRPS)',             (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Cross-Platform Visual Identity for Hybrid Performances',              (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop Motion Design Sequences for Testing AI Interaction',                 (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Media for AI-Mediated Performances',                             (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Augmented Reality Motion Design for Hybrid Spaces',                          (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Driven Social Media Engagement for Hybrid Events',                        (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Campaigns that Highlight AI Collaboration in BRPS',                   (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Campaign for Audience Engagement in Mediation Pathway Experiments',          (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Illustrate the Mediation Pathway in BRPS',                                   (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('World-Building for Hybrid Reality Performance',                              (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Illustration for Collaborative AI Stories in BRPS',                          (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design Interfaces for AI-Driven Interactive Experiences',                    (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Develop User Experience for Testing Mediation Pathways',                     (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Web Repository for Narrative Content',                           (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Video Documentation of AI and Human Collaboration in BRPS',                  (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Educational Videos on Mediation Pathways',                            (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Collaborative AI and Human-Generated Animation',                             (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Physical and Digital Packaging for BRPS Experiences',                 (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive Digital Publications for AI and Human Collaboration',            (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Create Data Visualizations for AI-Human Collaboration',                      (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Test and Evaluate Mediation Pathways Through User Interaction',              (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Data Analytics for Collaborative AI Projects',                               (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Collaborative Animation with AI Systems',                                    (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Rich Media Development for AI-Driven Performance Systems',                   (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Mediated Character Design and Visual Elements',                           (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Assisted Narrative Development in BRPS',                                  (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Test Collaborative Design Tools with AI',                                    (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Interactive AI-Assisted Performance Projects',                               (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('AI-Assisted Storytelling in Interactive Environments',                       (SELECT level_id FROM levels WHERE name='Advanced'),(SELECT status_id FROM statuses WHERE name='Proposed'));

-- Attach every COMD-listed item (Beginning + Intermediate + Advanced) to COMD
-- Easiest path: enumerate all titles in one bulk insert
INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Create Digital Posters for Hybrid Performances','Basic Logo Design for Project Sub-Groups',
        'Create Simple Character Concepts for Puppetry Projects','Design a Consistent Style Guide for Puppetry Projects',
        'Design Basic Web Page Layouts','Assist with User Interface Elements for Mobile Apps',
        'Create Basic Social Media Posts for Project Updates','Research Audience Engagement for Social Media',
        'Design Simple Infographics for Project Communication','Edit Short Video Clips for Performance Documentation',
        'Capture Basic Video Footage for Behind-the-Scenes Content','Create Animated GIFs for Social Media',
        'Research Visual Styles for Puppetry Design','Research Simple Storytelling Techniques',
        'Write Short Promotional Copy for Performances','Design and Animate Simple 2D Character Movements',
        'Create Motion Graphics for Simple Project Intros','Collect Basic Data on User Interactions',
        'Create Basic Reports on Audience Engagement',
        'Develop and Maintain Visual Identity Systems for the Shadow Puppetry Canon',
        'Design Visual Identity for AI-Driven Collaborative Projects','Logo and Branding Design for Sub-Projects',
        'Design Motion Graphics for Puppetry-Based Narratives','Develop Interactive Web Experiences for Puppetry Narratives',
        'Create Interactive Motion Design Assets for AR/VR Experiences','Plan and Execute Campaigns for Virtual Puppetry Events',
        'Self-Referential Marketing Campaigns Highlighting BSP Projects',
        'Develop Cross-Platform Marketing Campaigns for Shadow Puppetry Performances','Storyboarding for Puppetry Narratives',
        'Create Character and Environment Designs for the Puppetry World','Illustrate a Graphic Novel Based on Puppetry Narratives',
        'Develop a User-Friendly Repository for Canonical Media','UX/UI Development for Puppetry-Based Educational Platforms',
        'Design Mobile Interfaces for Puppetry-Driven Apps','Create Short Films and Animations Based on Puppetry Stories',
        'Design Title Sequences for Puppetry-Based Performances','Develop Motion Design for Social Media',
        'Design Packaging for Puppetry-Related Merchandise','Publication Design for Digital and Print Media',
        'Design E-books with Shadow Puppet Illustrations and Animations','Analyze Web Traffic and UX for Puppetry Websites',
        'Develop User Engagement Tracking for Puppetry Platforms','Rich Media for AI-Enhanced Performance Systems',
        'Develop Interactive AR/VR Experiences for Puppetry Performances',
        'Develop Branding for Blended Reality Performance System (BRPS)','Design Cross-Platform Visual Identity for Hybrid Performances',
        'Develop Motion Design Sequences for Testing AI Interaction','Interactive Media for AI-Mediated Performances',
        'Augmented Reality Motion Design for Hybrid Spaces','AI-Driven Social Media Engagement for Hybrid Events',
        'Create Campaigns that Highlight AI Collaboration in BRPS','Campaign for Audience Engagement in Mediation Pathway Experiments',
        'Illustrate the Mediation Pathway in BRPS','World-Building for Hybrid Reality Performance',
        'Illustration for Collaborative AI Stories in BRPS','Design Interfaces for AI-Driven Interactive Experiences',
        'Develop User Experience for Testing Mediation Pathways','Interactive Web Repository for Narrative Content',
        'Video Documentation of AI and Human Collaboration in BRPS','Create Educational Videos on Mediation Pathways',
        'Collaborative AI and Human-Generated Animation','Create Physical and Digital Packaging for BRPS Experiences',
        'Interactive Digital Publications for AI and Human Collaboration','Create Data Visualizations for AI-Human Collaboration',
        'Test and Evaluate Mediation Pathways Through User Interaction','Data Analytics for Collaborative AI Projects',
        'Collaborative Animation with AI Systems','Rich Media Development for AI-Driven Performance Systems',
        'AI-Mediated Character Design and Visual Elements','AI-Assisted Narrative Development in BRPS',
        'Test Collaborative Design Tools with AI','Interactive AI-Assisted Performance Projects',
        'AI-Assisted Storytelling in Interactive Environments'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='COMD'), 1
    FROM projects p
    WHERE p.project_id IN (SELECT project_id FROM project_categories WHERE category_id=(SELECT category_id FROM categories WHERE name='Department Research'))
      AND p.title IN (
        'Create Digital Posters for Hybrid Performances','Basic Logo Design for Project Sub-Groups',
        'Create Simple Character Concepts for Puppetry Projects','Design a Consistent Style Guide for Puppetry Projects',
        'Design Basic Web Page Layouts','Assist with User Interface Elements for Mobile Apps',
        'Create Basic Social Media Posts for Project Updates','Research Audience Engagement for Social Media',
        'Design Simple Infographics for Project Communication','Edit Short Video Clips for Performance Documentation',
        'Capture Basic Video Footage for Behind-the-Scenes Content','Create Animated GIFs for Social Media',
        'Research Visual Styles for Puppetry Design','Research Simple Storytelling Techniques',
        'Write Short Promotional Copy for Performances','Design and Animate Simple 2D Character Movements',
        'Create Motion Graphics for Simple Project Intros','Collect Basic Data on User Interactions',
        'Create Basic Reports on Audience Engagement',
        'Develop and Maintain Visual Identity Systems for the Shadow Puppetry Canon',
        'Design Visual Identity for AI-Driven Collaborative Projects','Logo and Branding Design for Sub-Projects',
        'Design Motion Graphics for Puppetry-Based Narratives','Develop Interactive Web Experiences for Puppetry Narratives',
        'Create Interactive Motion Design Assets for AR/VR Experiences','Plan and Execute Campaigns for Virtual Puppetry Events',
        'Self-Referential Marketing Campaigns Highlighting BSP Projects',
        'Develop Cross-Platform Marketing Campaigns for Shadow Puppetry Performances','Storyboarding for Puppetry Narratives',
        'Create Character and Environment Designs for the Puppetry World','Illustrate a Graphic Novel Based on Puppetry Narratives',
        'Develop a User-Friendly Repository for Canonical Media','UX/UI Development for Puppetry-Based Educational Platforms',
        'Design Mobile Interfaces for Puppetry-Driven Apps','Create Short Films and Animations Based on Puppetry Stories',
        'Design Title Sequences for Puppetry-Based Performances','Develop Motion Design for Social Media',
        'Design Packaging for Puppetry-Related Merchandise','Publication Design for Digital and Print Media',
        'Design E-books with Shadow Puppet Illustrations and Animations','Analyze Web Traffic and UX for Puppetry Websites',
        'Develop User Engagement Tracking for Puppetry Platforms','Rich Media for AI-Enhanced Performance Systems',
        'Develop Interactive AR/VR Experiences for Puppetry Performances',
        'Develop Branding for Blended Reality Performance System (BRPS)','Design Cross-Platform Visual Identity for Hybrid Performances',
        'Develop Motion Design Sequences for Testing AI Interaction','Interactive Media for AI-Mediated Performances',
        'Augmented Reality Motion Design for Hybrid Spaces','AI-Driven Social Media Engagement for Hybrid Events',
        'Create Campaigns that Highlight AI Collaboration in BRPS','Campaign for Audience Engagement in Mediation Pathway Experiments',
        'Illustrate the Mediation Pathway in BRPS','World-Building for Hybrid Reality Performance',
        'Illustration for Collaborative AI Stories in BRPS','Design Interfaces for AI-Driven Interactive Experiences',
        'Develop User Experience for Testing Mediation Pathways','Interactive Web Repository for Narrative Content',
        'Video Documentation of AI and Human Collaboration in BRPS','Create Educational Videos on Mediation Pathways',
        'Collaborative AI and Human-Generated Animation','Create Physical and Digital Packaging for BRPS Experiences',
        'Interactive Digital Publications for AI and Human Collaboration','Create Data Visualizations for AI-Human Collaboration',
        'Test and Evaluate Mediation Pathways Through User Interaction','Data Analytics for Collaborative AI Projects',
        'Collaborative Animation with AI Systems','Rich Media Development for AI-Driven Performance Systems',
        'AI-Mediated Character Design and Visual Elements','AI-Assisted Narrative Development in BRPS',
        'Test Collaborative Design Tools with AI','Interactive AI-Assisted Performance Projects',
        'AI-Assisted Storytelling in Interactive Environments'
    );

-- ----- English (ENG) ----------------------------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Narrative Writing for Interactive Shadow Puppetry Games',                            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Cultural Research on Global Puppetry Traditions',                                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Technical Writing for Shadow Puppetry Documentation',                                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Scriptwriting and Dialogue Development for Interactive Games',                       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on the Intersection of Traditional and Modern Storytelling Techniques',     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Development of Scripted Narratives for AR/VR Puppetry',                              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on Symbolism in Shadow Puppetry Across Cultures',                           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Writing Multilingual Puppetry Narratives for Digital Story Platforms',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Interactive Fiction Using Puppetry Characters for Digital Books',           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Exploring Puppetry as a Narrative Device in Contemporary Fiction',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Collaborative Writing Projects Using AI Puppetry Characters',             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Interactive E-books with Puppetry Themes for Young Readers',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Documenting Global Puppetry Traditions for Digital Storytelling Platforms',          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on the Evolution of Puppetry in Modern Media and Gaming',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Non-Linear Puppetry-Based Narratives for Virtual Experiences',              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Writing Interactive Puppetry Stories for Cross-Cultural Education',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Digital Narrative Analysis of Puppetry Themes Across Global Cultures',               (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Narrative Writing for Interactive Shadow Puppetry Games','Cultural Research on Global Puppetry Traditions',
        'Technical Writing for Shadow Puppetry Documentation','Scriptwriting and Dialogue Development for Interactive Games',
        'Research on the Intersection of Traditional and Modern Storytelling Techniques',
        'Development of Scripted Narratives for AR/VR Puppetry','Research on Symbolism in Shadow Puppetry Across Cultures',
        'Writing Multilingual Puppetry Narratives for Digital Story Platforms',
        'Creating Interactive Fiction Using Puppetry Characters for Digital Books',
        'Exploring Puppetry as a Narrative Device in Contemporary Fiction',
        'Developing Collaborative Writing Projects Using AI Puppetry Characters',
        'Creating Interactive E-books with Puppetry Themes for Young Readers',
        'Documenting Global Puppetry Traditions for Digital Storytelling Platforms',
        'Research on the Evolution of Puppetry in Modern Media and Gaming',
        'Creating Non-Linear Puppetry-Based Narratives for Virtual Experiences',
        'Writing Interactive Puppetry Stories for Cross-Cultural Education',
        'Digital Narrative Analysis of Puppetry Themes Across Global Cultures'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='ENG'), 1
    FROM projects p
    WHERE p.title IN (
        'Narrative Writing for Interactive Shadow Puppetry Games','Cultural Research on Global Puppetry Traditions',
        'Technical Writing for Shadow Puppetry Documentation','Scriptwriting and Dialogue Development for Interactive Games',
        'Research on the Intersection of Traditional and Modern Storytelling Techniques',
        'Development of Scripted Narratives for AR/VR Puppetry','Research on Symbolism in Shadow Puppetry Across Cultures',
        'Writing Multilingual Puppetry Narratives for Digital Story Platforms',
        'Creating Interactive Fiction Using Puppetry Characters for Digital Books',
        'Exploring Puppetry as a Narrative Device in Contemporary Fiction',
        'Developing Collaborative Writing Projects Using AI Puppetry Characters',
        'Creating Interactive E-books with Puppetry Themes for Young Readers',
        'Documenting Global Puppetry Traditions for Digital Storytelling Platforms',
        'Research on the Evolution of Puppetry in Modern Media and Gaming',
        'Creating Non-Linear Puppetry-Based Narratives for Virtual Experiences',
        'Writing Interactive Puppetry Stories for Cross-Cultural Education',
        'Digital Narrative Analysis of Puppetry Themes Across Global Cultures'
    );

-- ----- Business / Fashion Technology (FAS) ------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Textile Integration for Augmented and Virtual Reality Experiences',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design of Fabric-Based Scenic Elements for Puppetry Performances',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Tensile Fabric Integration with Modular Armatures',                                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Experimentation with Light and Shadow Interactions on Various Textiles',             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Innovative Uses of Cloth in Interactive Shadow Puppetry',                            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Wearable Puppetry Costumes for Mixed Reality Performances',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Integrating Smart Textiles in Puppetry Performances for Real-Time Visual Changes',   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Augmented Reality Fashion Experiences Based on Puppetry Themes',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Puppetry-Inspired Wearable Art for Theatrical Performances',              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Fashion Collections Based on Global Puppetry Traditions',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Puppetry-Based Accessories for Augmented Reality Platforms',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Smart Fabric Integration for Puppetry in Interactive Public Performances',           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Projection-Mapped Fashion Shows Inspired by Puppetry Narratives',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Interactive Fashion Installations with Puppetry Motifs',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Wearable Technology for Puppetry-Inspired Fashion Exhibits',              (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Textile Integration for Augmented and Virtual Reality Experiences',
        'Design of Fabric-Based Scenic Elements for Puppetry Performances',
        'Tensile Fabric Integration with Modular Armatures',
        'Experimentation with Light and Shadow Interactions on Various Textiles',
        'Innovative Uses of Cloth in Interactive Shadow Puppetry',
        'Designing Wearable Puppetry Costumes for Mixed Reality Performances',
        'Integrating Smart Textiles in Puppetry Performances for Real-Time Visual Changes',
        'Creating Augmented Reality Fashion Experiences Based on Puppetry Themes',
        'Developing Puppetry-Inspired Wearable Art for Theatrical Performances',
        'Designing Fashion Collections Based on Global Puppetry Traditions',
        'Creating Puppetry-Based Accessories for Augmented Reality Platforms',
        'Smart Fabric Integration for Puppetry in Interactive Public Performances',
        'Projection-Mapped Fashion Shows Inspired by Puppetry Narratives',
        'Designing Interactive Fashion Installations with Puppetry Motifs',
        'Developing Wearable Technology for Puppetry-Inspired Fashion Exhibits'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='FAS'), 1
    FROM projects p
    WHERE p.title IN (
        'Textile Integration for Augmented and Virtual Reality Experiences',
        'Design of Fabric-Based Scenic Elements for Puppetry Performances',
        'Tensile Fabric Integration with Modular Armatures',
        'Experimentation with Light and Shadow Interactions on Various Textiles',
        'Innovative Uses of Cloth in Interactive Shadow Puppetry',
        'Designing Wearable Puppetry Costumes for Mixed Reality Performances',
        'Integrating Smart Textiles in Puppetry Performances for Real-Time Visual Changes',
        'Creating Augmented Reality Fashion Experiences Based on Puppetry Themes',
        'Developing Puppetry-Inspired Wearable Art for Theatrical Performances',
        'Designing Fashion Collections Based on Global Puppetry Traditions',
        'Creating Puppetry-Based Accessories for Augmented Reality Platforms',
        'Smart Fabric Integration for Puppetry in Interactive Public Performances',
        'Projection-Mapped Fashion Shows Inspired by Puppetry Narratives',
        'Designing Interactive Fashion Installations with Puppetry Motifs',
        'Developing Wearable Technology for Puppetry-Inspired Fashion Exhibits'
    );

-- ----- Architectural Technology (ARCH) ----------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Modular Armature Design and Construction',                                           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design of Immersive Puppetry Stage Architecture',                                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Modular Stage Design for Enhanced Audience Immersion',                               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Modular Scenic Transitions with Laser-Cut Backdrops',                                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design of Large-Scale Set Pieces for Performances',                                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Integration of Traditional Architectural Elements into Shadow Puppet Staging',       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Outdoor Performance Spaces for Puppetry-Based Festivals',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Modular Pop-Up Stages for Puppetry Performances in Public Spaces',          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Immersive Digital-Physical Performance Spaces for Puppetry',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Temporary Architectural Installations for Puppetry Shows',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Curating Large-Scale Urban Art Installations Featuring Digital Puppetry',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Interactive Public Spaces for Real-Time Puppetry Performances',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Architectural Planning for Global Puppetry Cultural Exchange Spaces',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Integration of Virtual Reality Performance Spaces for Puppetry',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Dynamic Performance Stages for Mixed Reality Shows',                        (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Sustainable Design of Mobile Theaters for International Puppetry Shows',             (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Modular Armature Design and Construction','Design of Immersive Puppetry Stage Architecture',
        'Modular Stage Design for Enhanced Audience Immersion','Modular Scenic Transitions with Laser-Cut Backdrops',
        'Design of Large-Scale Set Pieces for Performances',
        'Integration of Traditional Architectural Elements into Shadow Puppet Staging',
        'Designing Outdoor Performance Spaces for Puppetry-Based Festivals',
        'Creating Modular Pop-Up Stages for Puppetry Performances in Public Spaces',
        'Designing Immersive Digital-Physical Performance Spaces for Puppetry',
        'Developing Temporary Architectural Installations for Puppetry Shows',
        'Curating Large-Scale Urban Art Installations Featuring Digital Puppetry',
        'Designing Interactive Public Spaces for Real-Time Puppetry Performances',
        'Architectural Planning for Global Puppetry Cultural Exchange Spaces',
        'Integration of Virtual Reality Performance Spaces for Puppetry',
        'Creating Dynamic Performance Stages for Mixed Reality Shows',
        'Sustainable Design of Mobile Theaters for International Puppetry Shows'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='ARCH'), 1
    FROM projects p
    WHERE p.title IN (
        'Modular Armature Design and Construction','Design of Immersive Puppetry Stage Architecture',
        'Modular Stage Design for Enhanced Audience Immersion','Modular Scenic Transitions with Laser-Cut Backdrops',
        'Design of Large-Scale Set Pieces for Performances',
        'Integration of Traditional Architectural Elements into Shadow Puppet Staging',
        'Designing Outdoor Performance Spaces for Puppetry-Based Festivals',
        'Creating Modular Pop-Up Stages for Puppetry Performances in Public Spaces',
        'Designing Immersive Digital-Physical Performance Spaces for Puppetry',
        'Developing Temporary Architectural Installations for Puppetry Shows',
        'Curating Large-Scale Urban Art Installations Featuring Digital Puppetry',
        'Designing Interactive Public Spaces for Real-Time Puppetry Performances',
        'Architectural Planning for Global Puppetry Cultural Exchange Spaces',
        'Integration of Virtual Reality Performance Spaces for Puppetry',
        'Creating Dynamic Performance Stages for Mixed Reality Shows',
        'Sustainable Design of Mobile Theaters for International Puppetry Shows'
    );

-- ----- Mechanical Engineering Technology (MECH) -------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Design and Development of Standardized Articulated Joints',                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('3D-Printed Shadow Puppet Joints and Mechanisms',                                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Robotic Armature for Puppet Automation',                                             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Customizable 3D-Printed Gears for Shadow Puppet Movement',                           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('CNC-Fabricated Shadow Puppet Components for Large-Scale Performances',               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Physical Adapters for System Integration',                                           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Testing and Evaluation of Set Stability and Durability',                             (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Large-Scale Articulated Puppetry for Public Performances',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Engineering Modular Puppetry Set Pieces with Hydraulic Motion Systems',              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Designing Robotics for Precision-Controlled Puppetry Movements',                     (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Large-Scale Kinetic Sculptures Based on Puppetry Mechanics',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing AI-Powered Mechanical Puppets for Automated Performances',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Design of Modular Mechanical Puppets for Multi-Layered Performances',                (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Innovating New Mechanical Joints for Complex Puppetry Movements',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Creating Pneumatic Systems for Large-Scale Interactive Puppetry',                    (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Advanced Control Mechanisms for Dynamic Puppetry Sets',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Engineering Interactive Puppetry Robots for Public Events',                          (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Design and Development of Standardized Articulated Joints','3D-Printed Shadow Puppet Joints and Mechanisms',
        'Robotic Armature for Puppet Automation','Customizable 3D-Printed Gears for Shadow Puppet Movement',
        'CNC-Fabricated Shadow Puppet Components for Large-Scale Performances','Physical Adapters for System Integration',
        'Testing and Evaluation of Set Stability and Durability',
        'Developing Large-Scale Articulated Puppetry for Public Performances',
        'Engineering Modular Puppetry Set Pieces with Hydraulic Motion Systems',
        'Designing Robotics for Precision-Controlled Puppetry Movements',
        'Creating Large-Scale Kinetic Sculptures Based on Puppetry Mechanics',
        'Developing AI-Powered Mechanical Puppets for Automated Performances',
        'Design of Modular Mechanical Puppets for Multi-Layered Performances',
        'Innovating New Mechanical Joints for Complex Puppetry Movements',
        'Creating Pneumatic Systems for Large-Scale Interactive Puppetry',
        'Developing Advanced Control Mechanisms for Dynamic Puppetry Sets',
        'Engineering Interactive Puppetry Robots for Public Events'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='MECH'), 1
    FROM projects p
    WHERE p.title IN (
        'Design and Development of Standardized Articulated Joints','3D-Printed Shadow Puppet Joints and Mechanisms',
        'Robotic Armature for Puppet Automation','Customizable 3D-Printed Gears for Shadow Puppet Movement',
        'CNC-Fabricated Shadow Puppet Components for Large-Scale Performances','Physical Adapters for System Integration',
        'Testing and Evaluation of Set Stability and Durability',
        'Developing Large-Scale Articulated Puppetry for Public Performances',
        'Engineering Modular Puppetry Set Pieces with Hydraulic Motion Systems',
        'Designing Robotics for Precision-Controlled Puppetry Movements',
        'Creating Large-Scale Kinetic Sculptures Based on Puppetry Mechanics',
        'Developing AI-Powered Mechanical Puppets for Automated Performances',
        'Design of Modular Mechanical Puppets for Multi-Layered Performances',
        'Innovating New Mechanical Joints for Complex Puppetry Movements',
        'Creating Pneumatic Systems for Large-Scale Interactive Puppetry',
        'Developing Advanced Control Mechanisms for Dynamic Puppetry Sets',
        'Engineering Interactive Puppetry Robots for Public Events'
    );

-- ----- Humanities (HUM) -------------------------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Research on Global Cultural Narratives in Shadow Puppetry',                          (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Comparative Analysis of Cultural Storytelling in Digital Puppetry',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Exploring Traditional African and Asian Puppetry in the Context of Modern Digital Performance', (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Study of Symbolism and Metaphor in Shadow Puppetry Across Cultures',                 (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Development of Educational Curricula for Shadow Puppetry Traditions and Technologies',(SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Workshops on Integrating Digital Storytelling with Traditional Puppetry',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on Cross-Cultural Influences in Puppetry Techniques and Technologies',      (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on Puppetry as a Form of Political and Social Commentary',                  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Cross-Cultural Puppetry Workshops for Global Storytelling Initiatives',              (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Exploring Puppetry''s Impact on Children''s Education in Global Cultures',           (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Documenting the Intersection of Puppetry and Ritual in Cultural Traditions',         (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on Puppetry''s Role in Preserving Indigenous Narratives',                   (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Studying the Use of Puppetry in Religious and Ceremonial Practices',                 (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Researching Puppetry''s Function in Peacebuilding and Cultural Exchange',            (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Developing Cross-Cultural Puppetry Storytelling Workshops for Conflict Resolution',  (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Exploring Puppetry''s Role in Contemporary Media and Communication Theories',        (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Research on Global Cultural Narratives in Shadow Puppetry',
        'Comparative Analysis of Cultural Storytelling in Digital Puppetry',
        'Exploring Traditional African and Asian Puppetry in the Context of Modern Digital Performance',
        'Study of Symbolism and Metaphor in Shadow Puppetry Across Cultures',
        'Development of Educational Curricula for Shadow Puppetry Traditions and Technologies',
        'Workshops on Integrating Digital Storytelling with Traditional Puppetry',
        'Research on Cross-Cultural Influences in Puppetry Techniques and Technologies',
        'Research on Puppetry as a Form of Political and Social Commentary',
        'Cross-Cultural Puppetry Workshops for Global Storytelling Initiatives',
        'Exploring Puppetry''s Impact on Children''s Education in Global Cultures',
        'Documenting the Intersection of Puppetry and Ritual in Cultural Traditions',
        'Research on Puppetry''s Role in Preserving Indigenous Narratives',
        'Studying the Use of Puppetry in Religious and Ceremonial Practices',
        'Researching Puppetry''s Function in Peacebuilding and Cultural Exchange',
        'Developing Cross-Cultural Puppetry Storytelling Workshops for Conflict Resolution',
        'Exploring Puppetry''s Role in Contemporary Media and Communication Theories'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='HUM'), 1
    FROM projects p
    WHERE p.title IN (
        'Research on Global Cultural Narratives in Shadow Puppetry',
        'Comparative Analysis of Cultural Storytelling in Digital Puppetry',
        'Exploring Traditional African and Asian Puppetry in the Context of Modern Digital Performance',
        'Study of Symbolism and Metaphor in Shadow Puppetry Across Cultures',
        'Development of Educational Curricula for Shadow Puppetry Traditions and Technologies',
        'Workshops on Integrating Digital Storytelling with Traditional Puppetry',
        'Research on Cross-Cultural Influences in Puppetry Techniques and Technologies',
        'Research on Puppetry as a Form of Political and Social Commentary',
        'Cross-Cultural Puppetry Workshops for Global Storytelling Initiatives',
        'Exploring Puppetry''s Impact on Children''s Education in Global Cultures',
        'Documenting the Intersection of Puppetry and Ritual in Cultural Traditions',
        'Research on Puppetry''s Role in Preserving Indigenous Narratives',
        'Studying the Use of Puppetry in Religious and Ceremonial Practices',
        'Researching Puppetry''s Function in Peacebuilding and Cultural Exchange',
        'Developing Cross-Cultural Puppetry Storytelling Workshops for Conflict Resolution',
        'Exploring Puppetry''s Role in Contemporary Media and Communication Theories'
    );

-- ----- Social Sciences (SOC) --------------------------------------------------
INSERT INTO projects (title, status_id) VALUES
    ('Audience Research on Engagement with Digital and Physical Puppetry',                 (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Sociological Analysis of Puppetry''s Cultural Impact',                               (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Ethical Considerations in Representing Cultural Narratives in Virtual Worlds',       (SELECT status_id FROM statuses WHERE name='Proposed')),
    ('Research on Community Engagement Through Traditional and Digital Puppetry',          (SELECT status_id FROM statuses WHERE name='Proposed'));

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Department Research')
    FROM projects p
    WHERE p.title IN (
        'Audience Research on Engagement with Digital and Physical Puppetry',
        'Sociological Analysis of Puppetry''s Cultural Impact',
        'Ethical Considerations in Representing Cultural Narratives in Virtual Worlds',
        'Research on Community Engagement Through Traditional and Digital Puppetry'
    );

INSERT INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='SOC'), 1
    FROM projects p
    WHERE p.title IN (
        'Audience Research on Engagement with Digital and Physical Puppetry',
        'Sociological Analysis of Puppetry''s Cultural Impact',
        'Ethical Considerations in Representing Cultural Narratives in Virtual Worlds',
        'Research on Community Engagement Through Traditional and Digital Puppetry'
    );

-- =============================================================================
-- SEMESTER COHORT PROJECTS (Fall 2024)
-- =============================================================================
INSERT INTO projects (title, semester, status_id, primary_url, summary) VALUES
    ('AI Generated Media Control',                                  'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://www.dropbox.com/scl/fi/nmf8zk917xw15bzds1um0/Independent-Study-Edward-Gonzalez-Fall-2024-Research-Proposal_-Integrating-Generative-AI-with-QLab-Using-Open-Sound-Control-OSC.pdf','Integrating Generative AI with QLab using OSC -- Edward Gonzalez'),
    ('Live Sound System Development',                                'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://docs.google.com/document/d/1pVfn8B1TqrQNmJ44UVW2rspqUWiWgy9w2FmLZ3M84Ps/edit?usp=sharing','Live sound system for BSP performances -- Anthony Navarro'),
    ('BSP Theatre Script Development',                               'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://docs.google.com/document/d/1rmCygzSqFIW71gwrwRgOOHxS-eqSIdOP1MMM0oZSp9o/edit?usp=sharing','BSP theatre script -- Tshari Yancey'),
    ('AI Assets for Live Blended Shadow Puppet',                     'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),NULL,'AI-generated assets for live BSP -- Samuel Cheung'),
    ('Designing Virtual Assets for Shadow Puppet Environments in Unity','Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),NULL,'Unity virtual asset design -- Hugo Sanchez'),
    ('Shadow Puppet Alternate Reality: Twine-Based Interactive Game','Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),NULL,'Twine-based interactive game -- Samuel Cheung'),
    ('Unity Platform Development for BSP 2D Virtual Environment',    'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),NULL,'Unity 2D environment -- Zixuan Wu'),
    ('AI Image Generation in Video Game Design',                     'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://www.dropbox.com/scl/fi/idemrtr2im9w5b7wpkqgj/Cheung-Sam-ESP-Proposal-2024-Fall.docx?rlkey=f92lyxdu4ipeugnn492p38734&st=7unacdf0&dl=0','AI image generation for game design -- Samuel Cheung'),
    ('World Building Platform',                                      'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://github.com/orgs/CHI-CityTech/projects/5?pane=info','World building GitHub project -- Tshari Yancey & Samuel Cheung'),
    ('Investigating AI Image Generation Capabilities',               'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://sites.google.com/view/balancedblendedspace/projects/ai-image-generators-evaluation','AI image-gen comparative evaluation -- Priya Begum'),
    ('Website Development and Project Management',                   'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),'https://docs.google.com/document/d/1-zqDTzT1-qFCXH0JD6zMqpXDfrvb6A2uWM_DEsm3pNE/edit','Website + PM work -- Priya Begum'),
    ('Chess-Inspired Shadow/Light Game Development',                 'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),NULL,'Chess-inspired light/shadow game -- Cordell Lane'),
    ('BSP Narrative and Character Development',                      'Fall 2024',(SELECT status_id FROM statuses WHERE name='Archived'),NULL,'Narrative + character dev -- John Powell');

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Semester Cohort')
    FROM projects p
    WHERE p.semester='Fall 2024';

-- Fall 2024 researcher assignments
INSERT INTO project_researchers (project_id, researcher_id, role) VALUES
    ((SELECT project_id FROM projects WHERE title='AI Generated Media Control'),                      (SELECT researcher_id FROM researchers WHERE full_name='Edward Gonzalez'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Live Sound System Development'),                   (SELECT researcher_id FROM researchers WHERE full_name='Anthony Navarro'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='BSP Theatre Script Development'),                  (SELECT researcher_id FROM researchers WHERE full_name='Tshari Yancey'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='AI Assets for Live Blended Shadow Puppet'),        (SELECT researcher_id FROM researchers WHERE full_name='Samuel Cheung'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Designing Virtual Assets for Shadow Puppet Environments in Unity'),(SELECT researcher_id FROM researchers WHERE full_name='Hugo Sanchez'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Shadow Puppet Alternate Reality: Twine-Based Interactive Game'),(SELECT researcher_id FROM researchers WHERE full_name='Samuel Cheung'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Unity Platform Development for BSP 2D Virtual Environment'),(SELECT researcher_id FROM researchers WHERE full_name='Zixuan Wu'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='AI Image Generation in Video Game Design'),        (SELECT researcher_id FROM researchers WHERE full_name='Samuel Cheung'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='World Building Platform'),                         (SELECT researcher_id FROM researchers WHERE full_name='Tshari Yancey'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='World Building Platform'),                         (SELECT researcher_id FROM researchers WHERE full_name='Samuel Cheung'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Investigating AI Image Generation Capabilities'),  (SELECT researcher_id FROM researchers WHERE full_name='Priya Begum'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Website Development and Project Management'),      (SELECT researcher_id FROM researchers WHERE full_name='Priya Begum'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='Chess-Inspired Shadow/Light Game Development'),    (SELECT researcher_id FROM researchers WHERE full_name='Cordell Lane'),'Lead'),
    ((SELECT project_id FROM projects WHERE title='BSP Narrative and Character Development'),         (SELECT researcher_id FROM researchers WHERE full_name='John Powell'),'Lead');

-- =============================================================================
-- SEMESTER COHORT PROJECTS (Spring 2025)
-- =============================================================================
INSERT INTO projects (title, semester, status_id, primary_url, summary, description) VALUES
    ('Quantum Music',                                                'Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),'https://github.com/CHI-CityTech/QuantumMusic',
        'Quantum computing applied to music analysis and generation of operatic works.',
        'Use quantum-compatible methodologies to analyze and generate new compositions inspired by Mozart and Rossini.'),
    ('Autonomous Vehicle Mobility Institute -- Audio Immersion in ATMOS','Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),NULL,
        'Acoustic simulation for AV-human interaction.',
        'Simulating acoustic environments to study autonomous-vehicle/human interactions using Dolby ATMOS.'),
    ('SeaChange 360 -- Immersive Projection',                        'Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),NULL,
        'Immersive 360 projection installation.', NULL),
    ('Balanced Blended Space -- Shadow Puppetry in Unreal',          'Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),NULL,
        'BSP environment authored inside Unreal Engine.', NULL),
    ('Blended Shadow Puppet Theatre',                                'Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),NULL,
        'Physical + virtual + AI-collaborative theatre.',
        'Building a stage and performance space, connecting it to a virtual world, collaborating with AI.'),
    ('CHI Digital Infrastructure',                                   'Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),NULL,
        'Integrated repository for all CHI data and virtual communication protocols.', NULL),
    ('International Collaboration -- Austrian American Educational Cooperation Association','Spring 2025',(SELECT status_id FROM statuses WHERE name='Active'),NULL,
        'International collaboration with the AAECA.', NULL);

INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Semester Cohort')
    FROM projects p
    WHERE p.semester='Spring 2025';

-- Spring 2025 Quantum Music team
INSERT INTO project_researchers (project_id, researcher_id, role) VALUES
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT researcher_id FROM researchers WHERE full_name='Oleg Berman'),'Technical Advisor'),
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT researcher_id FROM researchers WHERE full_name='Alyssa Burtsev'),'Student'),
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT researcher_id FROM researchers WHERE full_name='Mellisa Demolari'),'Student'),
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT researcher_id FROM researchers WHERE full_name='Elizabeth Frias'),'Student'),
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT researcher_id FROM researchers WHERE full_name='Houke Gao'),'Student'),
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT researcher_id FROM researchers WHERE full_name='Stefanie Rivera'),'Student');

-- =============================================================================
-- CATEGORY assignments for top-level pieces
-- =============================================================================
INSERT INTO project_categories (project_id, category_id) VALUES
    ((SELECT project_id FROM projects WHERE slug='bbs-theory'),                    (SELECT category_id FROM categories WHERE name='Theory')),
    ((SELECT project_id FROM projects WHERE slug='bbs-syntax'),                    (SELECT category_id FROM categories WHERE name='Syntax')),
    ((SELECT project_id FROM projects WHERE slug='bbs-syntax'),                    (SELECT category_id FROM categories WHERE name='Theory')),
    ((SELECT project_id FROM projects WHERE slug='brps'),                          (SELECT category_id FROM categories WHERE name='Practice')),
    ((SELECT project_id FROM projects WHERE slug='blended-shadow-puppet'),         (SELECT category_id FROM categories WHERE name='Meta-Project')),
    ((SELECT project_id FROM projects WHERE slug='world-building'),                (SELECT category_id FROM categories WHERE name='Meta-Project')),
    ((SELECT project_id FROM projects WHERE slug='ai-image-generators-evaluation'),(SELECT category_id FROM categories WHERE name='Meta-Project')),
    ((SELECT project_id FROM projects WHERE slug='fall-2024-research'),            (SELECT category_id FROM categories WHERE name='Semester Cohort')),
    ((SELECT project_id FROM projects WHERE slug='spring-2025-research'),          (SELECT category_id FROM categories WHERE name='Semester Cohort')),
    ((SELECT project_id FROM projects WHERE slug='personalized-llm'),              (SELECT category_id FROM categories WHERE name='Theory'));

-- Sub-project category for the four AI image-gen children
INSERT INTO project_categories (project_id, category_id)
    SELECT p.project_id, (SELECT category_id FROM categories WHERE name='Sub-Project')
    FROM projects p
    WHERE p.parent_project_id = (SELECT project_id FROM projects WHERE slug='ai-image-generators-evaluation');

-- =============================================================================
-- LINKS for top-level pieces and cohort projects
-- =============================================================================
INSERT INTO project_links (project_id, link_type_id, label, url, is_canonical) VALUES
    ((SELECT project_id FROM projects WHERE slug='bbs-theory'),(SELECT link_type_id FROM link_types WHERE name='Paper'),'BBS White Paper (CUNY Academic Works)','https://academicworks.cuny.edu/ny_pubs/1239/',1),
    ((SELECT project_id FROM projects WHERE slug='bbs-theory'),(SELECT link_type_id FROM link_types WHERE name='Google Drive'),'White Paper PDF (Drive)','https://drive.google.com/open?id=1GTGZkLXFIUO-xCxgF5jUhEY57bVNA6l4IaNPHzRPONw',0),
    ((SELECT project_id FROM projects WHERE slug='bbs-theory'),(SELECT link_type_id FROM link_types WHERE name='Dropbox'),'2024 City Tech Poster','https://www.dropbox.com/scl/fi/fl3tyu9xw8l56pbeak80r/DBS-BBS-Poster-for-22nd-Poster-Session-v2.pdf',0),
    ((SELECT project_id FROM projects WHERE slug='brps'),(SELECT link_type_id FROM link_types WHERE name='Google Drive'),'BRPS Stretched Fabric Components','https://drive.google.com/open?id=1K4v8sMsyLB63rExs2UqPzQ2h_qDVwvNpOCVMO1fyoH4',1),
    ((SELECT project_id FROM projects WHERE slug='brps'),(SELECT link_type_id FROM link_types WHERE name='Google Drive'),'BRPS Modular Pole + Connector System','https://drive.google.com/open?id=1wxxqKdPV23jkpp1OWPlHX86Q30jm274Vhb34w4lq4mo',0),
    ((SELECT project_id FROM projects WHERE slug='brps'),(SELECT link_type_id FROM link_types WHERE name='Google Drive'),'BRPS Stretched Fabric System Overview','https://drive.google.com/open?id=1SB4G8w61DzYdclu1lmahzyCYI4ud2Nde2VBQVLhpLII',0),
    ((SELECT project_id FROM projects WHERE title='Quantum Music'),(SELECT link_type_id FROM link_types WHERE name='GitHub'),'QuantumMusic Repo','https://github.com/CHI-CityTech/QuantumMusic',1),
    ((SELECT project_id FROM projects WHERE title='World Building Platform'),(SELECT link_type_id FROM link_types WHERE name='GitHub'),'World Building GitHub Project','https://github.com/orgs/CHI-CityTech/projects/5?pane=info',1),
    ((SELECT project_id FROM projects WHERE title='AI Generated Media Control'),(SELECT link_type_id FROM link_types WHERE name='Dropbox'),'Proposal PDF','https://www.dropbox.com/scl/fi/nmf8zk917xw15bzds1um0/Independent-Study-Edward-Gonzalez-Fall-2024-Research-Proposal_-Integrating-Generative-AI-with-QLab-Using-Open-Sound-Control-OSC.pdf',1),
    ((SELECT project_id FROM projects WHERE title='Live Sound System Development'),(SELECT link_type_id FROM link_types WHERE name='Google Doc'),'Proposal Doc','https://docs.google.com/document/d/1pVfn8B1TqrQNmJ44UVW2rspqUWiWgy9w2FmLZ3M84Ps/edit?usp=sharing',1),
    ((SELECT project_id FROM projects WHERE title='BSP Theatre Script Development'),(SELECT link_type_id FROM link_types WHERE name='Google Doc'),'Script Doc','https://docs.google.com/document/d/1rmCygzSqFIW71gwrwRgOOHxS-eqSIdOP1MMM0oZSp9o/edit?usp=sharing',1),
    ((SELECT project_id FROM projects WHERE title='AI Image Generation in Video Game Design'),(SELECT link_type_id FROM link_types WHERE name='Dropbox'),'Proposal','https://www.dropbox.com/scl/fi/idemrtr2im9w5b7wpkqgj/Cheung-Sam-ESP-Proposal-2024-Fall.docx?rlkey=f92lyxdu4ipeugnn492p38734&st=7unacdf0&dl=0',1),
    ((SELECT project_id FROM projects WHERE title='Website Development and Project Management'),(SELECT link_type_id FROM link_types WHERE name='Google Doc'),'PM Doc','https://docs.google.com/document/d/1-zqDTzT1-qFCXH0JD6zMqpXDfrvb6A2uWM_DEsm3pNE/edit',1),
    ((SELECT project_id FROM projects WHERE slug='personalized-llm'),(SELECT link_type_id FROM link_types WHERE name='Music'),'I am the Edison Factory Motor! (Suno)','https://suno.com/s/xqRASZfA66NTUdX6',0);

-- =============================================================================
-- CROSS-DEPARTMENT TAGS / OVERLAP examples
-- These are projects that, while listed under one department, clearly touch
-- multiple (AI ones touch CST, AR/VR ones touch MTEC, etc.).
-- =============================================================================

-- AI-* projects across departments cross-listed with CST
INSERT OR IGNORE INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='CST'), 0
    FROM projects p
    WHERE p.title LIKE 'AI-%' OR p.title LIKE '%AI %' OR p.title LIKE '%AI-%' OR p.title LIKE '%AI ' OR p.title='AI Generated Media Control';

-- AR/VR projects cross-listed with MTEC
INSERT OR IGNORE INTO project_departments (project_id, department_id, is_primary)
    SELECT p.project_id, (SELECT department_id FROM departments WHERE code='MTEC'), 0
    FROM projects p
    WHERE (p.title LIKE '%AR/VR%' OR p.title LIKE '%Augmented Reality%' OR p.title LIKE '%Virtual Reality%' OR p.title LIKE '%VR%' OR p.title LIKE '%AR %');

-- Tags: AI
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='AI')
    FROM projects p
    WHERE p.title LIKE '%AI%';

-- Tags: VR
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='VR')
    FROM projects p
    WHERE p.title LIKE '%VR%' OR p.title LIKE '%Virtual Reality%';

-- Tags: AR
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='AR')
    FROM projects p
    WHERE p.title LIKE '%AR %' OR p.title LIKE '%AR-%' OR p.title LIKE '%Augmented Reality%' OR p.title LIKE 'AR%';

-- Tags: Shadow Puppetry
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Shadow Puppetry')
    FROM projects p
    WHERE p.title LIKE '%Puppet%' OR p.title LIKE '%Shadow%';

-- Tags: Projection Mapping
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Projection Mapping')
    FROM projects p
    WHERE p.title LIKE '%Projection%';

-- Tags: 3D Printing
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='3D Printing')
    FROM projects p
    WHERE p.title LIKE '%3D-Printed%' OR p.title LIKE '%3D Print%';

-- Tags: Music / Sound
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Music')
    FROM projects p
    WHERE p.title LIKE '%Music%' OR p.title LIKE '%Soundtrack%' OR p.title='Quantum Music';

INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Sound')
    FROM projects p
    WHERE p.title LIKE '%Sound%' OR p.title LIKE '%Audio%' OR p.title LIKE '%Foley%';

-- Tags: Marketing
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Marketing')
    FROM projects p
    WHERE p.title LIKE '%Marketing%' OR p.title LIKE '%Campaign%' OR p.title LIKE '%Brand%';

-- Tags: World Building
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='World Building')
    FROM projects p
    WHERE p.title LIKE '%World Build%' OR p.slug='world-building';

-- Tags: LLM
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='LLM')
    FROM projects p
    WHERE p.slug='personalized-llm';

-- Tags: Quantum
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Quantum')
    FROM projects p
    WHERE p.title='Quantum Music';

-- Tags: Theory / Syntax
INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Theory')
    FROM projects p
    WHERE p.slug IN ('bbs-theory','bbs-syntax','personalized-llm');

INSERT OR IGNORE INTO project_tags (project_id, tag_id)
    SELECT p.project_id, (SELECT tag_id FROM tags WHERE name='Syntax')
    FROM projects p
    WHERE p.slug='bbs-syntax';

COMMIT;
