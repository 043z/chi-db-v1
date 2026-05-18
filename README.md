# Balanced Blended Space (BBS) -- Research Projects Database

A SQLite database modeling all research projects under the [Balanced Blended Space](https://sites.google.com/view/balancedblendedspace/home) framework. Projects are catalogued across 13 academic departments, multiple categories (Theory / Practice / Meta-Project / Semester Cohort / Sub-Project), tags, levels, statuses, researchers, and external links.

The source content is scraped from the public BBS site, primarily from the [Departments index](https://sites.google.com/view/balancedblendedspace/projects/departments) and each department/project page linked from it.

## Repository layout

```
balanced-blended-space-db/
├── README.md
├── balanced_blended_space.db        # built SQLite database (created by build_db.py)
├── sql/
│   ├── schema.sql                   # CREATE TABLE statements + indexes + views
│   ├── seed.sql                     # all departments, projects, links, researchers
│   ├── pipeline_schema.sql          # adds pending_submissions / review_log / ingestion_runs
│   └── queries.sql                  # example SELECTs
├── scripts/
│   ├── build_db.py                  # rebuild the DB from schema + seed
│   ├── query.py                     # CLI: departments, projects, crossdept, search, show
│   ├── export.py                    # dump every table to CSV + a combined JSON
│   ├── sync_github.py               # pull repo metadata from the GH org, classify activity
│   ├── link_repo.py                 # manual repo<->project linkage CLI
│   └── scan_repos.py                # parse README/docs of every repo into staged candidates
├── pipeline/
│   ├── README.md                    # end-to-end submission pipeline doc
│   ├── FORM_SETUP.md                # exact Google Form field spec
│   ├── ingest.py                    # Sheet CSV -> staging table
│   ├── review.py                    # reviewer CLI (approve / reject / list / show)
│   └── sample_submissions.csv       # offline test fixture
├── site/
│   ├── build_site.py                # writes ./site/dist for GitHub Pages
│   └── index.html                   # sql.js browser-side query page
├── .github/workflows/
│   ├── ingest-and-publish.yml       # hourly: ingest submissions + Pages deploy
│   ├── sync-github.yml              # daily 05:30 UTC: refresh CHI-CityTech repo metadata
│   └── scan-repos.yml               # daily 06:45 UTC: scan repo READMEs for project candidates
└── docs/
    └── er-diagram.md                # Mermaid ER diagram
```

## Adding new projects via researcher submissions

Researchers submit a Google Form. A GitHub Action ingests new responses
hourly, validates them, and stages them for reviewer approval. Approved
rows are promoted into the live `projects` table (plus department, tag,
researcher, and link join rows) and republished to GitHub Pages.

See [`pipeline/README.md`](pipeline/README.md) and
[`pipeline/FORM_SETUP.md`](pipeline/FORM_SETUP.md) for the full setup and the
exact Google Form field titles.

## GitHub integration -- Started / Finished / Never Started

The schema includes three project statuses driven by the
[CHI-CityTech GitHub org](https://github.com/CHI-CityTech): `Started`,
`Finished`, `Never Started`. A daily GitHub Action runs `scripts/sync_github.py`,
which pulls every public repo, classifies each by a heuristic, and links
repos to existing projects.

### Classification rule

| Bucket          | Trigger |
|-----------------|---------|
| `Finished`      | `archived == true` OR has at least one release tag |
| `Never Started` | 0 commits, OR size = 0, OR only the initial scaffold commit |
| `Started`       | has real commits (whether pushed recently or not) |

The reason is stored on `github_repos.activity_reason` so you can see why
the heuristic picked a bucket. To override, run
`scripts/link_repo.py set-status <repo_full_name> <bucket>`.

### Linking repos to projects

`sync_github.py` fuzzy-matches each repo's name against existing project
titles/slugs (after stripping `META-` / `CHI-` prefixes). Anything scoring
0.65 or higher gets linked in `project_github_repos`, with `match_method`
recording whether it was an `auto-slug`, `auto-fuzzy`, or `manual` match.
Manual links are never overwritten. To create one:

```bash
python3 scripts/link_repo.py list                # all repos + which project they map to
python3 scripts/link_repo.py unlinked            # repos waiting for a project
python3 scripts/link_repo.py link CHI-CityTech/Documentary 17
python3 scripts/link_repo.py unlink CHI-CityTech/Documentary
```

When a repo links to a project, the project's `status_id` is promoted to
match the repo's activity status -- but only if the project was previously
`Proposed`, `Concept`, or `Active`. Reviewer-set statuses are preserved.

### Convenience views

- `v_project_with_repo` -- one row per project with its primary repo + that repo's activity status.
- `v_repos_by_status`   -- count of repos in each bucket.

## Scanning inside the repos for project candidates

A daily GitHub Action also runs `scripts/scan_repos.py`, which goes one level
deeper than the metadata sync: for every repo it knows about, it fetches the
README plus any top-level `*.md`/`*.txt` and any `docs/*.md`, parses them for
candidate projects, and stages those candidates in `pending_submissions` with
`source='github-scan'`.

### What gets extracted

For each document:

- **H2 / H3 headings** that look like project titles become candidates (after
  filtering out generic section names like `Overview`, `Getting Started`,
  `Goals`, `Key Components`, etc.).
- **Top-level bullet points** like `- **Foo Bar**: description...` -- the
  parser keeps just the prefix before the colon so the title stays clean.
- **Tags** -- a curated keyword scan over the whole document body
  (e.g. `AI`, `VR`, `Unity`, `Shadow Puppetry`, `World Building`,
  `Quantum`, `Sound`, ...). These attach to every candidate from the same
  document.
- **External links** -- non-`github.com` http(s) URLs become proposed
  `project_links` rows.

### Reviewing scan candidates

```bash
python3 pipeline/review.py list --source github-scan    # only scan candidates
python3 pipeline/review.py show 4
python3 pipeline/review.py approve 4 --reviewer hosain --notes "useful sub-project"
python3 pipeline/review.py reject  9 --reviewer hosain -r "too generic"
```

Approving a scan row promotes it the same way a form submission does: a row in
`projects`, the auto-extracted tags attached (new tags are created on demand),
the source repo URL set as `primary_url`, and any extracted external links
inserted into `project_links`. The audit trail lives in `review_log`.

### Offline / dev mode

`scan_repos.py --fixture-dir <dir>` lets you point at a folder of pretend
READMEs named `<org>__<repo>__README.md` so you can iterate on the parser
without hitting the GitHub API.

## CHI²DS (CHIIDS) alignment

The database is wired to the [CHIIDS](https://github.com/CHI-CityTech/META-CHIIDS)
taxonomy so every row here can be located inside CHI's larger digital
ecosystem. Two orthogonal coordinate systems plus a fine-grained concept
list are seeded automatically by `sql/chiids_schema.sql` +
`sql/chiids_seed.sql`:

| Axis | Values | Table |
|---|---|---|
| **Cornerstone** | Management / Communications / Storage / Integration | `chiids_cornerstones` |
| **Layer**       | L0 Structural Framework / L1 Meta-Projects / L2 Coordination / L3 Execution | `chiids_layers` |
| **Concept**     | Living Archive, Project Documents, Public Website, External Systems, ... (one per leaf in the CHIIDS_V1 diagram) | `chiids_concepts` |

Every project, link, attachment, and GitHub repo gets coordinates in
`chiids_artifact_tags`. Auto-rules in the seed do the obvious backfill:

- projects → Management cornerstone, Layer 1 (meta-projects) or Layer 3 (everything else);
- project_links / project_attachments → Storage / Documentation Repository;
- github_repos → Integration + Storage / Version Control, Layer 1 (META-* repos), Layer 2 (CHI admin/coordination repos), or Layer 3 (execution repos).

External systems CHIIDS explicitly names (GitHub, OpenLab, WorldAnvil,
Zotero, OJS, Zenodo, WordPress, City Tech) are seeded in
`chiids_external_systems` and projects with matching URLs auto-link to them
via `project_external_systems`.

Two convenience views:

```sql
SELECT * FROM v_project_chiids WHERE project_id = 1;
SELECT * FROM v_chiids_coverage;
SELECT * FROM v_chiids_layer_coverage;
```

To tag your own artifact manually:

```sql
INSERT INTO chiids_artifact_tags (artifact_type, artifact_id,
                                  cornerstone_id, layer_id, concept_id,
                                  source, notes)
VALUES ('project', 42,
        (SELECT cornerstone_id FROM chiids_cornerstones WHERE code='comm'),
        2,
        (SELECT concept_id FROM chiids_concepts WHERE code='website'),
        'manual', 'this project IS the public site');
```

This deliberately *does not* duplicate CHIIDS' own relational schema —
following CHIIDS' "integration over creation" principle. The tags here just
let BBS rows be cross-referenced into CHIIDS' larger system later.

### Meta-project type and lifecycle stage

The CHIIDS README also names three meta-project types (Theory, Engineering,
AI/Human Collaboration) and describes a lifecycle from "theoretical proposal
through active research to long-term archival." Both are first-class columns
on `projects`:

```sql
SELECT title,
       (SELECT name FROM meta_project_types  WHERE type_id  = projects.meta_project_type_id)  AS type,
       (SELECT name FROM lifecycle_stages    WHERE stage_id = projects.lifecycle_stage_id)    AS lifecycle
  FROM projects WHERE is_meta_project = 1;
```

Meta-projects seeded from the CHIIDS README:

| Slug                   | Title                                       | Type                    | Layer |
|------------------------|---------------------------------------------|-------------------------|-------|
| `chiids-framework`     | CHIIDS Framework                            | Infrastructure          | L0    |
| `bbs-theory`           | BBS Theory                                  | Theory                  | L1    |
| `bbs-syntax`           | BBS Syntax                                  | Theory                  | L1    |
| `brps`                 | Blended Reality Performance System (BRPS)   | Engineering             | L1    |
| `collaborative-ai`     | Collaborative AI (CAI)                      | AI/Human Collaboration  | L1    |
| `blended-shadow-puppet`| Blended Shadow Puppet (BSP)                 | Practice                | L1    |
| `world-building`       | World Building Project (WBP)                | Practice                | L1    |

The lifecycle is backfilled from the existing `statuses` table by rule
(Proposed/Concept → Proposal, Active/Started → Active Research,
Completed/Archived/Finished → Archival) — but it's a real column you can
override per project.

## Combined database (CHIIDS tables imported)

The database now also contains a CHIIDS-aligned table set, prefixed
`chiids_*`, modeled on the [META-CHIIDS engineering specification](https://github.com/CHI-CityTech/META-CHIIDS/blob/main/project/architecture/chiids_original_spec.md)
(Sections 2.1–2.9). The BBS and CHIIDS tables live side-by-side in the same
file — nothing on either side is overwritten — and a join table records
which BBS project corresponds to which CHIIDS meta-project.

| Section (spec) | Table(s) added |
|---|---|
| 2.1 Org structure | `chiids_meta_projects`, `chiids_teams`, `chiids_roles`, `chiids_people`, `chiids_team_members`, `chiids_policies` |
| 2.2 Project management | `chiids_tasks`, `chiids_milestones`, `chiids_resources` |
| 2.3 Research opportunities | `chiids_research_opportunities`, `chiids_applications` |
| 2.4 Documentation | `chiids_documents` |
| 2.5 Media | `chiids_media`, `chiids_living_archive` |
| 2.6 Version control | `chiids_vcs_repos` (cross-references `github_repos`) |
| 2.7 Archival | `chiids_archives`, `chiids_metrics` |
| 2.8 Communication | `chiids_communications`, `chiids_public_engagement` |
| 2.9 Storage & backup | `chiids_storage_locations`, `chiids_backups` |
| Bridge | `project_chiids_aliases` |

Two views surface the combination:

```sql
-- All CHIIDS meta-projects with their BBS counterpart (if any)
SELECT * FROM v_chiids_meta_projects_with_bbs;

-- BBS + CHIIDS meta-projects unioned, source-tagged
SELECT * FROM v_combined_meta_projects ORDER BY source, slug;
```

Seeded:

- 7 CHIIDS meta-projects (BBS, BRPS, BSP, CAI, CHIIDS, UNESCO, INTL)
- 6 BBS↔CHIIDS aliases auto-created from slug/title matches
- 30 GitHub repos imported into `chiids_vcs_repos` as the version-control surface
- 10 storage locations (GitHub, OneDrive, SharePoint, OpenLab, WordPress, OJS, Zenodo, Zotero, WorldAnvil, OneDrive Backup)
- 8 org roles (PI, Co-PI, Project Lead, Technical Advisor, Student Researcher, Emerging Scholar, Collaborator, Administrator)

The schema mirrors CHIIDS' published data-type model but is intentionally
local: when the META-CHIIDS repo publishes its own `database/seed_data.sql`,
the GitHub Actions workflow can replace the seeded content here with the
canonical CHIIDS data without touching the schema or the BBS tables.

## Quick start

```bash
# 1. Build the database
python3 scripts/build_db.py

# 2. Browse via SQLite directly
sqlite3 balanced_blended_space.db ".tables"
sqlite3 balanced_blended_space.db < sql/queries.sql

# 3. Or use the CLI helpers
python3 scripts/query.py departments
python3 scripts/query.py projects --department COMD
python3 scripts/query.py projects --tag AI
python3 scripts/query.py crossdept
python3 scripts/query.py search --term "shadow"
python3 scripts/query.py show 1
python3 scripts/export.py            # writes ./export/csv/*.csv and ./export/bbs.json
```

## Data model

Many-to-many design: a single project can belong to multiple departments, multiple categories, and have any number of tags, links, attachments, notes, and researchers. This matches BBS's explicitly interdisciplinary nature -- an AI-driven puppetry project sits naturally in ENT, MTEC, and CST simultaneously.

### Core entity

`projects` -- title, slug, summary, description, status, level, parent project (for sub-projects like the AI Image Generator sub-pages), semester, primary URL, and an `is_meta_project` flag for umbrella initiatives (BBS Theory, BBS Syntax, BRPS, BSP, World Building, AI Image Generators Evaluation, Fall 2024, Spring 2025, Personalized LLM).

### Lookup / dimension tables

`departments`, `categories`, `tags`, `levels` (Beginning / Intermediate / Advanced / Unspecified), `statuses` (Proposed / Active / Completed / Archived / Concept), `link_types`, and `researchers`.

### Join tables

`project_departments` (with `is_primary` flag), `project_categories`, `project_tags`, `project_researchers` (with `role`: Lead / Contributor / Technical Advisor / Student).

### Children of projects

`project_links`, `project_attachments`, `project_notes`.

### Views

- `v_project_overview` -- flattened view per project with comma-separated departments/categories/tags plus status and level.
- `v_cross_department_projects` -- projects belonging to two or more departments.

## What's in the seeded database

After running `build_db.py` the DB contains:

| Table | Rows |
|------:|-----:|
| departments | 13 |
| categories | 9 |
| tags | 38 |
| researchers | 16 |
| projects | 287 |
| project_departments | 311 |
| project_categories | 288 |
| project_tags | 325 |
| project_researchers | 20 |
| project_links | 14 |

Department breakdown (project count per department):

| Code | Department | Projects |
|------|------------|---------:|
| COMD | Communication Design | 73 |
| CST  | Computer Systems Technology | 51 |
| MTEC | Emerging Media Technology | 46 |
| ENT  | Entertainment Technology | 28 |
| ENG  | English | 17 |
| MECH | Mechanical Engineering Technology | 17 |
| ARCH | Architectural Technology | 16 |
| HUM  | Humanities | 16 |
| FAS  | Business / Fashion Technology | 15 |
| MUS  | Music Technology | 15 |
| MKT  | Business / Marketing | 13 |
| SOC  | Social Sciences | 4 |
| CET  | Computer Engineering Technology | 0 (page empty on source) |

COMD is highest because its source page tags every item with a Beginning / Intermediate / Advanced level and each item is treated as its own project.

## How categories overlap with departments

Departments are the academic home (which dept owns the work). Categories are orthogonal classifications that cross departments:

- **Theory / Syntax / Practice / Meta-Project** -- framework pieces (BBS Theory, BBS Syntax, BRPS, BSP, World Building, AI Image Gen Evaluation, Personalized LLM).
- **Department Research** -- one of the listed project ideas on a department page; the bulk of the rows.
- **Semester Cohort** -- a concrete student/researcher project tied to a named semester (Fall 2024, Spring 2025).
- **Sub-Project** -- a child of another project (the four AI Image Generator prompt pages).
- **Wicked Problems / Collaborating with AI** -- theory sub-topics on the site, reserved for future expansion.

## Tag conventions

Tags are lightweight, user-extensible keywords (`AI`, `VR`, `AR`, `Mixed Reality`, `Projection Mapping`, `Shadow Puppetry`, `3D Printing`, `Music`, `Sound`, `Marketing`, `World Building`, `LLM`, `Quantum`, `Theory`, `Syntax`, ...). The seed script auto-tags projects by title pattern; you can add or refine tags directly in SQL or via your own scripts.

## Putting this on GitHub

The folder is self-contained. To publish:

```bash
cd balanced-blended-space-db
git init
git add .
git commit -m "Initial BBS project database"
git branch -M main
git remote add origin git@github.com:YOUR_ORG/balanced-blended-space-db.git
git push -u origin main
```

A `.gitignore` covering build artifacts:

```
balanced_blended_space.db
export/
__pycache__/
*.pyc
```

(Or commit the `.db` file too if you want a one-click clone-and-go repository -- it's small.)

## Extending the schema

- **More departments** -- add rows to `departments`; nothing else changes.
- **New project** -- insert into `projects`, then add rows to `project_departments`, `project_categories`, `project_tags`, `project_links` as needed.
- **New top-level classification** -- add a row to `categories`. Categories are intentionally generic so the same schema can host BBS-adjacent initiatives (e.g., other CUNY meta-projects).
- **Different DB engine** -- the schema is plain ANSI SQL except for the SQLite-specific `AUTOINCREMENT`. Replace with `SERIAL` for Postgres or `AUTO_INCREMENT` for MySQL.

## Source

All content is derived from the public BBS site:
https://sites.google.com/view/balancedblendedspace/home

Sources crawled: home, theory, syntax, BRPS, projects index, each of the 13 department pages, Blended Shadow Puppet + World Building, AI Image Generators Evaluation (and sub-pages), Fall 2024 Research, Spring 2025 Research, Personalized LLM.
