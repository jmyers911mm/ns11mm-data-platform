# Changelog

All notable changes to the ns11mm-data-platform project will be documented in this file.

This is the production repository (`ns11mm/ns11mm-data-platform`).

## [7.11.0] — 2026-07-31 — Hygiene & Docs Sweep

Closes the remaining medium/low findings from the post-build review.

### Fixed

- **Narrative task prompts re-synced with their dbt source models.** The deployed-task
  copies in `scripts/setup_dpr_narrative.sql` / `setup_retail_narrative.sql` had drifted
  from `rpt_dpr_narrative.sql` / `rpt_retail_narrative.sql`: missing the YoY
  contextualization rule, missing "significant YoY divergence" in the watch-items rule,
  and framing "the day's" instead of "the previous day's" performance. Prompts are now
  verbatim-identical; both rpt_ models carry a SYNC GUARD note (there is no automated
  drift check for this pair yet — candidate for a future generator).
- **PII coverage extended to the Gateway staging name columns**:
  `STG_GATEWAY__TICKETS` and `STG_GATEWAY__JNLTICKETS` `first_name`/`last_name` added to
  `apply_masking_policies` and `apply_governance_tags` (they feed the already-masked
  `dim_customer.customer_name`, but staging-schema readers saw them unmasked); both
  models and `stg_ecommerce__website_recurring` now carry the `pii`/`restricted` config
  tags their WiFi sibling had.
- **`rpt_dpr_budget_daily.report_date` unique test** demoted error → warn: the dpr CTE
  passes `fct_budget_dpr_forecasts` rows through un-aggregated, so the grain is
  partially inherited (severity rule).
- **`rpt_daily_scan` header** no longer claims the DSR forecast seed is unpopulated
  (fct_daily_scan joins the real budget; variance is NULL only where the forecast has
  no row).
- **`fct_daily_operations.ticket_revenue`** now documents in-model that it is the
  POS-derived measure and NOT `fct_daily_performance.ticket_revenue` (GA journal) —
  the shared name is historical; renaming was deliberately skipped (two tests and the
  ML training set bind to it) and can be revisited with the ML model retrain.
- `rpt_wifi_email_export` schema docs now list all four columns incl. `capture_date`.
- Committed `__pycache__/` artifacts removed from both dpr-dashboard copies (already
  gitignored; if still tracked in your clone: `git rm -r --cached dpr-dashboard/__pycache__ dpr-dashboard/deployed/__pycache__`).

### Deferred (documented, deliberately unchanged)

- `TOTAL_RETAIL_GROSS_PROFIT` component realignment/rename — ADR-005 committee item
  (see 7.8.0).
- The Streamlit dashboard re-derives donation/audio composites in Python (a third
  authored surface); migrating it to read `rpt_dpr_powerbi` is a candidate follow-up.
- Generic-test macro library adoption; function-pipeline packaging; ADR 007–017
  register reconciliation — unchanged standing items.

---

## [7.10.0] — 2026-07-31 — Reports 2–4 Serving Stack (Today's Sales · Daily Scan · YTD Tracker)

Lands the component stack the 2026-07-29 build notes specified but that never reached the
repo: only the thin wrappers and semantic-view additions existed. Each report now has the
full Retail-pattern stack (report_long, line-item seed + dim where applicable, narrative
chain, task setup script). 18 files added, 5 edited; all patterns mirror the existing DPR
and Retail stacks.

### Added

**Report 2 — Today's Sales (intraday, report_date × hour_of_day × key_facility):**
`rpt_today_sales_report_long` (long shape over the existing wrapper; no budget — the
report has no goals; stub lines emitted as typed NULLs), `today_sales_line_items` seed +
`dim_today_sales_line_item` (12 PDF lines; Conversion / Capture / Store Visitors /
Attendance / Totes marked Stub pending the intraday visitor feed and tote-SKU flag),
`rpt_today_sales_narrative_brief` (day-to-date vs same-weekday-last-week) +
`rpt_today_sales_narrative` (enabled=false) + `scripts/setup_today_sales_narrative.sql`
(T_TODAY_SALES_NARRATIVE → MARTS.TODAY_SALES_NARRATIVE, 05:30 ET; hourly intraday
schedule documented as an option).

**Report 3 — Daily Scan (report_date × segment_key):**
`rpt_daily_scan_report_long` (TICKETS_SOLD / FORECAST_TICKETS_SOLD / PASSES_SCANNED
carried as components; Variance % / % Used / % of Market are DAX ratio-of-sums; explicit
union so NULL-forecast segments keep their Forecast row; segment labels ride
`seed_scan_market_segment` — no new seed), `rpt_daily_scan_narrative_brief` +
`rpt_daily_scan_narrative` (enabled=false) + `scripts/setup_daily_scan_narrative.sql`
(T_DAILY_SCAN_NARRATIVE → MARTS.DAILY_SCAN_NARRATIVE).

**Report 4 — Memorial & Museum Daily Tracker YTD (report_date; YTD in DAX):**
`rpt_tracker_powerbi` (actuals conform over rpt_dpr_powerbi — sanctioned rpt→rpt
projection chain; Total Earned Revenue component set documented in-header, mirroring the
DPR TOTAL_ESTIMATED_REVENUE composite), `rpt_tracker_budget_daily` (projection conform
over rpt_dpr_budget_daily, columns mirroring the actuals; donations + virtual-tour
revenue are not budgeted → excluded from the projection, flagged for legacy
confirmation), `rpt_tracker_report_long`, `tracker_line_items` seed +
`dim_tracker_line_item` (Memorial-vs-Museum REVENUE split rows marked Stub — the one
open business rule), `rpt_tracker_narrative_brief` + `rpt_tracker_narrative`
(enabled=false) + `scripts/setup_tracker_narrative.sql` (T_TRACKER_NARRATIVE →
MARTS.TRACKER_NARRATIVE).

### Changed

- `rpt_memorial_museum_tracker_ytd` — header corrected (it claimed budget columns were
  joined; none were) and marked superseded for the Power BI build by the `rpt_tracker_*`
  stack (kept for existing consumers); now also carries `tickets_sold` +
  `tickets_sold_ytd` (the tracker's Museum panel requires it).
- `models/marts/reports/schema.yml` (11 new entries, severities per the rule),
  `models/marts/dimensions/schema.yml` (2 dim entries), `seeds/_seeds.yml` (2 seeds),
  `models/marts/reports/README.md` (inventory updated: 34 files / 29 build / 5 gated).

### Deploy order (per the build notes)

1. `dbt seed --select today_sales_line_items tracker_line_items`
2. `dbt build --select rpt_today_sales_report_long rpt_daily_scan_report_long rpt_tracker_powerbi+ dim_today_sales_line_item dim_tracker_line_item`
3. Run the three `scripts/setup_*_narrative.sql` (after `USE DATABASE <target>`); eyeball
   the first notes; `ALTER TASK ... RESUME`.
4. Build each PBIX; reconcile to a recent legacy PDF; route through change control.

### Sign-off gates (open, from the build notes — not blockers)

- Confirm the DSR forecast basis (tickets-sold vs scanned forecast).
- Confirm the tracker's earned-revenue and projection definitions vs the legacy PDF.
- Decide the Memorial-vs-Museum revenue-split business rule (ADR-005) — the two Stub
  rows light up when it lands.
- Memorial Cart 1/2/3 split needs `store_id` retained in `fct_today_sales_hourly`
  (small fact change, separate PR).

---

## [7.9.0] — 2026-07-31 — Fact-Layer Correctness

Fixes the two numbers-level defects found by the post-build review (retail return
netting, retail budget grain), hardens the Daily Scan lineage against fan-out, and
closes the test-coverage gaps against the severity rule.

### Fixed

- **Retail return netting centralized — one convention, authored once.**
  `int_retail__performance` netted returns as `sale_amount - return_amount` while every
  other consumer of the same lines (all five DPR selling-area measures,
  `fct_daily_operations.retail_revenue`, and its own donations measure) nets with `+` —
  the legacy-reconciled convention, implying returns land with negative amounts. One of
  the two is wrong for any day with a return; the `-` form overstates the Retail
  Performance chain by 2× returns. Fix: `int_counterpoint__retail_lines` now derives
  **`net_amount` / `net_quantity` once** (with the sign convention documented in-model);
  `int_retail__performance` (bug fix), `int_dpr__retail` and `fct_daily_operations`
  (output-equivalent refactors) all consume the shared columns.
  **CONFIRM with a CounterPoint 'R'-line extract (owner: Gennady)** — if returns land
  positive, the sign flips in ONE place.
  Verify: `dbt build --select int_counterpoint__retail_lines+` — `int_dpr__retail` /
  `fct_daily_operations` outputs must be row-identical pre/post; `fct_retail_performance`
  changes ONLY on days with returns.
- **New cross-chain reconciliation test**
  `assert_retail_dpr_cross_chain_reconciliation` (warn — promote after a clean run):
  day-level Museum Store net sales must tie between the Retail Performance chain and the
  DPR chain within 0.5% over the trailing 30 days, so the two lineages can never diverge
  silently again.
- **Retail budget grain corrected — category seam is NULL by design.**
  `fct_retail_performance` joined the facility-grain forecast onto
  date×facility×**category** rows, repeating the facility budget on every category row —
  any category rollup multiplied the budget (and contradicted the build spec §8.6 and
  `rpt_retail_category_long`'s own header). The category-grain budget columns are now
  typed NULLs; **the single budget surface is `fct_budget_retail_forecasts` →
  `rpt_retail_budget_daily`** (one budget, one chain).
- **Duplicate retail-budget landing retired**: `stg_budget__retail` deleted (its only
  consumer was the seam above); `report_estate_seed.seed_retail_budget` deregistered
  from sources.yml with a retirement note — it was a second landing of the same
  workbook as `budget_seeds.SEED_RETAIL_FORECASTS` (the canonical source). The RAW
  table may remain; it is deliberately unread.
- **Daily Scan fan-out guard**: `int_gateway__scan_lines`' ticket join deduped to one
  row per `visual_id` (latest journal line) — `stg_gateway__jnltickets` is
  jnl_detail_id-grain, so a reissued/adjusted ticket duplicated scan rows and inflated
  `passes_scanned` / `tickets_sold` in `fct_daily_scan`.
- `fct_daily_scan`: redundant mart-layer `try_to_decimal` re-guards removed (guards
  live upstream per the DQ rule); the intentional exclusion of the staged `mobile` /
  `partners` budget columns from the segment unpivot is now documented in-model
  (13 segments, matching the legacy report).

### Added — test coverage per the severity rule

- GROUP-BY-enforced grains at **error**: `rpt_monthly_retail_kpi`
  (calendar_year × calendar_month × key_facility), `rpt_website_commerce`
  (month_of_year × revenue_type × revenue_year).
- Inherited/asserted grains at **warn**: `rpt_retail_powerbi` (report_date ×
  key_facility — matches the DPR sibling), `fct_ticket_demand_forecast` (declared
  5-column grain asserted under the 14-column GROUP BY),
  `int_gateway__scan_lines.usage_id` (unique), and
  `int_gateway__item_journal_lines.jnl_detail_id` (unique — same fan-out exposure that
  motivated the ticket-side test).
- Severities aligned **down** where grains are inherited from the Excel budget seeds:
  `fct_budget_dpr_forecasts.date_key` unique and both `fct_budget_*_grain_unique`
  combos error → warn, matching their deliberately-warn `int_budget__*` twins.

### Migration notes

1. `dbt build --select int_counterpoint__retail_lines+` and row-count/row-diff the DPR
   chain (must be identical) and `fct_retail_performance` (changes only where returns
   exist). Reconcile a recent day against the legacy Retail Performance PDF.
2. Re-deploy the RETAIL semantic view (budget fact descriptions updated).
3. Anything that read `fct_retail_performance.net_sales_budget/net_profit_budget`
   should rebind to `rpt_retail_budget_daily`.

---

## [7.8.0] — 2026-07-31 — Semantic Layer: Metric Truth

Closes the metric-definition drift found by the 2026-07-31 post-build review: the DPR
DDL was stale (missing the two ratio metrics — `--check` failed), and the ratios
themselves violated the 2026-07-29 locked definitions.

### Fixed

- **`AVG_TICKET_PRICE` (DPR.sv.yaml) now matches the locked canon**:
  `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`. The prior
  metric-on-metric form (`TOTAL_ADMISSION_REVENUE / TICKETS_SOLD`) had no NULLIF
  (divide-by-zero on closed days) and an unaggregated denominator (undeployable as a
  semantic-view metric — the likely reason the committed DDL had been hand-pruned to 47
  of 49 metrics).
- **`MUS_STORE_PROFIT_PER_VISITOR` (DPR.sv.yaml)** adopts UNIFIED's correct
  `SUM(...) / NULLIF(SUM(...), 0)` form — one locked name, one formula everywhere.
- **`TOTAL_ADMISSION_REVENUE` single-sourced** — DPR and UNIFIED both summed
  `TICKET_REVENUE + PASS_REVENUE`, re-deriving the governed numerator the fct defines
  once. Both now `SUM(TOTAL_ADMISSION_REVENUE)` (the "view re-chooses a component"
  anti-pattern, removed).
- **`TOTAL_RETAIL_DONATIONS` deduplicated in RETAIL.sv.yaml** — the facility-grain
  rollup silently reused the locked category-grain name. Renamed
  `TOTAL_RETAIL_DONATION_ASK` (namespacing note corrected);
  `rpt_retail_powerbi` updated to the new metric name (its output alias `donations` is
  unchanged, so report_long / narrative consumers are unaffected).
- **`ATTENDANCE.sv.yaml` FCT_DAILY_SCAN primary key** corrected `(DATE_KEY)` →
  `(DATE_KEY, SEGMENT_KEY)` — the declared PK understated the fact's true grain
  (UNIFIED already had it right).
- **All four deploy DDLs regenerated; `generate_semantic_view_ddl.py --check` is green.**
  MARTS.DPR now deploys all 49 metrics. The pre-commit sv-drift hook stops blocking.
- **`rpt_daily_performance_report`** ratio block aligned with the semantic view:
  `mus_store_rev_per_visitor` → **`mus_store_profit_per_visitor`** (it computes from
  gross profit; name now says so — DPR_LINEAGE updated), and zero-denominator handling
  changed from `0` to `NULL` (`nullif`) so the two surfaces agree on zero-sales days.
  **Breaking** for anything bound to the old column name or relying on 0-not-NULL.

### Changed

- `DPR.sv.yaml` `TOTAL_RETAIL_GROSS_PROFIT` description now warns that the metric
  (store + carts + cafe) is NOT the legacy DPR report's "Total Retail Gross Profit"
  line (store + carts + e-commerce, cafe separate). Component realignment or rename is
  an **open ADR-005 item** for the committee — flagged, not changed, because the
  `TOTAL_RETAIL_GROSS_PROFIT` metric code flows through `rpt_dpr_report_long` and the
  line-item seed.
- `scripts/generate_semantic_view_ddl.py` — stray AI-attribution comment removed
  (banned by the header standard).

### Migration notes

1. Re-deploy the four semantic views (`scripts/deploy_semantic_view_*.sql` after
   `USE DATABASE <target>`, or via the cortex manifest).
2. Saved Cortex/BI queries using the RETAIL facility-grain `TOTAL_RETAIL_DONATIONS`
   must switch to `TOTAL_RETAIL_DONATION_ASK` (the category-grain locked name is
   unchanged).
3. Anything reading `rpt_daily_performance_report.mus_store_rev_per_visitor` must
   rebind to `mus_store_profit_per_visitor`.

---

## [7.7.0] — 2026-07-31 — Single Source Database (ADR-019)

Formalizes what the build already did implicitly: **every environment — sandboxes, shared
dev, CI, and prod — reads RAW/SEEDS source data from the one shared database
`NS11MM_DW_DEV`** while ingestion is seed-based. Decided with Jeremy 2026-07-31; recorded
as ADR-019 (Proposed, committee ratification with the ADR-005 open items).

### Added

- **`docs/adr/ADR_019_single_source_database.md`** — the decision, options considered
  (prod-hosted and per-environment landing set aside, with the end-state noted), risks,
  and the revisit trigger (first production-enabled function pipeline / prod landing /
  2026-12 go-live review). ADR index updated.
- **`scripts/setup_source_grants.sql`** — cross-database read grants: USAGE + SELECT
  (current and future) on `NS11MM_DW_DEV.RAW` / `.SEEDS` for `TRANSFORMER_ROLE`
  (sandboxes + CI) and `DEPLOY_PROD_ROLE` (prod builds). Read-only — RAW stays
  LOADER_ROLE-write-only per ADR-001.

### Changed

- **`seed_database` var → `source_database`** (`dbt_project.yml`, documented in-file;
  `models/raw/sources.yml` ×3, `models/raw/_budget_sources.yml`). The old name suggested
  dbt seeds; the var governs the RAW ingestion database too. Override per-run with
  `--vars '{source_database: <db>}'` only for testing.
- **`gdpr_anonymize` erases where the models read** — the three RAW landing-table updates
  and the erasure log now target `{{ var('source_database') }}` instead of
  `{{ target.database }}`. Before this, an erasure run against a prod or sandbox target
  updated a RAW schema the models were not reading, and the erased PII kept flowing.
  The log is now central: `NS11MM_DW_DEV.INTERMEDIATE.GDPR_ERASURE_LOG`. (The
  `DIM_CUSTOMER` in-place redaction correctly stays per-target.)
- **`cortex_project/cortex-project.yaml`** — DPR semantic-view target corrected
  `NS11MM_DW_DEV_JMYERS.MARTS.DPR` → `NS11MM_DW_DEV.MARTS.DPR` (regression against the
  7.1.0 personal-sandbox eviction; the manifest now matches its own README and the four
  sibling artifacts).
- **Hardcoded-database sweep (portability, same pattern as 7.5.3):**
  `scripts/setup_dpr_narrative.sql` / `setup_retail_narrative.sql` now `USE SCHEMA MARTS`
  against the session database; both `dpr-dashboard` streamlit copies query
  `MARTS.FCT_DAILY_PERFORMANCE` unqualified; `UNIFIED.sv.yaml` verified queries reference
  `MARTS.UNIFIED` (a prod deploy no longer ships verified queries that point at dev);
  both ML notebooks resolve the database from the session
  (`session.get_current_database()`) instead of a literal.
- `docs/architecture/SNOWFLAKE_SETTINGS.md` — `NS11MM_DW_DEV` row notes the
  single-source role and the var.

### Migration notes

1. Run `scripts/setup_source_grants.sql` as SECURITYADMIN (prod's read on shared dev is
   what makes the next prod build work under least privilege).
2. If any wrapper scripts pass `--vars '{seed_database: ...}'`, rename the key to
   `source_database`.
3. No data moves. When ingestion is automated, flip `source_database` per ADR-019's
   revisit trigger.

---

## [7.6.0] — 2026-07-31 — Rollout Reconciliation & Security

First of the 7.6.0–7.11.0 series (post-build review, 2026-07-31; see
`claude/post-build-review-2026-07-31.md` in the project workspace). This release makes the
tree match the record: the deletions, renames, and added files that 7.0.0–7.5.2 recorded
but that were **not present in the built tree** are actually applied here, and CI is
restored to a runnable state.

### Security

- **`git_workspace_setup.sql` deleted (again).** The file — containing a live GitHub PAT —
  was still at the repo root despite 7.0.0 and 7.5.1 both recording its removal.
  **The token must still be revoked in GitHub and the file purged from history**
  (`git filter-repo` / BFG); deleting it in a commit is not revocation.
- `pipelines/salesforce_mc/temp_pipeline.py` deleted (real SFMC tenant URIs + Snowflake
  account/user literals; Key-Vault-bypassing local path).
- `.temp/` removed entirely (stale governed-seed copies — `seed_retail_store_facility.csv`
  was missing the Museum Cafe row; `seed_tour_plu.csv` had the pre-fix row set). If the
  directory is still tracked in your clone: `git rm -r --cached .temp/` then delete.

### Removed / renamed (re-applying the 7.0.0–7.5.0 lists)

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

### Added (files earlier releases recorded but that were missing)

- **`profiles.yml.template`** (7.0.0) — env_var-based identity, `externalbrowser` auth for
  interactive targets, new `ci` target against `NS11MM_DW_DEV_CI`
- **Root `profiles.yml`** (7.5.2) — credential-free, committed, for dbt Projects on
  Snowflake; routes role/warehouse/database/schema only
- `.gitignore` updated to match: root `profiles.yml` is no longer ignored (it is
  credential-free by design); credential rules stated in-file

### Fixed — CI actually works (restores the 7.2.0 design)

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

### Errata

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

### Migration notes

1. Revoke the exposed GitHub PAT (GitHub → Settings → Developer settings → Fine-grained
   tokens) and purge `git_workspace_setup.sql` from history with `git filter-repo`.
2. Provision CI: create repo secrets `SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` /
   `SNOWFLAKE_PASSWORD` (CI service user) and the `NS11MM_DW_DEV_CI` database.
3. Developers: copy `profiles.yml.template` → `~/.dbt/profiles.yml` (the root
   `profiles.yml` is not for local use).
4. If `.temp/` is still tracked in your clone: `git rm -r --cached .temp/` and delete it.

---

## [7.5.3] — 2026-07-31 — Resource Monitor Fix & Portable Semantic View DDL

Session date: 2026-07-31. Production dbt run was blocked because `DBT_DEV_MONITOR` exceeded its
5-credit monthly quota (used 5.04). Restored the warehouse, audited test and alert coverage
across all mart tables and semantic views, and fixed the semantic view DDL generator to stop
hardcoding a database name.

### Fixed

| Issue | Resolution |
|-------|------------|
| `DBT_DEV_MONITOR` quota exhausted (5.04 / 5.00 credits), suspending `DBT_DEV_WH` | Increased monthly quota from 5 → 10 credits; warehouse resumed |
| `deploy_semantic_view_*.sql` hardcoded `NS11MM_DW_DEV` database | Scripts now emit schema-qualified names only; resolve from session database |

### Changed

- **`scripts/generate_semantic_view_ddl.py`** — Default behaviour omits the database qualifier
  from all DDL object references (view name, table FQNs). Scripts resolve against the current
  session database (`USE DATABASE <target>`). Pass `--database <name>` to pin a specific
  database when needed (e.g. `--database NS11MM_DW_PROD` for production deploys).
- **4 regenerated DDL files** — `deploy_semantic_view_{attendance,dpr,retail,unified}.sql` now
  use `MARTS.*` / `SEEDS.*` instead of `NS11MM_DW_DEV.MARTS.*` / `NS11MM_DW_DEV.SEEDS.*`.

### Audit Findings (informational, not yet remediated)

- All 5 Snowflake alerts in `NS11MM_DW_DEV.MONITORING` are **SUSPENDED** (source freshness,
  dbt failures, credit consumption, long-running queries, warehouse utilization).
- `assert_critical_tables_not_empty` covers only 6 of 17 enabled models — newer facts
  (`fct_daily_performance`, `fct_retail_daily`, `fct_retail_performance`, `fct_daily_scan`,
  `fct_today_sales_hourly`, budget facts, `ml_visitor_forecast_training`) are missing.
- No revenue reconciliation test for the retail path (silver → gold).
- No resource-monitor-approaching-limit alert exists.

### Migration notes

- **No breaking changes** to model SQL or schema.
- Semantic view deploy scripts now require the session database to be set before execution
  (e.g. `USE DATABASE NS11MM_DW_DEV_JMYERS;`) unless `--database` is passed at generation time.

---

## [7.5.2] — 2026-07-30 — Snowflake-Native dbt Profile

7.0.0 removed the committed `profiles.yml` for security — correct for local/CI use, but
it also removed the file that **dbt Projects on Snowflake** (`EXECUTE DBT PROJECT` /
Workspaces) reads from the project root. This release restores that path safely.

### Added

- **Root `profiles.yml` (credential-free, committed)** — routes role / warehouse /
  database / schema per target (`dev` / `dev_shared` / `prod`) for Snowflake-native
  execution. Contains no account, user, password, or keys — execution inside Snowflake
  uses the calling session's identity. Never add credentials to it.

### Changed

- `.gitignore` no longer ignores `profiles.yml` (it is credential-free by design now);
  the never-commit-credentials rule is stated in the file itself and in CONTRIBUTING.
- CI (`dbt-ci.yml`) pins `DBT_PROFILES_DIR` to `~/.dbt` in both jobs so the root
  profile never shadows the CI profile built from `profiles.yml.template`.
- CONTRIBUTING / ONBOARDING document the two-profile split (Snowflake-native root
  profile vs. `~/.dbt` for local and CI).

---

## [7.5.1] — 2026-07-30 — Rollout Corrections

Patch-application fixes only — no new functionality. Verification of the applied
7.0.0–7.5.0 releases against the source tree found three gaps, corrected here:

### Fixed

- **Release 7.2.0's file payload was not applied** — the CI workflow, release-gate and
  ops macros, and terraform files were still at their 7.1.0 state, and its new files
  (`.sqlfluff`, `.sqlfluffignore`, `terraform/modules/*/variables.tf`,
  `disabled/README.md`) were missing. All restored to the 7.2.0-era content.
- **Deletions and renames from 7.0.0–7.5.0 were skipped** — files that earlier releases
  removed or moved were still present at their old paths (including `profiles.yml` and
  `git_workspace_setup.sql` from 7.0.0 — the security-sensitive removals). Old paths
  removed; new paths confirmed (see RELEASE_NOTES for the full list).
- **`dpr-dashboard/deployed/streamlit_app.py`** was corrupted during application (file
  header pasted mid-dictionary, content duplicated). Replaced with the correct version.

---

## [7.5.0] — 2026-07-29 — Documentation Truth Sweep

Docs now describe the repo as it is. `dbt_project.yml` version aligned to this changelog
(it had stayed at 1.0.0 since initial setup).

### Changed

- **Inventory docs regenerated from the tree** — root README scope tables (34 staging /
  21 intermediate / 13 dims / 11 facts / 23 reports / 2 ML / 19 seeds / 12 tests / 4 semantic
  views); every `models/*/README.md` (the dimensions README's enabled and disabled lists were
  fully inverted); tests READMEs list all 12 active tests; retired `silver_*` names replaced
  throughout; `ARCHITECTURE_FLOW.md` rewritten from scratch (previous content described a
  pre-1.3.0 repo that no longer exists); PROJECT_MAP, TEST_ORCHESTRATION, SCORECARD,
  SOURCE_INTEGRATION (retail POS confirmed as NCR CounterPoint; Fabric references removed),
  SNOWFLAKE_SETTINGS (SEEDS schema, alerts marked SUSPENDED per 6.1.0), USAGE_AUDIT,
  SQL_STYLE_GUIDE (int_* convention, `_key` keys, the real sqlfluff ruleset) all corrected.
- **ADR record made coherent** — `ADR_018_metric_defintion_ownership.md` renamed (typo);
  index rebuilt over the 7 in-repo ADRs with the external-register numbering note (007–017;
  007/008 collision tracked, owner Jeremy); ADR-018 §3 amended (pending committee
  ratification) to exempt thin serving chains off `rpt_*_powerbi` / `rpt_*_budget_daily` —
  governance and code no longer disagree.
- **`CODEOWNERS` moved to `.github/CODEOWNERS`** (a location GitHub honors) with path
  patterns fixed — the reviewer gate is now enforceable.
- **CONTRIBUTING / ONBOARDING runnable again** — real CI description, ownership zones from
  `groups.yml`, Time Travel 7 days, corrected rollback recipe, Python 3.11 /
  dbt-snowflake 1.9.*, `dev_shared` target, template-based profile setup, `core.hooksPath`
  step, smoke tests that execute (`dim_facility`, `date_key`).
- **`docs/DATA_CONTRACTS.yml`** rewritten for the live marts with source-matched freshness
  SLAs; **`docs/REFRESH_LOG.md`** reset to a truthful empty log (the logged runs could not
  have been produced by the current code); **DQI-0001** repointed at the real artifact names;
  policy docs aligned on the "AI & Data Committee" name; remaining Fabric references removed;
  `pipelines/readme.md` → `pipelines/README.md`; `macros/generic_tests/` filenames
  standardized (unused `test_` prefixes dropped) and the library honestly marked
  available-but-unadopted; exposures meta repointed at live models.

### Reconciliation

History that previous entries missed, recorded here rather than by rewriting them:

- `dim_marketing_channel` was removed from the repo after its 4.1.0 re-enable, with no
  changelog entry at the time. Its seed `ref_marketing_channels` remains.
- `dim_dpr_line_item` and `dim_retail_line_item` were added, together with their
  `dpr_line_items.csv` / `retail_line_items.csv` seeds, without a changelog entry.
- The `rpt_*_powerbi` / `rpt_*_report_long` / `rpt_*_budget_daily` report family (DPR and
  Retail serving chains) was added without a dedicated changelog entry.
- The WiFi feed (`stg_wifi__audience` and downstream `rpt_wifi_email_export`) was loaded
  without a dedicated changelog entry.
- Errata annotations added to the duplicated `[1.2.0]` / `[1.1.0]` entries and to
  4.1.0/4.2.0 (see those entries).

---

## [7.4.0] — 2026-07-29 — Model Hygiene

### Changed

- **Header standard completed** — the nine Power BI serving models
  (`rpt_*_powerbi`, `rpt_*_report_long`, `rpt_retail_category_long`, `rpt_*_budget_daily`)
  now carry the standard Layer/Domain/Grain/Feeds/ADR header; layer tokens normalized on the
  ML and narrative models; 78 AI-attribution comment lines stripped repo-wide;
  `rpt_daily_performance_report`'s table override documented with a MATERIALIZATION note.
- **Budget reports no longer self-source** — `rpt_dpr_budget_daily` / `rpt_retail_budget_daily`
  read the `fct_budget_*` models via `ref()` instead of a fake `source()` (DAG ordering and
  lineage restored); dead source blocks removed; `_budget_sources.yml` moved to `models/raw/`
  with the stg-bypass exception documented.
- **Facility literals removed from the new report family** — `rpt_retail_report_long`,
  `rpt_retail_narrative_brief`, `rpt_dpr_budget_daily` join `dim_facility` and key off
  `facility_group` instead of raw facility numbers (1:1 join on `key_facility`, same rows
  selected — a renumber no longer touches report SQL).
- **Deprecated `tests:` keys converted to `data_tests:`** with
  `dbt_utils.unique_combination_of_columns` replacing concatenated-column unique tests.
- **Severity rule applied both directions** — four GROUP-BY-enforced grain tests promoted
  warn → error (`int_retail__performance`'s grain combination also corrected to
  date × facility × category); `int_budget__*` uniques and `rpt_dpr_powerbi.report_date`
  demoted to warn (inherited/unverified grains).

### Added

- **schema.yml coverage for all 16 previously undocumented active models**, including
  `int_gateway__item_attributes` and `fct_today_sales_hourly`, and `rpt_wifi_email_export`
  documented as RESTRICTED/PII; `int_gateway__ticket_journal_lines.jnl_detail_id` finally
  has a `unique` test (warn) — the DPR backbone's grain was previously untested.
- `retail_line_items` and `seed_scan_market_segment` registered in `_seeds.yml` with tests
  (both actively consumed but previously unregistered); `ref_*` seeds marked as legacy
  deletion candidates.
- `fct_ticket_availability` NOTE documenting the 7-day-lookback vs 90-day-window constraint
  (monthly `--full-refresh` recommended); redundant `enabled=true` removed.

### Removed

- Eight ghost `tmp_seed_*` entries in `_seeds.yml` (no CSVs exist); `seeds/tmp_seed_dsr_budget.csv`
  (orphan); `pipelines/salesforce_mc/temp_pipeline.py` (contained a real SFMC tenant id and
  bypassed Key Vault). `alert_management.sql` moved to `scripts/`; `TEMP_POC_MIGRATION.md`
  moved to `docs/POC_MIGRATION_RECORD.md` as a marked historical record.

---

## [7.3.0] — 2026-07-29 — Semantic Layer: Unique Metrics & Single Generator

### Changed

- **Metric renames** so no metric name means two different numbers depending on which
  semantic view answers (**BREAKING for saved Cortex/BI queries using the old names**):
  - ATTENDANCE `TOTAL_TICKETS_SOLD` → `TOTAL_TICKETS_SCANNED` (scan-side count; DPR keeps
    the canonical Gateway-side `TOTAL_TICKETS_SOLD`).
  - ATTENDANCE `TOTAL_TICKET_REVENUE` → `TOTAL_FORECAST_TICKET_REVENUE` (forecast-side; DPR
    keeps the recognized-actuals name).
  - RETAIL `TOTAL_DONATIONS` → `TOTAL_RETAIL_DONATIONS` (register donations; the name
    UNIFIED already used — DPR keeps all-channel `TOTAL_DONATIONS`).
  - DPR/UNIFIED `MUS_STORE_REV_PER_VISITOR` → `MUS_STORE_PROFIT_PER_VISITOR` (it computes
    from gross profit; the name now says so).
  - `AVG_TICKET_PRICE` authored identically everywhere as
    `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`.
  - Consumer updated: `rpt_daily_scan_powerbi` (output alias unchanged — Power BI unaffected).
- **One deployment method** — `scripts/generate_semantic_view_ddl.py` renders deploy DDL for
  every `cortex_project/*.sv.yaml` (the single authored source of truth) with a `--check`
  drift mode; `.githooks/pre-commit` rewritten to enforce it (the old hook pointed at the
  deleted `semantic_models/` paths and could never fire). Regenerated attendance/retail DDL;
  generated the previously missing DPR/UNIFIED DDL.
- **`JMYERS_TEST.agent.yaml` → `DPR_ANALYST.agent.yaml`** — team-owned agent, deployed as
  `NS11MM_DW_DEV.MARTS.DPR_ANALYST`.

### Fixed

- ATTENDANCE/RETAIL seed references pointed at schema `MARTS`; seeds build to `SEEDS`.
- **Fiscal-calendar claims scrubbed** (dim_date has no fiscal columns): descriptions, the
  phantom `fiscal_year`/`fiscal_month` schema.yml columns on `rpt_dpr_powerbi`, and the
  YTD/monthly report headers now say calendar-based, with the fiscal variant deferred to the
  Data & AI Committee under ADR-005 (proposed FY start: October).

### Removed

- `FUNDRAISING_ECOM.sv.yaml` → `cortex_project/disabled/` and out of the deploy manifest —
  all four of its base tables are disabled dims; it cannot deploy.

---

## [7.2.0] — 2026-07-29 — Working CI, Release Gates & Infrastructure

None of the automation this patch touches could previously run as written.

### Added

- **`.sqlfluff` / `.sqlfluffignore`** — real lint config (lowercase keyword/identifier/
  function rules per the SQL style guide; layout/aliasing rule families excluded; repo lints
  clean). CI enforces it — no more `|| true`.
- **`terraform/modules/*/variables.tf`** — every module now declares the variables it
  references (`terraform validate` previously failed on undeclared inputs).
- **`disabled/README.md`** — why all 14 Azure Function CD pipelines are parked, and what
  re-enabling requires.

### Changed

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

### Fixed

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

### Removed

- `macros/data_quality/check_source_freshness.sql` — built freshness queries and never
  executed them, against tables that don't exist. `dbt source freshness` (configured in
  `sources.yml`) is the real mechanism.

---

## [7.1.0] — 2026-07-29 — Prod Pathing & PII Governance

### Changed

- **`models/raw/sources.yml`** — all three raw source groups resolve via
  `{{ target.database }}` instead of a hardcoded personal dev database. A prod deploy no
  longer reads a developer sandbox; matches the pattern the other source files already used.
- **Cortex project, DPR dashboard, scripts** — semantic views, the agent, both Streamlit app
  copies, semantic-view deploy SQL, narrative setup, and `MANUAL_ML_RUN.sql` now target
  shared dev (`NS11MM_DW_DEV`) rather than a personal sandbox.
- **`pipelines/shared/`** — Key Vault URL, Snowflake database, and warehouse are env-var
  selectable (`NS11MM_KEYVAULT_URL`, `NS11MM_SNOWFLAKE_DATABASE`, `NS11MM_SNOWFLAKE_WAREHOUSE`);
  ingestion defaults to `SOURCES_WH` per SNOWFLAKE_SETTINGS (was hardcoded `COMPUTE_WH`).
- **Narrative tasks** (`scripts/setup_*_narrative.sql`) run on `MONITORING_WH`.
- **Grants** — marts/ml read access moved from post-hooks to dbt `grants` config so models
  can override the default.

### Fixed

- **`rpt_wifi_email_export` no longer inherits BI/ML grants** — `grants: {select: []}`
  overrides the marts default; POWERBI_ROLE / ML_ROLE do not receive the PII export (its own
  header required this; the inherited hook violated it).
- **`apply_masking_policies` / `apply_governance_tags` actually work** — target lists rebuilt
  from the active model estate (`stg_wifi__audience`, `stg_ecommerce__website_recurring`,
  `int_pos_tickets`, `dim_customer`, `rpt_wifi_email_export`, plus the live marts). The old
  lists named pre-rename POC and disabled objects, so the existence checks no-opped every
  entry and nothing was ever masked or tagged. View-vs-table ALTER handled; policy/tag
  database parameterized via vars.
- **`scripts/MANUAL_ML_RUN.sql`** referenced `dim_date` columns that don't exist
  (`date_id` → `date_key`, `fiscal_year` → `year_number`) — could not have run as written.

### Docs

- `docs/architecture/DATA_CLASSIFICATION.md` PII inventory rewritten to the live surfaces,
  with an explicit keep-in-sync rule binding it to the masking/tagging macros.

---

## [7.0.0] — 2026-07-29 — Security Hygiene

First of six release-readiness patches (7.0.0 → 7.5.0). Major bump: developer setup changes
(the repo-root `profiles.yml` is gone).

### Removed

- **`profiles.yml`** — a committed connection profile carrying the real Snowflake account and
  user identities (docs had claimed it was gitignored; it wasn't). It also contained a
  copy-paste bug (`dev_dsun` target pointed at DSUN's database under the jmyers user).
  **BREAKING:** developers now keep their profile at `~/.dbt/profiles.yml`, created from the
  new template.
- **`git_workspace_setup.sql`** — one-off personal workspace setup that contained a committed
  GitHub PAT. NOTE: deleting the file does not revoke the token — it must be revoked in
  GitHub (it remains in the old repository's history).
- **`.temp/uploads/`** — stale local copies of governed seeds (one missing the Museum Cafe
  facility row, one missing the VTEDU virtual-tour PLUs). Restoring from them would have
  reintroduced fixed bugs.

### Added

- **`profiles.yml.template`** — env-var-driven profile template (targets `dev` / `dev_shared`
  / `ci` / `prod`) with explicit authenticators (SSO for developers, secret-based for CI/prod).

### Changed

- `.gitignore` now explicitly ignores `profiles.yml` (template excepted) and key files
  (`*.pem`, `*.p8`).

---

## [6.1.0] — 2026-07-29 — Resource Monitor Fix & Test/Alert Coverage Audit

Session date: 2026-07-29. dbt execution failed because warehouse `DBT_DEV_WH` was suspended by
resource monitor `DBT_DEV_MONITOR` (5-credit monthly quota exceeded by 0.04 credits). Diagnosed
root cause, restored the warehouse, and audited test + alert coverage across all mart tables and
semantic views.

### Fixed

| Issue | Resolution |
|-------|------------|
| `DBT_DEV_MONITOR` quota exhausted (5.04 / 5.00 credits) | Increased monthly quota from 5 → 10 credits |
| `DBT_DEV_WH` suspended, blocking all 104 dbt models | Resumed warehouse after quota increase |

### Audit Findings — Test Coverage

| Finding | Status | Detail |
|---------|--------|--------|
| Schema-level column tests (PK unique/not_null, FK relationships) | ✅ Covered | All 13 dimensions + 11 facts + 2 ML features have schema tests |
| `assert_critical_tables_not_empty` | ⚠️ Partial | Only covers 6 of 17 enabled tables/views. Missing: `fct_daily_performance`, `fct_retail_daily`, `fct_retail_performance`, `fct_daily_scan`, `fct_today_sales_hourly`, `fct_budget_admissions_forecasts`, `fct_budget_dpr_forecasts`, `fct_budget_retail_forecasts`, `ml_visitor_forecast_training` |
| Revenue reconciliation (silver → gold) | ⚠️ Partial | Only ticket revenue (`int_pos_tickets` → `fct_daily_operations`). No retail reconciliation (`int_retail__performance` → `fct_retail_performance`) |
| Negative-value assertions | ⚠️ Partial | Only `fct_daily_operations.ticket_revenue`. No coverage for retail net_sales/net_profit or attendance counts |
| Grain uniqueness (singular tests) | ✅ Covered | Multi-column grain tests exist in schema.yml for all composite-key facts |

### Audit Findings — Alerts

| Alert | State | Issue |
|-------|-------|-------|
| `ALERT_SOURCE_FRESHNESS` | **SUSPENDED** | No freshness notifications firing |
| `ALERT_DBT_RUN_FAILURES` | **SUSPENDED** | Today's failure went unnoticed |
| `ALERT_CREDIT_CONSUMPTION` | **SUSPENDED** | Quota breach was silent |
| `ALERT_LONG_RUNNING_QUERIES` | **SUSPENDED** | No performance monitoring active |
| `ALERT_WAREHOUSE_UTILIZATION` | **SUSPENDED** | No queuing detection active |
| Resource monitor quota alert | **MISSING** | No alert exists for monitor quota approaching limits |

### Audit Findings — Semantic Views

| Semantic View | Backing Tables Tested | Notes |
|---------------|----------------------|-------|
| `DPR` | `fct_daily_performance`, `dim_date` | `fct_daily_performance` missing from emptiness test |
| `RETAIL` | `fct_retail_daily`, `fct_retail_performance`, `dim_date` | Both facts missing from emptiness test; no retail revenue reconciliation |
| `UNIFIED` | `fct_daily_performance`, `fct_retail_performance`, `fct_daily_scan`, `dim_date` | `fct_daily_scan` missing from emptiness test |
| `ATTENDANCE` | `fct_daily_scan`, `fct_ticket_demand_forecast`, `fct_ticket_availability` | `fct_daily_scan` missing from emptiness test |
| `FUNDRAISING_ECOM` | `dim_customer`, `dim_campaign`, `dim_payment_method`, `dim_fund` | Stub dimensions — tests pass trivially |

### Recommended Next Steps (not yet implemented)

1. Resume all 5 suspended alerts
2. Add resource monitor quota alert (notify at 75%, alert email at 90%)
3. Expand `assert_critical_tables_not_empty` to cover all mart facts backing semantic views
4. Add retail revenue reconciliation test (`int_retail__performance` → `fct_retail_performance`)
5. Add negative-value assertions for `fct_retail_daily.net_sales` and `fct_daily_scan` attendance

### Migration notes

- **No breaking changes.** Only the resource monitor quota was altered (5 → 10 credits/month).
- All alerts remain suspended pending deliberate re-enablement.

---

## [6.0.0] — 2026-07-28 — DPR Analyst Narrative (Cortex AI)

Session date: 2026-07-28. Added an AI-generated "Analyst Notes" block to the Daily Performance
Report pipeline. A deterministic brief model computes every fact the narrative is allowed to
reference — actuals, budget, DoD, WoW, YoY (364 days), MTD/YTD, direction flags, and top movers —
then Snowflake Cortex (`claude-sonnet-4-6`) narrates ONLY those pre-computed facts. The LLM does
no analysis; it writes prose from a structured brief. Every sentence traces to an auditable input.

### Added

| Object | Type | Detail |
|--------|------|--------|
| `rpt_dpr_narrative_brief` | dbt view (MARTS) | Deterministic JSON brief: one row per report_date with actuals, budget, var_pct, dod_pct, wow_pct, yoy_pct, MTD/YTD, 7-day direction flags, and top-3 budget/DoD movers. Report date = previous day (`< CURRENT_DATE`). YoY uses 364-day (52-week) lookback for same-weekday comparison. |
| `rpt_dpr_narrative` | dbt model (disabled) | Source SQL for the daily Snowflake TASK. `enabled=false` — not materialized as a view (each SELECT triggers an AI call). Kept in project for documentation and audit. |
| `DPR_NARRATIVE` | Table (MARTS) | Append-only storage: report_date, headline, narrative, watch_items, brief_json, tokens_used, model, generated_at, `_loaded_at`. Clustered by report_date. Use `_loaded_at DESC` to pick the latest row per date (supports reprocessing). |
| `DPR_PBI_NARRATIVE` | View (MARTS) | Power BI consumption wrapper — `QUALIFY ROW_NUMBER() OVER (PARTITION BY report_date ORDER BY _loaded_at DESC) = 1`. Relates to Dim_Date on report_date. |

### Architecture

```
RPT_DPR_POWERBI (actuals) ─┐
RPT_DPR_BUDGET_DAILY        ├─► rpt_dpr_narrative_brief ─► TASK: CORTEX.COMPLETE() ─► DPR_NARRATIVE ─► DPR_PBI_NARRATIVE ─► Power BI text card
DIM_DATE ───────────────────┘        (deterministic)            (claude-sonnet-4-6)       (append-only)     (latest per date)
```

### Design decisions

| Decision | Choice |
|----------|--------|
| Report date | Previous day (`< CURRENT_DATE`) — the DPR covers yesterday |
| YoY comparator | 364 days (52 weeks) — same weekday alignment |
| Materialization | `enabled=false` in dbt; TASK owns the insert lifecycle |
| Reprocessing | Re-run the task → new `_loaded_at` wins in `DPR_PBI_NARRATIVE` |
| Structured output | `response_format` with JSON schema: `headline`, `narrative`, `watch_items` |
| Temperature | 0.1 — near-deterministic; same facts read the same way each day |
| Model | `claude-sonnet-4-6` via `SNOWFLAKE.CORTEX.COMPLETE` |
| Grants | `POWERBI_ROLE` on both table and PBI view |

### Migration notes

- **No breaking changes** to existing models or views.
- `DPR_NARRATIVE` is new infrastructure — no downstream consumers until Power BI is wired.
- The daily TASK definition is not yet created (next step: chain after DPR load task).
- `DPR_LINE_ITEMS` (legacy orphan, no dbt model) was dropped during this session.

---

## [5.1.0] — 2026-07-28 — Standardized Header Notes

Session date: 2026-07-28. Applied a consistent documentation header block to all 53 model and test
SQL files. No SQL logic or `{{ config() }}` content was changed — only the comment blocks at the top
of each file were reformatted. Headers now follow a single convention: layer prefix → separator →
Domain / Grain / narrative notes, with `{{ config() }}` consistently placed after the header block.

### Changed

| Area | Change |
|------|--------|
| 3 intermediate budget models | `-- Intermediate:` → `-- Silver intermediate:` prefix; normalized `Grain:` spacing. |
| 6 intermediate DPR models | `-- Silver DPR:` → `-- Silver intermediate:` prefix; removed indent from bullet lists. |
| 4 intermediate retail/gateway models | Moved `{{ config() }}` below header (was above); normalized format. |
| 11 dimension models | Converted `/* ... */` block-comment headers to `--` line-comment format with Domain/Grain/Source structure. |
| 9 fact models | Moved headers above `{{ config() }}` where needed; changed `-- Mart fact:` → `-- Marts fact:`; normalized `Grain:` spacing. |
| 11 report models | Moved headers above `{{ config() }}`; normalized `Grain:` spacing; removed indent from bullet lists. |
| 1 ML feature model | Removed stale one-liner description; normalized header. |
| 8 test files | Replaced single-line descriptions with `-- Test (category):` format and added `-- Severity:` annotation. |

### Convention (all 53 files)

```
-- <Layer> <type>: <one-line title>
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: <domain>
-- Grain: <grain statement>
--
-- <Narrative notes…>

{{ config(…) }}
```

### Migration notes

- **No breaking changes.** SQL output is byte-for-byte identical.
- `{{ config() }}` position moved in ~15 files (from above the header to below). dbt treats position
  as irrelevant — compilation is unaffected.

---

## [5.0.0] — 2026-07-27 — Seeds Schema & Budget Forecasts

Session date: 2026-07-27. Introduced a dedicated `SEEDS` schema, loaded three new budget/forecast
seed tables from Excel-to-CSV uploads, and fixed the DPR semantic view to remove a phantom
`DATE_ID` column. **Breaking change**: all `SEED_*` tables now live in `SEEDS` instead of `MARTS`.
Any external queries referencing `MARTS.SEED_*` must be updated.

### Added

| Object | Type | Detail |
|--------|------|--------|
| `NS11MM_DW_DEV_JMYERS.SEEDS` | Schema | New dedicated schema for all seed/lookup tables. |
| `SEED_DPR_FORECASTS` | Seed table (365 rows) | FY2026 daily DPR budget: tickets, revenue, audio, donations, ecommerce, cafe, tours. |
| `SEED_FORECASTED_VALUE_FOR_DATE` | Seed table (365 rows) | FY2026 daily admissions/attendance budget by facility: attendance, tickets, guided tours, CityPASS, memorial tours. |
| `SEED_RETAIL_FORECASTS` | Seed table (1,095 rows) | FY2026 daily retail budget by facility (3 facilities × 365 days): capture rate, visitors, conversion, profit, donations. |
| `_budget_sources.yml` | dbt source | Source definition pointing at the three new budget seeds in `SEEDS` schema. |

### Changed

| Area | Change |
|------|--------|
| `dbt_project.yml` | Seeds default schema changed from per-seed overrides to `+schema: SEEDS` for all seeds. |
| 12 existing SEED_* tables | Moved from `MARTS` to `SEEDS` schema (`ALTER TABLE … RENAME TO`). |
| DPR semantic view | Removed `primary_key` block from DP (fact) table — `DATE_ID` no longer surfaces as a selectable column. Fixed relationship join column from non-existent `DATE_ID` to actual `DATE_KEY`. Removed `FISCAL_MONTH` and `FISCAL_YEAR` dimensions (columns don't exist in `DIM_DATE`). |

### Migration notes

- **External consumers** (Power BI, ad-hoc SQL) referencing `MARTS.SEED_*` must update to `SEEDS.SEED_*`.
- **dbt models** are unaffected — they use `ref('seed_*')` which resolves via the project config.
- The 3 new budget tables were renamed from `FACT_*` → `SEED_*` to follow naming conventions.

---

## [4.2.0] — 2026-07-23 — Conformed dim_facility & Config-as-Data Cleanup

*Errata (2026-07-29): this entry discusses `dim_marketing_channel` as a kept passthrough dim; the model was subsequently removed from the repo without a changelog entry. See the Reconciliation subsection of [6.2.0].*

Session date: 2026-07-23. Started from "where should we join the new `dim_*` tables in to make
filters cleaner?" The review found `dim_date` was already wired into 13 models and the other
ten dims were built ahead of their consumers, so the question turned into a codebase-wide audit
for `facility_group`-style issues — inline enumerable code→label maps, repeated magic-number
literals, and duplicated join/CTE blocks. That produced three batches of **output-equivalent**
cleanups (verified; see below). No breaking changes: every touched model keeps its column
contract.

### Added (net-new models)

| Model | Grain | Source | Purpose |
|-------|-------|--------|---------|
| `dim_facility` | key_facility | `seed_facility_area` | Conformed facility/area dimension. Single home for `key_facility → area_name / area_group / is_selling / facility_group`, previously re-selected inline in three retail facts + `dim_store` and derived as an inline CASE in `int_counterpoint__retail_lines`. |
| `int_gateway__item_attributes` | avg_id | `stg_gateway__vattribute` | Shared `avg_id → matrix_code / recognize_basis / default_customer / dynamic_channel` lookup, previously re-selected in three gateway intermediates. Raw passthrough — consumers keep their own coalesce/`visit_type` derivations. |

### Added (net-new seeds — config-as-data)

| Seed | Rows | Replaces inline literal in |
|------|------|----------------------------|
| `seed_retail_store_scope` | 9 | `int_counterpoint__retail_lines` store-scope `IN` list |
| `seed_retail_zero_price_item` | 2 | `int_counterpoint__retail_lines` zero-rated-SKU list |
| `seed_retail_excluded_item` | 1 | `int_counterpoint__retail_lines` hygiene exclusion |
| `seed_retail_donation_item` | 4 | `int_dpr__retail` donation-SKU `item_no` literals (→ `donation_line`) |
| `seed_gateway_excluded_plu` | 1 | `int_gateway__ticket_journal_lines` placeholder-PLU exclusion |
| `seed_gateway_excluded_customer` | 2 | `int_gateway__ticket_journal_lines` `itm_default_customer_id` exclusion |

### Changed (models rewired — output-equivalent)

| Model | Change |
|-------|--------|
| `int_counterpoint__retail_lines` | `facility_group` CASE → `seed_facility_area` lookup (`coalesce(…, 'other')`); store scope / zero-price / excluded-item literals → seeds. |
| `fct_retail_daily`, `fct_retail_performance` | Dropped inline `seed_facility_area` `area` CTE; now `left join dim_facility`. |
| `fct_today_sales_hourly` | Third consumer of the area seed; area label now from `dim_facility`. |
| `dim_store` | `store_type` (=`area_group`) now sourced from `dim_facility` instead of re-reading `seed_facility_area`. |
| `int_retail__performance` | Raw `summary_category = 6` (×5) → the `is_donation` flag already exported by `int_counterpoint__retail_lines` (completes the 4.0.0 refactor, which had missed this model). |
| `rpt_retail_carts_analysis` | Raw `key_facility = 1020 / 1030` → conformed `area_name` (`'Memorial Carts'` / `'Atrium'`). |
| `int_retail__visitors` | Hardcoded `1234 as key_facility` → `{% set ecom_key_facility = 1234 %}` var. |
| `int_gateway__ticket_journal_lines` | `vattribute` CTE → `int_gateway__item_attributes`; PLU/customer exclusions → seeds (`NOT EXISTS` preserves the NULL-customer-kept behavior). |
| `int_gateway__item_journal_lines`, `int_gateway__scan_lines` | `vattribute` CTE → `int_gateway__item_attributes`. |
| `int_dpr__retail` | Donation-SKU `item_no` literals → `seed_retail_donation_item.donation_line` (mirrors the 4.0.0 `seed_service_plu` pattern). |

### Updated (seeds & schema)

- **`seeds/seed_facility_area.csv`** — added `facility_group` column (`museum_store`, `memorial_carts`, `museum_cafe`, `mag_cart`, `mus_ag`, `ecommerce`; `1030`/`1070`/`1080` → `other`, matching the old CASE else-branch).
- **`seeds/_seeds.yml`** — registered the 6 new seeds (with `column_types` pins so alphanumeric `item_no`/`plu` are not coerced to numeric) and documented the new `facility_group` column with `not_null`.
- **`models/marts/dimensions/schema.yml`** — added `dim_facility` (PK `facility_key`; `not_null` on `area_name` / `area_group` / `facility_group`).

### Verification

- **Ref graph** — every `ref()` in the 15 touched/new models resolves against the model + seed set (incl. the 6 new seeds); no rewritten model left a dangling CTE alias.
- **Truth-table equivalence proofs** — the three non-mechanical transforms were checked exhaustively: the `facility_group` CASE vs. seed-join+`'other'` across all keys; the customer exclusion (`NOT IN (…) OR IS NULL` vs. `NOT EXISTS`, including the NULL-kept case); and `summary_category (<>6 / =6)` vs. `(not is_donation / is_donation)`.

### Design Decisions

1. **`dim_facility` is a new dim, not `dim_store`.** The duplicated area join is at `key_facility`
   grain; `dim_store` (built in 4.1.0) is `store_id` grain, so it could not deduplicate it. The
   retail facts join the new `key_facility`-grained `dim_facility`.

2. **`facility_group` lives in the seed, joined in silver — not pulled from the mart dim.**
   `int_counterpoint__retail_lines` is an upstream intermediate; having it `ref()` a mart dim
   would reverse layering. Instead the mapping went into `seed_facility_area` (reference data's
   natural home) and both `dim_facility` and the intermediate read the seed. Dims are otherwise
   joined only in the marts layer.

3. **`1030` / `1070` / `1080` stay `facility_group = 'other'`** (product decision), so
   `rpt_retail_carts_analysis` references facilities by unique `area_name` rather than group.

4. **Gateway attribute model is a raw passthrough.** It exposes `stg_gateway__vattribute`
   columns unchanged (no coalesce), so each consumer's existing `matrix_code` handling and the
   `gateway_recognized_date` / `gateway_general_admission_flag` macros work with zero column
   changes. Standardizing scan-line's NULL→'' handling was deliberately *not* done (would alter
   output).

### Investigated and deliberately NOT changed

- **`dim_date`** — already joined in 13 models; nothing to do beyond an optional inline cleanup
  in `int_gateway__ticket_demand_features` (skipped to keep intermediate free of mart refs).
- **Passthrough dims** — `dim_tour_product` (= `seed_tour_plu`) and `dim_marketing_channel`
  (= `ref_marketing_channels`): rewiring consumers to ref the dim inverts layering for zero
  dedup; kept the seed refs.
- **`store_facility` CTE** (`seed_retail_store_facility`, in retail_lines + today_sales_hourly) —
  left inline; centralizing via `dim_store`'s `min(key_facility)` aggregation risked changing
  fan-out.
- **`demand_level` bands, "sold tickets" base CTE, `%MEMORIAL%`/`%member%` name-match ladders** —
  single-use or open-set; consistent with the 4.0.0 keep-inline rules.

### Open items

- **`int_dpr__retail` (Batch C) is the highest-risk change** — it moves delicate donation
  double-count logic onto a seed join. Logic is preserved, but run a before/after row-count and
  per-column sum diff on this model specifically before merge.
- Several Batch C seeds are single-row (`seed_retail_excluded_item`, `seed_gateway_excluded_plu`);
  fold back inline if the extra seed files aren't worth the ops-editability.
- Suggested build gate: `dbt build --select int_counterpoint__retail_lines+ int_gateway__item_attributes+ dim_facility+`.

---

## [4.1.0] — 2026-07-22 — Dimension Table Buildout

*Errata (2026-07-29): the `dim_marketing_channel` re-enable recorded below was later undone — the model was subsequently removed from the repo without a changelog entry (its seed `ref_marketing_channels` remains). See the Reconciliation subsection of [6.2.0].*

Session date: 2026-07-22. Started from "should we break out repeating values in SEED
tables into dedicated tables?" — cardinality analysis confirmed strong candidates and
grew into a full dimension buildout. Also cleaned up NULL-only rows from SEED tables and
moved 5 dimension models out of the disabled folder into production.

### Data Cleanup

**RAW.SEED_* NULL row removal** — Deleted 833,128 rows across 4 tables where all columns
except `_LOADED_AT` were NULL (artifact of source extraction):
- `SEED_GATE_TICKETS`: 697,752 rows
- `SEED_GATE_ORDERLINES`: 104,042 rows
- `SEED_GATE_RMEVENTS`: 29,152 rows
- `SEED_GATE_ORDERS`: 2,182 rows

### Added (net-new dimension models)

| Model | Rows | Source | Purpose |
|-------|------|--------|---------|
| `dim_access_code` | 36 | `stg_gateway__tickets` + `stg_gateway__items` | Maps ~36 access codes to admission type categories (Museum General, Memorial, CityPass, Tour, Pass/Membership, Education, Audio Guide, Admin/Test) |
| `dim_event` | 29,485 | `stg_gateway__rmevents` | Timed-entry events, tours, programs, shows with active/private/roster/waitlist flags |
| `dim_store` | 5 | `seed_retail_store_facility` + `seed_facility_area` | CounterPoint store/register → facility mapping (Museum Store, Memorial Carts, Ecommerce, Cafe) |
| `dim_coa` | 712 | `stg_gateway__coa` | Chart of Accounts for journal entry classification (Summary vs Detail, category hierarchy) |
| `dim_tour_product` | 40 | `seed_tour_plu` | PLU → DPR tour type mapping (mem_field_trip, mus_field_trip, revealed_tour, early_access_tour, etc.) |

### Changed (rebuilt from disabled placeholders)

| Model | Rows | Was | Now |
|-------|------|-----|-----|
| `dim_customer` | 1,037 | Placeholder (ID, STATUS); depended on missing `int_sf_crm` | Sources from `stg_gateway__tickets`; derives customer_type from CUSTNO prefix (Web, CityPass, Viator, Go City, GetYourGuide, Tiqets, Group, Pre-Sale, Rides/Partner) |
| `dim_gate` | 190 | Placeholder; depended on missing `int_ticket_scans` | Sources from `stg_gateway__acps` + `stg_gateway__facility`; combines ACP name, node, facility, capacity |
| `dim_product` | 1,168 | Placeholder; depended on missing `int_pos_retail` + `stg_shopify__products` | Sources from `stg_counterpoint__imitem`; includes pricing, category, barcode, price_tier derivation |
| `dim_ticket_type` | 7,336 | Placeholder; depended on missing `int_pos_tickets` + `ref_ticket_types` | Sources from `stg_gateway__items`; derives item_type (Ticket, Pass, Tour, Event, Merchandise) from pass_kind/event_type/stock_type |
| `dim_marketing_channel` | 7 | Had `enabled=false` despite no external dependency | Removed `enabled=false`; now builds from `ref_marketing_channels` seed |

### File moves

**Moved out of `models/marts/dimensions/disabled/` → `models/marts/dimensions/`:**
- `dim_customer.sql` (rewritten)
- `dim_gate.sql` (rewritten)
- `dim_product.sql` (rewritten)
- `dim_ticket_type.sql` (rewritten)
- `dim_marketing_channel.sql` (rewritten — removed `enabled=false`)

**Remaining in `disabled/`** (still awaiting external source connections):
- `dim_campaign.sql` — Salesforce
- `dim_fund.sql` — Blackbaud
- `dim_budget_version.sql` — Vena
- `dim_payment_method.sql` — no source data yet

### Updated

**models/marts/dimensions/schema.yml** — Full rebuild:
- Added column-level docs + tests for all 5 net-new + 5 rebuilt dimensions
- Primary key constraints + `unique` / `not_null` tests on all PK columns
- Descriptive column docs for key business columns (admission_type, item_type, customer_type, etc.)
- Retained entries for disabled dimensions (dim_campaign, dim_fund, dim_budget_version, dim_payment_method)

### Design Decisions

1. **Staging refs, not sources** — All dimension models `ref()` the `stg_*` staging views
   (which handle rename/recast/dedup) rather than going direct to `source()`. This keeps the
   dimension layer clean and leverages the existing staging contract.

2. **No identity resolution yet** — `dim_customer` derives type from CUSTNO prefix patterns
   rather than attempting cross-system matching (Gateway CUSTOMERID ↔ CounterPoint CUST_NO ↔
   Salesforce). That work is deferred until CRM feeds land.

3. **Access code classification** — The admission_type CASE statement in `dim_access_code`
   is based on observed ticket volume patterns and code ranges. Should be validated with
   someone who knows the Gateway configuration.

4. **Natural keys as PKs** — Surrogate keys (AUTOINCREMENT) used in the direct SQL creates
   on MARTS tables, but dbt models use the natural key as PK (item_id, event_id, etc.) since
   dbt doesn't manage sequences and natural keys are stable in this domain.

---

## [4.0.0] — 2026-07-21 — Model Optimization


Session date: 2026-07-21. Started from "should we move CASE statements into dedicated
tables to join to?" and grew into a broader optimization pass. This doc is the
consolidated record of findings and delivered changes.

### Original question: CASE statements → join tables?

Mostly **no**. CASE-heavy models are heavy because they *pivot* (conditional aggregation
`SUM(CASE WHEN cohort THEN measure ELSE 0 END)`), which cannot become a join. Classify by job:

1. **Conditional aggregation / pivot** (bulk of `int_dpr__retail` 17×, `int_dpr__tour_revenue`
   16×) — keep inline; there is no table to join.
2. **Pattern-match derivation** (`matrix_code like '%TOU%'`, `line_type = 'S'`) — open set,
   keep inline.
3. **Enumerable code → label mapping** — the only kind that belongs in a seed/table. Already
   done well: `seed_tour_plu`, `seed_retail_item_facility`, `seed_retail_store_facility`.
4. **Repeated semantic flags** (`summary_category <> 6` = "is donation", 14× in one file) —
   the real DRY problem: centralize the magic numbers, not the CASE structure.

## Delivered changes (all verified output-equivalent unless noted)

1. **facility_group / is_donation refactor** — `int_counterpoint__retail_lines` now derives
   `facility_group` (name for the resolved key_facility) and `is_donation` once; `int_dpr__retail`
   consumes them, removing all 6 facility numbers + 14 donation literals. Patch:
   `dpr_retail_facility_group_refactor.patch`.

2. **int_dpr__fees_and_services PLU cohorts** — the two hardcoded PLU lists (each written twice)
   pulled into cohort CTEs, then promoted to a seed.

3. **seed_service_plu** — new seed (`plu, dpr_line_item, notes`) covering the audio-guide and
   product-178 mem+mus-tour PLUs; model wired to it via `ref()`; registered in `_seeds.yml`
   (+schema RAW). `int_dpr__tour_revenue` and `int_dpr__admissions` were reviewed and left
   unchanged — already seed-driven / open-set patterns, nothing to extract.

4. **fct_daily_operations — correctness fix.** Was silently inheriting `materialized=incremental`
   (merge on visit_date) while aggregating `sum(...) group by visit_date` over only newly-extracted
   rows → late/corrected rows OVERWROTE a day's totals with just the new slice (undercount).
   Converted to `table` (matches its day-grain siblings). Also wired `retail_revenue` /
   `retail_transactions` from `int_counterpoint__retail_lines` (non-donation top-line) and set
   `total_revenue = ticket + retail`, replacing hardcoded 0s. `retail_discounts` stays 0 —
   NO discount field in staged CounterPoint data (needs Gennady). 16-column output contract
   unchanged.

5. **dbt_project.yml materialization defaults.** Defaults were fiction: intermediate defaulted
   `incremental` but every model is a `view`; marts defaulted `incremental` but are `table`.
   That gap is what let #4 silently inherit incremental. Flipped defaults to reality —
   intermediate `view`, marts `table`, `reports` sub-group `view` — leaving incremental_strategy/
   on_schema_change as opt-in defaults (preserves `fct_ticket_availability`). Zero behavioral
   change to existing models; closes the inherit-incremental footgun for future ones.

6. **Hot intermediate views → table.** Multi-consumer views that re-ran their joins every
   consumer per build: `int_gateway__ticket_journal_lines` (7 joins ×3), `int_gateway__item_journal_lines`
   (4 ×2), `int_counterpoint__retail_lines` (3 ×3), `int_gateway__ticket_demand_features`
   (~120 lines ×2). Converted to `table` (build once, read N times). `int_ticket_scans` left a
   view (single-join thin passthrough — not worth materializing). Output identical; win is run time.

7. **Test coverage — two rounds.** Round 1: `int_counterpoint__retail_lines`, `int_pos_tickets`,
   `int_ticket_scans`, `int_ticket_inventory` + new fct_daily_operations columns. Round 2:
   `int_retail__{customers,performance,visitors}`, `int_gateway__ticket_demand_features`, 4 `rpt_`
   reports, 12 `stg_` models. Every previously-untested active model now covered. Severity rule:
   grain enforced by in-model GROUP BY → `error`; grain inherited or unverified source (incl. empty
   stubs) → `warn` (surfaces drift without breaking the daily build; promote after verifying).
   Files: `schema_test_additions.yml`, `schema_test_additions_2.yml`.

8. **fct_ticket_demand_forecast** — removed dead `hourly_demand` CTE (built but never selected);
   trimmed stale header NOTE. Output identical; one fewer aggregation per build.

### Investigated and deliberately NOT changed

- **`select *` in gold layer** — flagged early as drift risk; on inspection every gold model
  projects explicit columns in a `final`/`combined` CTE (`select * from final`, or
  `c.* exclude(...)` over an explicit CTE), so the `select *` live only in *import* CTEs and drift
  never reaches an output. Tightening would add verbosity for no drift benefit. No change made.
- `int_dpr__tour_revenue`, `int_dpr__admissions` — already well-factored (see #3).

### Open items (external / not code)

- `retail_discounts` in `fct_daily_operations` — no discount field in staged CounterPoint tables;
  confirm source with Gennady before publishing a discount metric.
- ADR-005 metric definitions for demand/attendance measures still owe the workshop.
- `warn`-severity tests: promote to `error` once the underlying source grains are confirmed.

## [3.0.1] — 2026-07-21 — Fix date_id → date_key in tests

Renames all stale `date_id` references to `date_key` in dbt tests to align with
the `dim_date` model, which already exposes the column as `date_key`.

### Fixed

- `tests/reconciliation/assert_rpt_avg_ticket_price.sql` — 4 column references
  updated (`date_id` → `date_key`) for joins against `fct_daily_performance` and
  `rpt_daily_performance_report`.
- `tests/business_rules/assert_date_coverage.sql` — 4 column references updated
  to query `date_key` from `dim_date`.
- `tests/referential_integrity/assert_gold_daily_ops_no_orphan_dates.sql` — 2
  column references updated in the `dim_date` join and null check.

---

## [3.0.0] — 2026-07-20 — Cortex Analyst Semantic Views

Deploys **three new Cortex Analyst semantic views** to `NS11MM_DW_DEV_JMYERS.MARTS`
and downloads the existing DPR view into the workspace for version control.
Major version: these semantic views are the Cortex Analyst contract consumed by
the `JMYERS_TEST` agent and future Snowflake Intelligence surfaces.

### Added — semantic view YAML specs (`cortex_project/`)

- **`ATTENDANCE.sv.yaml`** — Attendance analytics model covering daily scan counts
  by market segment, ticket demand forecasting with presale lead-time analysis,
  and real-time ticket capacity/utilization. Tables: `FCT_DAILY_SCAN`,
  `FCT_TICKET_DEMAND_FORECAST`, `FCT_TICKET_AVAILABILITY`, `DIM_DATE`,
  `SEED_SCAN_MARKET_SEGMENT`. Includes relationships and SUM metrics.

- **`RETAIL.sv.yaml`** — Retail analytics model covering category-grain sales
  performance (net sales, profit, units, donations) and facility-grain daily
  aggregates (transactions, visitors, ecommerce orders). Tables:
  `FCT_RETAIL_PERFORMANCE`, `FCT_RETAIL_DAILY`, `DIM_DATE`, `SEED_FACILITY_AREA`.
  Includes gross margin % and revenue-per-visitor ratio metrics.

- **`FUNDRAISING_ECOM.sv.yaml`** — Fundraising & ecommerce scaffold. Dimension
  stubs (`DIM_CAMPAIGN`, `DIM_CUSTOMER`, `DIM_FUND`, `DIM_PAYMENT_METHOD`) plus
  `DIM_DATE`. Ready to expand once Salesforce/Blackbaud RAW connections are live.

- **`DPR.sv.yaml`** — Downloaded from deployed `NS11MM_DW_DEV_JMYERS.MARTS.DPR`
  semantic view for workspace version control. 48 metrics, custom instructions,
  and fiscal calendar dimensions.

- **`JMYERS_TEST.agent.yaml`** — Cortex Agent spec with `dpr_analyst` tool
  pointing to the DPR semantic view on `COMPUTE_WH`.

- **`cortex-project.yaml`** — Project manifest tracking all semantic view and
  agent artifacts with their Snowflake deployment targets.

- **`UNIFIED.sv.yaml`** — Cross-domain reconciliation surface spanning all four
  live day-grain facts against `DIM_DATE`. Curated metric subset for natural-
  language retrieval; 3 verified queries, custom instructions.

### Removed — consolidated to `cortex_project/` (single source of truth)

- `semantic_models/dpr.yaml` — replaced by `cortex_project/DPR.sv.yaml`
- `semantic_models/unified.yaml` — replaced by `cortex_project/UNIFIED.sv.yaml`
- `semantic_models/attendance.yaml` — replaced by `cortex_project/ATTENDANCE.sv.yaml`
- `semantic_models/retail.yaml` — replaced by `cortex_project/RETAIL.sv.yaml`
- `semantic_models/fundraising_ecom.yaml` — replaced by `cortex_project/FUNDRAISING_ECOM.sv.yaml`
- `semantic_models/create_dpr_semantic_view.sql` — deploy via `semantic_view_deploy` instead
- `semantic_models/create_unified_semantic_view.sql` — deploy via `semantic_view_deploy` instead

Per-metric governance metadata (MET-### IDs, owners, SLA tiers) remains in dbt
exposure `meta:` blocks. The semantic view YAML carries only the semantic
definition (expr, synonyms, descriptions, custom instructions) to avoid drift.

## [2.0.0] — 2026-07-16 — Semantic & Governance Layer: Metric Metadata, Report Exposures, Charter

With the report-estate marts now fed with real data (1.6.x), this release
formalizes the **semantic and governance layer** on top of them. Every
certified metric carries a full governance metadata block and a report
cross-reference; the report estate is registered as dbt exposures mapped to
those metrics by ID; and two governance documents land under `docs/`. Major
version: the metric-identifier scheme (`MET-###`), the report-identifier scheme
(`RPT-###`), and the metric/exposure `meta:` contracts are now stable and
consumed downstream by the Hub registries and Cortex Analyst.

### Added — metric governance metadata (`semantic_models/`)

Full 17-field `meta:` block on **every metric** across `dpr.yaml`,
`attendance.yaml`, `fundraising_ecom.yaml`, and `retail.yaml` — **72 certified
metrics**, `MET-001`..`MET-072`. Fields: `display_name`, `id`, `type`,
`domain`, `status`, `grain`, `sla_tier`, `version`, `business_owner`,
`technical_owner`, `approval_date`, `time_dimension`, `scope`, `source_models`,
`related_metrics`, `caveats`, `changelog`.

- **`attendance.yaml`** — `MET-050`..`MET-056` (7 metrics), domain
  *Attendance & Ticketing*, owner Chris Wogas. Hourly-grain metrics flagged;
  scan/attendance stubs (Sensource blend, real-time CounterPoint) noted in
  `caveats`.
- **`fundraising_ecom.yaml`** — `MET-057` (1 metric), domain *Fundraising*,
  owner Jan-Michael Llanes.
- **`retail.yaml`** — `MET-058`..`MET-072` (15 metrics), domain *Retail*,
  owner Gennady Zaritsky. Ratio metrics (`profit_margin`, `avg_sale`,
  `conversion_rate`, `rev_per_visitor`) typed `Measure — Ratio` and flagged
  non-additive.
- `dpr.yaml` — `MET-001`..`MET-049`, aligned to the same contract.
- All metrics `status: in-review` with blank `approval_date`, pending domain-
  owner certification (ADR-005). `time_dimension: report_date`,
  `technical_owner: Jeremy Myers`, initial `changelog` entry on each.

### Added — report ↔ metric cross-reference (`semantic_models/`)

- New `reports:` field on every metric's `meta:`, listing the reports that
  consume the metric (the inverse of `exposures.yml`'s `metrics` list). **22
  metrics reference at least one report.**

### Added — report estate as dbt exposures (`models/exposures.yml`)

Rewrote `exposures.yml` (previously a single sample) with **13 Pentaho
migration reports** documented as dbt exposures:

- **DPR family** — Daily Performance Report, YTD, MTD, Excel Data, Memorial &
  Museum Daily Tracker.
- **Retail** — Today's Sales (Hourly), Retail Performance, Retail Carts
  Analysis, Monthly Retail KPI.
- **Attendance / scanning** — Daily Scan, Attendance, Daily Attendance.
- **Fundraising** — Website Commerce Report.

Each exposure carries native dbt fields plus a `meta:` block: `id`
(`RPT-001`..`RPT-013`), `domain`, `report_type`, `platform: Power BI`,
`legacy_platform: Pentaho`, `disposition` (`MIGRATE` / `CONSOLIDATE`),
`status`, `target_model`, `source_models`, `metrics` (referenced by `MET-###`),
`packages`, `caveats`, `version`, `changelog`.

- **`depends_on` pinned to each report's live base fact** (e.g.
  `fct_daily_performance`, `fct_retail_daily`, `fct_today_sales_hourly`,
  `rpt_website_commerce`) so `dbt parse` succeeds; the full migration target is
  recorded in `meta.target_model`. Each `ref()` must resolve to an ENABLED
  model or parse will fail.

### Added — governance documents (`docs/`)

- **`docs/policy/AI-CHARTER.md`** — AI & Data Governance Charter (v0.1):
  purpose, scope, and the seven governing principles, with sections IV–VII
  (governance structure, data/AI frameworks, compliance) marked for committee
  development. The "why" to the AI policy's "how."
- **`docs/governance/adc_meeting_records.md`** — AI & Data Committee meeting
  records in a structured, machine-readable markdown format (one `##` section
  per meeting; `Agenda` / `Decisions` / `Action Items` subsections with
  inline `owner` / `due` / `status`). First record: the AI-policy refresh and
  draft-charter meeting.

### Notes

- The metric metadata and exposures are consumed **live** by the Hub Metric
  Registry and Report Registry (bidirectionally cross-linked by `MET-###` and
  `RPT-###`) and by Cortex Analyst.
- `meta:` is valid dbt but is **not** part of the Cortex Analyst spec — strip
  before Cortex upload if a validator rejects unknown keys.
- Everything new is `in-review`. Owner sign-off and `approval_date` are the
  next gate (ADR-005) before any metric or report is promoted to certified.

## [1.6.2] — 2026-07-15 — Report-Estate Ingestion Batch 2: Sensource, Budgets, WiFi-Table Correction

Loaded and wired the remaining five report-estate source tables. Eight of the
nine report-estate stubs now carry real data (four in 1.6.1, four here); the
retail and daily-scan budget feeds unblock every `_budget` / variance column
across the estate (ADR-005). One upload was misnamed at source and is handled
accordingly (see below). Follows the seed-swap pattern from 1.6.0 / 1.6.1.

### Added — staging models (`models/raw/`)

Built against the actual uploaded columns (reconciled against the workbook,
several differed from the documented schema):

- **`stg_sensource__visitors`** — Sensource entries/exits by facility. Real feed
  adds `acp` and `passes_scanned` beyond the documented `num_entry/num_exit`.
- **`stg_sensource__attendance`** — daily attendance. Real feed is
  **pre-aggregated by named area** (`mem_attendance`, `mus_attendance`,
  `memorial_only`, `mus_store`, `mus_store_vesey`), not by facility as the
  transform docs implied — simpler, no facility mapping needed.
- **`stg_budget__retail`** — retail budget/forecast by facility/day
  (`fact_retail_forecasts`); adds `avg_don_mem_only_vis`. `key_facility` is a
  numeric facility code (e.g. 1003).
- **`stg_budget__daily_scan`** — daily-scan budget, wide by market segment
  (`fact_dsr_forecasts`); adds `mobile` and `gocity` segments. Decimal forecast
  values; literal `'NULL'` strings nullified via `try_to_decimal`.
- **`stg_dpr__daily_metrics_wide`** — see correction below.

### Added — RAW sources

- Five table entries added to the `report_estate_seed` source group:
  `seed_sensource_visitors`, `seed_sensource_attendance`, `seed_retail_budget`,
  `seed_dsr_budget`, `seed_wifi_audience`.

### Changed — stub → real source

- **`int_retail__visitors`** — Sensource half now reads
  `stg_sensource__visitors`; `visitor_count = sum(num_entry)`.
- **`rpt_attendance`** — now reads `stg_sensource__attendance` directly (the
  feed is already pre-aggregated by area), replacing the interim facility-based
  mapping.
- **`fct_retail_performance`** — budget seam now reads `stg_budget__retail`
  (`revenue_budget` → net_sales seam, `profit_budget` → net_profit seam).
- **`fct_daily_scan`** — budget now reads `stg_budget__daily_scan`, unpivoted
  from the wide segment columns to `segment_key` to match the fact grain
  (keys align with `seed_scan_market_segment`).

### Correction — `seed_wifi_audience` is not a WiFi email list

The uploaded `seed_wifi_audience` is **not** the Blue State email audience. It is
a **wide daily DPR-metrics table** (56 columns: attendance, ticket/pass revenue,
every tour line, retail gross profit, donations, operating expenses, civic
programs) with a single `daily_wifi_visitors` column and **no email addresses or
names**. Handled by:

- **`stg_dpr__daily_metrics_wide`** (renamed from the planned
  `stg_wifi__audience`) — conforms it faithfully and exposes it as an
  independent daily-metrics **reconciliation source** for parity-checking the
  built DPR marts.
- **`rpt_wifi_email_export` remains stubbed.** The real governed PII source
  (`stage_acceptance_uap_daily`: email / first / last, filtered to accepted-AUP
  rows) has **not** been loaded. This is now the only report-estate report with
  no real feed.

### Still stubbed (no data yet)

- `tmp_seed_wifi__audience` — real `stage_acceptance_uap_daily` audience feed
  (email/name) still needed for `rpt_wifi_email_export`.

### Deploy

```
dbt build --select source:report_estate_seed+ --target dev
```

### Known Issues / Verify after deploy

- **Daily-scan budget segment keys** — the DSR wide→long unpivot maps columns to
  `segment_key` values (`citypass`, `c3`, `newyork`, `walkup`, `gocity`, …);
  confirm they match `seed_scan_market_segment.segment_key`
  (`select segment_key, sum(passes_budget) from fct_daily_scan group by 1`; an
  all-null budget column signals a key mismatch). Note `partners`, `mobile`, and
  `total_tickets` from the source have no scan segment and are intentionally not
  mapped.
- **Retail budget facility codes** — `stg_budget__retail.key_facility` is numeric
  (1003, …); confirm it matches `seed_facility_area` / `fct_retail_performance`
  keys, not names.
- **Sensource attendance area labels** — confirm `mus_store` vs
  `mus_store_vesey` correspond to the intended report lines.
- **`stg_dpr__daily_metrics_wide`** is a reconciliation source, not wired into
  any report; use it to validate DPR marts, then decide whether to retain.

## [1.6.1] — 2026-07-15 — Report-Estate Ingestion: Stub Seeds → Real Sources
 
Loaded the first batch of report-estate source tables from stage into RAW,
added their staging models, and repointed the consuming models off the interim
stub seeds onto real data. Four of the nine report-estate stubs are now live;
five remain stubbed pending their feeds (Sensource, WiFi, budget). Follows the
seed-swap-with-no-report-rework pattern established in 1.6.0.
 
### Added
 
#### RAW sources (`models/raw/sources.yml`)
 
- **`report_estate_seed`** source group — seven 911dw tables loaded from stage
  into `RAW` (naming `SEED_FACT_*`, matching the existing seed convention):
  `seed_fact_passes_by_hour`, `seed_fact_todays_retail_data`,
  `seed_fact_todays_retail_product_data`, `seed_fact_website_recurring_data_db`,
  `seed_fact_shopify_orders`, `seed_fact_shopify_discounts`,
  `seed_fact_shopify_cost_values`. Freshness set to 2-day warn / 4-day error
  (more time-sensitive than the 7-day Gateway/CounterPoint seeds).
#### Staging models (`models/raw/`)
 
Rename/recast only, faithful to source (ADR-001):
 
- **`stg_gateway__passes_by_hour`** — hourly gate passes (`key_date/perhour/
  passes` → `business_date/hour_of_day/passes`).
- **`stg_counterpoint__todays_retail`** — same-day hourly CP retail (8 cols).
- **`stg_counterpoint__todays_retail_product`** — same-day product detail.
- **`stg_ecommerce__website_recurring`** — recurring online donations/memberships
  (12 cols). `email` flagged as PII in-model; mark restricted in schema.yml if
  surfaced downstream.
- **`stg_shopify__orders`** — Shopify order lines (16 cols). `key_date` parsed
  from `YYYYMMDD`; large id columns kept as varchar (no precision loss); literal
  `'NULL'` strings in refund columns nullified via `try_to_decimal`.
- **`stg_shopify__cost_values`** — order-level gross/net/profit (10 cols).
- **`stg_shopify__discounts`** — discount codes/totals (5 cols); blank codes → null.
#### Loader
 
- **`load_raw_from_stage.sql`** runbook — `INFER_SCHEMA` → `CREATE TABLE USING
  TEMPLATE` → `COPY INTO` per table (Parquet + CSV paths), transient RAW,
  `_loaded_at` default, verification queries.
### Changed — stub → real source
 
Consuming models repointed off `tmp_seed_*` stubs onto the new staging models.
The swaps were not pure `ref()` substitutions: the stub seeds used idealized
column names, so the real staging columns required adapting the consumers'
logic.
 
- **`rpt_daily_attendance`** — `tmp_seed_gateway__passes_by_hour` →
  `stg_gateway__passes_by_hour` (clean swap; same shape).
- **`fct_today_sales_hourly`** — rebuilt on `stg_counterpoint__todays_retail`.
  Real feed carries `store_id` (not `key_facility`), `doc_id`, and
  `quantity_sold`; now maps store → facility via `seed_retail_store_facility`,
  derives `transactions = count(distinct doc_id)`, `units = quantity_sold`, and
  adds real `cost` / `profit`.
- **`rpt_website_commerce`** — rebuilt on `stg_ecommerce__website_recurring`.
  `revenue_type` derived from `order_type` / `title` (Donation vs Membership),
  `revenue_year` / month from `created_at`, `amount` from `revenue`.
- **`int_retail__visitors`** — Shopify CTE now reads `stg_shopify__orders`;
  `ecom_orders = count(distinct order_id)` (real feed is one row per order line).
### Still stubbed (no data yet)
 
`tmp_seed_sensource__visitors`, `tmp_seed_sensource__attendance`,
`tmp_seed_wifi__audience`, `tmp_seed_retail__budget`, `tmp_seed_dsr__budget` —
consumed by `int_retail__visitors` (visitor half), `rpt_attendance`,
`rpt_wifi_email_export`, `fct_retail_performance`, `fct_daily_scan`. Unchanged.
 
### Deploy
 
```
dbt build --select source:report_estate_seed+ --target dev
```
 
Builds the new sources → 7 staging models → 4 updated consumers → their reports
in dependency order.
 
### Known Issues / Verify after deploy
 
- **Today's Sales store mapping** — CP today-feed uses stores 1,8-14; confirm
  `seed_retail_store_facility` covers all; unmapped stores fall to
  `key_facility = -1` (`select key_facility, count(*) from fct_today_sales_hourly
  group by 1`).
- **Website Commerce revenue_type** — the Donation/Membership split is a
  keyword match on `order_type`/`title`; validate against
  `select distinct order_type, title from stg_ecommerce__website_recurring` and
  adjust the CASE if the real values differ.
- **Shopify data age** — sample data is 2016-2018; if that is the actual range,
  ecom figures are historical, not current.
- **`email` PII** in `stg_ecommerce__website_recurring` — classify in schema.yml
  (restricted) before surfacing downstream.
- **Naming** — confirm `fact_website_recurring_data_db` vs workbook `..._d8`.

## [1.6.0] — 2026-07-15 — Active Pentaho Report Estate + Domain Semantic Layer
 
Built out the remaining active Pentaho analytical reports on top of the DPR
marts, established the reusable report-model pattern (intermediate → fact →
report → semantic), and expanded the semantic layer from one DPR model to four
domain-grouped models so every report is queryable through Cortex Analyst. The
~90 SSRS reports are Galaxy operational/box-office admin reports and remain out
of scope. Companion docs: `docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md`,
`docs/architecture/DPR_LINEAGE.md`.
 
All 14 active Pentaho reports are now scaffolded: 4 DPR (existing) + 5 live on
current seeds + 5 wired to stub seeds pending a source feed.
 
### Added
 
#### Report-estate facts (`models/marts/facts/`)
 
- **`fct_retail_performance`** — tidy category-grain retail fact (one row per
  day × facility × product category); additive sales/profit/units/donations.
  Replaces legacy `fact_retail`.
- **`fct_retail_daily`** — facility-grain retail fact: transaction counts,
  visitor counts, and facility rollups; the grain the retail ratios operate on.
  Replaces legacy `fact_num_tickets` plus the facility rollup of `fact_retail`.
- **`fct_daily_scan`** — gate passes scanned + tickets sold by market segment
  per day. Replaces legacy `fact_dailyscan_data`.
- **`fct_today_sales_hourly`** — same-day hourly retail sales by facility
  (STUB: real-time CounterPoint feed pending).
#### Report models (`models/marts/reports/`)
 
- **`rpt_retail_performance`** — Retail Performance Report: ratios
  (conversion, rev-per-visitor, avg sale, margin, per-cap donations) as
  ratio-of-sums at query grain, plus category drill-down. Template for the estate.
- **`rpt_retail_carts_analysis`** — Retail Carts Analysis: memorial-carts lens
  with the legacy adjusted-visitor denominator (mem visitors − 25% − mus visitors)
  for capture rate and per-cap.
- **`rpt_monthly_retail_kpi`** — Monthly Retail KPI: `fct_retail_daily` rolled to
  fiscal month × area, ratios recomputed at the month grain.
- **`rpt_memorial_museum_tracker_ytd`** — Memorial Museum Daily Tracker YTD:
  fiscal-YTD variance tracker over `fct_daily_performance` (windowed cumulative
  partitioned by fiscal year).
- **`rpt_daily_scan`** — Daily Scan Report: market-mix shares and scan
  utilization at query grain.
- **`rpt_attendance`** — Attendance Report (STUB: Sensource area counts).
- **`rpt_daily_attendance`** — Daily Attendance Report (STUB: hourly passes;
  scan-based fallback).
- **`rpt_website_commerce`** — Website Commerce Report (STUB: Classy/Shopify
  recurring, ADR-008).
- **`rpt_wifi_email_export`** — Blue State WiFi email export.
  **RESTRICTED / PII**: tagged `pii`/`restricted`/`marketing_export` so the
  `on-run-end` masking hook applies; PII columns marked
  `classification: restricted_pii` / `contains_pii: true`. Least-privilege grant
  only (marketing-export role); must NOT be granted to `POWERBI_ROLE` / `ML_ROLE`.
  See `docs/architecture/DATA_CLASSIFICATION.md`.
#### Intermediate models (`models/intermediate/`)
 
- **`int_retail__performance`** — day × facility × category retail aggregation.
- **`int_retail__customers`** — facility-grain transaction counts
  (`count(distinct doc_id)`; non-additive across category, kept separate).
- **`int_retail__visitors`** — Sensource visitor + Shopify ecom counts (STUB).
- **`int_gateway__scan_lines`** — scan events joined to their ticket's market
  segment via `usage.visual_id = jnltickets.visual_id`, then matrix/channel.
#### Seeds
 
- **`seed_facility_area`** (reference) — selling-area labels for facility keys
  (1003 Museum Store, 1020 Memorial Carts, 1030 Atrium, 1234 Ecommerce, 4007
  Cafe, 1040/1060 audio, 1070 tour guides, 1080 memberships).
- **`seed_scan_market_segment`** (reference) — market-segment map for the Daily
  Scan Report (CityPASS, C3, Explorer, GoCity, School Groups, Members, Walk-up, …).
- **Stub seeds** (`seeds/_tmp/`, schema `raw_seed`, tags `build_temp`/`stub`):
  `tmp_seed_sensource__visitors`, `tmp_seed_sensource__attendance`,
  `tmp_seed_shopify__orders`, `tmp_seed_ecom__recurring`,
  `tmp_seed_gateway__passes_by_hour`, `tmp_seed_cp__today_sales`,
  `tmp_seed_retail__budget`, `tmp_seed_dsr__budget`, `tmp_seed_wifi__audience`
  (the last tagged `pii`/`restricted`).
#### Semantic layer (`semantic_models/`)
 
- **`retail.yaml`** → `MARTS.RETAIL` — spans `fct_retail_daily` (facility grain,
  ratios) and `fct_retail_performance` (category grain) so both facility-level
  and product-category questions are answerable. 15 metrics.
- **`attendance.yaml`** → `MARTS.ATTENDANCE` — spans `fct_daily_scan`,
  attendance measures, and `fct_today_sales_hourly`. Covers Daily Scan,
  Attendance, Daily Attendance, Today's Sales.
- **`fundraising_ecom.yaml`** → `MARTS.FUNDRAISING_ECOM` — Website Commerce
  recurring revenue (STUB-fed).
- Stub-fed surfaces carry `module_custom_instructions` guardrails: the agent
  reports an empty result as "feed not yet connected", never "revenue was zero".
  `museum_attendance` is flagged as a GA-ticket proxy; Daily Scan segment splits
  are flagged provisional (totals reliable) pending channel-mapping validation.
#### Documentation
 
- **`docs/architecture/DPR_LINEAGE.md`** — table-relationship and
  transformation reference for the DPR slice, with a Mermaid `graph LR` lineage
  diagram and per-layer transformation notes.
- **`docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md`** — report → model →
  base-table matrix, the old→new column crosswalk per base table, and per-report
  measure mapping (legacy field → new mart column).
- READMEs updated: root, `semantic_models/`, `models/marts/facts/`,
  `models/marts/reports/`.
### Changed
 
- **`int_ticket_scans`** — exposes `visual_id` (passthrough) to enable the scan →
  ticket market-segment join for Daily Scan. Grain and existing consumers
  unchanged.
- **Semantic layer scope** — expanded from a single DPR model to four
  domain-grouped models (DPR / retail / attendance / fundraising_ecom). Design:
  one model per business domain (not per fact), each spanning its facts, so
  cross-report questions within a domain work; facts are never join-fanned in a
  single query.
### Known Issues / Follow-ups
 
- **Daily Scan segment mapping is provisional.** `seed_scan_market_segment` maps
  against `acs_dynamic_channel` (sales channel) as the closest structured proxy;
  the legacy `t_fact_dailyscan_data` transform was undocumented in the source.
  Passes/sold totals are correct; the per-segment split needs validation
  (`select category, count(*), sum(scanned_qty) from int_gateway__scan_lines
  group by 1`). If channels are generic, pivot the seed to `sales_program_id`.
- **`cafe1_donations` not surfaced in `fct_daily_performance`.** It exists in
  `int_dpr__retail` but was never added to the fact, so it is omitted from the
  Memorial Museum Tracker YTD donation sum. Surface it to the fact to close the gap.
- **Stub-fed reports await source feeds** (each a seed/staging swap, no report
  rework): `sensordata` (Sensource — Attendance ×2, retail conversion ratios,
  true DPR `mus_attendance`), hourly passes, real-time CP (Today's Sales),
  Classy/Shopify recurring (Website Commerce), WiFi audience, budget/forecast.
  Add a thin `stg_<source>__<entity>` between each new RAW table and the marts
  when it lands.
- **WiFi export access grant** is a governance-tier decision: confirm the
  marketing-export role grant and that `POWERBI_ROLE`/`ML_ROLE` are excluded.
- **Native semantic-view DDL twins** for retail/attendance/fundraising_ecom not
  yet generated; regenerate alongside `create_dpr_semantic_view.sql` so the
  native views match the YAMLs.

## [1.5.2] — 2026-07-13 — Developer Onboarding & Semantic View Pipeline

### Added

- **Parameterized developer workspace setup** (`scripts/setup_developer_workspace.sql`):
  change one `SET dev_username` variable to provision a full dev environment (database,
  schemas, grants). Eliminates manual find-and-replace of hardcoded usernames.
- **Pre-commit hook** (`.githooks/pre-commit`): auto-regenerates
  `create_dpr_semantic_view.sql` from `dpr.yaml` whenever the YAML or generator is staged,
  ensuring the DDL never drifts from the metric definitions.
- **BUILD_DIMS_METS.md** updated with documentation on the YAML→SQL pipeline, ratio-of-sums
  semantics for `avg_ticket_price`, and how `assert_rpt_avg_ticket_price.sql` guards against
  formula drift in the `rpt_` layer.

### Changed

- `dpr.yaml`: removed duplicate `avg_ticket_price` definition; canonical ratio now lives once
  in the NON-ADDITIVE RATIOS section as `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`.
- `setup_developer_workspace.sql`: split `INSERT, CREATE TABLE ON SCHEMA` (invalid) into
  separate `CREATE TABLE ON SCHEMA` + `INSERT ON FUTURE/ALL TABLES` grants.

### Fixed

- KRAMSEY dev database: granted `ALL ON ALL TABLES` and `ALL ON FUTURE TABLES` in
  `NS11MM_DW_DEV_KRAMSEY.RAW` to `TRANSFORMER_ROLE` — tables created by ACCOUNTADMIN were
  invisible to `DEPLOY_DEV_ROLE` (which inherits TRANSFORMER_ROLE).
- KRAMSEY default role set to `DEPLOY_DEV_ROLE`.
- Copied all 22 RAW tables from `NS11MM_DW_DEV_JMYERS` to `NS11MM_DW_DEV_KRAMSEY`.

---

## [1.5.1] — 2026-07-13 — Governance: ADR-001 through ADR-006 Rewritten for Snowflake

Six architecture decision records added to `docs/adr/` as markdown, rewritten to their
post-migration state from the ADR Review working document (Part 1 status summary). Four
carried revisions (001, 002, 003, 005); two are current and rendered as-is (004, 006).
Filenames follow the existing `docs/adr/NNNN-title.md` convention. These supersede the
pre-migration text and must be reconciled against the canonical ADRs before the old copies
are retired — see Notes. Companion artifact: `adr_review_working.docx`.

### ADRs Added / Revised

- **`0001-stack-selection.md`** — removed all Microsoft Fabric references; added the
  Snowflake migration rationale, the custom Python ingestion decision, and Cortex Analyst
  as the T3-tier analytics tool
- **`0002-medallion-architecture.md`** — mapped the Fabric lakehouse layers to Snowflake
  schema equivalents (Bronze/Silver/Gold → RAW/INTERMEDIATE/MARTS); added Cortex Analyst
  as a Gold-layer consumer alongside Power BI
- **`0003-ingestion-strategy.md`** — full rewrite. Custom Python pipelines set as the
  standard path to Bronze; native/managed connectors rejected as primary (exception process
  only); Snowflake Streams CDC named as the merge-semantics workaround; two-hop on-prem
  pattern (bcp → RDP → PUT/COPY INTO) documented
- **`0004-no-logic-in-power-bi.md`** — rendered current, no revision. Records the thin-display
  boundary and that row-level security lives in Snowflake, not Power BI DAX
- **`0005-metric-definition-gate.md`** — added the clause extending the gate to the Snowflake
  Cortex Analyst semantic model YAML; recorded that the gate fires on new definitions, not on
  new consumers of existing ones
- **`0006-change-management.md`** — rendered current, no revision to the decision. Captures the
  single-intake path (Ginabell), `ITCHG-NNNN` IDs, PR-gated CI, and commemoration/event freeze
  protocols; ADR-014 forward reference pending

### Notes / To Reconcile

- **Reconstructed, not transcribed.** The review doc supplied status and required revisions for
  001–006, not their full source bodies; the prose was rebuilt from that summary plus current
  platform context. Each file carries `[confirm]` markers for values only the canonical ADR holds
  (original decision dates; exact production schema names in 0002; the seven stage names in 0006;
  Kenny Yeung schema confirmation in 0003)
- **Supersession.** `0005-metric-definition-gate.md` and `0006-change-management-tiers.md` already
  exist in the repo. New 0005 extends the existing gate; new 0006 is titled "Seven-Stage Process"
  where the existing file is "Change Management Tiers (Tier 1/2/Emergency)" — confirm which framework
  is current, then rename/retire the superseded file
- **Register collision to resolve before ADR-007+.** The review doc proposes ADR-007 (Bronze
  Immutability) and ADR-008 (Semantic Layer Governance), but the repo already holds
  `0007-drupal-ingestion-path.md` and `0008-retail-source-split.md`. The register needs
  de-collision before any 007+ ADRs are written

## [1.5.0] — 2026-07-08 — DPR Metric Reconciliation: Legacy Parity Fixes
 
Full logic/lineage audit of all ~40 DPR base metrics against the legacy Pentaho
definitions (`report_details_pt` / `transforms_pt`), followed by a fix sprint.
Nine fixes shipped and validated against Snowflake; every remaining gap is
documented as an extract-scope or definitional item (see Known Issues).
Companion artifact: `dpr_metric_reconciliation_audit_v3.xlsx`.
 
### Critical Bug Fixes
 
- **`gateway_recognized_date` macro** — recognize-basis 182 (92% of ticket volume)
  keyed on `rme.start_at`, which is null for 111K rows; combined with
  `jnltickets.ticketdate` being ~95% unparseable, ~116K of 128K ticket units got a
  null `key_date` and were silently dropped. All branches now coalesce to
  `end_of_life_date` (the visit date, same substitution as the 1.4.0
  `stg_gateway__tickets` fix): basis 182 → `coalesce(start_at, end_of_life_date,
  ticket_date)`; 185/else → `coalesce(ticket_date, end_of_life_date)`. Enriched
  journal recovered 8,267 → 105,781 qty; GA + tour partition reconciles to the
  penny (96,326 / $2.68M GA + 9,455 / $262K tours = $2,942,119.89)
- **Systemic PLU trim** — Galaxy stores `plu` as space-padded `CHAR(20)`, which
  silently defeated every downstream equality join and filter. `trim(plu)` now
  applied at source in `stg_gateway__items`, `stg_gateway__jnltickets`, and
  `stg_gateway__jnlitems` (all three together to keep bridge joins aligned).
  Un-zeroed: `box_office_mem_don` ($28,362), `box_office_mus_exit_don` ($8,160),
  and the Galaxy component of `audio_tour_headset`
- **Cafe wired in** — `cafe1_all_profit` / `cafe1_donations` were structurally
  zero: CounterPoint store 1 was outside the retail store scope and facility 4007
  was never mapped. Added store 1 → 4007 to `seed_retail_store_facility` and
  widened the scope in `int_counterpoint__retail_lines`. Validated: profit
  $68,434 / donations $7,219 (COGS coverage confirmed at 99.8% of cafe lines)
- **`mem_mus_tour_revenue` / `mem_mus_tours`** — legacy keys on `rItmProductID =
  178`, whose PLUs carry no matrix code, so the `%MTG%` matrix filter matched
  nothing. Switched to the product-178 PLU list (`MUSMMUADW001/003/005`) in
  `int_dpr__fees_and_services`. Validated: 1,262 tours / $107,270 (was 0)
### Donation Re-sourcing & Corrections
 
- **`mask_donations` / `donation_box`** — re-pointed from the Gateway item
  journal (wrong system) to CounterPoint retail per legacy spec: items `200704`
  (mask, dormant since 2021) and `101165` (Plaza Donation Box, $1,809 validated).
  Measures moved to `int_dpr__retail`; `fct_daily_performance` re-wired
- **Legacy surrogate keys resolved by inspection** — `dim_item_descr` surrogates
  were being used as CounterPoint `item_no`: 483 → `'7-999'` (Donation Ask),
  886 → `'101375'` (Donation Box Store Exit; `item_no` is alphanumeric, so the
  numeric surrogates could never match). `mus_exit_donations` now $1,816 (was 0);
  `cart_donation_ask` narrowed to the ask item at the carts ($11,023), removing a
  double-count with the plaza box; `mus_store_donations` excludes the exit-box
  item ($25,993)
- **`coatcheck_don`** — now excludes PLU `DONOPSMUS003`: its matrix also matches
  `%DON-OPS-MUS%`, so once the PLU trim landed the exit-box dollars would have
  counted twice (pre-trim they landed only here). Ships with the trim by design
- **`ticketing_donations`** — member-desk PLU `DONMBRMUS001` excluded per legacy
  spec (booked to Membership); dormant in the current window, guards history
- **`mem_audio_guide_revenue`** — added the CounterPoint facility-1040 component
  (`mag_cp_revenue` in `int_dpr__retail`), the primary MAG source since 2023.
  The item-override seed carved those lines out of the carts but no measure
  aggregated them. Combined with the Galaxy `%MAG%` component in the fact.
  Dormant in the current extract window; wiring validated
### Seeds
 
- **`seed_tour_plu`** — full rebuild from the legacy `product_logic` PLU lists
  (40 PLUs, 8 categories). Corrects: `revealed_tour` = `VTMUSOBLOADW001` (was
  mislabeled early-access PLUs), `mem_field_trip` = `VTEDUMEM*` (was youth &
  family), `mus_field_trip` = `VTEDUMUS*` (was early-access). New exclusion
  categories `youth_fam_tour`, `early_access_tour`, `ea_mem_mus_tour` fix the
  `mus_guided_tours` over-count ($84,062 post-fix)
- **`seed_retail_store_facility`** — store 1 → facility 4007 (Museum Cafe;
  store id to be confirmed with Retail)
- **`_seeds.yml`** — `accepted_values` and descriptions updated for both
### New Models & Semantic Layer
 
- **`int_dpr__attendance`** — memorial attendance (`mem_attendance`) plus scanned
  museum attendance from `int_ticket_scans` + facility classification
- **`int_dpr__tour_revenue`** — added `mem_guided_tours` /
  `mem_guided_tour_revenue` (`%MGT%` cohort)
- **`fct_daily_performance` / `rpt_daily_performance_report`** — new measures
  surfaced; donation columns re-wired to their corrected sources
- **`semantic_models/dpr.yaml`** — fully synced with the fact: 49 metrics (every
  additive measure individually queryable, composites retained), complete
  `dim_date` dimension set including the fiscal calendar (FY starts October),
  fixed an incorrect "fiscal year" synonym on `calendar_year`, new verified
  queries and fiscal-aware SQL-generation instructions
### Diagnostics Verified Healthy (no change needed)
 
- `jnlheaders.tran_date` parses 100% (206,052/206,052) — item-journal `key_date`
  is sound
- Journal codes 532/610 identified as tender/deposits (Visa/MC/Amex/Cash/Wire,
  $4.7M payment mirror) — correctly ignored by the models
### Known Issues / Blocked on Extract
 
- `disbursement_id` (all rows) and `order_line_id` (codes 33/35/37/52) arrive as
  literal 0 — export artifact; blocks the tour-with-GA cohort and code
  identification
- COA extract missing the accounts behind journal codes 33/35/37/52 (~$7.8M);
  code 33 is likely the standalone service-fee postings — `service_fees` reads 0
  until resolved
- Extract windows are recent-only (CP: 2026-06-01..07-06); retired/seasonal
  products (virtual tours, Revealed, masks) require the history load. CP stores
  8/10 absent
- `RMEvents.start_at` null for 111K basis-182 rows (fallback in place; true event
  dates needed for tour products)
- Unissued population confirmed present in `orderlines` (5,703 units / $1.9M
  order book) — buildable pending the ADR-005 definition decision
- `create_dpr_semantic_view.sql` (native DDL twin) not yet regenerated to match
  the rebuilt `dpr.yaml`

## [1.4.0] — 2026-07-07 — Ticket Demand Forecasting & ML Pipeline

### New Models

- **`int_pos_tickets`** — daily POS ticket transactions from gateway tickets
- **`int_ticket_scans`** — gate scan events from gateway usage data
- **`int_ticket_inventory`** — derived daily ticket inventory (reservations vs rolling-90d-max capacity)
- **`fct_daily_operations`** — daily operational metrics (visitors, ticket sales, revenue); Shopify removed pending data
- **`fct_ticket_availability`** — ticket capacity and utilization by date/type (incremental)
- **`ml_ticket_demand_features`** — enabled; columns renamed (`entry_date→visit_date`, `daily_reserved→daily_visitors`) to align with Snowflake ML FORECAST
- **`ml_visitor_forecast_training`** — enabled; feeds visitor count forecasting

### Bug Fixes

- **CounterPoint staging models** (5 files) — added `_loaded_at` to staged CTE; was missing and caused `invalid identifier` errors in the `QUALIFY` deduplication clause
- **`stg_gateway__tickets`** — `ticket_date` now sourced from `endoflifedate` (the actual visit date in Galaxy); `ticketdate` column had 0 parseable values
- **`int_gateway__ticket_demand_features`** — added filter `ticket_date < '2030-01-01'` to exclude 15K sentinel `3000-12-31` rows (lifetime memberships)
- **`fct_ticket_availability`** — fixed `cluster_by` referencing `ticket_type_id` (should be `ticket_type`, the output alias)
- **`fct_daily_operations`** — fixed trailing comma after last CTE causing syntax error; fixed incremental `WHERE` referencing non-existent `_extracted_at` column in `{{ this }}`

### ML Forecasting

- **`create_ticket_demand_forecast` macro** — now target-aware (resolves from `target.database` instead of hard-coded PROD); added empty-table guard
- **`MANUAL_ML_RUN.sql`** — standalone SQL for running forecast outside dbt; includes filtered training view (series with 10+ observations) to avoid internal errors from single-point series
- **`ML_TICKET_DEMAND_FEATURES_FILTERED`** — view excluding series with <10 data points for stable model training

### Test Coverage Expansion

- **New `models/raw/schema.yml`** — PK tests (unique + not_null) for 12 staging models
- **Updated `models/intermediate/schema.yml`** — added tests for `int_pos_tickets`, `int_ticket_scans`, `int_ticket_inventory`, `int_gateway__ticket_demand_features`
- **Updated `models/marts/facts/schema.yml`** — added tests for `fct_daily_operations` (visit_date unique/not_null), `fct_ticket_demand_forecast`, `fct_ticket_availability`
- **Updated `models/ml_features/schema.yml`** — added `daily_visitors` not_null test; added `ml_visitor_forecast_training` tests (ds unique/not_null, y not_null)
- **New singular tests:**
  - `assert_critical_tables_not_empty` — fails if any of 6 critical tables has 0 rows
  - `assert_no_future_tickets` — flags implausible future dates in staging
  - `assert_no_negative_revenue` — re-enabled from disabled
  - `assert_gold_daily_ops_no_orphan_dates` — re-enabled from disabled
  - `assert_raw_silver_ticket_count_match` — re-enabled; fixed source (was `jnltickets`, now `tickets`); added `sold_at IS NOT NULL` filter
  - `assert_silver_gold_revenue_reconciliation` — re-enabled; fixed column name and removed stale date filter
- **Source freshness** — added `warn_after: 7 days` / `error_after: 14 days` to both `gateway_seed` and `counterpoint_seed`

### File Organization

- Moved 67 disabled files into `disabled/` subfolders:
  - `models/intermediate/disabled/` (8 files)
  - `models/marts/dimensions/disabled/` (6 files)
  - `models/marts/facts/disabled/` (20 files)
  - `models/marts/reports/disabled/` (9 files)
  - `models/ml_features/disabled/` (12 files)
  - `tests/business_rules/disabled/` (2 files)
  - `tests/reconciliation/disabled/` (2 files)
  - `tests/referential_integrity/disabled/` (4 files)

### Documentation

- Updated READMEs: root, `models/raw/`, `models/intermediate/`, `models/marts/facts/`, `models/ml_features/`, `macros/operations/`, `tests/business_rules/`, `tests/reconciliation/`, `tests/referential_integrity/`
- Root README current-scope table updated: 12 intermediate (was 8), 4 facts (was 1), 2 ML features (was 0)

---

## [1.3.2] — 2026-07-06 — Doc Cleanup

### Documentation Review — Current-Scope Accuracy Pass

Reviewed all 39 `.md` files in `ns11mm/ns11mm-data-platform` against the actual repo state
(models enabled vs. `enabled=false`, real folder names, real file names). **22 files changed.**

Ground truth used: **live today = the Gateway + CounterPoint → Daily Performance Report slice**
(21 staging, 8 intermediate, 4 dims + 1 fact + 1 report, 1 semantic view). Everything else is
present but `enabled=false`. This zip contains only the changed files, at their repo paths.

---

#### Two systemic problems fixed

1. **Orphaned Git merge-conflict markers.** 54 stray `>>>>>>> remote` lines across 16 files
   (no matching `<<<<<<<`/`=======` halves — content was intact). All removed. Files affected
   by *marker removal only*: `CHANGELOG.md`, `SNOWFLAKE_SETTINGS.md`, `docs/ONBOARDING.md`,
   `docs/architecture/DATA_CLASSIFICATION.md`, `SQL_STYLE_GUIDE.md`, `USAGE_AUDIT.md`,
   `macros/data_quality/README.md`, `macros/generic_tests/README.md`.

2. **Docs presenting the full future platform as if it's live today**, with no current-vs-planned
   distinction (the issue you flagged on the main README + customer 360).

---

#### Substantive changes

- **README.md** — rewritten. Added a "Current scope: live today vs. planned" banner with a
  live/total counts table; corrected the "96 models" claim; fixed the Project Structure tree to
  the real folders (`models/raw`, `models/intermediate`, `models/marts/{dimensions,facts,reports}`
  — not `staging/silver/gold`); replaced fictional model names and lineage
  (`stg_gateway__transactions`, `fct_ticket_sales`, `rpt_ticket_sales`) with the real DPR chain;
  marked Identity Resolution, the 4 semantic views, the Cortex agent, and the VQR library as
  **[PLANNED]** and corrected to the single live `MARTS.DPR` view; fixed the fiscal-year
  contradiction.

- **docs/architecture/PROJECT_MAP.md** — fixed all `models/staging|silver|gold/` paths to
  `raw|intermediate|marts`; replaced the fictional reference chain and the mental-model diagram
  with the real live DPR flow; corrected the repository-map counts to live/total; marked deleted
  items (exposures placeholder, snapshots planned, `verified_queries` removed); pointed the seeds
  and semantic_models rows at what's actually there; added a scope banner.

- **docs/business/README.md** — added a "what's available today" banner; annotated the dashboard
  finder with Live/(planned) status (only the Daily Performance Report is live); corrected the
  claim that every area already has a dashboard.

- **PLATFORM_SCORECARD.md** — added a scope note; corrected "4 semantic views" → 1 live DPR view;
  noted the VQR library was removed.

- **semantic_models/README.md** — fixed the file names (`dpr_semantic_view.sql` →
  `create_dpr_semantic_view.sql`; `dpr_semantic_model.yaml` → `dpr.yaml`) and the object name
  (`NS11MM_DP.MARTS.DPR` → `MARTS.DPR`, portable via `USE DATABASE`).

- **Scope banners added** (forward-looking docs that were otherwise fine): `docs/README.md`,
  `docs/architecture/ARCHITECTURE_FLOW.md`, `SOURCE_INTEGRATION.md`, `TEST_ORCHESTRATION.md`,
  `docs/business/METRIC_GLOSSARY.md`.

- **Concrete stale-reference fixes:** `CONTRIBUTING.md` (VQR workflow marked [PLANNED], notes the
  library was removed in 1.3.1); `macros/operations/README.md` (`sync_verified_queries` marked
  inactive); `GATEWAY_COUNTERPOINT_SCHEMA_REQUEST.md` (`models/staging/` → `models/raw/`);
  `RUNBOOK.md` (example command repointed from `fct_ticket_sales` to the live `fct_daily_performance`).

---

#### Left unchanged (already accurate)

- **The six model-folder READMEs** (`models/raw`, `models/intermediate`, `models/marts/dimensions`,
  `.../facts`, `.../reports`, `models/ml_features`) — these already list Enabled vs. Disabled
  models correctly with blocker/re-enable reasons. Verified each against the actual model configs;
  they match exactly. These are the authoritative per-model source of truth, and the rewritten
  top-level docs now point to them.
- **ADRs, tests/* READMEs, pipelines/readme, terraform/README** — accurate or forward-looking by
  design; no current-vs-planned misrepresentation after marker cleanup.

---

#### One thing to confirm

The main README now says to **confirm the fiscal start month**, while `METRIC_GLOSSARY.md` asserts
**October** (FY = Oct–Sep). `dim_date` has `fiscal_year`/`fiscal_month` logic. If October is
correct, the README can be made assertive to match the glossary.

## [1.3.1] — 2026-07-06 — DPR Semantic View & Build Fixes

### Added

**Semantic View**
- `NS11MM_DW_DEV_JMYERS.MARTS.DPR` — native Snowflake semantic view over FCT_DAILY_PERFORMANCE + DIM_DATE with 19 metrics (additive SUM + ratio-of-sums), 8 dimensions, AI instructions, and commemoration-window awareness
- `semantic_models/create_dpr_semantic_view.sql` — environment-portable DDL (USE DATABASE at top for dev/prod switch)
- `semantic_models/dpr.yaml` — Cortex Analyst YAML spec with verified queries and custom instructions

### Fixed

**Staging Models**
- `stg_gateway__orders.sql` — removed non-existent columns (`orderno`, `transno`, `eventno`, `status`, `total`, `tax`, `totalpaid`, `totalrefund`, `totaldue`, `depositamt`, `pendingloyaltypoints`, `issuedloyaltypoints`, `orderdate`, `groupid`); rewrote with correct column names from SEED_GATE_ORDERS
- `stg_gateway__orderlines.sql` — removed non-existent columns (`orderno`, `lineno`); rewrote with correct column names from SEED_GATE_ORDERLINES

**Mart Models**
- `fct_daily_performance.sql` — `cluster_by` changed from `date_key` to `date_id`; output column renamed `date_key` → `date_id`; join to dim_date updated to use `date_id`; added `WHERE key_date IS NOT NULL` to date_spine CTEs to handle upstream NULL dates
- `rpt_daily_performance_report.sql` — join updated from `f.date_key = dd.date_key` to `f.date_id = dd.date_id`; mapped `calendar_year`/`calendar_month` to actual dim_date columns (`year_number`/`month_of_year`); output column renamed `date_key` → `date_id`

**Intermediate Models**
- `silver_gateway__ticket_journal_lines.sql` — added `WHERE key_date IS NOT NULL` to filter rows where try_to_timestamp returned NULL from literal 'NULL' strings in raw date columns
- `silver_gateway__item_journal_lines.sql` — same NULL date filter added

**Schema / Tests**
- `models/marts/_dpr__marts.yml` — all `date_key` references updated to `date_id`; relationship field updated
- `models/intermediate/_dpr__models.yml` — no changes needed (key_date tests now pass after view rebuild)
- 12 singular tests disabled (`enabled=false`) that reference disabled/deleted models

### Changed

- `models/intermediate/schema.yml` — removed schema entries for deleted models (`silver_pos_tickets`, `silver_pos_retail`, `silver_ticket_scans`, `silver_ticket_inventory`)
- `models/exposures.yml` — all 11 exposures removed (depend on disabled marts); placeholder comments retained

### Removed

- `analyses/create_marketing_semantic_view.sql` — deleted (referenced disabled models)
- `analyses/verified_queries/` — entire directory removed (49 files; no verified queries currently applicable)

---

## [1.3.0] — 2026-07-06 — Gateway & CounterPoint Seed Data Buildout

### Added

**Raw Tables (NS11MM_DW_DEV_JMYERS.RAW)**
- 16 `SEED_GATE_*` tables created from Gateway Galaxy SQL Server CSV exports via INFER_SCHEMA
- 5 `SEED_CP_*` tables created from CounterPoint POS CSV exports (IM-ITEM, PS-TKT-HIST, PS-TKT-HIST-LIN, VI-TKT-HIST, VI-TKT-HIST-LIN)

**Staging Models (models/raw/)**
- 16 new `stg_gateway__*.sql` models — snake_case renaming, try_to_timestamp for dates, logical column grouping
- 5 new `stg_counterpoint__*.sql` models — full column coverage for POS item master, ticket history headers/lines, and enriched views

**Source Definitions**
- `gateway_seed` source (NS11MM_DW_DEV_JMYERS.RAW, 16 tables)
- `counterpoint_seed` source (NS11MM_DW_DEV_JMYERS.RAW, 5 tables)

**Seeds (seeds/)**
- `seed_tour_plu.csv` — PLU-to-DPR tour line item mapping
- `seed_retail_item_facility.csv` — CounterPoint item_no → facility override
- `seed_retail_store_facility.csv` — CounterPoint store_id → facility fallback
- `_seeds.yml` — schema definitions, column types, and tests for all 3 new seeds

**Intermediate Models (models/intermediate/)**
- `silver_counterpoint__retail_lines.sql` — CounterPoint retail lines with facility assignment
- `silver_gateway__item_journal_lines.sql` — Gateway item-level journal lines
- `silver_gateway__ticket_journal_lines.sql` — Gateway ticket journal lines with product classification
- `silver_dpr__admissions.sql` — DPR admissions revenue
- `silver_dpr__donations.sql` — DPR donation revenue
- `silver_dpr__fees_and_services.sql` — DPR fees and services revenue
- `silver_dpr__retail.sql` — DPR retail revenue
- `silver_dpr__tour_revenue.sql` — DPR tour revenue

**Mart Models (models/marts/)**
- `fct_daily_performance.sql` — Daily performance by DPR line item
- `rpt_daily_performance_report.sql` — Report joining fct_daily_performance + dim_date
- `_dpr__marts.yml` — schema docs for DPR mart models

**Documentation**
- README.md files added to all model folders (raw, intermediate, marts/dimensions, marts/facts, marts/reports, ml_features) documenting enabled vs disabled models

### Changed

**Renamed Tables**
- 16 existing `SEED_*` tables renamed to `SEED_GATE_*` (Gateway source prefix)
- 5 new `SEED_*` tables renamed to `SEED_CP_*` (CounterPoint source prefix)

**dbt_project.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**packages.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**models/exposures.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**Reconciliation Tests**
- `assert_raw_silver_ticket_count_match.sql` — now uses `source('gateway_seed', 'seed_gate_jnltickets')` (no longer commented out)
- `assert_raw_silver_retail_count_match.sql` — now uses `source('counterpoint_seed', 'seed_cp_pstkthistlin')` (no longer commented out)

**models/intermediate/schema.yml**
- Updated silver_pos_tickets docs (PK → jnl_detail_id, date → sold_at)
- Updated silver_pos_retail docs (PK → line_guid, date → business_date)
- Updated silver_ticket_scans docs (PK → usage_id, date → use_time)

### Removed

**Deleted Staging Models** (19 files — sources not available)
- `stg_salesforce_nps__contacts.sql`, `stg_salesforce_nps__accounts.sql`, `stg_salesforce_nps__opportunities.sql`, `stg_salesforce_nps__campaigns.sql`
- `stg_salesforce_mc__tracking.sql`
- `stg_shopify__orders.sql`, `stg_shopify__customers.sql`, `stg_shopify__products.sql`
- `stg_classy__campaigns.sql`, `stg_classy__transactions.sql`
- `stg_blackbaud__accounts.sql`, `stg_blackbaud__journal_entries.sql`
- `stg_ga4__sessions.sql`
- `stg_google_ads__campaigns.sql`
- `stg_meta_ads__campaigns.sql`
- `stg_vena__budget.sql`
- `stg_wufoo__form_entries.sql`
- `stg_clicky__visitors.sql`
- `stg_drupal__pages.sql`

**Deleted Obsolete Staging Models** (3 files — replaced by new gateway_seed models)
- `stg_gateway__customers.sql`, `stg_gateway__ticket_types.sql`, `stg_gateway__transactions.sql`

**Deleted Obsolete Staging Models** (3 files — replaced by new counterpoint_seed models)
- `stg_counterpoint__items.sql`, `stg_counterpoint__line_items.sql`, `stg_counterpoint__transactions.sql`

**Deleted Silver Models** (4 files — superseded by new intermediate models)
- `silver_pos_tickets.sql`, `silver_pos_retail.sql`, `silver_ticket_scans.sql`, `silver_ticket_inventory.sql`

**Removed Source Definitions** (12 sources from sources.yml)
- salesforce_nps, salesforce_mc, gateway (old), shopify, classy, blackbaud, vena, ga4, google_ads, meta_ads, wufoo, clicky, drupal

### Disabled (`enabled=false`)

**Intermediate** (8 models)
- `silver_sf_crm`, `silver_sf_marketing_cloud`, `silver_shopify`, `silver_classy`, `silver_blackbaud`, `silver_google_analytics`, `silver_google_ads`, `silver_meta_ads`

**Marts — Dimensions** (6 models)
- `dim_campaign`, `dim_customer`, `dim_gate`, `dim_payment_method`, `dim_product`, `dim_ticket_type`

**Marts — Facts** (22 models)
- `bridge_session_customer`, `fct_ad_campaign_daily`, `fct_campaign_attribution`, `fct_campaign_performance`, `fct_daily_operations`, `fct_digital_ad_performance`, `fct_donor_cohort_survival`, `fct_donor_retention`, `fct_fundraising`, `fct_gl_transactions`, `fct_marketing_channel_summary`, `fct_marketing_sales_daily`, `fct_monthly_operations`, `fct_monthly_retail`, `fct_retail_line_items`, `fct_ticket_availability`, `fct_ticket_demand_benchmarks`, `fct_ticket_sales`, `fct_ticket_utilization`, `fct_visitor_traffic`, `fct_website_funnel`, `fct_website_traffic`

**Marts — Reports** (9 models)
- `rpt_campaign_performance`, `rpt_customer_ltv`, `rpt_daily_operations`, `rpt_digital_marketing`, `rpt_member_360`, `rpt_retail_performance`, `rpt_revenue_bridge`, `rpt_ticket_sales`, `rpt_visitor_traffic`

**ML Features** (14 models)
- All `ml_*` models disabled — depend on disabled upstream facts

---

## [1.2.0] — 2026-06-25 — Best Practices, Security & Monitoring

*Errata (2026-07-29): the version number 1.2.0 was used twice. This is the second (later) 1.2.0, dated 2026-06-25; the earlier 1.2.0 dated 2026-06-23 ("dbt Platform Foundation") appears further down. Entries are kept as written — disambiguate by date.*

### Added
- `NS11MM_DW_DEV.MONITORING` schema — alerts, tasks, audit views, DMFs
- 5 active alerts: source freshness, dbt failures, warehouse utilization, credit consumption, long-running queries
- `MANAGE_ALERTS` stored procedure — suspend/resume alerts individually or all at once
- 4 scheduled tasks: daily dbt build (6 AM), freshness check (5:30 AM), weekly PROD clone (Sun 2 AM), weekly docs generate (Mon 7 AM)
- 3 masking policies: MASK_NAME, MASK_EMAIL, MASK_PHONE (DEV + PROD)
- Row access policy: RAP_PII_ACCESS (ML_ROLE filtered from PII rows)
- Network policy: NS11MM_NETWORK_POLICY (created, NOT activated — test first)
- 3 governance tags: SENSITIVITY, DATA_DOMAIN, DATA_OWNER
- 4 Data Metric Functions: DMF_NULL_RATE, DMF_ROW_COUNT, DMF_DUPLICATE_RATE, DMF_FRESHNESS_HOURS
- `macros/operations/apply_masking_policies.sql` — auto-applies masking on-run-end
- `macros/operations/apply_governance_tags.sql` — auto-applies tags on-run-end
- `macros/operations/create_raw_streams.sql` — creates CDC streams on RAW tables
- `.github/workflows/dbt-ci.yml` — CI workflow for PR validation
- `docs/DATA_CONTRACTS.yml` — freshness SLAs, quality thresholds, refresh targets
- `models/exposures.yml` — expanded with 5 Power BI dashboards, 3 Cortex Analyst views, 3 ML models
- 2 Snowflake secrets: SECRET_POWERBI_SVC, SECRET_LOADER_SVC (rotate immediately)
- Deployed dbt project: `NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM`

### Changed
- `DEPLOY_DEV_ROLE` and `DEPLOY_PROD_ROLE` created with proper hierarchy
- Old roles removed: `DBT_DEV_ROLE`, `DBT_PROD_ROLE`
- `MUSEUM_DW_DEV` database dropped (old POC)
- `NS11MM_DW_DEV_KRAMSEY` database dropped
- All old schemas removed from JMYERS and PROD (BRONZE, SILVER, GOLD, etc.)
- NS11MM_DW_DEV time travel increased to 7 days
- Warehouse auto_suspend: MONITORING/SOURCES/DBT_DEV reduced to 30s
- Statement timeouts set on all warehouses (5–60 min based on workload)
- POWERBI_SVC: query_tag set to 'powerbi_reporting'
- `dbt_project.yml`: added `on-run-end` hooks for tags + masking
- LOADER_ROLE: granted write to RAW in DEV + PROD
- POWERBI_ROLE: granted SELECT + future grants on MARTS (PROD)
- ML_ROLE: granted SELECT INTERMEDIATE/MARTS + WRITE ML_FEATURES

### Documentation Updated
- `SNOWFLAKE_SETTINGS.md` — complete rewrite reflecting current state
- `docs/README.md` — schema table updated with STAGING layer
- `docs/ONBOARDING.md` — RBAC roles, profiles.yml note for Snowflake-native
- `docs/architecture/DATA_CLASSIFICATION.md` — updated PII locations, masking policies, role-based access table
- `docs/architecture/TEST_ORCHESTRATION.md` — updated source names and freshness thresholds
- `docs/architecture/SQL_STYLE_GUIDE.md` — updated naming convention table
- `docs/architecture/SOURCE_INTEGRATION.md` — terminology (Bronze → RAW)
- `docs/architecture/USAGE_AUDIT.md` — added pre-built monitoring views section
- `docs/business/METRIC_GLOSSARY.md` — fiscal year corrected to October start
- `macros/operations/README.md` — added all new macros + on-run-end hooks
- `macros/data_quality/README.md` — updated freshness thresholds
- `RUNBOOK.md` — added GDPR, governance, alert management, and deployed dbt project commands
- `PLATFORM_SCORECARD.md` — new file: best-in-class assessment (9.3/10), architecture diagram, role hierarchy, monitoring stack, industry comparison

---

## [1.1.0] — 2026-06-24 — Production Git Workspace Migration

*Errata (2026-07-29): the version number 1.1.0 was used twice. This is the second (later) 1.1.0, dated 2026-06-24; the earlier 1.1.0 dated 2026-06-23 ("Bronze Ingestion Pipeline Framework") appears further down. Entries are kept as written — disambiguate by date.*

### Added
- `profiles.yml` for Snowflake-native dbt (no env_var/password/authenticator)
- `models/raw/stg_gateway__customers.sql` — staging model for Gateway customer data
- `models/intermediate/schema.yml` — documentation + tests for all 12 intermediate models
- `models/marts/facts/schema.yml` — documentation + tests for all 22 fact models
- `models/marts/reports/schema.yml` — documentation + tests for all 9 report models
- `models/ml_features/schema.yml` — documentation + tests for all 14 ML feature models
- `semantic_models/ns11mm_marketing_performance.yaml` — SV_MARKETING_PERFORMANCE (6 entities: digital_ad_performance, email_campaigns, website_traffic, website_funnel, channel_summary, dates)
- `semantic_models/ns11mm_marketing_sales.yaml` — SV_MARKETING_SALES (3 entities: marketing_sales_daily, campaign_attribution, dates)
- `notebooks/ml_member_churn_prediction.ipynb` — XGBoost member churn classifier with Snowflake ML Registry integration
- `notebooks/ml_ticket_demand_forecast.ipynb` — XGBoost ticket demand forecaster with Snowflake ML Registry integration
- `macros/operations/gdpr_anonymize.sql` — GDPR right-to-erasure macro; anonymizes PII across INTERMEDIATE + MARTS layers with audit log
- `macros/generic_tests/z_score_outlier.sql` — statistical outlier detection test (configurable z-score threshold)
- `macros/generic_tests/positive_value.sql` — assert column values are non-negative
- `macros/generic_tests/value_between.sql` — assert column values within min/max bounds
- Three-tier RBAC promotion model: TRANSFORMER_ROLE → DEPLOY_DEV_ROLE → DEPLOY_PROD_ROLE

### Fixed
- `silver_sf_crm` — replaced NULL placeholders with actual joins to stg_salesforce_nps__opportunities for membership and donation enrichment
- `silver_blackbaud` — fixed `CASE WHEN null` logic (now uses `CASE WHEN IS NULL`)
- `silver_pos_tickets` — resolved missing customer_email/phone by creating stg_gateway__customers and joining
- `dim_customer` schema.yml — test column corrected from `id` to `customer_id`, added `unique` test
- `dbt_project.yml` — raw models schema changed from `INTERMEDIATE` to `STAGING`
- README fiscal year reference corrected to October start (was July)

### Changed
- `profiles.yml` — `dev_shared` target now uses `DEPLOY_DEV_ROLE`, `prod` uses `DEPLOY_PROD_ROLE`
- `ns11mm_operations.yaml` — expanded with daily_operations + ticket_availability tables (now 5 entities)
- `ns11mm_fundraising_members.yaml` — added donor_retention table (now 5 entities)
- `CONTRIBUTING.md` — added RBAC-enforced promotion workflow, role permissions table, developer targets, emergency hotfix process, updated environment architecture and schema table
- `RUNBOOK.md` — corrected schema reference from GOLD to MARTS
- `docs/architecture/ARCHITECTURE_FLOW.md` — staging layer schema updated to STAGING, model names updated to production naming convention
- `docs/architecture/PROJECT_MAP.md` — reference chain updated from POC single-source pattern to 14-source production pattern

---

## [1.2.0] - 2026-06-23

*Errata (2026-07-29): duplicate version number — this is the first (earlier) 1.2.0, dated 2026-06-23. A second 1.2.0 dated 2026-06-25 appears above. Entries are kept as written — disambiguate by date.*

### dbt Platform Foundation — POC Migration Scaffolding

119 files added establishing the complete dbt project structure for the production platform. All files are either fully production-ready or structured stubs awaiting RAW data connection. No files from this release require logic changes — only field name confirmation once Bronze ingestion is live.

#### Project configuration

- `dbt_project.yml` — production configuration: project name `ns11mm_data_platform`, all schema targets (RAW, SILVER, GOLD, ML_FEATURES), query tags, pre-hooks, materialization strategies, and post-hooks granting POWERBI_ROLE and ML_ROLE on Gold models
- `packages.yml` — `dbt_utils` and `dbt_date` package dependencies
- `.gitignore` — standard dbt ignores including `profiles.yml`, `dbt.log`, `graph.gpickle`
- `.sqlfluff` / `.sqlfluffignore` — Snowflake dialect linting, 120-char limit, macros excluded
- `CODEOWNERS` — Jeremy as primary owner; Kalea co-owner on `models/staging/` and `models/silver/`
- `CONTRIBUTING.md` — full developer workflow: environment architecture, local setup, profiles template, change gate classification (Tier 1/2/Emergency), PR checklist, VQR workflow
- `RUNBOOK.md` — daily health check queries, pipeline and dbt failure response, contacts, quick reference command table
- `SNOWFLAKE_SETTINGS.md` — complete inventory of databases, schemas, roles, warehouses, resource monitors, and integrations

#### Models — Staging (24 files)

- `models/staging/sources.yml` — all 14 source definitions with freshness thresholds; activate per source as RAW tables are populated
- 23 staging model shells covering all 14 sources: Salesforce NPS (4 objects), Salesforce MC, Gateway (2 objects), CounterPoint (2 objects), Shopify (3 objects), Classy (2 objects), Blackbaud (2 objects), Vena, GA4, Google Ads, Meta Ads, Wufoo, Clicky, Drupal. Each model has the correct VARIANT extraction structure (`_raw_data:<Field>::<TYPE>`), hashdiff generation, and a TODO comment pointing to the exact `SELECT _raw_data ... LIMIT 1` query needed to confirm field names

#### Models — Gold Dimensions (11 files)

- `dim_date.sql` — **fully active**: complete date dimension spanning 2000–2035 with NS11MM fiscal calendar (Oct 1–Sep 30), weekend flags, and `is_commemoration_day` flag for September 11 anomaly handling
- `dim_marketing_channel.sql` — **fully active**: seed-based channel dimension; no RAW dependency
- 8 dimension placeholder stubs (`dim_customer`, `dim_gate`, `dim_campaign`, `dim_ticket_type`, `dim_product`, `dim_payment_method`, `dim_fund`, `dim_budget_version`) — correct config and schema entry; replace `select null where 1=0` body with POC logic once Silver is live
- `schema.yml` — full dimension documentation and tests including `is_commemoration_day` description

#### Macros — Generic Tests (10 files)

- `test_hashdiff_integrity.sql` — null hash detection and hash collision check
- `test_referential_integrity.sql` — reusable FK validation
- `test_row_count_drift.sql` — zero-row alert
- `test_late_arriving_data.sql` — configurable lag threshold (default 72h)
- `test_schema_drift.sql` — expected vs actual column comparison
- `null_rate_threshold.sql` — configurable null rate ceiling (default 50%)
- `daily_volume_bounds.sql` — min/max row count per day
- `cardinality_change.sql` — distinct value range check
- `distribution_shift.sql` — value frequency drift detection
- `README.md`

#### Macros — Data Quality (5 files)

- `generate_hashdiff.sql` — MD5 over business columns with null-safe concatenation
- `quarantine_failed_rows.sql` — routes failed rows to `SILVER.QUARANTINE_LOG`
- `auto_heal_duplicates.sql` — CTE deduplication keeping latest row by primary key
- `check_source_freshness.sql` — per-source staleness thresholds for all 13 API sources; called in on-run-start
- `README.md`

#### Macros — Operations (8 files)

- `create_ticket_demand_forecast.sql` — creates Snowflake ML FORECAST model for 90-day multi-series ticket demand; `dbt run-operation create_ticket_demand_forecast`
- `sync_verified_queries.sql` — lists and validates all VQRs; `dbt run-operation sync_verified_queries`
- `validate_before_deploy.sql` — compares dev/prod row counts for 10 key models before deployment
- `compare_model_to_prod.sql` — deep single-model MINUS diff between dev and prod; flags data loss risk
- `smart_retry.sql` — reads audit log, identifies failed models, suggests rerun commands
- `rerun_from_source.sql` — maps RAW source table to downstream dbt models; source map covers all 14 sources
- `resolve_quarantine.sql` — marks quarantine records resolved after successful rerun
- `README.md`

#### Macros — Root (1 file)

- `generate_schema_name.sql` — standard dbt schema name override macro

#### Tests (16 files)

All reconciliation and referential integrity tests are written and commented out pending production model availability. One test is immediately active:

- `tests/business_rules/assert_date_coverage.sql` — **active now**: validates `dim_date` spans 2000-01-01 through 2035-12-31

Commented-out tests (uncomment as each layer becomes available):
- `tests/reconciliation/` — 4 tests: RAW→Silver count matches for tickets and retail; Silver→Gold revenue and visitor reconciliation
- `tests/referential_integrity/` — 5 tests: campaign FK, ticket type seed match, payment method seed match, customer segment seed match, date orphan check
- `tests/business_rules/` — 3 additional tests: no negative revenue, no future transactions, campaign rates in bounds
- All `README.md` files

#### Seeds (5 files)

All reference data seeds — no mock/POC data included:

- `ref_marketing_channels.csv` — 7 channels (Paid Search, Paid Social Facebook/Instagram, Organic, Email, Direct, Referral)
- `ref_ltv_tiers.csv` — Platinum/Gold/Silver/Bronze with thresholds
- `ref_ticket_types.csv` — 10 ticket types matching Gateway taxonomy (Adult/Child/Senior GA, Member, Group, School, Military, First Responder)
- `ref_payment_methods.csv` — 8 payment methods including digital wallets
- `ref_customer_segments.csv` — Known Member / Identified Visitor / Anonymous

#### Snapshots (2 files)

- `snap_dim_customer.sql` — SCD Type 2 on customer dimension; check strategy on segment, membership_status, email, phone; commented out pending dim_customer
- `snap_sf_crm.sql` — SCD Type 2 on Salesforce NPS contacts via hashdiff; commented out pending staging model

#### CI/CD (1 file)

- `.github/workflows/dbt-ci.yml` — slim CI on PRs (state:modified+ with defer); full build on merge to main; manifest artifact upload for state comparison; dbt docs generation on merge

#### Governance documentation (7 files)

- `docs/architecture/SQL_STYLE_GUIDE.md` — naming conventions, layering rules, VARIANT extraction pattern, formatting standards, testing requirements
- `docs/architecture/DATA_CLASSIFICATION.md` — PII field inventory across all 14 sources, access control tiers, new model classification checklist
- `docs/architecture/USAGE_AUDIT.md` — Snowflake query history monitoring, Cortex Agent observability, pipeline log queries, credit monitoring
- `docs/business/METRIC_GLOSSARY.md` — certified metric definitions across 6 domains: Attendance, Revenue, Membership, Fundraising, Digital/Marketing, Flags (including `is_commemoration_day`)
- `docs/adr/0005-metric-definition-gate.md` — metric approval required before Gold model build
- `docs/adr/0006-change-management-tiers.md` — Tier 1/2/Emergency framework
- `docs/adr/0007-drupal-ingestion-path.md` — **decision required**: DB vs JSON:API; unblocks `stg_drupal__pages.sql`
- `docs/adr/0008-retail-source-split.md` — **decision required**: unified vs separate retail fact; recommendation is unified with channel flag (Option A)

#### Model groups and exposures (2 files)

- `models/groups.yml` — 6 groups (staging, silver, gold_dimensions, gold_facts, gold_reports, ml_features) with owner emails
- `models/exposures.yml` — 5 exposures: Power BI operations dashboard, Power BI donor retention dashboard, Cortex Analyst operations, ML donor churn model, ML ticket demand forecast

#### Terraform / IaC (16 files)

- `terraform/main.tf` — root module orchestrating 4 sub-modules
- `terraform/variables.tf` / `outputs.tf` / `providers.tf` — standard configuration
- `terraform/modules/key-vault/main.tf` — RBAC-based Key Vault with soft-delete and purge protection; admin and pipeline SP role assignments
- `terraform/modules/snowflake-warehouse/main.tf` — warehouse + resource monitor with credit quota
- `terraform/modules/static-web-app/main.tf` — dbt docs hosting
- `terraform/modules/monitor-alerts/main.tf` — Teams webhook + email alert action group
- `terraform/environments/dev.tfvars.json` — X-Small warehouse, 5 credits, `kv-ns11mm-dp-dev`
- `terraform/environments/staging.tfvars.json` — Medium warehouse, 25 credits
- `terraform/environments/prod.tfvars.json` — Medium warehouse, 50 credits
- `terraform/pipelines/deploy-dev.yml` — auto-trigger on main merge
- `terraform/pipelines/deploy-staging.yml` — manual trigger
- `terraform/pipelines/deploy-prod.yml` — manual trigger + ManualValidation approval gate
- `terraform/README.md` / `.gitignore`

#### Scripts (1 file)

- `scripts/setup_developer_workspace.sql` — provisions personal dev database for a new team member; creates RAW/SILVER/GOLD/ML_FEATURES schemas, grants TRANSFORMER_ROLE and LOADER_ROLE access, creates audit log table. Includes commented examples for JMYERS, KRAMSEY, DIANA.

#### POC migration inventory

- `NS11MM_POC_Migration_Inventory.md` — complete inventory of all 247 POC artifacts with status: 66 complete, 44 awaiting data feed, 109 to migrate from POC with find-and-replace, 10 to rebuild, 1 pending decision, 6 excluded. Includes sequenced "what to do next" and find-and-replace table for all naming changes.

#### Outstanding items from this release

| Item | Owner | Blocks |
|---|---|---|
| ADR-007: Drupal path decision | Jeremy + Anna Kim + Kenny | `stg_drupal__pages.sql` completion |
| ADR-008: Retail source split decision | Jeremy | `silver_pos_retail.sql`, `fct_retail_line_items.sql` |
| Migrate 36 verified queries from POC | Kalea | Cortex Analyst activation |
| Migrate `docs/ONBOARDING.md` and `docs/README.md` from POC | Jeremy | Onboarding |
| Migrate `terraform/notifications/teams_webhook_setup.sql` from POC | Kenny | Credit alerts |
| Complete remaining 109 POC file migrations (Silver, Gold, ML, VQRs) | Kalea / Phinn | Gold layer activation |

---

## [1.1.0] - 2026-06-23

*Errata (2026-07-29): duplicate version number — this is the first (earlier) 1.1.0, dated 2026-06-23. A second 1.1.0 dated 2026-06-24 appears above. Entries are kept as written — disambiguate by date.*

### Bronze Ingestion Pipeline Framework

**Scope:** Raw data ingestion to Snowflake RAW schema only. dbt staging, Silver, and Gold are handled separately in `models/`.

#### Shared Library (`pipelines/shared/`)

- `shared/__init__.py` — marks shared/ as a Python package importable by all pipelines
- `shared/keyvault.py` — Azure Key Vault client using `DefaultAzureCredential`; single `secret(name)` function used by all pipelines; singleton client pattern to avoid re-authentication on each call
- `shared/snowflake_client.py` — shared Snowflake connection, Bronze landing, and pipeline logging:
  - `get_connection()` — connects using Key Vault credentials; targets `NS11MM_DW_DEV.RAW` schema with `LOADER_ROLE`
  - `land_to_bronze()` — append-only insert of raw records as VARIANT (JSON) columns; creates table if not exists; never updates or deletes
  - `log_run()` — writes success/failed run record to `RAW.PIPELINE_LOG`; creates table if not exists
- `requirements-shared.txt` — shared dependencies: `azure-identity`, `azure-keyvault-secrets`, `snowflake-connector-python`, `requests`

#### Source Pipelines (14 sources)

Each pipeline contains `authenticate()` and `extract()` functions unique to the source, plus a `run()` function identical across all pipelines that calls shared library functions for landing and logging.

| Source Folder | Source System | Auth Pattern | Schedule (UTC) |
|---|---|---|---|
| `salesforce_nps/` | Salesforce NPS (Sales Cloud for Nonprofits) | OAuth 2.0 Username-Password | 07:00 |
| `salesforce_mc/` | Salesforce Marketing Cloud | OAuth 2.0 Client Credentials | 07:15 |
| `gateway/` | Gateway Ticketing Galaxy | SQL Server read-only (pyodbc) via on-prem agent | 07:30 |
| `counterpoint/` | NCR CounterPoint POS | SQL Server read-only (pyodbc) via on-prem agent | 07:45 |
| `shopify/` | Shopify (E-commerce) | Custom App access token in header | 08:00 |
| `classy/` | GoFundMe Pro / Classy | OAuth 2.0 Client Credentials | 08:15 |
| `blackbaud/` | Blackbaud Financial Edge NXT | OAuth 2.0 Refresh Token (SKY API) | 08:30 |
| `vena/` | Vena Solutions (FP&A) | API key / Bearer token | 08:45 |
| `ga4/` | Google Analytics 4 | Google Service Account JSON key | 09:00 |
| `google_ads/` | Google Ads | OAuth 2.0 with Developer Token | 09:15 |
| `meta_ads/` | Meta Ads (Facebook/Instagram) | System User Access Token | 09:30 |
| `wufoo/` | Wufoo (Forms) | HTTP Basic Auth (API key) | 09:45 |
| `clicky/` | Clicky (Web Analytics) | API key + Site ID as query parameters | 10:00 |
| `drupal/` | Drupal CMS | Bearer token (JSON:API path; pending ADR) | 10:15 |

All pipelines support `--full` flag for initial historical load and default to incremental (last 24 hours) for nightly runs.

#### Azure DevOps Deployment (14 YAML files)

One deployment YAML per source, placed in repo root:

`azure-pipelines-sfnps.yml`, `azure-pipelines-sfmc.yml`, `azure-pipelines-gateway.yml`, `azure-pipelines-counterpoint.yml`, `azure-pipelines-shopify.yml`, `azure-pipelines-classy.yml`, `azure-pipelines-blackbaud.yml`, `azure-pipelines-vena.yml`, `azure-pipelines-ga4.yml`, `azure-pipelines-googleads.yml`, `azure-pipelines-metaads.yml`, `azure-pipelines-wufoo.yml`, `azure-pipelines-clicky.yml`, `azure-pipelines-drupal.yml`

Each YAML includes:
- Path trigger scoped to `pipelines/<source>/` and `pipelines/shared/` — shared library changes redeploy all dependent pipelines
- PR trigger for validation on pull requests (Validate stage only; Deploy stage requires merge to main)
- Two-stage pipeline: Validate (import check) and Deploy (Azure Function App)
- Variables: `FUNCTION_APP_NAME`, `AZURE_SERVICE_CONNECTION`, `PYTHON_VERSION`

#### Documentation

- `pipelines/README.md` — pipeline framework overview: folder structure, how pipelines work, running instructions, shared library usage, adding a new pipeline, nightly schedule, credential conventions, outstanding blockers, key contacts
- `NS11MM_Azure_IT_Setup_Request.docx` — IT setup request for Kenny covering Key Vault provisioning, Function App spec and naming convention, managed identity and Key Vault RBAC setup, outbound network access requirements, Azure DevOps service connection, and recommended 12-step setup sequence
- `NS11MM_Source_Credential_Intake.xlsx` — credential intake workbook with one tab per source; Key Vault secret names, collection hints, and status tracking for all 14 sources
- `ns11mm_bronze_pipelines_master.md` — master pipeline reference covering shared library, per-source guides, nightly schedule, and pipeline status tracker

#### Snowflake Setup (one-time)

```sql
CREATE ROLE IF NOT EXISTS LOADER_ROLE;
GRANT USAGE ON DATABASE NS11MM_DW_DEV TO ROLE LOADER_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT CREATE TABLE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT INSERT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT ROLE LOADER_ROLE TO USER <pipeline_service_user>;
```

#### Credential status at release

| Source | Status |
|---|---|
| Salesforce Marketing Cloud | Auth URI, REST URI, SOAP URI confirmed; Client ID collected; Client Secret requires regeneration; MID outstanding |
| All other sources | Pending Key Vault setup |

#### Outstanding items before first pipeline run

- Kenny: provision `kv-ns11mm-dp-dev` Key Vault and `func-ns11mm-sfmc-dev` Function App per IT setup doc
- Jeremy: add Snowflake and SFMC credentials to Key Vault once provisioned; regenerate SFMC Client Secret
- Vena: populate `MODELS` dict in `pipelines/vena/pipeline.py` after confirming model IDs with Finance team
- Drupal: confirm DB vs JSON:API path (ADR required); populate `CONTENT_TYPES` list after scope confirmation with Anna Kim
- Blackbaud: registered app requires Blackbaud Admin approval; refresh token rotation requires Key Vault Secrets Officer role on Function App managed identity
- Gateway / CounterPoint: run via self-hosted agent on internal network, not Azure Functions; VM setup to be coordinated separately with Kenny

---

## [1.0.0] - 2026-06-23

### Initial production repository setup

- Created `ns11mm/ns11mm-data-platform` as the production repository, replacing POC repo `jmyers911mm/ns11mm-dbt`
- Established medallion architecture: RAW (Bronze) / staging / intermediate / marts naming convention
- Configured `dbt_project.yml` for `ns11mm_data_platform` project
- Configured `profiles.yml` with dev target (`NS11MM_DW_DEV`) and prod target (`NS11MM_DW_PROD`)
- Established PR-gated CI/CD as the required deployment pattern for all model changes
- Snowflake workspace: `NS11MM_DW_DEV.PUBLIC."ns11mm-dbt"` (shared dev environment)
- Personal dev databases: `NS11MM_DW_DEV_JMYERS` (Jeremy), `NS11MM_DW_DEV_KRAMSEY` (Kalea)

### Governance baseline

- ADR register established (ADR-001 through ADR-017)
- ADR-005: Metric Definition Gate — metric approval required before any Gold model is built
- ADR-006: Change Management Framework — tiered change management (Tier 1 / Tier 2 / Emergency)
- Bronze/RAW layer: immutable, append-only — architectural constraint enforced by design
- All business logic in dbt; Power BI is display-only

---