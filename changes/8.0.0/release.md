# 8.0.0: Legacy Reference Capture

- **Date:** 2026-08-12
- **Version:** 8.0.0

Additive documentation only. No model, seed, macro, test or semantic-view change — `dbt parse`
output is byte-identical to 7.13.1, and the only file in the dbt project that changes is the
version string. **It ships first and it is the only release in the v8 series with an external
deadline.** Every v8 correction was found by reading legacy SQL; after January that SQL is
gone, and any correction not yet made becomes unverifiable — we would hold a number that
disagrees with a report nobody can re-read. Committing the reference decouples the deadline
from the pace of the corrections.

## Why this is 8.0.0, and why 7.14.0 is a live option

Semver on this platform has been ambiguous (release-process brief, Q5). The v8 series opens
with a major because the **series** is breaking: 8.5.0 through 8.8.0 change what certified
metrics count. **8.0.0 itself breaks nothing** — it opens the series and establishes the
reference material every later release cites. If the team prefers the major to land on the
first release that actually moves a number, **this can ship as 7.14.0 with no other change**
and the major moves to 8.5.0's position in the sequence. Worth deciding once, at the top of
the series, and recording in the release-process work.

## Added

- **`docs/migration/legacy_sql/` — 216 Pentaho transformations as `.sql`**, and
  **`docs/migration/legacy_report_sql/` — 309 report queries extracted from the nine live
  `.prpt` bundles**, nine files.
- **`docs/migration/index/`** — `pentaho_parsed.json` (216 transformations + 80 jobs,
  structured), `closure2.json` (live/dead classification and source closure),
  `prpt_tables.json` (table references per live report), plus `parse2.py` (the `.ktr`/`.kjb`
  extractor) and `closure2.py` (the live/dead walker).
- **`docs/migration/README.md`** — what the capture is, how it was built, how to grep it.
- **`docs/migration/RECOVERY_CHECKLIST.md`** — the urgent half. See below.
- **`dbt_project.yml` version 7.13.1 → 8.0.0.** No other file in the dbt project changes.

## Verified

- **The dbt project is untouched apart from the version string.** `dbt parse` plus a
  `git diff --stat` against 7.13.1 over `dbt_project.yml`, `models/`, `seeds/`, `macros/`,
  `tests/` and `cortex_project/` — expect one file, one insertion, one deletion.
- **The capture is complete**: 216 files in `legacy_sql/`, 9 in `legacy_report_sql/`, 309
  query blocks across them.
- **No credentials rode along.** `.prpt` bundles carry `data:property name="password"` blobs
  and `.ktr` connection blocks carry credentials; `parse2.py` captures connection *names* only
  and the report extractor takes only `data:static-query` bodies. The grep is in the NOTES and
  must be run before merging anyway — this is a public-ish repo and the check is free.
- **~2.4 MB across 230 files**, mostly `legacy_sql/`. No binaries, no `.prpt` files, no PDFs —
  all text, all diffable.

## Findings recorded in the caveats tables (no code change this release)

- **`RECOVERY_CHECKLIST.md` is the sharper point of this release: 7 transformations, 2 stored
  procedures, 8 workbooks, 10 open questions and 4 unrecoverable items are *not* in this
  capture.** §A1–A3 alone mean **three of the four Daily Scan Report ETL steps are missing
  today**, including the `report.fe_dailyScan_*` stored procedures whose bodies are not in the
  migrated SQL.
- **`docs/README.md` does not yet list `docs/migration/` in its map.** Left for the release
  that adds the v8 series index, so the doc map is edited once.
- **`parse2.py` and `closure2.py` are committed as-is from the analysis sandbox.** They are
  re-runnable but not packaged (standard library only — `zipfile`, `xml.etree`, `re`, `json`).
  Fine as reference; do not import them into anything.
