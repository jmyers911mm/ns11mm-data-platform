# Test Orchestration & Alert Routing

> **Current scope (July 2026):** Gateway (ticketing), CounterPoint (retail POS), the
> 911dw report-estate tables, and the budget seeds are connected, feeding the Daily
> Performance Report, the migrated Pentaho report estate, and ticket demand
> forecasting. Other sources and domains described below are part of the
> target design but are currently disabled / not yet ingested.

> **Source of truth:** `ns11mm/ns11mm-data-platform`  
> **Last updated: 2026-07-29**  ·  Jeremy Myers, VP of AI & Analytics  
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
 │  TICKETING, RETAIL &       │ │░░CRM & FUNDRAISING░░│ │░░DIGITAL &░░░░░░░│
 │  REPORT ESTATE  ✓ ENABLED  │ │░░NOT YET CONNECTED░░│ │░░MARKETING░░░░░░░│
 │                            │ │                      │ │░░NOT CONNECTED░░░│
 │  gateway_seed (17 stg)     │ │  raw_salesforce_*    │ │                  │
 │  counterpoint_seed (7 stg) │ │  raw_classy_*        │ │  raw_ga4_*       │
 │  report_estate_seed (10stg)│ │  raw_blackbaud_nxt_* │ │  raw_google_ads_*│
 │  budget_seeds (SEEDS)      │ │                      │ │  raw_meta_ads_*  │
 │                            │ │  Freshness SLA       │ │                  │
 │  Freshness SLA (sources.yml)│ │  (once connected)   │ │  Freshness SLA   │
 │  gateway/counterpoint:     │ │                      │ │  (once connected)│
 │    warn > 7d / error > 14d │ │                      │ │                  │
 │  report_estate:            │ │                      │ │                  │
 │    warn > 2d / error > 4d  │ │                      │ │                  │
 └────────────────────────────┘ └─────────────────────┘ └──────────────────┘
          │
          │  (Gateway + CounterPoint + report estate + budget seeds today)
          │
          ▼

                         3 RAW source groups + budget_seeds land in
                         {{ target.database }}.RAW / .SEEDS (immutable)
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
 │  evaluates _loaded_at on the gateway / counterpoint / report_estate     │
 │  source tables · per-group thresholds defined in sources.yml            │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 2  ·  dbt build → STAGING  (34 stg_ views)                       │
 │  17 gateway + 7 counterpoint + 2 budget + 2 sensource + 3 shopify       │
 │  + 1 each dpr / ecommerce / wifi                                        │
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
 │  STEP 3  ·  dbt build → INTERMEDIATE  (21 int_ models)                 │
 │  views + 4 tables (ticket/item journal lines, retail lines,             │
 │  ticket demand features):                                               │
 │    int_gateway__item_attributes / item_journal_lines /                  │
 │      scan_lines / ticket_demand_features / ticket_journal_lines         │
 │    int_counterpoint__retail_lines                                       │
 │    int_dpr__admissions / attendance / donations / fees / retail / tours │
 │    int_retail__customers / performance / visitors                       │
 │    int_budget__admissions / dpr / retail forecasts                      │
 │    int_pos_tickets · int_ticket_inventory · int_ticket_scans            │
 │  generic tests: unique + not_null on all PKs, accepted_values          │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE A  ·  RECONCILIATION  ·  4 tests enabled                    ║
 ║  severity: error  ·  store_failures: true                              ║
 ║                                                                         ║
 ║  ✓ assert_raw_silver_ticket_count_match                                 ║
 ║  ✓ assert_rpt_avg_ticket_price                                          ║
 ║  ✓ assert_silver_gold_retail_revenue_reconciliation                     ║
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
 │  STEP 4  ·  dbt build → MARTS DIMENSIONS  (13 enabled)                  │
 │                                                                         │
 │  ✓ dim_access_code · dim_coa · dim_customer · dim_date                  │
 │  ✓ dim_dpr_line_item · dim_event · dim_facility · dim_gate              │
 │  ✓ dim_product · dim_retail_line_item · dim_store                       │
 │  ✓ dim_ticket_type · dim_tour_product                                   │
 │                                                                         │
 │  DISABLED (4): dim_budget_version, dim_campaign, dim_fund,              │
 │    dim_payment_method                                                   │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STEP 5  ·  dbt build → MARTS FACTS  (11 enabled)                       │
 │                                                                         │
 │  ✓ fct_daily_operations · fct_daily_performance · fct_daily_scan        │
 │  ✓ fct_retail_daily · fct_retail_performance · fct_today_sales_hourly   │
 │  ✓ fct_ticket_availability · fct_ticket_demand_forecast                 │
 │  ✓ fct_budget_dpr / admissions / retail _forecasts                      │
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
 │  STEP 6  ·  dbt build → MARTS REPORTS  (21 enabled views)               │
 │                                                                         │
 │  ✓ DPR: rpt_daily_performance_report (table) · report_long ·            │
 │    budget_daily · powerbi · narrative_brief · tracker_ytd               │
 │  ✓ Retail: performance · report_long · category_long · budget_daily ·   │
 │    carts_analysis · monthly_kpi · powerbi · narrative_brief             │
 │  ✓ Attendance: attendance · daily_attendance · daily_scan ·             │
 │    daily_scan_powerbi · today_sales_powerbi                             │
 │  ✓ Other: website_commerce · wifi_email_export (PII, grants opt-out)    │
 │                                                                         │
 │  GATED (2, enabled=false by design): rpt_dpr_narrative,                 │
 │    rpt_retail_narrative (Cortex AI_COMPLETE; deployed via scripts/)     │
 │  DISABLED (9, in disabled/): rpt_campaign_performance,                  │
 │    rpt_customer_ltv, rpt_daily_operations, rpt_digital_marketing,       │
 │    rpt_member_360, rpt_retail_performance (POC), rpt_revenue_bridge,    │
 │    rpt_ticket_sales, rpt_visitor_traffic                                │
 └─────────────────────────────────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────────────────┐
       PASS                                             WARN / ERROR
         │                                               └──► Section 3
         ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  TEST GATE C  ·  BUSINESS RULES  ·  7 tests enabled                    ║
 ║  severity: error (assert_) / warn (alert_)  ·  store_failures: true    ║
 ║                                                                         ║
 ║  ✓ alert_null_primary_keys_in_raw  (warn)                               ║
 ║  ✓ assert_critical_tables_not_empty  (15 critical tables)               ║
 ║  ✓ assert_date_coverage                                                 ║
 ║  ✓ assert_no_future_tickets                                             ║
 ║  ✓ assert_no_negative_attendance                                        ║
 ║  ✓ assert_no_negative_retail_revenue                                    ║
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
 │  SEEDS  (19 CSVs → SEEDS schema)                                        │
 │                                                                         │
 │  ✓ 12 seed_* mapping/scope seeds (tour PLU, retail facility/scope/      │
 │    exclusions, scan segments, gateway exclusions, service PLUs…)        │
 │  ✓ 5 legacy ref_* reference tables                                      │
 │  ✓ 2 report line-item catalogs (dpr_line_items, retail_line_items)      │
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

 | Layer         | Enabled | Disabled | Notes                                          |
 |---------------|---------|----------|------------------------------------------------|
 | Source groups | 4       | ~10      | gateway / counterpoint / report_estate + budget_seeds |
 | Staging       | 34      | 0        | 17 gateway, 7 counterpoint, 2 budget, 2 sensource, 3 shopify, 1 each dpr/ecommerce/wifi |
 | Intermediate  | 21      | 8        | Views + 4 tables (not incremental merge)       |
 | Dimensions    | 13      | 4        | See Step 4                                     |
 | Facts         | 11      | 20       | DPR + report estate + budget + demand          |
 | Reports       | 21      | 9 (+2 gated) | 23 files; 2 narrative sources enabled=false |
 | ML Features   | 2       | 12       | Ticket demand + visitor forecast               |
 | Seeds         | 19      | 0        | → SEEDS schema                                 |
 | Snapshots     | 0       | 0        | None configured                                |
 | **Singular tests** | **12** | **8** | 7 business rules / 4 reconciliation / 1 ref. integrity |
