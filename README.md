# ns11mm-data-platform

> 📚 **New here?** Start with the [Documentation Map](docs/README.md).

> **Production repo:** `ns11mm/ns11mm-data-platform` — Python 3.12, dbt-snowflake 1.8.4, VS Code workflow.
> Schema naming: RAW → INTERMEDIATE → MARTS (not Bronze/Silver/Gold).
> **December 2026 go-live target.**


> Business user? Go straight to [Start Here](docs/business/README.md).

A production dbt project for the Museum Data Warehouse on Snowflake. Transforms raw bronze-layer data into analytics-ready silver, gold, and ML feature tables powering operations dashboards, member engagement, retail performance, and ticket demand forecasting.

**Current state:** 96 models | 14 sources | 24 staging | 12 silver | 10 dims | 22 facts | 9 reports | 14 ML features | 2 snapshots | 5 seeds | 4 semantic views | 16 macros

---

## Documentation Guide

| Document | Purpose | Read when... |
|----------|---------|--------------|
| **[README.md](README.md)** | Full technical reference: every model, test, role, semantic view, and deployment detail | You need authoritative detail on a specific model, role, or test |
| **[PROJECT_MAP.md](docs/architecture/PROJECT_MAP.md)** | Team orientation guide: mental model, file placement, cross-references | You're new to the repo or need to know where something goes |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Development workflow: branching, PR checklist, VQR workflow, workspace isolation | You're about to write code and open a PR |
| **[ARCHITECTURE_FLOW.md](docs/architecture/ARCHITECTURE_FLOW.md)** | End-to-end data flow diagram (Bronze → Silver → Gold → Consumers) | You want the big-picture "how does data get here" story |
| **[SOURCE_INTEGRATION.md](docs/architecture/SOURCE_INTEGRATION.md)** | Per-source extraction plans: APIs, auth models, ingestion standards | You're onboarding a new source or debugging ingestion |
| **[TEST_ORCHESTRATION.md](docs/architecture/TEST_ORCHESTRATION.md)** | Test scheduling, source clustering, freshness SLAs, alert routing | You're touching test severity, scheduling, or alerting |
| **[USAGE_AUDIT.md](docs/architecture/USAGE_AUDIT.md)** | Cost management: credit auditing, warehouse spend, Cortex AI costs, resource monitors, budgets | You need to audit usage, track spend, or set up cost controls |
| **[SNOWFLAKE_SETTINGS.md](docs/architecture/SNOWFLAKE_SETTINGS.md)** | Account/user settings: roles, warehouses, integrations, MFA status | You need to look up account configuration |
| **[CHANGELOG.md](CHANGELOG.md)** | Release history with detailed per-version changes | You need history or are cutting a release note |

---

## Best-in-Class Scorecard

| Category | Elements | Count |
|----------|----------|-------|
| **Architecture** | 3-layer medallion, incremental merge, identity resolution, star schema, SCD2 snapshots | ✅ |
| **Testing** | Source, schema, data quality, business rules, reconciliation, referential integrity, seed validation | 372+ tests |
| **Governance** | Groups, exposures, deprecation markers, PII classification, CODEOWNERS, ownership metadata | 6 groups / 15 exposures |
| **CI/CD** | Slim CI (`state:modified+`), docs on merge, pre-deploy validation, full path triggers | ✅ |
| **Semantic Layer** | 4 semantic views, 35 VQRs, 60+ synonyms, sample values, AI instructions | 20 + 10 + 5 VQRs |
| **AI & Observability** | Cortex Agent, unredacted event logging, daily gap detection, email + Teams alerts | ✅ |
| **Operations** | Task DAG (5 tasks), hourly freshness, weekly log purge, pattern analysis | 8 tasks |
| **Reference Data** | Version-controlled seeds for ticket types, payment methods, LTV tiers, segments, marketing channels, marketing data | 8 seeds |
| **Developer Experience** | CONTRIBUTING.md, VQR workflow, .sqlfluff, trunk-based dev, Terraform IaC | ✅ |

---

## Table of Contents

- [Best-in-Class Scorecard](#best-in-class-scorecard)
- [Architecture](#architecture)
- [Identity Resolution](#identity-resolution)
- [Project Structure](#project-structure)
- [Data Sources](#data-sources)
- [Data Layers](#data-layers)
- [Models](#models)
  - [Staging](#staging-9-models)
  - [Silver](#silver-9-models)
  - [Gold Dimensions](#gold-dimensions-9-models)
  - [Gold Facts](#gold-facts-22-models)
  - [Gold Reports](#gold-reports-8-models)
  - [ML Features](#ml-features-14-models)
- [Semantic Views](#semantic-views-4)
- [Cortex Agent](#cortex-agent)
- [Verified Query Framework](#verified-query-framework)
- [Testing Strategy](#testing-strategy)
  - [Schema Tests](#schema-tests-250)
  - [Data Quality Tests](#data-quality-tests)
  - [Business Rule Tests](#business-rule-tests-4)
  - [Reconciliation Tests](#reconciliation-tests-6)
  - [Referential Integrity Tests](#referential-integrity-tests-12)
- [Macros](#macros)
- [Snapshots](#snapshots)
- [Incremental Strategy](#incremental-strategy)
- [Access Control & Grants](#access-control--grants)
- [Environments](#environments)
- [CI/CD Pipeline](#cicd-pipeline)
- [Getting Started](#getting-started)
- [Common Operations](#common-operations)
- [Deployment](#deployment)
- [Governance](#governance)
- [Contributing](#contributing)
- [Model Lineage](#model-lineage)

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        MUSEUM DATA WAREHOUSE                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  BRONZE (raw)  →  STAGING (views)  →  SILVER (incremental)              │
│       │                                      │                           │
│       │                                      ▼                           │
│       │                              GOLD (incremental)                  │
│       │                          ┌────────┬────────┬────────┐           │
│       │                          │  Dims  │ Facts  │Reports │           │
│       │                          └────────┴────────┴────────┘           │
│       │                                      │                           │
│       │                                      ▼                           │
│       │                            ML_FEATURES (tables)                  │
│       │                                      │                           │
│       ▼                                      ▼                           │
│  Snowflake ML FORECAST          Power BI / Snowsight Dashboards         │
│                                      │                           │
│                                      ▼                           │
│                          SEMANTIC VIEWS (Cortex Analyst / PBI)    │
│                      ┌──────────────────────────────────────────┐ │
│                      │ SV_MUSEUM_OPERATIONS    (5 entities)     │ │
│                      │ SV_DONOR_RETENTION      (5 entities)     │ │
│                      │ SV_MARKETING_PERFORMANCE (6 entities)    │ │
│                      │ SV_MARKETING_SALES       (3 entities)    │ │
│                      └──────────────────────────────────────────┘ │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

- **Incremental merge strategy** for Silver and Gold layers to minimize reprocessing
- **Hashdiff columns** on all staging models for change detection
- **Contract enforcement** on dimension tables to catch schema drift
- **Fiscal year logic** uses October start (museum fiscal calendar, FY = Oct–Sep)
- **Transient tables** for Silver and ML Features (no Time Travel overhead)
- **Copy grants** enabled for Silver and Gold (preserves downstream access)
- **Identity resolution** via graph-based customer matching (shared email OR phone = same customer)
- **Role-playing dates** on ticket sales (transaction_date vs scan_date)
- **Semantic views** for Cortex Analyst and Power BI Semantic Views connector

---

## Identity Resolution

The `dim_customer` model implements graph-based identity resolution to unify customers across disconnected systems (POS, CRM, email marketing).

### Problem

A single person can appear as:
- A CRM contact with email + phone
- A ticket buyer identified only by email
- A retail shopper identified only by phone
- Multiple transactions with different email/phone combinations

### Approach: Connected Components via Shared Identifiers

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        IDENTITY RESOLUTION GRAPH                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  SCENARIO 1: Shared Phone merges records                                     │
│  ─────────────────────────────────────────                                   │
│                                                                              │
│  Ticket Purchase         Retail Purchase          CRM Record                 │
│  email: j@museum.org     phone: 212-555-1234      email: j@museum.org        │
│  phone: 212-555-1234     (no email)               phone: 212-555-1234        │
│        │                       │                        │                    │
│        └───────────┐   ┌──────┘                         │                    │
│                    ▼   ▼                                │                    │
│             ┌──────────────┐                             │                    │
│             │ SHARED PHONE │◄────────────────────────────┘                    │
│             └──────┬───────┘                                                 │
│                    │                                                          │
│                    ▼                                                          │
│         ┌──────────────────────┐                                             │
│         │   customer_id: abc1  │                                             │
│         │   emails: [j@museum] │  ← All 3 records are ONE customer           │
│         │   phones: [212-555-] │                                             │
│         └──────────────────────┘                                             │
│                                                                              │
│                                                                              │
│  SCENARIO 2: Shared Email merges records                                     │
│  ─────────────────────────────────────────                                   │
│                                                                              │
│  Ticket Purchase (May 1)      Retail Purchase (May 5)     Ticket (May 10)    │
│  email: sarah@gmail.com       email: sarah@gmail.com      email: sarah@gm    │
│  phone: 917-555-8888          (no phone)                  phone: 646-555-    │
│        │                            │                     9999               │
│        └──────────┐     ┌──────────┘                       │                 │
│                   ▼     ▼                                  │                 │
│            ┌──────────────┐                                │                 │
│            │ SHARED EMAIL  │◄──────────────────────────────┘                  │
│            └──────┬───────┘                                                  │
│                   │                                                           │
│                   ▼                                                           │
│        ┌────────────────────────────┐                                        │
│        │   customer_id: def2        │                                        │
│        │   emails: [sarah@gmail]    │  ← Same email = same person            │
│        │   phones: [917-555-8888,   │  ← Both phones collected               │
│        │            646-555-9999]   │                                        │
│        └────────────────────────────┘                                        │
│                                                                              │
│                                                                              │
│  SCENARIO 3: Transitive merge (email→phone→email chain)                      │
│  ──────────────────────────────────────────────────────                      │
│                                                                              │
│  Transaction A             Transaction B             Transaction C            │
│  email: work@911.org       email: work@911.org       phone: 212-555-4444     │
│  (no phone)                phone: 212-555-4444       email: personal@me.com  │
│        │                         │                         │                 │
│        └────── SHARED ──────────┘                         │                 │
│                EMAIL                                       │                 │
│                  │                                         │                 │
│                  └────────── SHARED PHONE ────────────────┘                  │
│                                                                              │
│                              ▼                                               │
│               ┌────────────────────────────────┐                             │
│               │   customer_id: ghi3            │                             │
│               │   emails: [work@911,           │  ← A, B, C all resolve     │
│               │            personal@me]        │    to ONE customer via      │
│               │   phones: [212-555-4444]       │    transitive matching      │
│               └────────────────────────────────┘                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Rules

1. **Same email** across any two transactions → same customer
2. **Same phone** across any two transactions → same customer
3. **Transitive:** If A shares an email with B, and B shares a phone with C → A, B, C are all the same customer
4. **CRM enrichment:** If resolved customer matches a CRM email → inherit membership, donor tier, and contact preferences

### Data Flow

```
BRONZE.RAW_CUSTOMER_IDENTIFIERS   ← All emails + phones from CRM, POS tickets, POS retail
        │
        ▼
GOLD.DIM_CUSTOMER                 ← Resolved: one row per customer_id
        │                            Columns: customer_id, crm_contact_id, emails[], phones[],
        │                            membership_type, customer_segment
        ▼
FCT_TICKET_SALES.CUSTOMER_ID     ← Joined via primary_email OR primary_phone
FCT_RETAIL_LINE_ITEMS.CUSTOMER_ID ← Same join logic
RPT_CUSTOMER_LTV.CUSTOMER_ID     ← Unified LTV across both channels
```

### Customer Segments

| Segment | Definition |
|---------|-----------|
| Known Member | Resolved customer matches a CRM contact_id |
| Identified Visitor | Has email or phone but no CRM match |
| Anonymous | No identifiers captured (cash transactions, no email/phone) |

### Multi-Value Support

`DIM_CUSTOMER` stores arrays of all known identifiers:
- `EMAILS` (ARRAY) — all email addresses associated with this customer
- `PHONES` (ARRAY) — all phone numbers associated with this customer
- `EMAIL_COUNT` / `PHONE_COUNT` — number of distinct identifiers

---

## Project Structure

```
ns11mm-data-platform/
├── dbt_project.yml            # Project configuration, materializations, hooks
├── profiles.yml               # Connection profiles (dev/prod targets)
├── CHANGELOG.md               # Release history
├── CONTRIBUTING.md            # Development workflow & conventions
├── PROJECT_MAP.md             # Team orientation guide — start here
├── ARCHITECTURE_FLOW.md       # End-to-end platform architecture diagram
├── SOURCE_INTEGRATION.md      # Per-source extraction plans & API details
├── TEST_ORCHESTRATION.md      # Test scheduling, SLAs, and alert routing
├── SNOWFLAKE_SETTINGS.md      # Account/user settings reference
├── CODEOWNERS                 # PR approval routing
├── .github/
│   └── workflows/
│       └── dbt-ci.yml         # Slim CI pipeline
├── models/
│   ├── groups.yml             # Layer-based ownership groups (6 groups)
│   ├── exposures.yml          # Dashboard, agent, and ML model exposures (15)
│   ├── staging/               # Views over raw sources (9 models)
│   │   ├── sources.yml        # Source definitions + freshness + tests
│   │   └── stg_*.sql
│   ├── silver/                # Incremental cleansed models (9 models)
│   │   ├── schema.yml         # Column tests, data quality generics
│   │   └── silver_*.sql
│   ├── gold/
│   │   ├── dimensions/        # Dimension tables (9 models)
│   │   │   ├── schema.yml     # Contract enforcement, accepted_values
│   │   │   └── dim_*.sql
│   │   ├── facts/             # Fact tables (22 models incl. bridge)
│   │   │   └── fct_*.sql
│   │   └── reports/           # Pre-joined dashboard views (9 models)
│   │       └── rpt_*.sql
│   └── ml_features/           # ML feature tables (14 models)
│       └── ml_*.sql
├── analyses/
│   ├── create_marketing_semantic_view.sql
│   └── verified_queries/      # 35 certified VQRs across 9 business domains
│       ├── README.md
│       ├── revenue_operations/ # 7 VQRs
│       ├── ticket_sales/       # 5 VQRs
│       ├── visitor_experience/ # 2 VQRs
│       ├── retail/             # 2 VQRs
│       ├── membership/         # 3 VQRs
│       ├── campaigns/          # 1 VQR
│       ├── donor_retention/    # 5 VQRs
│       ├── capacity_planning/  # 5 VQRs
│       └── digital_marketing/  # 5 VQRs
├── macros/
│   ├── generic_tests/         # Custom test macros (3 files, 10 tests)
│   │   ├── data_quality_tests.sql
│   │   ├── generate_hashdiff.sql
│   │   └── test_hashdiff_integrity.sql
│   └── operations/            # Run-operation macros
│       ├── generate_schema_name.sql
│       ├── create_ticket_demand_forecast.sql
│       └── sync_verified_queries.sql
├── tests/
│   ├── business_rules/        # Rate bounds, no-negative checks (4 tests)
│   ├── reconciliation/        # Cross-layer count/revenue matching (6 tests)
│   └── referential_integrity/ # FK existence checks (12 tests)
├── seeds/                     # Reference data (8 CSVs)
├── snapshots/
│   ├── snap_sf_crm.sql        # SCD Type 2 for CRM contacts (hashdiff-based)
│   └── snap_dim_customer.sql  # SCD Type 2 for identity-resolved customers
└── terraform/                 # Infrastructure-as-Code
    ├── main.tf, variables.tf, outputs.tf, providers.tf
    ├── modules/               # snowflake-warehouse, key-vault, monitor-alerts, static-web-app
    ├── environments/          # dev, staging, prod tfvars
    ├── pipelines/             # deploy-dev, deploy-staging, deploy-prod
    └── notifications/         # Teams webhook setup
```

---

## Data Sources

Defined in `models/raw/sources.yml`:

| Source | Table | Description |
|--------|-------|-------------|
| bronze | `raw_pos_tickets` | POS ticket sales with phone, ticket_number, payment_method_id (574+ rows) |
| bronze | `raw_pos_retail` | Gift shop/retail with phone, product_id, payment_method_id |
| bronze | `raw_sf_crm` | Salesforce CRM contacts |
| bronze | `raw_sf_marketing_cloud` | Email campaign events |
| bronze | `raw_ticket_scans` | Gate entry scan logs |
| bronze | `raw_ticket_capacity` | Capacity by date/window/type (19,200 rows) |
| bronze | `raw_customer_identifiers` | Identity graph linking customers via email and phone across systems |
| bronze | `raw_google_analytics` | Google Analytics session-level data with traffic source attribution |
| bronze | `raw_google_ads` | Google Ads daily ad performance metrics |
| bronze | `raw_meta_ads` | Meta (Facebook/Instagram) Ads daily ad performance metrics |

All sources have:
- `not_null` and `unique` tests on primary keys
- `accepted_values` tests on type/category columns
- Column-level descriptions

---

## Data Layers

| Layer | Schema | Materialization | Strategy | Tags | Description |
|-------|--------|-----------------|----------|------|-------------|
| Staging | SILVER | View | — | daily, critical | Type casting, trimming, hashdiff computation |
| Silver | SILVER | Incremental | Merge | daily, critical | Business logic, computed columns, deduplication |
| Gold | GOLD | Incremental | Merge | daily, critical | Star schema: dimensions + facts + reports |
| ML Features | ML_FEATURES | Table | Full rebuild | daily, non-critical | Feature-engineered tables for ML models |

### on-run-start Hooks
- Source freshness check
- Circuit breaker (skippable via `--vars 'skip_circuit_breaker: true'`)

### on-run-end Hooks
- Audit log entry to `SILVER.DBT_RUN_AUDIT_LOG`

---

## Models

### Staging (9 models)

| Model | Source | Key Transformations |
|-------|--------|---------------------|
| `stg_gateway__transactions` | raw_pos_tickets | Trim, lowercase email, hashdiff, entry window mapping |
| `stg_pos_retail` | raw_pos_retail | Trim item names, lowercase email, hashdiff |
| `stg_sf_crm` | raw_sf_crm | Trim names, lowercase email, hashdiff |
| `stg_sf_marketing_cloud` | raw_sf_marketing_cloud | Trim campaign names, lowercase email, hashdiff |
| `stg_ticket_scans` | raw_ticket_scans | Hashdiff on scan attributes |
| `stg_ticket_capacity` | raw_ticket_capacity | Passthrough with hashdiff |
| `stg_google_analytics` | raw_google_analytics | Lowercase source/medium/event, hashdiff |
| `stg_google_ads` | raw_google_ads | Cost micros → dollars conversion, hashdiff |
| `stg_meta_ads` | raw_meta_ads | Lowercase platform/placement, hashdiff |

### Silver (9 models)

| Model | Key Logic |
|-------|-----------|
| `silver_pos_tickets` | Visitor category derivation (Adult/Child/Senior/Member/School Group/Family), discount flag |
| `silver_pos_retail` | Discount percentage calculation, is_discounted flag |
| `silver_sf_crm` | Computed membership status (Active/Grace Period/Expired/Lapsed), donor tier (Major/Mid-Level/Donor/Small/Non-Donor), days_since_last_visit |
| `silver_sf_marketing_cloud` | Event date extraction, is_bounced/is_unsubscribed flags |
| `silver_ticket_scans` | scan_date/scan_hour extraction, is_valid_scan derivation |
| `silver_ticket_inventory` | Capacity vs reservations join, utilization %, demand level classification |
| `silver_google_analytics` | Channel grouping derivation, page categorization, is_conversion flag |
| `silver_google_ads` | Cost per conversion, ROAS calculation, campaign categorization |
| `silver_meta_ads` | CPC, CPA, ROAS calculation, campaign categorization |

### Gold Dimensions (9 models)

| Model | Grain | Key Attributes |
|-------|-------|----------------|
| `dim_customer` | 1 row per resolved customer | Identity-resolved via email/phone graph. Supports multiple emails/phones. Segments: Known Member, Identified Visitor, Anonymous |
| `dim_date` | 1 row per day (2025-2027) | Fiscal year/quarter (July start), is_weekend, is_today, days_ago |
| `dim_campaign` | 1 row per campaign | Campaign type (Membership/Fundraising/Newsletter/Retail/Exhibition), audience size tier |
| `dim_gate` | 1 row per gate | Gate name, location, is_members_only, is_primary_entrance |
| `dim_member` | 1 row per contact | Full profile: membership status, donor tier, contact preferences |
| `dim_payment_method` | 1 row per method | Payment category (Card/Cash/Digital), is_electronic |
| `dim_product` | 1 row per SKU | Category, price tier (Premium/Mid-Range/Value), product group |
| `dim_ticket_type` | 1 row per ticket type | Visitor category, pricing tier, is_free_admission, is_special_exhibition |
| `dim_marketing_channel` | 1 row per channel | Paid/owned/earned classification, cost model, channel group |

### Gold Facts (22 models)

| Model | Grain | Key Metrics |
|-------|-------|-------------|
| `fct_ticket_sales` | **1 row per ticket barcode** | customer_id, payment_method_id, ticket_type, transaction_date + scan_date (role-playing), utilization_status, minutes_purchase_to_entry |
| `fct_retail_line_items` | **1 row per retail line item** | customer_id, product_id, payment_method_id, discount_pct |
| `fct_daily_operations` | 1 row per day | total_visitors, ticket/retail revenue, discounts, scans, gates_active |
| `fct_monthly_operations` | 1 row per fiscal month | Monthly aggregations, revenue_per_visitor, peak_day_visitors |
| `fct_visitor_traffic` | 1 row per date+hour+gate | visitors_admitted, valid/rejected scans, valid_scan_rate_pct |
| `fct_retail_performance` | 1 row per date+category | transaction_count, items_sold, gross/net revenue, discount_rate_pct |
| `fct_monthly_retail` | 1 row per month+category | Monthly retail rollups, avg_daily_revenue, avg_items_per_transaction |
| `fct_ticket_utilization` | 1 row per ticket (legacy) | was_scanned, visitors_admitted, utilization_status (superseded by fct_ticket_sales) |
| `fct_ticket_availability` | 1 row per capacity slot | Utilization %, demand level, remaining capacity |
| `fct_ticket_demand_benchmarks` | 1 row per benchmark | 90-day rolling avg/median/p25/p75/p90 with ±2σ bounds |
| `fct_campaign_performance` | 1 row per campaign | open/click/bounce/unsubscribe rates, unique recipients |
| `fct_member_360` | 1 row per contact | Unified view: tickets + retail + donations + email engagement |
| `fct_donor_retention` | 1 row per cohort+month+segment | retention_rate_pct, churn_rate_pct by cohort month, membership type, donor tier |
| `fct_donor_cohort_survival` | 1 row per cohort+period | Survival analysis with half-life detection and cohort health scoring |
| `fct_digital_ad_performance` | 1 row per campaign+adgroup+date+platform | Unified Google Ads + Meta Ads: impressions, clicks, spend, conversions, ROAS, CTR, CPC, reach, frequency |
| `fct_website_traffic` | 1 row per date+channel+campaign+page+device | GA sessions, conversions, unique users, avg duration, conversion rate |
| `fct_ad_campaign_daily` | 1 row per campaign+platform+date | Campaign-level daily summary: spend, conversions, ROAS, active ads/ad groups |
| `fct_marketing_channel_summary` | 1 row per date+channel | Unified cross-channel: impressions, clicks, spend, conversions, CPA, ROAS |
| `fct_website_funnel` | 1 row per date+channel+device | Page progression funnel, drop-off rates, conversion rates |
| `fct_marketing_sales_daily` | 1 row per date+channel | Marketing spend joined with same-day ticket + retail revenue, revenue-to-spend ratio |
| `fct_campaign_attribution` | 1 row per date+channel+source+medium+segment+membership | Session-attributed ticket and retail revenue via bridge_session_customer |
| `bridge_session_customer` | 1 row per session+customer match | Links converting GA sessions to identity-resolved customers |

### Gold Reports (9 models)

Pre-joined views optimized for dashboard consumption with full dimension attributes:

- `rpt_daily_operations` — Operations: revenue, visitors, AOV, net revenue, revenue per visitor with fiscal context
- `rpt_visitor_traffic` — Traffic: hourly gate patterns with dim_gate attributes + ticket utilization per gate
- `rpt_retail_performance` — Retail: line-item level with dim_product, dim_payment_method, dim_customer joins
- `rpt_campaign_performance` — Campaign: metrics with dim_campaign type/tier + dim_date fiscal context
- `rpt_revenue_bridge` — Weekly revenue bridge: budget vs actual, YoY comparison, component breakdown (tickets + retail), WoW change, discount impact
- `rpt_member_360` — Members: identity-resolved with ticket + retail spend from new fact tables, LTV tier
- `rpt_customer_ltv` — Unified LTV (tickets + retail + donations) with tier (Platinum/Gold/Silver/Bronze), tenure, avg spend
- `rpt_ticket_sales` — Full star-schema tickets with role-playing dates, all dim attributes joined
- `rpt_digital_marketing` — Digital marketing: ad performance + website traffic joined with fiscal date context

### ML Features (14 models)

| Model | Target Use Case | Key Features |
|-------|-----------------|--------------|
| `ml_daily_visitor_features` | Visitor forecasting | 7/30-day rolling avgs, peak hour, day-of-week, same-day-last-week lag, ad spend, web sessions |
| `ml_ticket_demand_features` | Ticket demand prediction | Demand level encoding, rolling utilization, z-scores |
| `ml_donor_churn_features` | Donor churn prediction | tenure_months, donation_velocity, recency_band, is_churned label |
| `ml_member_churn_features` | Member churn risk | days_since_last_interaction, email_click_through_rate, churn_risk_flag |
| `ml_ticket_no_show_features` | Ticket no-show prediction | Customer no-show history, ticket type base rate, purchase hour, anonymity |
| `ml_retail_cross_sell_features` | Product cross-sell | Co-occurrence matrix, Jaccard similarity, lift scores |
| `ml_email_send_time_features` | Send time optimization | Preferred open hour, hours-from-preferred distance, time buckets |
| `ml_campaign_response_features` | Campaign response scoring | Open/click rates, LTV tier, email web sessions, paid search/social signals |
| `ml_dynamic_pricing_features` | Dynamic pricing | Demand z-score, utilization band, benchmark comparison, suggested multiplier (0.85x–1.25x) |
| `ml_donor_upgrade_propensity_features` | Donor upgrade propensity | Monthly value velocity, spend-to-next-tier gap, engagement, tenure |
| `ml_visitor_forecast_training` | Visitor forecast (Snowflake ML) | Time-series format (ds/y) for FORECAST model |
| `ml_ad_budget_optimization_features` | Ad budget allocation | ROAS trends, spend share, performance tiers, budget recommendations |
| `ml_marketing_attribution_features` | Multi-touch attribution | First/last touch channels, conversion paths, days to convert, path length tiers |
| `ml_ad_creative_features` | Creative performance | CTR/ROAS rolling avgs, cumulative efficiency, performance tiers by placement |

---

## Testing Strategy

### Schema Tests (~250)

Applied via `schema.yml` files at each layer:
- `not_null` / `unique` on all primary keys
- `accepted_values` on categorical columns (ticket types, membership statuses, donor tiers)
- Custom generics: `hashdiff_integrity`, `late_arriving_data`, `daily_volume_bounds`, `cardinality_change`, `distribution_shift`, `z_score_outlier`, `positive_value`, `value_between`, `null_rate_threshold`

### Data Quality Tests

| Test Macro | Purpose | Severity |
|------------|---------|----------|
| `hashdiff_integrity` | Detects hash collisions vs true duplicates | warn on retail/marketing |
| `late_arriving_data` | Alerts if data > 72h old arrives | warn |
| `daily_volume_bounds` | Flags days with too few/many rows | error |
| `cardinality_change` | Detects unexpected new categories | error |
| `distribution_shift` | Identifies statistical distribution changes | warn |
| `z_score_outlier` | Flags values > 3σ from mean | warn |

### Business Rule Tests (4)

| Test | Validates |
|------|-----------|
| `assert_gold_campaign_rates_valid` | No rate > 100% (open, bounce, unsub, CTO) |
| `assert_gold_daily_ops_no_negative_revenue` | total_revenue >= 0 |
| `assert_gold_member_no_negative_ltv` | total_lifetime_value >= 0 |
| `assert_gold_ops_covers_all_scan_dates` | Daily ops has rows for every scan date |

### Reconciliation Tests (6)

| Test | Validates |
|------|-----------|
| `assert_silver_bronze_retail_count_match` | Silver row count = Bronze row count |
| `assert_silver_bronze_ticket_count_match` | Silver row count = Bronze row count |
| `assert_silver_bronze_scan_count_match` | Silver row count = Bronze row count |
| `assert_retail_revenue_reconciles` | Silver retail total ≈ Gold daily ops retail (±$10) |
| `assert_ticket_revenue_reconciles` | Silver ticket total ≈ Gold daily ops tickets (±$1) |
| `assert_visitor_count_reconciles` | Silver valid scans = Gold total_visitors (exact) |

### Referential Integrity Tests (12)

| Test | Validates |
|------|-----------|
| `assert_campaign_fk_integrity` | All fact campaign_ids exist in dim_campaign |
| `assert_gold_daily_ops_no_orphan_dates` | All ops dates have corresponding silver data |
| `assert_member360_emails_exist_in_crm` | All gold emails exist in silver CRM |
| `assert_member360_no_orphan_contacts` | All gold contacts exist in silver CRM |
| `assert_payment_methods_exist_in_dim` | All ticket payment methods are in dim |
| `assert_payment_methods_match_seed` | Payment method IDs exist in ref_payment_methods seed |
| `assert_products_exist_in_dim` | All retail SKUs are in dim_product |
| `assert_scan_gates_exist_in_dim` | All scan gate_ids are in dim_gate |
| `assert_ticket_types_exist_in_dim` | All ticket types are in dim_ticket_type |
| `assert_ticket_types_match_seed` | Ticket types exist in ref_ticket_types seed |
| `assert_customer_segments_match_seed` | Customer segments exist in ref_customer_segments seed |
| `assert_ltv_tiers_match_seed` | LTV tiers exist in ref_ltv_tiers seed |

---

## Macros

### Generic Tests (`macros/generic_tests/`)

| Macro | Purpose |
|-------|--------|
| `data_quality_tests.sql` | 8 reusable tests: z_score_outlier, positive_value, value_between, null_rate_threshold, late_arriving_data, daily_volume_bounds, cardinality_change, distribution_shift |
| `generate_hashdiff.sql` | Generates MD5 hashdiff column from a list of columns with null-safe concatenation |
| `test_hashdiff_integrity.sql` | Validates hashdiff columns for collisions and null hashes |

### Operations (`macros/operations/`)

| Macro | Purpose |
|-------|--------|
| `generate_schema_name.sql` | Custom schema routing using model config rather than appending to target schema |
| `create_ticket_demand_forecast.sql` | Creates Snowflake ML FORECAST model for 90-day ticket demand prediction |
| `sync_verified_queries.sql` | Lists and validates all verified queries for semantic view integration |

```bash
dbt run-operation create_ticket_demand_forecast
dbt run-operation sync_verified_queries
```

---

## Snapshots

### `snap_sf_crm`
- **Strategy:** Check (on `hashdiff` column)
- **Unique key:** `contact_id`
- **Target schema:** SILVER
- **Purpose:** Track SCD Type 2 changes to CRM contacts (membership status changes, donation updates, etc.)

### `snap_dim_customer`
- **Strategy:** Check (on `customer_segment`, `membership_type`, `membership_status`, `primary_email`, `primary_phone`, `email_count`, `phone_count`)
- **Unique key:** `customer_id`
- **Target schema:** SILVER
- **Purpose:** Track SCD Type 2 changes to identity-resolved customer dimension (segment changes, membership transitions)

---

## Incremental Strategy

All incremental models use **merge** strategy:

| Layer | Unique Key Pattern | Merge Behavior |
|-------|-------------------|----------------|
| Silver | Source primary key (e.g., `transaction_id`) | Update existing, insert new |
| Gold Facts | Composite keys (e.g., `visit_date`, `date+category`) | Update existing, insert new |
| Gold Dims | Dimension key (e.g., `gate_id`, `product_id`) | Full rebuild (no incremental) |

**Schema change policy:** `append_new_columns` (new source columns are added automatically)

---

## Access Control & Grants

### Roles

| Role | Purpose | Warehouses |
|------|---------|-----------|
| **ACCOUNTADMIN** | Full account administration. Manages all aspects of the Snowflake account including billing, resource monitors, and security integrations. Top-level role. | All |
| **ORGADMIN** | Organization-level administration. Manages accounts within the Snowflake organization. | — |
| **SECURITYADMIN** | Security administration. Manages grants, role hierarchy, and network policies. Parent of USERADMIN. | — |
| **USERADMIN** | User and role management. Creates and manages users and custom roles. | — |
| **SYSADMIN** | System administration. Creates and manages databases, warehouses, and other account objects. Parent of all custom roles. | All |
| **PUBLIC** | Default role granted to every user. Minimal privileges. | — |
| **TRANSFORMER_ROLE** | dbt development. Full read/write access to `NS11MM_DW_DEV` (all schemas: BRONZE, SILVER, GOLD, ML_FEATURES, PUBLIC). Owns all dbt-created objects in dev. | COMPUTE_WH, DBT_DEV_WH |
| **TRANSFORMER_ROLE** | dbt production builds. Full read/write access to `NS11MM_DW_PROD` (all schemas). Owns all dbt-created objects in prod. | DBT_PROD_WH |
| **POWERBI_ROLE** | Read-only reporting for Power BI dashboards. No write access anywhere. | COMPUTE_WH, DBT_PROD_WH, MONITORING_WH |
| **ML_ROLE** | ML engineering. Read access to Silver/Gold layers; full read/write to `ML_FEATURES` schema. Can create Snowflake ML models (FORECAST, ANOMALY_DETECTION). | COMPUTE_WH, ML_STUDIO_WH, MONITORING_WH |

### Role Hierarchy

```
ACCOUNTADMIN
├── SECURITYADMIN
│   └── USERADMIN
├── SYSADMIN
│   ├── TRANSFORMER_ROLE
│   ├── TRANSFORMER_ROLE
│   ├── POWERBI_ROLE
│   └── ML_ROLE
└── ORGADMIN
```

### Role Access Matrix

| Database.Schema | TRANSFORMER_ROLE | TRANSFORMER_ROLE | POWERBI_ROLE | ML_ROLE |
|-----------------|:------------:|:-------------:|:------------:|:-------:|
| **NS11MM_DW_DEV.RAW** | Read/Write | — | — | — |
| **NS11MM_DW_DEV.INTERMEDIATE** | Read/Write | — | — | — |
| **NS11MM_DW_DEV.MARTS** | Read/Write | — | Read | Read |
| **NS11MM_DW_DEV.ML_FEATURES** | Read/Write | — | — | Read |
| **NS11MM_DW_PROD.RAW** | — | Read/Write | — | — |
| **NS11MM_DW_PROD.INTERMEDIATE** | — | Read/Write | — | Read |
| **NS11MM_DW_PROD.MARTS** | — | Read/Write | Read | Read |
| **NS11MM_DW_PROD.ML_FEATURES** | — | Read/Write | — | Read/Write |

### POWERBI_ROLE Details

- **Read:** All tables in `NS11MM_DW_PROD.MARTS` (dims, facts, reports, seeds), plus monitoring views (`V_BUILD_HISTORY`, `V_DATA_SOURCE_STATUS`, `V_PIPELINE_HEALTH`, `V_SLA_COMPLIANCE`, `V_SOURCE_FRESHNESS_HISTORY`)
- **Read:** All tables in `NS11MM_DW_DEV.MARTS` (for dev dashboard testing)
- **Read:** Semantic views `SV_MUSEUM_OPERATIONS`, `SV_DONOR_RETENTION`
- **Write:** None

### ML_ROLE Details

- **Read:** All Silver tables/views (staging views + incremental tables) in PROD
- **Read:** All Gold tables in both DEV and PROD
- **Read/Write:** All ML_FEATURES tables in PROD (INSERT, UPDATE, DELETE, TRUNCATE)
- **Create:** FORECAST and ANOMALY_DETECTION models in DEV and PROD MARTS schemas
- **Read:** Monitoring views in PROD GOLD

### dbt Post-Hook Grants

Configured via `dbt_project.yml` post-hooks:

| Layer | Grants |
|-------|--------|
| Gold (all) | `GRANT SELECT ON {{ this }} TO ROLE POWERBI_ROLE` |
| Gold (all) | `GRANT SELECT ON {{ this }} TO ROLE ML_ROLE` |
| ML Features | `GRANT SELECT ON {{ this }} TO ROLE ML_ROLE` |

Additional:
- `+copy_grants: true` on Silver and Gold ensures grants survive incremental rebuilds
- `+persist_docs: relation: true, columns: true` pushes descriptions to Snowflake metadata

---

## Environments

| Target | Database | Warehouse | Role | Threads |
|--------|----------|-----------|------|---------|
| dev | NS11MM_DW_DEV | DBT_DEV_WH | TRANSFORMER_ROLE | 4 |
| staging | NS11MM_DW_STAGING | DBT_PROD_WH | TRANSFORMER_ROLE | 8 |
| prod | NS11MM_DW_PROD | DBT_PROD_WH | TRANSFORMER_ROLE | 8 |

### Session Configuration
- `STATEMENT_TIMEOUT_IN_SECONDS = 3600` (default)
- `STATEMENT_TIMEOUT_IN_SECONDS = 300` (models tagged `intraday`)

---

## CI/CD Pipeline

### GitHub Actions (`.github/workflows/dbt-ci.yml`)

Triggers on PRs to `main` that touch model/macro/test files.

**Pipeline steps:**
1. Checkout PR branch + main branch (for state comparison)
2. Install dbt + dependencies
3. `dbt build --select state:modified+` — only builds/tests changed models and their downstream dependents
4. Fail the PR if any test errors occur

### Slim CI
Uses dbt state artifacts from `main` branch to identify modified models. Only changed models (and their children) are built and tested, keeping CI fast.

---

## Getting Started

### Prerequisites
- Snowflake account with `TRANSFORMER_ROLE` access
- dbt installed (or use VS Code)

### Commands

```bash
# Install packages
dbt deps

# Run all models (dev target)
dbt build

# Run specific layer
dbt run --select staging+
dbt run --select tag:daily
dbt run --select gold.facts

# Run a single model + downstream
dbt build --select fct_daily_operations+

# Run tests only
dbt test

# Full refresh (rebuild all incremental models from scratch)
dbt build --full-refresh

# Skip circuit breaker (for testing)
dbt build --vars 'skip_circuit_breaker: true'

# Generate and serve docs
dbt docs generate
dbt docs serve
```

---

## Common Operations

### Train ticket demand forecast model
```bash
dbt run-operation create_ticket_demand_forecast
```

### Run only ML features
```bash
dbt run --select ml_features
```

### Rebuild a single silver model from scratch
```bash
dbt run --select silver_pos_tickets --full-refresh
```

### Run reconciliation tests
```bash
dbt test --select test_type:singular
```

---

## Deployment

Production deployment uses Snowflake's native dbt integration:

```sql
-- Deploy project
-- Deploy via: dbt run --target prod
  FROM 'snow://workspace/USER$.PUBLIC."ns11mm-data-platform"/versions/live/'
  ...;

-- Execute build
EXECUTE DBT PROJECT ns11mm_data_platform
  TARGET = 'prod'
  COMMAND = 'build';
```

Or via Snowflake CLI:
```bash
snow dbt deploy --project-dir . --connection prod
```

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## Semantic Views (4)

Four semantic views provide self-service analytics via Cortex Analyst and Power BI Semantic Views connector:

### `NS11MM_DW_PROD.MARTS.SV_MUSEUM_OPERATIONS`

Day-to-day operations, revenue, and customer analytics.

- **13 entities:** ticket_sales, retail_items, campaigns, daily_ops, traffic, customer_ltv, dates, customers, dim_gate, dim_campaign, dim_ticket_type, dim_product, dim_payment_method
- **16 relationships** including role-playing dates (transaction_date + scan_date → dates)
- **35 metrics** with formatting hints (USD/percentage/count)
- **6 verified queries**
- **Identity resolution:** customers merged by shared email OR phone
- **Cross-entity LTV:** tickets + retail share customer_id

### `NS11MM_DW_PROD.MARTS.SV_DONOR_RETENTION`

Donor lifecycle analytics and ticket capacity planning.

- **6 entities:** retention, survival, availability, benchmarks, dates, dim_ticket_type
- **16 metrics** covering retention rates, survival curves, capacity utilization, demand benchmarks
- **4 verified queries**

### `NS11MM_DW_PROD.MARTS.SV_MARKETING_PERFORMANCE`

Digital marketing performance across paid advertising, email campaigns, and website analytics.

- **6 entities:** ad_performance (Google Ads + Meta Ads), website_traffic (Google Analytics), email_campaigns (SFMC), channel_summary, channels (dim), dates
- **21 metrics** covering impressions, clicks, spend, conversions, ROAS, CTR, CPC, reach, frequency, sessions, email open/click/bounce rates
- **17 dimensions:** ad platform, campaign category, channel grouping, page category, device, placement, channel group (paid/owned/earned)
- **5 verified queries** (ROAS by platform, top campaigns, weekend vs weekday CTR, cross-channel comparison, website funnel)
- **AI instructions:** Rounds to 2 decimal places, splits platforms, uses fiscal year by default
- **DDL location:** `analyses/create_marketing_semantic_view.sql`

### `NS11MM_DW_PROD.MARTS.SV_MARKETING_SALES`

Marketing-to-sales attribution connecting channel spend to actual ticket and retail revenue.

- **2 entities:** marketing_sales (fct_marketing_sales_daily), campaign_attribution (fct_campaign_attribution)
- **14 metrics** covering spend, impressions, ticket revenue, retail revenue, attributed revenue, ROAS, CTR
- **12 dimensions:** date, channel, customer segment, membership type, source, medium, fiscal year
- **AI instructions:** Combines marketing spend with same-day transaction-level attributed revenue

### Access

All views are accessible to `POWERBI_ROLE` for the Power BI Semantic Views connector.

---

## Cortex Agent

`NS11MM_DW_PROD.MARTS.MUSEUM_OPERATIONS_AGENT` provides natural language analytics with full observability.

**Tools:**
- `MUSEUM_OPERATIONS_DATA` → `SV_MUSEUM_OPERATIONS` (operations, revenue, customers)
- `DONOR_RETENTION_DATA` → `SV_DONOR_RETENTION` (retention, capacity)

**Observability:**
- All questions, generated SQL, and results are logged via `GET_AI_OBSERVABILITY_EVENTS`
- Unredacted content access granted for full audit trail
- Query: `SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS('NS11MM_DW_PROD', 'GOLD', 'MUSEUM_OPERATIONS_AGENT', 'CORTEX AGENT'))`

**Automated Gap Detection:**
- `MONITORING.TASK_AGENT_PATTERN_ANALYSIS` runs daily at 8 AM ET
- Clusters questions by topic, detects unanswered patterns
- Alerts via email when coverage gaps exceed thresholds (>50% failure = HIGH)
- Results stored in `MONITORING.AGENT_QUESTION_PATTERNS`

---

## Verified Query Framework

Certified queries live in `analyses/verified_queries/` organized by business domain. Each domain folder contains:
- `_verified_queries.yml` — governance metadata (owner, ADR ref, approval, tags, PBI datasets)
- `*.sql` — the verified query SQL using `SEMANTIC_VIEW()` syntax

**35 certified VQRs** across 9 domains, synced to semantic views.

**Governance fields:**
```yaml
- stakeholder_owner    # Business owner
- adm_reference        # Architecture decision record
- approved_by          # Approver username
- approved_date        # Approval date
- tags                 # Searchable tags (certified, action_required, etc.)
- power_bi_datasets    # Which PBI datasets consume this
```

**Commands:**
- `dbt run-operation sync_verified_queries` — list and validate all certified VQRs
- `dbt compile` — validates SQL files parse correctly

---

## Governance

| Document | Purpose |
|----------|---------|
| [CHANGELOG.md](CHANGELOG.md) | Release history with model/test counts per version |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branching strategy, PR process, commit conventions |
| [CODEOWNERS](CODEOWNERS) | PR approval routing by file path |

### Code Ownership
All files currently owned by `@jwmyers82`. See CODEOWNERS for per-path routing.

### Query Tags
All models emit query tags for Snowflake query history filtering:
- `dbt_ns11mm_staging`
- `dbt_ns11mm_silver`
- `dbt_ns11mm_gold`
- `dbt_ns11mm_ml_features`
- `dbt_ns11mm_snapshots`

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide. Summary:

1. Create a short-lived feature branch from `main`
2. Develop in your personal dev workspace (`NS11MM_DW_DEV_<USERNAME>`)
3. Run `dbt build` to verify
4. Push and open a PR — CI will run slim builds
5. Get review, merge to `main`
6. Deploy to prod via `CREATE DBT PROJECT`

---

## Model Lineage

### Full DAG Overview

```
RAW SOURCES          STAGING              SILVER                    GOLD                         ML FEATURES / REPORTS
──────────────          ───────              ──────                    ────                         ─────────────────────

raw_pos_tickets    →  stg_gateway__transactions    →  silver_pos_tickets    →  fct_daily_operations      →  rpt_daily_operations
                                                                  →  fct_ticket_utilization        ml_daily_visitor_features
                                                                  →  dim_ticket_type
                                                                  →  dim_payment_method

raw_pos_retail     →  stg_pos_retail     →  silver_pos_retail     →  fct_daily_operations      →  rpt_retail_performance
                                                                  →  fct_retail_performance    →  fct_monthly_retail
                                                                  →  dim_product
                                                                  →  dim_payment_method

raw_sf_crm         →  stg_sf_crm        →  silver_sf_crm         →  fct_member_360            →  rpt_member_360
                                          → snap_sf_crm           →  fct_donor_retention           ml_donor_churn_features
                                                                  →  fct_donor_cohort_survival     ml_member_churn_features
                                                                  →  dim_member

raw_sf_marketing   →  stg_sf_marketing   →  silver_sf_marketing   →  fct_campaign_performance  →  rpt_campaign_performance
_cloud                _cloud                _cloud                →  dim_campaign

raw_ticket_scans   →  stg_ticket_scans   →  silver_ticket_scans   →  fct_daily_operations      →  rpt_visitor_traffic
                                                                  →  fct_visitor_traffic           ml_daily_visitor_features
                                                                  →  fct_ticket_utilization
                                                                  →  dim_gate

raw_ticket_        →  stg_ticket_        →  silver_ticket_        →  fct_ticket_availability   →  fct_ticket_demand_benchmarks
capacity              capacity              inventory                                              ml_ticket_demand_features
```

### Per-Model Lineage (Upstream → Model → Downstream)

#### Staging
| Model | Upstream (Source) | Downstream |
|-------|-------------------|------------|
| `stg_gateway__transactions` | `bronze.raw_pos_tickets` | silver_pos_tickets |
| `stg_pos_retail` | `bronze.raw_pos_retail` | silver_pos_retail |
| `stg_sf_crm` | `bronze.raw_sf_crm` | silver_sf_crm, snap_sf_crm |
| `stg_sf_marketing_cloud` | `bronze.raw_sf_marketing_cloud` | silver_sf_marketing_cloud |
| `stg_ticket_scans` | `bronze.raw_ticket_scans` | silver_ticket_scans |
| `stg_ticket_capacity` | `bronze.raw_ticket_capacity` | silver_ticket_inventory |

#### Silver
| Model | Upstream | Downstream |
|-------|----------|------------|
| `silver_pos_tickets` | stg_gateway__transactions | fct_daily_operations, fct_ticket_utilization, dim_ticket_type, dim_payment_method |
| `silver_pos_retail` | stg_pos_retail | fct_daily_operations, fct_retail_performance, dim_product, dim_payment_method |
| `silver_sf_crm` | stg_sf_crm | fct_member_360, fct_donor_retention, fct_donor_cohort_survival, dim_member, ml_donor_churn_features |
| `silver_sf_marketing_cloud` | stg_sf_marketing_cloud | fct_campaign_performance |
| `silver_ticket_scans` | stg_ticket_scans | fct_daily_operations, fct_visitor_traffic, fct_ticket_utilization, dim_gate |
| `silver_ticket_inventory` | stg_ticket_capacity, stg_gateway__transactions | fct_ticket_availability |

#### Gold Dimensions
| Model | Upstream | Downstream |
|-------|----------|------------|
| `dim_date` | (generated) | fct_monthly_operations, fct_monthly_retail, fct_ticket_availability, fct_donor_retention, fct_donor_cohort_survival, ml_daily_visitor_features, ml_ticket_demand_features, all rpt_* models |
| `dim_campaign` | fct_campaign_performance | (terminal — consumed by BI tools) |
| `dim_gate` | silver_ticket_scans | (terminal — consumed by BI tools) |
| `dim_member` | silver_sf_crm | (terminal — consumed by BI tools) |
| `dim_payment_method` | silver_pos_tickets, silver_pos_retail | (terminal — consumed by BI tools) |
| `dim_product` | silver_pos_retail | (terminal — consumed by BI tools) |
| `dim_ticket_type` | silver_pos_tickets | (terminal — consumed by BI tools) |

#### Gold Facts
| Model | Upstream | Downstream |
|-------|----------|------------|
| `fct_daily_operations` | silver_pos_tickets, silver_ticket_scans, silver_pos_retail | fct_monthly_operations, rpt_daily_operations, ml_daily_visitor_features |
| `fct_monthly_operations` | fct_daily_operations, dim_date | (terminal — BI) |
| `fct_visitor_traffic` | silver_ticket_scans | rpt_visitor_traffic, ml_daily_visitor_features |
| `fct_retail_performance` | silver_pos_retail | fct_monthly_retail, rpt_retail_performance |
| `fct_monthly_retail` | fct_retail_performance, dim_date | (terminal — BI) |
| `fct_ticket_utilization` | silver_pos_tickets, silver_ticket_scans | (terminal — BI) |
| `fct_ticket_availability` | silver_ticket_inventory, dim_date | fct_ticket_demand_benchmarks, ml_ticket_demand_features |
| `fct_ticket_demand_benchmarks` | fct_ticket_availability | (terminal — Snowflake ML FORECAST input) |
| `fct_campaign_performance` | silver_sf_marketing_cloud | dim_campaign, rpt_campaign_performance |
| `fct_member_360` | silver_sf_crm, silver_pos_tickets, silver_pos_retail, silver_sf_marketing_cloud | rpt_member_360, ml_donor_churn_features, ml_member_churn_features |
| `fct_donor_retention` | silver_sf_crm, dim_date | (terminal — BI) |
| `fct_donor_cohort_survival` | silver_sf_crm, dim_date | (terminal — BI) |

#### ML Features
| Model | Upstream | Downstream / Output Target |
|-------|----------|---------------------------|
| `ml_daily_visitor_features` | fct_daily_operations, fct_visitor_traffic, dim_date | → `ML_FEATURES.ml_daily_visitor_features` → Snowflake ML FORECAST (visitor predictions) |
| `ml_ticket_demand_features` | fct_ticket_availability, dim_date | → `ML_FEATURES.ml_ticket_demand_features` → Snowflake ML FORECAST (ticket demand predictions) |
| `ml_donor_churn_features` | fct_member_360, silver_sf_crm | → `ML_FEATURES.ml_donor_churn_features` → Classification model (donor churn) |
| `ml_member_churn_features` | fct_member_360 | → `ML_FEATURES.ml_member_churn_features` → Classification model (member churn risk) |

#### Reports (output to Power BI / Snowsight)
| Model | Upstream | Output Table |
|-------|----------|--------------|
| `rpt_daily_operations` | fct_daily_operations, dim_date | → `GOLD.rpt_daily_operations` |
| `rpt_visitor_traffic` | fct_visitor_traffic, dim_date | → `GOLD.rpt_visitor_traffic` |
| `rpt_retail_performance` | fct_retail_performance, dim_date | → `GOLD.rpt_retail_performance` |
| `rpt_campaign_performance` | fct_campaign_performance | → `GOLD.rpt_campaign_performance` |
| `rpt_member_360` | fct_member_360 | → `GOLD.rpt_member_360` |
