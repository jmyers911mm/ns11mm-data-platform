# Test Orchestration & Alert Routing

> **Source of truth:** `ns11mm/ns11mm-data-platform`  
> **Last updated:** June 2026  ·  Jeremy Myers, VP of AI & Analytics  
> **Legend:** `┌─┐` pipeline step  `╔═╗` custom test gate

```

┌─────────────────────────────────────────────────────────────────────────────┐
│         NS11MM DATA PLATFORM  ·  Test Orchestration & Alert Routing         │
│              Source Clustering  ·  Test Triggers  ·  Outcomes               │
└─────────────────────────────────────────────────────────────────────────────┘


 ══════════════════════════════════════════════════════════════════════════════
  SECTION 1  ·  SOURCE CLUSTERS & FRESHNESS THRESHOLDS
 ══════════════════════════════════════════════════════════════════════════════

 ┌────────────────────────────┐ ┌─────────────────────┐ ┌──────────────────┐
 │  TICKETING & OPERATIONS    │ │  CRM & FUNDRAISING     │ │  DIGITAL &       │
>>>>>>> remote
 │                            │ │                      │ │  MARKETING       │

 │  raw_gateway_transactions  │ │  raw_salesforce_nps_  │ │                  │
 │  raw_gateway_customers     │ │    contact/account/  │ │  raw_ga4_         │
 │  raw_counterpoint_*        │ │    opportunity       │ │    sessionreport  │
 │  raw_shopify_*             │ │  raw_classy_*         │ │  raw_google_ads_* │
 │                            │ │  raw_blackbaud_nxt_*  │ │  raw_meta_ads_*   │
 │  Freshness SLA             │ │                      │ │  raw_salesforce_  │
 │  warn  >  3 hours          │ │  Freshness SLA       │ │    mc_tracking_*  │
 │  error >  6 hours          │ │  warn  > 3 hours      │ │                  │
 │                            │ │  error > 6 hours      │ │  Freshness SLA   │
 │  High-frequency ops data   │ │                      │ │  warn  > 4 hrs   │
 │  drives real-time capacity │ │  Fundraising + CRM    │ │  error > 8 hrs   │
 │  planning & Cortex agent   │ │  enrichment           │ │                  │
>>>>>>> remote
 └────────────────────────────┘ └─────────────────────┘ └──────────────────┘
          │                              │                       │
          └──────────────────────────────┴───────────────────────┘
                                         │

                            all 14 sources land in
                            NS11MM_DW_DEV.RAW (immutable)
>>>>>>> remote
                                         │
                                         ▼


 ══════════════════════════════════════════════════════════════════════════════
  SECTION 2  ·  TEST TRIGGER SEQUENCE
 ══════════════════════════════════════════════════════════════════════════════

  GitHub Actions  ·  dbt-ci.yml
  trigger: pull_request → main   ·   schedule: 05:30 UTC daily (prod)
                                   │
                                   ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 1  ·  dbt source freshness                                        │
 │  evaluates loaded_at_field on all Bronze source tables                  │
 │  per-cluster thresholds defined in sources.yml                          │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 2  ·  dbt build → SILVER STAGING  (9 stg_ views)                 │
 │  generic tests per model:                                               │
 │    unique + not_null on all PKs                                         │
 │    accepted_values on categorical columns                               │
 │    source freshness re-asserted on every stg_ model                    │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 3  ·  dbt build → SILVER INCREMENTAL  (9 silver_ + 2 snap_)      │
 │  generic tests per model:                                               │
 │    unique + not_null on all PKs                                         │
 │    accepted_values on categoricals                                      │
 │    snapshot integrity: hashdiff column populated, no null dbt_scd_id   │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE A  ·  RECONCILIATION  ·  Bronze ↔ Silver row counts         ║
 ║  severity: error  ·  store_failures: true  ·  3 tests                  ║
 ║                                                                         ║
 ║  assert_silver_bronze_retail_count_match                                ║
 ║  assert_silver_bronze_scan_count_match                                  ║
 ║  assert_silver_bronze_ticket_count_match                                ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                              FAIL
         │                                    failing rows → quarantine
         │                                    pipeline halts → Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 4  ·  dbt build → MARTS DIMENSIONS  (9 dim_ tables)               │
 │  generic tests per model:                                               │
 │    unique + not_null on surrogate & natural keys                        │
 │    accepted_values on type/category columns                             │
 │    relationships: FK references validated against source models         │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 5  ·  dbt build → MARTS FACTS  (20 fct_ + bridge models)          │
 │  generic tests per model:                                               │
 │    unique + not_null on surrogate keys                                  │
 │    relationships: all dim FKs validated                                 │
 │    accepted_values on status / type / flag columns                      │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE B  ·  REFERENTIAL INTEGRITY  ·  11 tests                    ║
 ║  severity: error  ·  store_failures: true                               ║
 ║                                                                         ║
 ║  assert_campaign_fk_integrity                                           ║
 ║  assert_customer_segments_match_seed                                    ║
 ║  assert_ltv_tiers_match_seed                                            ║
 ║  assert_member360_emails_exist_in_crm                                   ║
 ║  assert_member360_no_orphan_contacts                                    ║
 ║  assert_payment_methods_exist_in_dim                                    ║
 ║  assert_payment_methods_match_seed                                      ║
 ║  assert_products_exist_in_dim                                           ║
 ║  assert_scan_gates_exist_in_dim                                         ║
 ║  assert_ticket_types_exist_in_dim                                       ║
 ║  assert_ticket_types_match_seed                                         ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                              FAIL
         │                                    failing rows → quarantine
         │                                    pipeline halts → Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 6  ·  dbt build → MARTS REPORTS  (8 rpt_ models)                  │
 │  generic tests per model:                                               │
 │    unique + not_null on report PKs                                      │
 │    accepted_values on dimension attributes                              │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE C  ·  BUSINESS RULES + REVENUE RECONCILIATION  ·  7 tests   ║
 ║  severity: error  ·  store_failures: true                               ║
 ║                                                                         ║
 ║  assert_gold_campaign_rates_valid                                       ║
 ║  assert_gold_daily_ops_no_negative_revenue                              ║
 ║  assert_gold_member_no_negative_ltv                                     ║
 ║  assert_gold_ops_covers_all_scan_dates                                  ║
 ║  assert_retail_revenue_reconciles                                       ║
 ║  assert_ticket_revenue_reconciles                                       ║
 ║  assert_visitor_count_reconciles                                        ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                              FAIL
         │                                    failing rows → quarantine
         │                                    pipeline halts → Section 3
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
 │  GitHub check passes  ·  pipeline continues  ·  no action required      │
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
 │  ②  PR blocked from merging to main (GitHub status check fails)        │
 │  ③  Failing rows written → dbt_test__audit schema  (quarantine)        │
 │  ④  Cortex observability log entry created, tagged: ERROR               │
 │  ⑤  Hub Incident Log opened with priority by test gate:                │
 │                                                                         │
 │      Source freshness fail   →  P1 Critical  ·  SLA: resolve in 24 h  │
 │      Gate A  reconciliation  →  P1 Critical  ·  SLA: resolve in 24 h  │
 │      Gate B  ref. integrity  →  P2 High      ·  SLA: resolve in 72 h  │
 │      Gate C  business rules  →  P2 High      ·  SLA: resolve in 72 h  │
 │      Generic model test      →  P2 High      ·  SLA: resolve in 72 h  │
 │                                                                         │
 │  ⑥  Owner paged immediately  ·  SLA clock starts on incident open      │
 │  ⑦  Downstream blocked: Power BI refresh held · Cortex paused          │
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
 │  ② hold pipeline              │    │  ① open fix branch in GitHub     │
 │  ③ re-trigger after upstream  │    │  ② PR review + dbt CI passes     │
 │    fix is confirmed           │    │  ③ merge to main                 │
 │  ④ resolve Hub incident       │    │  ④ re-run pipeline               │
 │  ⑤ document in runbook        │    │  ⑤ resolve Hub incident          │
 └───────────────────────────────┘    └──────────────────────────────────┘

```