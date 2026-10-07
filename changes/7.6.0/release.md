# 7.6.0: Rollout Reconciliation & Security

- **Date:** 2026-07-31
- **Version:** 7.6.0

First of the 7.6.0–7.11.0 series (post-build review, 2026-07-31; see
`claude/post-build-review-2026-07-31.md` in the project workspace). This release makes the
tree match the record: the deletions, renames, and added files that 7.0.0–7.5.2 recorded
but that were **not present in the built tree** are actually applied here, and CI is
restored to a runnable state.

## Security

- **`git_workspace_setup.sql` deleted (again).** The file — containing a live GitHub PAT —
  was still at the repo root despite 7.0.0 and 7.5.1 both recording its removal.
  **The token must still be revoked in GitHub and the file purged from history**
  (`git filter-repo` / BFG); deleting it in a commit is not revocation.
- `pipelines/salesforce_mc/temp_pipeline.py` deleted (real SFMC tenant URIs + Snowflake
  account/user literals; Key-Vault-bypassing local path).
- `.temp/` removed entirely (stale governed-seed copies — `seed_retail_store_facility.csv`
  was missing the Museum Cafe row; `seed_tour_plu.csv` had the pre-fix row set). If the
  directory is still tracked in your clone: `git rm -r --cached .temp/` then delete.

## Removed / renamed (re-applying the 7.0.0–7.5.0 lists)

- `TEMP_POC_MIGRATION.md` (root) — superseded by `docs/POC_MIGRATION_RECORD.md` (7.4.0)
- `seeds/tmp_seed_dsr_budget.csv` — orphan; dbt was loading it as a stray table every `dbt seed`
- `cortex_project/JMYERS_TEST.agent.yaml` — byte-identical duplicate of `DPR_ANALYST.agent.yaml` (7.3.0)
- `macros/data_quality/check_source_freshness.sql` — removed in 7.2.0; targeted nonexistent `RAW.RAW_*` tables
- `scripts/generate_dpr_semantic_view.py` — legacy DPR-only generator superseded by
  `generate_semantic_view_ddl.py` (7.3.0); crashed on run and emitted old DB-qualified DDL
- `docs/adr/ADR_018_metric_defintion_ownership.md` → `ADR_018_metric_definition_ownership.md`
  (filename typo fixed; the ADR index already linked the corrected name)
- `docs/architecture/CODEOWNERS` → `.github/CODEOWNERS` (the location GitHub enforces),
  with paths modernized to the current tree (`models/raw` / `models/intermediate` /
  `models/marts`, cortex_project, profiles files)

## Added (files earlier releases recorded but that were missing)

- **`profiles.yml.template`** (7.0.0) — env_var-based identity, `externalbrowser` auth for
  interactive targets, new `ci` target against `NS11MM_DW_DEV_CI`
- **Root `profiles.yml`** (7.5.2) — credential-free, committed, for dbt Projects on
  Snowflake; routes role/warehouse/database/schema only
- `.gitignore` updated to match: root `profiles.yml` is no longer ignored (it is
  credential-free by design); credential rules stated in-file

## Fixed — CI actually works (restores the 7.2.0 design)

- **`.github/workflows/dbt-ci.yml` rewritten as two jobs:** `main-manifest` (push to main →
  publish `manifest.json` artifact) and `pr-ci` (restore latest main manifest → slim
  `state:modified+` deferred build, with full-build fallback when no manifest exists).
- Builds land in **`NS11MM_DW_DEV_CI`**, never a personal sandbox.
- `DBT_PROFILES_DIR` pinned to `~/.dbt` in both jobs; profile written from
  `profiles.yml.template`; `SNOWFLAKE_ACCOUNT` moved from a hardcoded literal to a
  repository secret.
- **SQLFluff lint enforced** — the `|| true` is gone.
- CI secrets (`SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` / `SNOWFLAKE_PASSWORD`) and the
  `NS11MM_DW_DEV_CI` database must be provisioned before the workflow can go green.

## Errata

- **7.5.1's core claims did not land in this tree.** "Old paths removed; new paths
  confirmed" was false for the twelve files above, the CI restore was false (the workflow
  was still pre-7.2.0), and the `RELEASE_NOTES` file it cites does not exist in the repo.
  Its macro/lint/terraform restores (`.sqlfluff`, `.sqlfluffignore`, terraform
  `variables.tf`, ops macros, dashboard fix) **did** land and are verified.
- **7.5.2's file payload did not land** (neither profile file existed until this release).
- **7.5.3 corrections:** its resource-monitor incident text duplicates 6.1.0 verbatim
  (the quota was already raised 5→10 on 2026-07-29 and terraform already says 10) — verify
  the actual quota in Snowflake before trusting either entry; its audit findings were
  wrong against the tree (`assert_critical_tables_not_empty` covers 15 models including
  every fact listed as missing, and
  `assert_silver_gold_retail_revenue_reconciliation.sql` exists at severity error).
  Its script changes (schema-qualified deploy DDLs, generator `--database` flag) are real.

## Migration notes

1. Revoke the exposed GitHub PAT (GitHub → Settings → Developer settings → Fine-grained
   tokens) and purge `git_workspace_setup.sql` from history with `git filter-repo`.
2. Provision CI: create repo secrets `SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` /
   `SNOWFLAKE_PASSWORD` (CI service user) and the `NS11MM_DW_DEV_CI` database.
3. Developers: copy `profiles.yml.template` → `~/.dbt/profiles.yml` (the root
   `profiles.yml` is not for local use).
4. If `.temp/` is still tracked in your clone: `git rm -r --cached .temp/` and delete it.

---
