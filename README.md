# ns11mm-data-platform

> 📚 **New here?** Start with the [Documentation Map](docs/README.md).

> **Production repo:** `ns11mm/ns11mm-data-platform` — Python 3.12, dbt-snowflake 1.9.x, VS Code workflow.
> Schema naming: RAW → INTERMEDIATE → MARTS (not Bronze/Silver/Gold).
> **December 2026 go-live target.**

> Business user? Go straight to [Start Here](docs/business/README.md).

A production dbt project for the Museum Data Warehouse on Snowflake.

---

## ⚠️ Current scope: what is live today vs. planned

This repo contains the **full target architecture** for the platform. The
**Daily Performance Report (DPR)** slice plus the **active Pentaho report estate**
(retail, scan, attendance, tracker, today's-sales, website commerce, WiFi) are
built and enabled on the Gateway (ticketing), CounterPoint (retail POS),
report-estate (attendance/ecommerce/WiFi), Shopify-export, and budget-seed
domains. Everything outside these domains remains scaffolded but **disabled**
(`enabled=false`) pending source connectivity.

**Live today — DPR pipeline + report estate + budget + ticket demand forecasting:**

| Layer | Live | Disabled | What's live |
|-------|:----:|:--------:|-------------|
| Staging (`models/raw/`) | **34** | 0 | 17 `stg_gateway__*` + 7 `stg_counterpoint__*` + 2 `stg_budget__*` + 2 `stg_sensource__*` + 3 `stg_shopify__*` + `stg_dpr__daily_metrics_wide` + `stg_ecommerce__website_recurring` + `stg_wifi__audience` |
| Intermediate (`models/intermediate/`) | **21** | 8 | 5 gateway + 6 DPR + 3 retail + 3 budget + `int_counterpoint__retail_lines`, `int_pos_tickets`, `int_ticket_scans`, `int_ticket_inventory` |
| Mart dimensions (`models/marts/dimensions/`) | **13** | 4 | `dim_access_code`, `dim_coa`, `dim_customer`, `dim_date`, `dim_dpr_line_item`, `dim_event`, `dim_facility`, `dim_gate`, `dim_product`, `dim_retail_line_item`, `dim_store`, `dim_ticket_type`, `dim_tour_product` |
| Mart facts (`models/marts/facts/`) | **11** | 20 | `fct_daily_performance`, `fct_daily_operations`, `fct_daily_scan`, `fct_retail_daily`, `fct_retail_performance`, `fct_today_sales_hourly`, `fct_ticket_availability`, `fct_ticket_demand_forecast`, `fct_budget_dpr_forecasts`, `fct_budget_admissions_forecasts`, `fct_budget_retail_forecasts` |
| Mart reports (`models/marts/reports/`) | **21** | 9 | 23 `rpt_*.sql` files; 21 build (2 — `rpt_dpr_narrative`, `rpt_retail_narrative` — carry `enabled=false` as gated Cortex AI_COMPLETE sources) |
| ML features (`models/ml_features/`) | **2** | 12 | `ml_ticket_demand_features`, `ml_visitor_forecast_training` |
| Semantic views (`cortex_project/`) | **4** | 1 | `MARTS.DPR`, `MARTS.RETAIL`, `MARTS.ATTENDANCE`, `MARTS.UNIFIED` (+ `FUNDRAISING_ECOM` scaffold in `disabled/`) |

**Planned / disabled** (present in the repo, `enabled=false`): the marketing, digital
(GA4/Google Ads/Meta Ads), CRM/customer-360, membership, fundraising/donor, GL, website,
and visitor-traffic domains, plus most ML feature models. These become live as their
upstream sources are connected. Each layer's folder README lists exactly which models are
enabled vs. disabled and what unblocks each one:

- [`models/raw/README.md`](models/raw/README.md)
- [`models/intermediate/README.md`](models/intermediate/README.md)
- [`models/marts/dimensions/README.md`](models/marts/dimensions/README.md)
- [`models/marts/facts/README.md`](models/marts/facts/README.md)
- [`models/marts/reports/README.md`](models/marts/reports/README.md)
- [`models/ml_features/README.md`](models/ml_features/README.md)

The rest of this document describes the **full target platform**. Sections that describe
capabilities not yet live (identity resolution, the marketing/donor semantic views, the
Cortex agent, ML forecasting, the verified-query library) are marked **[PLANNED]**.

---

## Documentation Guide

| Document | Purpose | Read when... |
|----------|---------|--------------|
| **[README.md](README.md)** | Technical reference and target architecture; current-scope banner above | You need detail on a model, role, or layer |
| **[PROJECT_MAP.md](docs/architecture/PROJECT_MAP.md)** | Team orientation: mental model, file placement, cross-references | You're new or need to know where something goes |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Development workflow: branching, PR checklist, workspace isolation | You're about to write code and open a PR |
| **[ARCHITECTURE_FLOW.md](docs/architecture/ARCHITECTURE_FLOW.md)** | End-to-end data flow diagram (RAW → INTERMEDIATE → MARTS → consumers) | You want the big-picture story |
| **[SOURCE_INTEGRATION.md](docs/architecture/SOURCE_INTEGRATION.md)** | Per-source extraction plans: APIs, auth, ingestion standards | You're onboarding a source or debugging ingestion |
| **[TEST_ORCHESTRATION.md](docs/architecture/TEST_ORCHESTRATION.md)** | Test scheduling, freshness SLAs, alert routing | You're touching test severity, scheduling, or alerting |
| **[USAGE_AUDIT.md](docs/architecture/USAGE_AUDIT.md)** | Cost management: credit auditing, warehouse spend, resource monitors | You need to audit usage or set cost controls |
| **[SNOWFLAKE_SETTINGS.md](docs/architecture/SNOWFLAKE_SETTINGS.md)** | Account/user settings: roles, warehouses, integrations, MFA status | You need account configuration |
| **[CHANGELOG.md](CHANGELOG.md)** | Release history with per-version changes | You need history or are cutting a release note |

---

## Table of Contents

- [Current scope](#️-current-scope-what-is-live-today-vs-planned)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Sources](#data-sources)
- [Data Layers](#data-layers)
- [Models — Live today (DPR)](#models--live-today-dpr)
- [Models — Planned](#models--planned)
- [Semantic View](#semantic-view)
- [Testing Strategy](#testing-strategy)
- [Access Control & Grants](#access-control--grants)
- [Environments](#environments)
- [CI/CD Pipeline](#cicd-pipeline)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Governance](#governance)
- [Model Lineage — Live today](#model-lineage--live-today)
- [Identity Resolution (planned)](#identity-resolution-planned)

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        MUSEUM DATA WAREHOUSE                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  RAW  →  STAGING (views)  →  INTERMEDIATE (views + 4 tables)               │
│   │                                  │                                     │
│   │                                  ▼                                     │
│   │                          MARTS (tables; reports as views)             │
│   │                      ┌────────┬────────┬────────┐                     │
│   │                      │  Dims  │ Facts  │Reports │                     │
│   │                      └────────┴────────┴────────┘                     │
│   │                                  │                                     │
│   │                                  ▼                                     │
│   │                        ML_FEATURES (planned)                         │
│   ▼                                  ▼                                     │
│  Pipelines (in-network agent)   Power BI / Snowsight                      │
│                                      │                                     │
│                                      ▼                                     │
│                       SEMANTIC VIEWS (Cortex Analyst / PBI)               │
│              ┌──────────────────────────────────────────────────┐         │
│              │ MARTS.DPR · MARTS.RETAIL · MARTS.ATTENDANCE ·     │  ← live │
│              │ MARTS.UNIFIED (cross-domain)                      │         │
│              └──────────────────────────────────────────────────┘         │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

- **Views by default, tables where hot**: staging and intermediate are views (four heavily-read intermediates are tables); marts are tables; reports are views (except `rpt_daily_performance_report`, a table). Incremental merge is an opt-in default, not the norm
- **RAW immutability** (ADR-001): raw lands append-only and is never edited; all logic is downstream in dbt
- **No business logic in Power BI** (ADR-004): BI reads the `rpt_` surface only
- **Metric definition gate** (ADR-005): a metric is defined and approved before any mart is built on it
- **`try_to_timestamp`** on raw date columns; intermediate models filter `date_key IS NULL` rows out to drop unparseable literals
- **Commemoration window** (Sep 6–16) carried as `is_commemoration_day` and treated as a known structural exception
- **Calendar-based reporting** today: `dim_date` is a calendar spine with no fiscal columns yet; the fiscal calendar (proposed FY start October) is an open ADR-005 item pending Data & AI Committee definition
- **[PLANNED] Identity resolution**, **role-playing dates**, and **SCD2 snapshots** land with the CRM/POS-customer domains

---

## Project Structure

```
ns11mm-data-platform/
├── dbt_project.yml            # Project config, materializations, hooks, grants
├── profiles.yml.template      # Copy to profiles.yml locally (profiles.yml is gitignored)
├── CHANGELOG.md               # Release history
├── CONTRIBUTING.md            # Development workflow & conventions
├── .github/
│   ├── CODEOWNERS             # PR approval routing
│   └── workflows/dbt-ci.yml   # Two-job slim CI (lint + build in NS11MM_DW_DEV_CI)
├── docs/
│   ├── README.md              # Documentation map (front door)
│   ├── ONBOARDING.md
│   ├── business/              # Business-user start-here + metric glossary
│   ├── adr/                   # Architecture Decision Records
│   └── architecture/          # PROJECT_MAP, ARCHITECTURE_FLOW, SCORECARD, SNOWFLAKE_SETTINGS, etc.
├── models/
│   ├── groups.yml             # Layer-based ownership groups
│   ├── exposures.yml          # 13 exposures for the migrated Pentaho report estate
│   ├── raw/                   # Staging views over raw sources
│   │   ├── sources.yml        # 3 seed-loaded source groups + freshness
│   │   ├── _budget_sources.yml# budget_seeds source (SEEDS schema)
│   │   ├── README.md          # Staging model inventory
│   │   └── stg_*.sql          # 34 live staging views
│   ├── intermediate/          # int_* business-logic models (21 live, 8 disabled)
│   │   ├── schema.yml
│   │   └── README.md          # Enabled vs disabled
│   ├── marts/
│   │   ├── dimensions/        # dim_*  (13 live, 4 disabled)
│   │   ├── facts/             # fct_*  (11 live, 20 disabled)
│   │   └── reports/           # rpt_*  (23 files; 21 build, 2 gated) — the Power BI surface
│   └── ml_features/           # ml_*  (2 live, 12 disabled)
├── macros/
│   ├── generate_schema_name.sql  # Custom schema naming (repo-root of macros/)
│   ├── generic_tests/         # Custom test macros (library, not yet adopted)
│   ├── data_quality/          # Data-quality test macros
│   └── operations/            # Run-operation + model-logic macros
├── tests/
│   ├── business_rules/        # 7 singular business-invariant tests
│   ├── reconciliation/        # 4 cross-layer count/total tests
│   └── referential_integrity/ # 1 FK test
├── seeds/                     # Reference + mapping + budget seeds (19 CSVs → SEEDS schema)
├── cortex_project/            # Cortex semantic views + agents (.sv.yaml source of truth)
├── scripts/                   # Generated semantic-view DDL, setup + ops SQL
├── pipelines/                 # Per-source ingestion (scaffolded; deploy YAMLs in disabled/)
├── disabled/                  # 14 Azure DevOps deploy YAMLs, parked (see its README)
└── terraform/                 # Infrastructure-as-Code
```

> Note: dbt model folders are `raw/`, `intermediate/`, and `marts/` — **not** `staging/`,
> `silver/`, `gold/`. Older diagrams that used the Bronze/Silver/Gold folder names have been
> corrected to match the repo.

---

## Data Sources

Defined in `models/raw/sources.yml` (three groups, resolved via `{{ target.database }}`
into the `RAW` schema) plus `models/raw/_budget_sources.yml` (`budget_seeds`, in the
`SEEDS` schema). **Live sources** feed the DPR and report estate; the rest are declared
for the target platform but not yet connected.

| Source | Status | Feeds |
|--------|--------|-------|
| `gateway_seed` (Gateway Galaxy ticketing) | **Live** (seed load in `RAW`) | 17 `stg_gateway__*` |
| `counterpoint_seed` (NCR CounterPoint POS) | **Live** (seed load in `RAW`) | 7 `stg_counterpoint__*` |
| `report_estate_seed` (911dw attendance / today's-sales / ecommerce / WiFi / DPR / Shopify-export tables) | **Live** (stage load in `RAW`) | `stg_sensource__*`, `stg_counterpoint__todays_retail*`, `stg_ecommerce__website_recurring`, `stg_wifi__audience`, `stg_dpr__daily_metrics_wide`, `stg_shopify__*` |
| `budget_seeds` (Excel budget workbooks → CSV seed loads) | **Live** (`SEEDS` schema) | `int_budget__*` (documented exception to the `stg_` pattern); `stg_budget__*` read budget seeds too |
| Salesforce NPS / Marketing Cloud | Planned | disabled `int_sf_crm`, `int_sf_marketing_cloud` |
| GA4 / Google Ads / Meta Ads | Planned | disabled `int_google_*`, `int_meta_ads` |
| Classy / Blackbaud | Planned | disabled `int_classy`, `int_blackbaud` |

> The current RAW layer is a **seed/stage load** of source exports (see CHANGELOG).
> Production ingestion moves to an in-network agent with watermark-based incremental
> extracts; repoint `sources.yml` from the seed tables to the RAW landing tables when
> that lands.

---

## Data Layers

| Layer | Schema | Materialization | Tags | Description |
|-------|--------|-----------------|------|-------------|
| Staging | STAGING | View | daily, critical | Type casting, trimming, column renaming |
| Intermediate | INTERMEDIATE | View (4 hot models as tables) | daily, critical | Business logic, computed columns, dedup |
| Marts | MARTS | Table | daily, critical | Star schema: dimensions + facts; reports as views (`rpt_daily_performance_report` is a table) |
| ML Features | ML_FEATURES | Table (full rebuild) | daily, non-critical | Feature tables for Snowflake ML FORECAST |
| Seeds | SEEDS | Seed table | — | 19 reference / mapping / budget CSVs |

---

## Models — Live today

### Staging (34 — `models/raw/`)

17 `stg_gateway__*` (acps, coa, disbursementdetails, facility, items, jnldetails, jnlheaders,
jnlitems, jnltickets, orderlines, orders, passes_by_hour, rmevents, tickets, usage,
vattribute, vusage), 7 `stg_counterpoint__*` (imitem, pstkthist, pstkthistlin,
todays_retail, todays_retail_product, vitkthist, vitkthistlin), 2 `stg_budget__*`
(daily_scan, retail), 2 `stg_sensource__*` (attendance, visitors), 3 `stg_shopify__*`
(cost_values, discounts, orders), plus `stg_dpr__daily_metrics_wide`,
`stg_ecommerce__website_recurring`, and `stg_wifi__audience`. See
[`models/raw/README.md`](models/raw/README.md) for the source-table map.

### Intermediate (21 — `models/intermediate/`)

The DPR conformance + metric-definition chain, the retail/report-estate chain, and the
budget chain. Key models (full inventory with one-liners in
[`models/intermediate/README.md`](models/intermediate/README.md)):

| Model | Purpose |
|-------|---------|
| `int_gateway__ticket_journal_lines` | Enriched ticket journal (jnl_code_id 101); backbone for tickets/tours/passes |
| `int_gateway__item_journal_lines` | Item journal (codes 102–104): audio, fees, ticketing donations |
| `int_counterpoint__retail_lines` | Retail lines with seed-driven store-scope + facility mapping |
| `int_dpr__admissions` / `__tour_revenue` / `__fees_and_services` / `__retail` / `__donations` / `__attendance` | The six DPR metric-definition models (one row per `date_key`) |
| `int_retail__performance` / `__customers` / `__visitors` | Retail report-estate building blocks |
| `int_budget__dpr_forecasts` / `__admissions_forecasts` / `__retail_forecasts` | Budget/forecast seed conformance |

### Marts (13 dims + 11 facts + 21 report views)

The full lists live in the folder READMEs. Highlights:

| Model | Layer | Grain | Purpose |
|-------|-------|-------|---------|
| `dim_date` | dimension | 1 row/day | Calendar spine 2000–2035 + `is_commemoration_day`; keys on `date_key` |
| `dim_facility` | dimension | 1 row/facility | Conformed facility / selling-area dimension |
| `fct_daily_performance` | fact | 1 row/`date_key` | Additive DPR measures; replaces legacy `fact_dpr_report_data` |
| `fct_retail_daily` / `fct_retail_performance` | fact | day×facility / day×facility×category | Retail report-estate facts |
| `fct_budget_*_forecasts` | fact | day (×facility) | Budget/forecast facts behind the budget-vs-actual reports |
| `rpt_daily_performance_report` | report | 1 row/day | Power BI surface: today/MTD/YTD + non-additive ratios |

---

## Models — Planned

All other `int_*`, `dim_*`, `fct_*`, `rpt_*`, and most `ml_*` models exist in the repo
with `enabled=false` in per-folder `disabled/` subfolders. They cover marketing/digital,
CRM/customer-360, membership, donor retention, fundraising, GL, website analytics, and
ML features.
The authoritative, per-model enabled/disabled inventory (with the blocker and re-enable
condition for each) lives in the six folder READMEs linked in the [Current scope](#️-current-scope-what-is-live-today-vs-planned)
section. They are not re-listed here to avoid drift.

---

## Semantic Views

**Four domain-grouped semantic views** for Cortex Analyst and the Power BI
Semantic Views connector -- one per business domain (plus a cross-domain
surface), each spanning its facts so every report (and its drill-down
dimensions) is chattable. Defined in `cortex_project/`:

| View | Domain | Facts | Status |
|---|---|---|---|
| `MARTS.DPR` | Daily Performance Report | `fct_daily_performance` × `dim_date` | Live |
| `MARTS.RETAIL` | Retail (Performance, Carts, Monthly KPI) | `fct_retail_daily` + `fct_retail_performance` | Live |
| `MARTS.ATTENDANCE` | Scanning + attendance + today's sales | `fct_daily_scan` + attendance + `fct_today_sales_hourly` | Live |
| `MARTS.UNIFIED` | Cross-domain reconciliation | DPR + retail + scan facts × conformed `dim_date` | Ready |
| `MARTS.FUNDRAISING_ECOM` | Website Commerce | (base dims disabled) | Scaffold in `cortex_project/disabled/` |

The `DPR_ANALYST` Cortex agent spec (`cortex_project/DPR_ANALYST.agent.yaml`) fronts the
DPR view for natural-language Q&A.

Each has a `<DOMAIN>.sv.yaml` (Cortex Analyst model with verified queries +
custom instructions) — the single authored source of truth — and a generated
native DDL twin `scripts/deploy_semantic_view_<domain>.sql`, rendered by
`scripts/generate_semantic_view_ddl.py` (never hand-edited; a pre-commit hook
runs `--check` for drift). Design rationale (additive SUM metrics +
ratio-of-sums, one-model-per-domain, stub guardrails) is in
[`docs/architecture/BUILD_DIMS_METS.md`](docs/architecture/BUILD_DIMS_METS.md).

Surfaces whose upstream feed can lag instruct the agent to report empty results
as "feed not yet loaded" rather than "zero".

> **[PLANNED]** The marketing, donor-retention, and museum-operations semantic
> views, the Cortex agent, and the verified-query library described in earlier
> revisions are not present in this repo yet. They return when their upstream
> marts are enabled.

---

## Testing Strategy

Tests run at each layer via `schema.yml` plus the singular tests in `tests/`.

- **Schema tests:** `not_null` / `unique` on keys, `accepted_values` on categoricals.
- **Custom generics** (`macros/generic_tests/`, `macros/data_quality/`): `hashdiff_integrity`,
  `daily_volume_bounds`, `cardinality_change`, `distribution_shift`, `z_score_outlier`, etc.
- **Singular tests** (`tests/business_rules`, `tests/reconciliation`, `tests/referential_integrity`):
  12 active (7 business-rule + 4 reconciliation + 1 referential-integrity), covering the
  live DPR/retail/budget chain; 8 more sit in per-folder `disabled/` subfolders because
  they assert against disabled models.

Run `dbt test` to execute the enabled tests for the current scope.

---

## Access Control & Grants

Roles, warehouses, and the full access matrix are documented in
[SNOWFLAKE_SETTINGS.md](docs/architecture/SNOWFLAKE_SETTINGS.md). Summary of the relevant custom roles:

| Role | Purpose |
|------|---------|
| `TRANSFORMER_ROLE` | dbt build role; read/write across the dbt schemas |
| `POWERBI_ROLE` | Read-only on `MARTS` for Power BI |
| `ML_ROLE` | Read on INTERMEDIATE/MARTS, read/write on `ML_FEATURES` (planned use) |

MARTS models grant `SELECT` to `POWERBI_ROLE` and `ML_ROLE` via dbt's `grants` config
(not post-hooks), so a model can override the default — `rpt_wifi_email_export`
(RESTRICTED/PII) sets `grants: {select: []}` to opt out. `+copy_grants: true` on
INTERMEDIATE/MARTS preserves grants across rebuilds.

---

## Environments

| Target | Database | Warehouse | Role | Threads |
|--------|----------|-----------|------|---------|
| dev | NS11MM_DW_DEV (per-dev: `NS11MM_DW_DEV_<USER>`) | DBT_DEV_WH | TRANSFORMER_ROLE | 4 |
| prod | NS11MM_DW_PROD | DBT_PROD_WH | TRANSFORMER_ROLE | 8 |

Session config: `STATEMENT_TIMEOUT_IN_SECONDS = 3600` (default), `300` for models tagged `intraday`.

---

## CI/CD Pipeline

GitHub Actions (`.github/workflows/dbt-ci.yml`) runs a two-job pipeline against the
dedicated `NS11MM_DW_DEV_CI` database on dbt-snowflake `1.9.*`: a lint/compile job
(`sqlfluff lint` per the repo `.sqlfluff` + `dbt compile`, uploading the manifest) and a
build job (`dbt build --select state:modified+`, slim when a `main` manifest is
available) so only changed models and their downstream are built and tested. A
pre-commit hook also runs `scripts/generate_semantic_view_ddl.py --check` to catch
semantic-view DDL drift.

---

## Getting Started

```bash
# One-time: create your local connection profile from the template
cp profiles.yml.template profiles.yml   # then fill in your account/user values
                                        # (profiles.yml is gitignored)

# Install packages
dbt deps

# Build the live DPR chain (dev target)
dbt build

# A single model + downstream
dbt build --select fct_daily_performance+

# Tests only
dbt test

# Full refresh of incrementals
dbt build --full-refresh
```

See [ONBOARDING.md](docs/ONBOARDING.md) for day-1 setup and [CONTRIBUTING.md](CONTRIBUTING.md)
for the workflow.

---

## Deployment

Production deployment uses Snowflake's native dbt integration:

```sql
EXECUTE DBT PROJECT ns11mm_data_platform
  TARGET = 'prod'
  COMMAND = 'build';
```

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## Governance

| Document | Purpose |
|----------|---------|
| [CHANGELOG.md](CHANGELOG.md) | Release history with model/test counts per version |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branching, PR process, change tiers |
| `.github/CODEOWNERS` | PR approval routing by path |
| [docs/adr/](docs/adr/) | Architecture Decision Records — see the register in `docs/adr/README.md` for status of each decision |

### Query Tags
`dbt_ns11mm_staging`, `dbt_ns11mm_silver`, `dbt_ns11mm_gold`, `dbt_ns11mm_ml_features`,
`dbt_ns11mm_snapshots` (the snapshot tag applies only if snapshots are ever configured).

---

## Model Lineage — Live today

```
RAW (seed load)          STAGING                              INTERMEDIATE                        MARTS
────────────────         ───────                              ────────────                        ─────

SEED_GATE_* ──────────►  stg_gateway__jnltickets ┐
                         stg_gateway__jnldetails  ├──►  int_gateway__ticket_journal_lines ────┐
                         stg_gateway__items       │                                            ├─► int_dpr__admissions ─────┐
                         stg_gateway__vattribute  │                                            ├─► int_dpr__tour_revenue ───┤
                         stg_gateway__coa …       ┘                                            │                            │
                         stg_gateway__jnlitems ───────►  int_gateway__item_journal_lines ─────┼─► int_dpr__fees_and_services
                                                                                               ├─► int_dpr__donations        │
SEED_CP_* ────────────►  stg_counterpoint__pstkthistlin ─► int_counterpoint__retail_lines ────┴─► int_dpr__retail ───────────┤
                         stg_counterpoint__imitem …                                                                          │
                                                                                                                             ▼
                                              dim_date ───────────────────────────────────────────────►  fct_daily_performance
                                                                                                                             │
                                                                                                                             ▼
                                                                                              rpt_daily_performance_report ─► Power BI / MARTS.DPR
```

---

## Identity Resolution (planned)

> **[PLANNED]** Graph-based identity resolution (unifying customers across POS, CRM, and email
> by shared email/phone) lands with the CRM/POS-customer upstreams, currently `enabled=false`
> (today's `dim_customer` is Gateway-only). The design (connected-components matching, transitive merge,
> multi-value email/phone arrays, and the Known Member / Identified Visitor / Anonymous segments)
> is retained in version control and will be documented here when the domain is enabled.