# NS11MM Data Platform Architecture

> **Source of truth:** `ns11mm/ns11mm-data-platform` — built from actual repo structure  
> **Last updated:** June 2026  ·  Jeremy Myers, VP of AI & Analytics  
> **Legend:** `┌─┐` standard layer  `╔═╗` test gate

```

┌─────────────────────────────────────────────────────────────────────────────┐
│              NS11MM DATA PLATFORM  ·  ns11mm_data_platform                            │
│   Snowflake  ·  dbt Core  ·  Cortex Semantic Views  ·  Power BI            │
└─────────────────────────────────────────────────────────────────────────────┘

  CI/CD ─── ns11mm/ns11mm-data-platform ─── PR gate ─── GitHub Actions dbt-ci.yml
            SQLFluff  ·  dbt_project_evaluator  ·  no direct pushes to main


 ┌─────────────────────────────────────────────────────────────────────────┐
 │  RAW SCHEMA  ·  immutable  ·  no dbt model writes to BRONZE          │
 │                                                                         │
 │  raw_pos_tickets       raw_pos_retail        raw_ticket_scans           │
 │  raw_ticket_capacity   raw_customer_identifiers                         │
 │  raw_sf_crm            raw_sf_marketing_cloud                           │
 │  raw_google_analytics  raw_google_ads         raw_meta_ads              │
 │                                                                         │
 │  Freshness  default: warn 24 h / error 48 h                            │
 │             tickets & scans: warn 30 min / error 60 min                │
 └─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  STAGING  ·  schema: STAGING  ·  materialized: view                   │
 │  query_tag: dbt_ns11mm_staging  ·  tags: daily, critical                │
 │                                                                         │
 │  stg_salesforce_nps__contacts   stg_salesforce_mc__tracking             │
 │  stg_gateway__transactions      stg_gateway__customers                  │
 │  stg_counterpoint__transactions stg_counterpoint__line_items             │
 │  stg_shopify__orders            stg_classy__transactions                │
 │  stg_ga4__sessions   stg_google_ads__campaigns  stg_meta_ads__campaigns │
 │  stg_blackbaud__journal_entries stg_vena__budget   + 12 more             │
 │                                                                         │
 │  Rename & cast · deduplicate · unique + not_null on PKs                 │
 │  source freshness enforced on all models                                │
 └─────────────────────────────────────────────────────────────────────────┘
          │                                           ▲
          │                    ┌──────────────────────┤
          │                    │  SEEDS  (8 total)     │
          │                    │                       │
          │                    │  raw data (dev/test)  │
          │                    │  raw_google_ads       │
          │                    │  raw_google_analytics │
          │                    │  raw_meta_ads         │
          │                    │                       │
          │                    │  reference tables     │
          │                    │  ref_customer_segments│
          │                    │  ref_ltv_tiers        │
          │                    │  ref_marketing_chan.  │
          │                    │  ref_payment_methods  │
          │                    │  ref_ticket_types     │
          │                    └──────────────────────┘
          ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  INTERMEDIATE — INCREMENTAL  ·  schema: INTERMEDIATE  ·  incremental merge          │
 │  on_schema_change: append_new_columns  ·  copy_grants: true             │
 │  query_tag: dbt_museum_silver  ·  transient: true                       │
 │                                                                         │
 │  silver_pos_tickets       silver_pos_retail    silver_ticket_scans      │
 │  silver_ticket_inventory  silver_sf_crm        silver_sf_marketing_cloud│
 │  silver_google_analytics  silver_google_ads    silver_meta_ads          │
 │                                                                         │
 │  ┌───────────────────────────────────────────────────────────────────┐  │
 │  │  SNAPSHOTS  →  SILVER  ·  strategy: check  ·  unique_key: hashdiff│  │
 │  │  snap_sf_crm   snap_dim_customer                                  │  │
 │  └───────────────────────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║  RECONCILIATION TESTS  ·  Bronze ↔ Silver row counts                   ║
 ║                                                                         ║
 ║  assert_silver_bronze_retail_count_match                                ║
 ║  assert_silver_bronze_scan_count_match                                  ║
 ║  assert_silver_bronze_ticket_count_match                                ║
 ╚═════════════════════════════════════════════════════════════════════════╝
                                   │
                                   ▼
 ┌─────────────────────────────────────────────────────────────────────────┐
 │  GOLD  ·  schema: MARTS  ·  copy_grants: true                            │
 │  post-hook: GRANT SELECT → POWERBI_ROLE  and  ML_ROLE                   │
 │                                                                         │
 │  ┌─────────────────────────────────────────────────────────────────┐   │
 │  │  DIMENSIONS  ·  materialized: table  ·  access: public          │   │
 │  │                                                                 │   │
 │  │  dim_customer   dim_member         dim_date                     │   │
 │  │  dim_ticket_type  dim_gate         dim_payment_method           │   │
 │  │  dim_campaign   dim_marketing_channel   dim_product             │   │
 │  └─────────────────────────────────────────────────────────────────┘   │
 │                                                                         │
 │  ┌─────────────────────────────────────────────────────────────────┐   │
 │  │  FACTS  ·  materialized: incremental merge  ·  access: public   │   │
 │  │                                                                 │   │
 │  │  Visitor & Tickets             Operations                       │   │
 │  │  fct_ticket_sales              fct_daily_operations             │   │
 │  │  fct_ticket_utilization        fct_monthly_operations           │   │
 │  │  fct_ticket_availability                                        │   │
 │  │  fct_ticket_demand_benchmarks  Retail                           │   │
 │  │  fct_visitor_traffic           fct_retail_line_items            │   │
 │  │                                fct_retail_performance           │   │
 │  │  Membership & Donors           fct_monthly_retail               │   │
 │  │  fct_member_360                                                 │   │
 │  │  fct_donor_retention           Digital & Marketing              │   │
 │  │  fct_donor_cohort_survival     fct_digital_ad_performance       │   │
 │  │                                fct_ad_campaign_daily            │   │
 │  │                                fct_campaign_performance         │   │
 │  │                                fct_marketing_channel_summary    │   │
 │  │                                fct_website_traffic              │   │
 │  │                                fct_website_funnel               │   │
 │  │                                bridge_session_customer          │   │
 │  └─────────────────────────────────────────────────────────────────┘   │
 │                           │                                             │
 │  ╔════════════════════════╩════════════════════════════════════════╗   │
 │  ║  REFERENTIAL INTEGRITY TESTS  ·  FK integrity & seed alignment  ║   │
 │  ║                                                                 ║   │
 │  ║  assert_campaign_fk_integrity                                   ║   │
 │  ║  assert_customer_segments_match_seed                            ║   │
 │  ║  assert_ltv_tiers_match_seed                                    ║   │
 │  ║  assert_member360_emails_exist_in_crm                           ║   │
 │  ║  assert_member360_no_orphan_contacts                            ║   │
 │  ║  assert_payment_methods_exist_in_dim                            ║   │
 │  ║  assert_payment_methods_match_seed                              ║   │
 │  ║  assert_products_exist_in_dim                                   ║   │
 │  ║  assert_scan_gates_exist_in_dim                                 ║   │
 │  ║  assert_ticket_types_exist_in_dim                               ║   │
 │  ║  assert_ticket_types_match_seed                                 ║   │
 │  ╚═════════════════════════════════════════════════════════════════╝   │
 │                                                                         │
 │  ┌─────────────────────────────────────────────────────────────────┐   │
 │  │  REPORTS  ·  materialized: incremental merge  ·  access: public │   │
 │  │                                                                 │   │
 │  │  rpt_daily_operations   rpt_visitor_traffic   rpt_ticket_sales  │   │
 │  │  rpt_retail_performance rpt_member_360        rpt_customer_ltv  │   │
 │  │  rpt_campaign_performance   rpt_digital_marketing               │   │
 │  └─────────────────────────────────────────────────────────────────┘   │
 │                           │                                             │
 │  ╔════════════════════════╩════════════════════════════════════════╗   │
 │  ║  BUSINESS RULES + REVENUE RECONCILIATION TESTS                  ║   │
 │  ║                                                                 ║   │
 │  ║  assert_gold_campaign_rates_valid                               ║   │
 │  ║  assert_gold_daily_ops_no_negative_revenue                      ║   │
 │  ║  assert_gold_member_no_negative_ltv                             ║   │
 │  ║  assert_gold_ops_covers_all_scan_dates                          ║   │
 │  ║  assert_retail_revenue_reconciles                               ║   │
 │  ║  assert_ticket_revenue_reconciles                               ║   │
 │  ║  assert_visitor_count_reconciles                                ║   │
 │  ╚═════════════════════════════════════════════════════════════════╝   │
 └─────────────────────────────────────────────────────────────────────────┘
              │                                         │
              ▼                                         ▼
 ┌────────────────────────────┐     ┌───────────────────────────────────────┐
 │  ML_FEATURES SCHEMA        │     │  CORTEX SEMANTIC VIEWS  (GOLD schema) │
 │  materialized: table       │     │  CREATE SEMANTIC VIEW DDL             │
 │  GRANT SELECT → ML_ROLE    │     │  defined in analyses/  ·  outside dbt │
 │  transient: true           │     │                                       │
 │                            │     │  SV_MUSEUM_OPERATIONS  (13 entities)  │
 │  Forecasting & Demand      │     │    fct_ticket_sales                   │
 │  ml_daily_visitor_features │     │    fct_retail_line_items              │
 │  ml_ticket_demand_features │     │    fct_daily_operations               │
 │  ml_visitor_forecast_train.│     │    fct_visitor_traffic                │
 │  ml_dynamic_pricing_feat.  │     │    fct_campaign_performance           │
 │                            │     │    rpt_customer_ltv · dim_*           │
 │  Churn & Retention         │     │                                       │
 │  ml_donor_churn_features   │     │  SV_DONOR_RETENTION  (6 entities)     │
 │  ml_member_churn_features  │     │    fct_donor_retention                │
 │  ml_ticket_no_show_feat.   │     │    fct_donor_cohort_survival          │
 │  ml_donor_upgrade_prop._f. │     │    dim_customer                       │
 │                            │     │                                       │
 │  Marketing & Revenue       │     │  MARKETING_PERFORMANCE_SV (5 entities)│
 │  ml_email_send_time_feat.  │     │    fct_digital_ad_performance         │
 │  ml_campaign_response_feat.│     │    fct_website_traffic                │
 │  ml_ad_budget_optim._feat. │     │    fct_campaign_performance           │
 │  ml_marketing_attr._feat.  │     │    fct_marketing_channel_summary      │
 │  ml_ad_creative_features   │     │    dim_marketing_channel · dim_date   │
 │  ml_retail_cross_sell_feat.│     │    Synonyms · Facts · Relationships   │
 └────────────────────────────┘     └───────────────────────────────────────┘
              │                                  │                   │
              ▼                                  ▼                   ▼
 ┌────────────────────────────┐   ┌─────────────────────────┐  ┌────────────┐
 │  SNOWFLAKE ML MODELS       │   │  POWER BI               │  │  CORTEX    │
 │  trained on ML_FEATURES    │   │  Museum Analytics WS    │  │  AGENT     │
 │  maturity in exposures.yml │   │  PBIP · Tabular Editor  │  │            │
 │                            │   │  thin display layer only│  │  museum_   │
 │  FORECAST  (90-day)        │   │                         │  │  ops_agent │
 │    ml_visitor_forecasting  │   │  Daily Operations       │  │            │
 │                            │   │    rpt_daily_operations │  │  Reads:    │
 │  CLASSIFICATION            │   │    rpt_visitor_traffic  │  │  SV_MUSEUM │
 │    donor churn             │   │    rpt_retail_performance│  │  _OPERA-   │
 │    ticket no-show          │   │    refresh: 6:30 AM ET  │  │  TIONS     │
 │    donor upgrade           │   │                         │  │            │
 │    email send time         │   │  Membership & Donors    │  │  SV_DONOR  │
 │    campaign response       │   │    rpt_member_360       │  │  _RETEN-   │
 │                            │   │    rpt_customer_ltv     │  │  TION      │
 │  REGRESSION                │   │    fct_donor_retention  │  │            │
 │    dynamic pricing         │   │    fct_donor_cohort_*   │  │  Observ-   │
 │                            │   │    refresh: 7:00 AM ET  │  │  ability   │
 │  COLLAB. FILTERING         │   │                         │  │  enabled   │
 │    retail cross-sell       │   │  Retail Performance     │  └────────────┘
 └────────────────────────────┘   │    rpt_retail_performance│
                                  │    fct_retail_line_items │
                                  │    refresh: 6:30 AM ET   │
                                  │                         │
                                  │  Capacity Planning      │
                                  │    fct_ticket_avail.    │
                                  │    fct_ticket_demand_   │
                                  │      benchmarks         │
                                  │    refresh: every 30 min│
                                  │                         │
                                  │  Campaign Analytics     │
                                  │    rpt_campaign_perf.   │
                                  │    refresh: 7:00 AM ET  │
                                  │                         │
                                  │  ─────────────────────  │
                                  │  Semantic Views         │
                                  │  Connector (DirectQuery)│
                                  │  SV_MUSEUM_OPERATIONS   │
                                  │  Role: POWERBI_ROLE     │
                                  │  WH: DBT_PROD_WH        │
                                  └─────────────────────────┘

```