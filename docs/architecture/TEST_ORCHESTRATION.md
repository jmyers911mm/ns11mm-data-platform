# Test Orchestration & Alert Routing

> **Current scope (July 2026):** Gateway (ticketing) and CounterPoint (retail POS)
> sources are connected, feeding the Daily Performance Report and ticket demand
> forecasting models. Other sources and domains described below are part of the
> target design but are currently disabled / not yet ingested.

> **Source of truth:** `ns11mm/ns11mm-data-platform`  
> **Last updated:** July 2026  ·  Jeremy Myers, VP of AI & Analytics  
> **Legend:** `┌─┐` pipeline step  `╔═╗` custom test gate  `░░` disabled/future

```

┌─────────────────────────────────────────────────────────────────────────────┐
│         NS11MM DATA PLATFORM  ·  Test Orchestration & Alert Routing         │
│              Source Clustering  ·  Test Triggers  ·  Outcomes               │
└─────────────────────────────────────────────────────────────────────────────┘


 ══════════════════════════════════════════════════════════════════════════════
  SECTION 1  ·  SOURCE CLUSTERS & FRESHNESS THRESHOLDS
 ══════════════════════════════════════════════════════════════════════════════

 ┌────────────────────────────┐ ┌─────────────────────┐ ┌──────────────────┐
 │  TICKETING & OPERATIONS    │ │░░CRM & FUNDRAISING░░│ │░░DIGITAL &░░░░░░░│
 │  ✓ ENABLED                 │ │░░NOT YET CONNECTED░░│ │░░MARKETING░░░░░░░│
 │                            │ │                      │ │░░NOT CONNECTED░░░│
 │  stg_gateway_* (16 views)  │ │  raw_salesforce_*    │ │                  │
 │  stg_counterpoint_* (5)    │ │  raw_classy_*        │ │  raw_ga4_*       │
 │                            │ │  raw_blackbaud_nxt_* │ │  raw_google_ads_*│
 │  Freshness SLA             │ │                      │ │  raw_meta_ads_*  │
 │  warn  >  3 hours          │ │  Freshness SLA       │ │                  │
 │  error >  6 hours          │ │  warn  > 3 hours     │ │  Freshness SLA   │
 │                            │ │  error > 6 hours     │ │  warn  > 4 hrs   │
 │  High-frequency ops data   │ │                      │ │  error > 8 hrs   │
 │  drives capacity planning  │ │                      │ │                  │
 │  & Cortex agent            │ │                      │ │                  │
 └────────────────────────────┘ └─────────────────────┘ └──────────────────┘
          │
          │  (only Gateway + CounterPoint connected today)
          │
          ▼

                         2 sources land in
                         NS11MM_DW_DEV.RAW (immutable)
                                         │
                                         ▼


 ══════════════════════════════════════════════════════════════════════════════
  SECTION 2  ·  TEST TRIGGER SEQUENCE
 ══════════════════════════════════════════════════════════════════════════════

  Snowflake Workspace  ·  EXECUTE DBT PROJECT
  trigger: manual via workspace   ·   scheduled via Snowflake Task (prod)
                                   │
                                   ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 1  ·  dbt source freshness                                        │
 │  evaluates loaded_at_field on Gateway + CounterPoint source tables      │
 │  per-cluster thresholds defined in sources.yml                          │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 2  ·  dbt build → STAGING  (21 stg_ views)                       │
 │  16 gateway + 5 counterpoint staging models                             │
 │  generic tests per model:                                               │
 │    unique + not_null on all PKs                                         │
 │    accepted_values on categorical columns                               │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 3  ·  dbt build → INTERMEDIATE  (13 int_ models)                 │
 │  incremental merge models:                                              │
 │    int_gateway__item_journal_lines                                      │
 │    int_gateway__ticket_journal_lines                                    │
 │    int_gateway__ticket_demand_features                                  │
 │    int_pos_tickets                                                      │
 │    int_ticket_inventory                                                 │
 │    int_ticket_scans                                                     │
 │    int_counterpoint__retail_lines                                       │
 │    int_dpr__admissions / attendance / donations / fees / retail / tours │
 │  generic tests: unique + not_null on all PKs, accepted_values          │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE A  ·  RECONCILIATION  ·  2 tests enabled                    ║
 ║  severity: error  ·  store_failures: true                              ║
 ║                                                                         ║
 ║  ✓ assert_raw_silver_ticket_count_match                                 ║
 ║  ✓ assert_silver_gold_revenue_reconciliation                            ║
 ║                                                                         ║
 ║  DISABLED (future):                                                     ║
 ║  ░ assert_raw_silver_retail_count_match                                 ║
 ║  ░ assert_silver_gold_visitor_reconciliation                            ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                              FAIL
         │                                    failing rows → quarantine
         │                                    pipeline halts → Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 4  ·  dbt build → MARTS DIMENSIONS  (1 enabled)                   │
 │                                                                         │
 │  ✓ dim_date                                                             │
 │                                                                         │
 │  DISABLED (8): dim_budget_version, dim_campaign, dim_customer,          │
 │    dim_fund, dim_gate, dim_marketing_channel, dim_payment_method,       │
 │    dim_product, dim_ticket_type                                         │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 5  ·  dbt build → MARTS FACTS  (4 enabled)                        │
 │                                                                         │
 │  ✓ fct_daily_operations                                                 │
 │  ✓ fct_daily_performance                                                │
 │  ✓ fct_ticket_availability                                              │
 │  ✓ fct_ticket_demand_forecast                                           │
 │                                                                         │
 │  DISABLED (20): fct_ad_campaign_daily, fct_campaign_attribution,        │
 │    fct_campaign_performance, fct_digital_ad_performance,                │
 │    fct_donor_cohort_survival, fct_donor_retention, fct_fundraising,     │
 │    fct_gl_transactions, fct_marketing_channel_summary,                  │
 │    fct_marketing_sales_daily, fct_monthly_operations,                   │
 │    fct_monthly_retail, fct_retail_line_items,                            │
 │    fct_ticket_demand_benchmarks, fct_ticket_sales,                      │
 │    fct_ticket_utilization, fct_visitor_traffic, fct_website_funnel,     │
 │    fct_website_traffic, bridge_session_customer                         │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE B  ·  REFERENTIAL INTEGRITY  ·  1 test enabled              ║
 ║  severity: error  ·  store_failures: true                               ║
 ║                                                                         ║
 ║  ✓ assert_gold_daily_ops_no_orphan_dates                                ║
 ║                                                                         ║
 ║  DISABLED (4, require dims not yet enabled):                            ║
 ║  ░ assert_campaign_fk_integrity                                         ║
 ║  ░ assert_customer_segments_match_seed                                  ║
 ║  ░ assert_payment_methods_match_seed                                    ║
 ║  ░ assert_ticket_types_match_seed                                       ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                              FAIL
         │                                    failing rows → quarantine
         │                                    pipeline halts → Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 6  ·  dbt build → MARTS REPORTS  (1 enabled)                      │
 │                                                                         │
 │  ✓ rpt_daily_performance_report                                         │
 │                                                                         │
 │  DISABLED (8): rpt_campaign_performance, rpt_customer_ltv,              │
 │    rpt_daily_operations, rpt_digital_marketing, rpt_member_360,         │
 │    rpt_retail_performance, rpt_revenue_bridge, rpt_ticket_sales,        │
 │    rpt_visitor_traffic                                                   │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE C  ·  BUSINESS RULES  ·  5 tests enabled                    ║
 ║  severity: error  ·  store_failures: true                               ║
 ║                                                                         ║
 ║  ✓ alert_null_primary_keys_in_raw                                       ║
 ║  ✓ assert_critical_tables_not_empty                                     ║
 ║  ✓ assert_date_coverage                                                 ║
 ║  ✓ assert_no_future_tickets                                             ║
 ║  ✓ assert_no_negative_revenue                                           ║
 ║                                                                         ║
 ║  DISABLED (2):                                                          ║
 ║  ░ assert_campaign_rates_in_bounds                                      ║
 ║  ░ assert_no_future_transactions                                        ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                              FAIL
         │                                    failing rows → quarantine
         │                                    pipeline halts → Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 7  ·  dbt build → ML_FEATURES  (2 models)                        │
 │                                                                         │
 │  ✓ ml_ticket_demand_features                                            │
 │  ✓ ml_visitor_forecast_training                                         │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  SEEDS  (3 reference tables)                                            │
 │                                                                         │
 │  ✓ seed_tour_plu            → RAW schema                                │
 │  ✓ seed_retail_item_facility                                            │
 │  ✓ seed_retail_store_facility                                           │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  PIPELINE COMPLETE                                                      │
 │  Power BI refresh proceeds  ·  Cortex Semantic Views available          │
 │  ML_FEATURES models run  ·  Cortex Agent query surface live             │
 └─────────────────────────────────────────────────────────────────────────┘


 ══════════════════════════════════════════════════════════════════════════════
  SECTION 3  ·  OUTCOME DECISION TREE
 ══════════════════════════════════════════════════════════════════════════════

 ┌─────────────────────────────────────────────────────────────────────────┐
 │  PASS                                                                   │
 │  Pipeline continues  ·  no action required                              │
 └─────────────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────────────┐
 │  WARN  (severity: warn)                                                 │
 │                                                                         │
 │  ①  Pipeline continues — non-blocking                                   │
 │  ②  Failing rows written → dbt_test__audit schema (Snowflake)          │
 │  ③  Cortex observability log entry created, tagged: WARN                │
 │  ④  Hub Incident Log: Priority 3 / Normal  ·  SLA: resolve in 168 h   │
 │  ⑤  Notification posted to #data-alerts channel                        │
 │  ⑥  Owner reviews at next business day standup                         │
 └─────────────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────────────┐
 │  ERROR / FAIL  (severity: error)                                        │
 │                                                                         │
 │  ①  dbt exits with code 1  ·  pipeline halts immediately               │
 │  ②  Failing rows written → dbt_test__audit schema  (quarantine)        │
 │  ③  Cortex observability log entry created, tagged: ERROR               │
 │  ④  Hub Incident Log opened with priority by test gate:                │
 │                                                                         │
 │      Source freshness fail   →  P1 Critical  ·  SLA: resolve in 24 h  │
 │      Gate A  reconciliation  →  P1 Critical  ·  SLA: resolve in 24 h  │
 │      Gate B  ref. integrity  →  P2 High      ·  SLA: resolve in 72 h  │
 │      Gate C  business rules  →  P2 High      ·  SLA: resolve in 72 h  │
 │      Generic model test      →  P2 High      ·  SLA: resolve in 72 h  │
 │                                                                         │
 │  ⑤  Owner paged immediately  ·  SLA clock starts on incident open      │
 │  ⑥  Downstream blocked: Power BI refresh held · Cortex paused          │
 └─────────────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────────────┐
 │  QUARANTINE  ·  dbt_test__audit schema in Snowflake                     │
 │                                                                         │
 │  Activated by: store_failures: true on all custom test gates            │
 │  Stores the exact failing rows for every test that does not pass        │
 │  Enables root-cause query without re-running the pipeline               │
 │                                                                         │
 │  Naming pattern:                                                        │
 │    dbt_test__audit.assert_<test_name>                                   │
 │    dbt_test__audit.not_null_<model>_<column>                            │
 │    dbt_test__audit.unique_<model>_<column>                              │
 └─────────────────────────────────────────────────────────────────────────┘


 ══════════════════════════════════════════════════════════════════════════════
  SECTION 4  ·  INVESTIGATION PATHS  (after ERROR / FAIL)
 ══════════════════════════════════════════════════════════════════════════════

 ┌───────────────────────────────┐    ┌──────────────────────────────────┐
 │  SOURCE / FRESHNESS ISSUE     │    │  MODEL / LOGIC ISSUE             │
 │                               │    │                                  │
 │  upstream delay, source drop, │    │  schema drift from source,       │
 │  or ingestion pipeline fault  │    │  business rule change, FK break, │
 │                               │    │  or seed table mismatch          │
 │  ① notify source system owner │    │                                  │
 │  ② hold pipeline              │    │  ① fix in workspace              │
 │  ③ re-trigger after upstream  │    │  ② re-run dbt build              │
 │    fix is confirmed           │    │  ③ verify tests pass             │
 │  ④ resolve Hub incident       │    │  ④ resolve Hub incident          │
 │  ⑤ document in runbook        │    │  ⑤ document in runbook           │
 └───────────────────────────────┘    └──────────────────────────────────┘

```


 ## Summary of Enabled Assets (July 2026)

 | Layer         | Enabled | Disabled | Notes                              |
 |---------------|---------|----------|------------------------------------|
 | Sources       | 2       | ~12      | Gateway + CounterPoint only        |
 | Staging       | 21      | 0        | 16 gateway + 5 counterpoint        |
 | Intermediate  | 13      | 0        | All incremental merge              |
 | Dimensions    | 1       | 8        | dim_date only                      |
 | Facts         | 4       | 20       | DPR + ticket demand + availability |
 | Reports       | 1       | 8        | rpt_daily_performance_report       |
 | ML Features   | 2       | 0        | Ticket demand + visitor forecast   |
 | Seeds         | 3       | 0        | tour_plu, retail item/store        |
 | Snapshots     | 0       | 0        | None configured                    |
 | **Tests**     | **8**   | **8**    | See gates A/B/C above              |
