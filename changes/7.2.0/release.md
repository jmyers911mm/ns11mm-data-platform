# 7.2.0: Working CI, Release Gates & Infrastructure

- **Date:** 2026-07-29
- **Version:** 7.2.0

None of the automation this patch touches could previously run as written.

## Added

- **`.sqlfluff` / `.sqlfluffignore`** — real lint config (lowercase keyword/identifier/
  function rules per the SQL style guide; layout/aliasing rule families excluded; repo lints
  clean). CI enforces it — no more `|| true`.
- **`terraform/modules/*/variables.tf`** — every module now declares the variables it
  references (`terraform validate` previously failed on undeclared inputs).
- **`disabled/README.md`** — why all 14 Azure Function CD pipelines are parked, and what
  re-enabling requires.

## Changed

- **`.github/workflows/dbt-ci.yml`** rebuilt as a working two-job slim CI: pushes to main
  compile and publish a manifest artifact; PRs lint + `dbt build --select state:modified+
  --defer` against it (full build when no state exists). Runs in a dedicated
  `NS11MM_DW_DEV_CI` database from the profile template + secrets (the old workflow exported
  env vars nothing consumed and deferred to state nothing produced). Requires repo secrets
  `SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` / `SNOWFLAKE_PASSWORD` and the CI database.
- **Azure Function CD** — `azure-pipelines-{counterpoint,gateway,drupal}.yml` moved to
  `disabled/`: the deployed packages had no function entrypoint and did not include
  `pipelines/shared/`, and their source queries are unconfirmed placeholders. Live ingestion
  is seed-based.
- **Terraform** — per-environment backend state keys (dev/staging/prod no longer share one
  tfstate); deploy pipelines rewritten to valid Azure DevOps YAML (ManualValidation in a
  server job for staging/prod); required variables supplied via variable groups; dev
  `credit_quota` synced 5 → 10 to match the live 6.1.0 change.

## Fixed

- **`validate_before_deploy`** (the documented release gate) — was unrunnable: 8 of 10
  models it checked are disabled/deleted and it queried a `GOLD` schema that doesn't exist.
  Rebuilt against the active critical set in `MARTS`, with graceful skips.
  `compare_model_to_prod` had the same `GOLD` bug.
- **Quarantine paths unified** on `{{ target.database }}.INTERMEDIATE` — write, resolve, and
  audit paths previously disagreed and referenced a nonexistent `SILVER` schema.
- **`gdpr_anonymize`** rewritten for the active PII surfaces: erasure happens in the RAW
  landing tables (the documented, logged exception to ADR-001 immutability), requires a
  request id, and writes an erasure audit log. The old version updated tables that no longer
  exist.
- **`rerun_from_source`** rewritten around the real seed-based source groups.

## Removed

- `macros/data_quality/check_source_freshness.sql` — built freshness queries and never
  executed them, against tables that don't exist. `dbt source freshness` (configured in
  `sources.yml`) is the real mechanism.

---
