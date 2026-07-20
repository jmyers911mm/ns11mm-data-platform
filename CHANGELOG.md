# Changelog

All notable changes to the ns11mm-data-platform project will be documented in this file.

This is the production repository (`ns11mm/ns11mm-data-platform`).

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
