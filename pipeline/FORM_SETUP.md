# Google Form setup -- exact field spec

Create a new Google Form titled "BBS Project Submission". Add the following questions **in this order and with these exact titles** -- the ingestion script reads the Google Sheet column headers literally.

| # | Field title (column header in Sheet) | Type | Required | Notes |
|---|--------------------------------------|------|----------|-------|
| 1 | `Submitter name`                     | Short answer | yes | Researcher full name. |
| 2 | `Submitter email`                    | Short answer (Email validation) | yes | Used for review follow-up. |
| 3 | `Project title`                      | Short answer | yes | The project's title. |
| 4 | `One-line summary`                   | Short answer | yes | ~140 chars. |
| 5 | `Full description`                   | Paragraph | no  | Abstract / goals. |
| 6 | `Departments`                        | Checkbox (multi-select) | yes | Pre-populate with the 13 dept codes: ENT, MTEC, MUS, CST, MKT, COMD, ENG, FAS, ARCH, MECH, HUM, SOC, CET. Researcher checks all that apply. |
| 7 | `Categories`                         | Checkbox (multi-select) | yes | Options: Theory, Syntax, Practice, Meta-Project, Department Research, Semester Cohort, Sub-Project. |
| 8 | `Tags`                               | Short answer | no  | Comma-separated free-form (e.g. `AI, VR, Shadow Puppetry`). New tags are auto-created. |
| 9 | `Skill level`                        | Multiple choice | no  | Beginning / Intermediate / Advanced / Unspecified. |
| 10 | `Semester`                          | Short answer | no  | e.g. `Fall 2025`. Leave blank for non-cohort projects. |
| 11 | `Parent project slug`               | Short answer | no  | For sub-projects only -- the parent's `slug` value (e.g. `blended-shadow-puppet`). |
| 12 | `Primary URL`                       | Short answer (URL validation) | no | The canonical page for the project. |
| 13 | `Extra links`                       | Paragraph | no  | One per line, format: `Label|https://url`. Lines starting with `#` are ignored. |

Google automatically adds a `Timestamp` column at the front of the linked Sheet. The ingestion script reads it as the submission timestamp and uses it (together with submitter email + title) to build a stable hash so re-ingesting is idempotent.

## Publishing the Sheet so the pipeline can read it

1. Open the form's linked **Google Sheet** (Form -> Responses -> green Sheets icon).
2. `File -> Share -> Publish to web`.
3. Pick **"Comma-separated values (.csv)"** and the specific responses sheet.
4. Click **Publish**, copy the resulting URL (looks like `https://docs.google.com/spreadsheets/d/e/.../pub?output=csv`).
5. Store that URL as the `BBS_SHEET_CSV_URL` environment variable / GitHub Actions secret.

> The published CSV URL is read-only and contains no PII the form didn't already collect; you're not exposing the underlying sheet, just a snapshot of the answers tab. If the form gathers sensitive contact info you'd rather not publish, switch to the OAuth path (see `pipeline/README.md`).

## Validation rules the ingestion script applies

- `Project title` non-empty, <= 200 chars.
- `Submitter email` matches a basic email regex.
- `Departments` -- each token (after splitting on `,` / `;`) must match an existing department `code` or `name` (case-insensitive). Unknown departments produce a validation error and the submission is still inserted with `review_status='pending'` and the error recorded in `validation_errors` so the reviewer can fix it.
- `Categories` -- same matching against the `categories` table.
- `Skill level` must be one of the known levels (or blank, which means "Unspecified").
- `Parent project slug` if provided must already exist in `projects.slug`.
- `Primary URL` and each `Extra links` URL must parse as a valid http(s) URL.

Rows that fail validation are **not rejected** -- they just land with `validation_errors` populated so a reviewer can correct them via the review CLI.
