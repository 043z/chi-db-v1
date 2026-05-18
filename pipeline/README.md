# Submission pipeline -- end-to-end

```
Researcher  ──┐
              ▼
       Google Form
              │
              ▼
    Linked Google Sheet ── "File ▸ Share ▸ Publish to web ▸ CSV"
              │
              │   (BBS_SHEET_CSV_URL)
              ▼
   GitHub Actions (hourly cron)  ──►  pipeline/ingest.py
                                          │
                                          ▼
                              pending_submissions  (staging)
                                          │
                              reviewer runs  pipeline/review.py
                                          │
                  approve ──►    projects + join tables (live)
                  reject  ──►    review_status='rejected'
                                          │
                                          ▼
                              site/build_site.py   (sql.js page + CSV)
                                          │
                                          ▼
                                   GitHub Pages
```

## One-time setup

1. **Create the Google Form** with the exact field titles in [`FORM_SETUP.md`](FORM_SETUP.md).
2. **Link a Google Sheet** (Form ▸ Responses ▸ green Sheets icon ▸ "Create").
3. **Publish the Sheet as CSV**: `File ▸ Share ▸ Publish to web ▸ CSV ▸ Publish`. Copy the resulting URL.
4. **Push this repo to GitHub** and add a repository secret:
   - `Settings ▸ Secrets and variables ▸ Actions ▸ New repository secret`
   - Name: `BBS_SHEET_CSV_URL`  Value: the URL from step 3.
   - Optionally add a repository **variable** `BBS_AUTO_APPROVE=true` if you want clean rows to auto-approve.
5. **Enable GitHub Pages**: `Settings ▸ Pages ▸ Source = GitHub Actions`.

That's it. The `.github/workflows/ingest-and-publish.yml` workflow runs every hour and on every push to `main`.

## Local usage

```bash
# Rebuild the seeded DB and apply pipeline staging tables
python3 scripts/build_db.py
python3 -c "import sqlite3; sqlite3.connect('balanced_blended_space.db').executescript(open('sql/pipeline_schema.sql').read())"

# Test ingestion with a local CSV (no Google Sheet needed)
python3 pipeline/ingest.py --file pipeline/sample_submissions.csv

# Review queue
python3 pipeline/review.py list
python3 pipeline/review.py show 1
python3 pipeline/review.py approve 1 --reviewer hosain
python3 pipeline/review.py reject  2 --reviewer hosain -r "Out of scope"

# Build the publishable site
python3 site/build_site.py
# Now open site/dist/index.html in your browser
```

## How approval promotes a submission

`pipeline/review.py approve N` runs inside a transaction:

1. Inserts a row into `projects` with status='Proposed', slug auto-generated (uniqueness enforced), parent/level/semester preserved.
2. Resolves each token in `departments_raw` against `departments.code` / `departments.name` and inserts into `project_departments`. First match is flagged `is_primary=1`.
3. Resolves each token in `categories_raw` against `categories.name`.
4. **Tags are auto-created** if they don't exist (`tags` table grows organically).
5. Creates or updates a `researchers` row for the submitter and links it with role='Submitter'.
6. Parses `extra_links_raw` (lines of `label|url`) into `project_links` rows.
7. Marks the submission `review_status='approved'`, fills `reviewed_by`/`reviewed_at`, and writes an entry to `review_log`.

Rejection / duplicate paths just update `review_status` + `review_log` without touching any live tables.

## Re-ingestion safety

Every submission gets a stable `source_row_hash = sha256(timestamp|email|title)` -- the staging table has a UNIQUE constraint on it, so re-running ingestion any number of times only adds rows the DB hasn't seen yet.

## Switching to OAuth instead of published-CSV

If the form collects info that shouldn't be exposed via a public CSV URL, replace the `urllib.request.urlopen(...)` call in `ingest.py` with a `gspread` call using a service-account JSON. The rest of the pipeline (validation, staging, review, site build) is unchanged.

## Auto-approve mode

Setting the repo variable `BBS_AUTO_APPROVE=true` causes the workflow to call `review.py approve` for any submission with no `validation_errors`. The reviewer (`reviewed_by`) is recorded as `github-actions`. Anything with validation errors still waits for a human.
