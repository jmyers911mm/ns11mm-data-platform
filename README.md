# ns11mm-data-platform

> 📚 **New here?** Start with the [Documentation Map](docs/README.md).

> **Production repo:** `ns11mm/ns11mm-data-platform` — Python 3.12, dbt-snowflake 1.8.4, VS Code workflow.
> Schema naming: RAW → INTERMEDIATE → MARTS (not Bronze/Silver/Gold).
> **December 2026 go-live target.**

> Business user? Go straight to [Start Here](docs/business/README.md).

A production dbt project for the Museum Data Warehouse on Snowflake.

---

## ⚠️ Current scope: what is live today vs. planned

This repo contains the **full target architecture** for the platform. The
**Daily Performance Report (DPR)** slice plus the **active Pentaho report estate**
(retail, scan, attendance, tracker) are built and enabled on the Gateway
(ticketing) and CounterPoint (retail POS) domains. Reports that need a
not-yet-connected source (Sensource, real-time CP, Classy/Shopify, WiFi) are
**wired to stub seeds** and populate on a seed swap. Everything outside these
domains remains scaffolded but **disabled** (`enabled=false`) pending source
connectivity.

**Live today — DPR pipeline + report estate + ticket demand forecasting:**

| Layer | Live | Of total | What's live |
|-------|:----:|:--------:|-------------|
| Staging (`models/raw/`) | **21** | 21 | 16 `stg_gateway__*` + 5 `stg_counterpoint__*` |
| Intermediate (`models/intermediate/`) | **17** | 25 | 4 gateway (+`int_gateway__scan_lines`) + 5 DPR + 3 retail (`int_retail__performance/customers/visitors`) + `int_pos_tickets`, `int_ticket_scans`, `int_ticket_inventory`, `int_gateway__ticket_demand_features` |
| Mart dimensions (`models/marts/dimensions/`) | **4** | 10 | `dim_date`, `dim_fund`, `dim_budget_version`, `dim_marketing_channel` |
| Mart facts (`models/marts/facts/`) | **8** | 28 | + report estate: `fct_retail_performance`, `fct_retail_daily`, `fct_daily_scan`, `fct_today_sales_hourly` (stub) |
| Mart reports (`models/marts/reports/`) | **10** | 19 | DPR + 9 migrated Pentaho reports (5 live, 4 stub-wired) |
| ML features (`models/ml_features/`) | **2** | 14 | `ml_ticket_demand_features`, `ml_visitor_forecast_training` |
| Semantic views (`semantic_models/`) | **4** | 4 | `MARTS.DPR`, `MARTS.RETAIL`, `MARTS.ATTENDANCE`, `MARTS.FUNDRAISING_ECOM` |

**Planned / disabled** (present in the repo, `enabled=false`): all marketing, digital
(GA4/Google Ads/Meta Ads), CRM/customer-360, membership, fundraising/donor, GL, website,
visitor-traffic, ticket-demand, and every ML feature model. These become live as their
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
| **[SNOWFLAKE_SETTINGS.md](SNOWFLAKE_SETTINGS.md)** | Account/user settings: roles, warehouses, integrations, MFA status | You need account configuration |
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
│  RAW  →  STAGING (views)  →  INTERMEDIATE (incremental)                    │
│   │                                  │                                     │
│   │                                  ▼                                     │
│   │                          MARTS (incremental)                          │
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
│              │ MARTS.FUNDRAISING_ECOM (stub-fed)                 │         │
│              └──────────────────────────────────────────────────┘         │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

- **Incremental merge strategy** for the INTERMEDIATE and MARTS layers to minimize reprocessing
- **RAW immutability** (ADR-001): raw lands append-only and is never edited; all logic is downstream in dbt
- **No business logic in Power BI** (ADR-004): BI reads the `rpt_` surface only
- **Metric definition gate** (ADR-005): a metric is defined and approved before any mart is built on it
- **`try_to_timestamp`** on raw date columns; silver models filter `key_date IS NULL` to drop unparseable literals
- **Commemoration window** (Sep 6–16) carried as `is_commemoration_day` and treated as a known structural exception
- **Fiscal calendar** is defined in `dim_date` (`fiscal_year` / `fiscal_month`); confirm the fiscal start month before publishing fiscal metrics
- **[PLANNED] Identity resolution**, **role-playing dates**, and **SCD2 snapshots** land with the CRM/POS-customer domains

---

## Project Structure

```
ns11mm-data-platform/
├── dbt_project.yml            # Project config, materializations, hooks, grants
├── profiles.yml               # Connection profiles (gitignored)
├── CHANGELOG.md               # Release history
├── CONTRIBUTING.md            # Development workflow & conventions
├── RUNBOOK.md                 # Operational procedures
├── SNOWFLAKE_SETTINGS.md      # Account/user settings reference
├── PLATFORM_SCORECARD.md      # Best-in-class self-assessment
├── CODEOWNERS                 # PR approval routing
├── .github/workflows/dbt-ci.yml
├── docs/
│   ├── README.md              # Documentation map (front door)
│   ├── ONBOARDING.md
│   ├── business/              # Business-user start-here + metric glossary
│   ├── adr/                   # Architecture Decision Records
│   └── architecture/          # PROJECT_MAP, ARCHITECTURE_FLOW, SOURCE_INTEGRATION, etc.
├── models/
│   ├── groups.yml             # Layer-based ownership groups
│   ├── exposures.yml          # Exposures (currently placeholder — see CHANGELOG 1.3.1)
│   ├── raw/                   # Staging views over raw sources
│   │   ├── sources.yml        # Source definitions + freshness + tests
│   │   ├── README.md          # Enabled vs disabled staging models
│   │   └── stg_*.sql          # 21 live (gateway + counterpoint)
│   ├── intermediate/          # silver_* incremental models
│   │   ├── schema.yml, _dpr__models.yml
│   │   ├── README.md          # Enabled vs disabled
│   │   └── silver_*.sql       # 8 live (gateway/counterpoint + dpr)
│   └── marts/
│       ├── dimensions/        # dim_*  (4 live of 10)
│       ├── facts/             # fct_*  (1 live of 23)
│       └── reports/           # rpt_*  (1 live of 10) — the Power BI surface
│   └── ml_features/           # ml_*  (0 live of 14, all planned)
├── macros/
│   ├── generic_tests/         # Custom test macros
│   ├── data_quality/          # Data-quality test macros
│   └── operations/            # Run-operation macros
├── tests/
│   ├── business_rules/        # Singular business-invariant tests
│   ├── reconciliation/        # Cross-layer count/total tests
│   └── referential_integrity/ # FK / seed-alignment tests
├── seeds/                     # Reference + DPR mapping seeds (8 CSVs)
├── semantic_models/           # DPR semantic view (SQL DDL + Cortex YAML)
├── pipelines/                 # Per-source ingestion (scaffolded)
├── snapshots/                 # SCD2 snapshots (planned domains)
└── terraform/                 # Infrastructure-as-Code
```

> Note: dbt model folders are `raw/`, `intermediate/`, and `marts/` — **not** `staging/`,
> `silver/`, `gold/`. Older diagrams that used the Bronze/Silver/Gold folder names have been
> corrected to match the repo.

---

## Data Sources

Defined in `models/raw/sources.yml`. **Live sources** feed the DPR; the rest are declared
for the target platform but not yet connected.

| Source | Status | Feeds |
|--------|--------|-------|
| `gateway_seed` (Gateway Galaxy ticketing) | **Live** (seed load in `RAW`) | `stg_gateway__*` |
| `counterpoint_seed` (NCR CounterPoint POS) | **Live** (seed load in `RAW`) | `stg_counterpoint__*` |
| Salesforce NPS / Marketing Cloud | Planned | disabled `silver_sf_*` |
| GA4 / Google Ads / Meta Ads | Planned | disabled `silver_google_*`, `silver_meta_ads` |
| Shopify / Classy / Blackbaud / Vena | Planned | disabled `silver_shopify`, `silver_classy`, `silver_blackbaud` |

> The current RAW layer is a **seed load** of Gateway/CounterPoint CSV exports (see
> CHANGELOG 1.3.0). Production ingestion moves to an in-network agent with watermark-based
> incremental extracts; repoint `sources.yml` from the seed schema to the RAW landing tables
> when that lands.

---

## Data Layers

| Layer | Schema | Materialization | Strategy | Tags | Description |
|-------|--------|-----------------|----------|------|-------------|
| Staging | STAGING | View | — | daily, critical | Type casting, trimming, column renaming |
| Intermediate | INTERMEDIATE | Incremental | Merge | daily, critical | Business logic, computed columns, dedup |
| Marts | MARTS | Incremental / Table | Merge | daily, critical | Star schema: dimensions + facts + reports |
| ML Features | ML_FEATURES | Table | Full rebuild | daily, non-critical | Feature tables for Snowflake ML FORECAST |

---

## Models — Live today (DPR)

### Staging (21 — `models/raw/`)

16 `stg_gateway__*` (acps, coa, disbursementdetails, facility, items, jnldetails, jnlheaders,
jnlitems, jnltickets, orderlines, orders, rmevents, tickets, usage, vattribute, vusage) and
5 `stg_counterpoint__*` (imitem, pstkthist, pstkthistlin, vitkthist, vitkthistlin). See
[`models/raw/README.md`](models/raw/README.md) for the source-table map.

### Intermediate (8 — `models/intermediate/`)

| Model | Purpose |
|-------|---------|
| `silver_gateway__ticket_journal_lines` | Enriched ticket journal (jnl_code_id 101); backbone for tickets/tours/passes |
| `silver_gateway__item_journal_lines` | Item journal (codes 102–104): audio, fees, ticketing donations |
| `silver_counterpoint__retail_lines` | Retail lines with seed-driven facility mapping |
| `silver_dpr__admissions` | GA tickets sold, ticket revenue, scanned-GA attendance, pass revenue |
| `silver_dpr__tour_revenue` | Guided/virtual/field-trip tour quantities and revenue |
| `silver_dpr__fees_and_services` | Service fees, audio guide, memorial+museum tour |
| `silver_dpr__retail` | Retail gross profit, MUS AG, retail-sourced donations |
| `silver_dpr__donations` | Ticketing/box/exit donations |

### Marts (6 live)

| Model | Layer | Grain | Purpose |
|-------|-------|-------|---------|
| `dim_date` | dimension | 1 row/day | Calendar + `is_commemoration_day`; keys on `date_id` |
| `dim_fund` | dimension | 1 row/fund | Fund reference (seed) |
| `dim_budget_version` | dimension | 1 row/version | Budget version reference (seed) |
| `dim_marketing_channel` | dimension | 1 row/channel | Channel reference (seed) |
| `fct_daily_performance` | fact | 1 row/`date_id` | Additive DPR measures; replaces legacy `fact_dpr_report_data` |
| `rpt_daily_performance_report` | report | 1 row/day | Power BI surface: today/MTD/YTD + non-additive ratios |

---

## Models — Planned

All other `silver_*`, `dim_*`, `fct_*`, `rpt_*`, and every `ml_*` model exist in the repo
with `enabled=false`. They cover marketing/digital, CRM/customer-360, membership, donor
retention, fundraising, GL, website analytics, ticket-demand forecasting, and ML features.
The authoritative, per-model enabled/disabled inventory (with the blocker and re-enable
condition for each) lives in the six folder READMEs linked in the [Current scope](#️-current-scope-what-is-live-today-vs-planned)
section. They are not re-listed here to avoid drift.

---

## Semantic Views

**Four domain-grouped semantic views** for Cortex Analyst and the Power BI
Semantic Views connector -- one per business domain, each spanning its facts so
every report (and its drill-down dimensions) is chattable. Defined in
`semantic_models/`:

| View | Domain | Facts | Status |
|---|---|---|---|
| `MARTS.DPR` | Daily Performance Report | `fct_daily_performance` × `dim_date` | Live |
| `MARTS.RETAIL` | Retail (Performance, Carts, Monthly KPI) | `fct_retail_daily` + `fct_retail_performance` | Live |
| `MARTS.ATTENDANCE` | Scanning + attendance + today's sales | `fct_daily_scan` + attendance + `fct_today_sales_hourly` | Live / partial-stub |
| `MARTS.FUNDRAISING_ECOM` | Website Commerce | `rpt_website_commerce` | Stub-fed |

Each has a `<domain>.yaml` (Cortex Analyst model with verified queries + custom
instructions) and a native `create_<domain>_semantic_view.sql` DDL twin
(`create_dpr_semantic_view.sql` exists; retail/attendance/ecom twins generate
from their YAML). Design rationale (additive SUM metrics + ratio-of-sums,
one-model-per-domain, stub guardrails) is in
[`semantic_models/README.md`](semantic_models/README.md).

Stub-fed surfaces (`fundraising_ecom`, today's-sales) instruct the agent to
report empty results as "feed not yet connected" rather than "zero".

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
  many currently carry `enabled=false` because they assert against disabled/deleted models
  (see CHANGELOG 1.3.1). The active set covers the live DPR chain.

Run `dbt test` to execute the enabled tests for the current scope.

---

## Access Control & Grants

Roles, warehouses, and the full access matrix are documented in
[SNOWFLAKE_SETTINGS.md](SNOWFLAKE_SETTINGS.md). Summary of the relevant custom roles:

| Role | Purpose |
|------|---------|
| `TRANSFORMER_ROLE` | dbt build role; read/write across the dbt schemas |
| `POWERBI_ROLE` | Read-only on `MARTS` for Power BI |
| `ML_ROLE` | Read on INTERMEDIATE/MARTS, read/write on `ML_FEATURES` (planned use) |

MARTS models post-hook `GRANT SELECT` to `POWERBI_ROLE` and `ML_ROLE`; `+copy_grants: true`
on INTERMEDIATE/MARTS preserves grants across incremental rebuilds.

---

## Environments

| Target | Database | Warehouse | Role | Threads |
|--------|----------|-----------|------|---------|
| dev | NS11MM_DW_DEV (per-dev: `NS11MM_DW_DEV_<USER>`) | DBT_DEV_WH | TRANSFORMER_ROLE | 4 |
| prod | NS11MM_DW_PROD | DBT_PROD_WH | TRANSFORMER_ROLE | 8 |

Session config: `STATEMENT_TIMEOUT_IN_SECONDS = 3600` (default), `300` for models tagged `intraday`.

---

## CI/CD Pipeline

GitHub Actions (`.github/workflows/dbt-ci.yml`) runs on PRs to `main` touching model/macro/test
files: `dbt build --select state:modified+` (Slim CI) so only changed models and their
downstream are built and tested.

---

## Getting Started

```bash
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
| [CODEOWNERS](CODEOWNERS) | PR approval routing by path |
| [docs/adr/](docs/adr/) | Architecture Decision Records (ADR-005 metric gate, ADR-006 change tiers, ADR-007/008 open decisions) |

### Query Tags
`dbt_ns11mm_staging`, `dbt_ns11mm_silver`, `dbt_ns11mm_gold`, `dbt_ns11mm_ml_features`,
`dbt_ns11mm_snapshots` (the last two apply once those layers are enabled).

---

## Model Lineage — Live today

```
RAW (seed load)          STAGING                              INTERMEDIATE                        MARTS
────────────────         ───────                              ────────────                        ─────

SEED_GATE_* ──────────►  stg_gateway__jnltickets ┐
                         stg_gateway__jnldetails  ├──►  silver_gateway__ticket_journal_lines ─┐
                         stg_gateway__items       │                                            ├─► silver_dpr__admissions ─┐
                         stg_gateway__vattribute  │                                            ├─► silver_dpr__tour_revenue ┤
                         stg_gateway__coa …       ┘                                            │                            │
                         stg_gateway__jnlitems ───────►  silver_gateway__item_journal_lines ──┼─► silver_dpr__fees_and_services
                                                                                               ├─► silver_dpr__donations     │
SEED_CP_* ────────────►  stg_counterpoint__pstkthistlin ─► silver_counterpoint__retail_lines ─┴─► silver_dpr__retail ────────┤
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
> by shared email/phone) lands with the `dim_customer` model and its CRM/POS-customer upstreams,
> all currently `enabled=false`. The design (connected-components matching, transitive merge,
> multi-value email/phone arrays, and the Known Member / Identified Visitor / Anonymous segments)
> is retained in version control and will be documented here when the domain is enabled.