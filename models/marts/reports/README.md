# Mart Models — Reports

Report views optimized for Power BI and Cortex Analyst consumption. All reports
are views except `rpt_daily_performance_report` (table). See
[report_table_column_crosswalk.md](report_table_column_crosswalk.md) for the full
report → table → column mapping and
[report_semantic_view_map.md](report_semantic_view_map.md) for which semantic
view fronts each report.

## Enabled Models (23 files; 21 build, 2 gated)

### DPR family

| Model | Description |
|-------|-------------|
| `rpt_daily_performance_report` | Daily Performance Report (Power BI consumption layer; table) |
| `rpt_dpr_report_long` | Long/unpivoted DPR serving shape (actual + budget per line item) |
| `rpt_dpr_budget_daily` | Budget-vs-actual daily serving — day-grain DPR budget |
| `rpt_dpr_powerbi` | Thin `SEMANTIC_VIEW()` projection of the DPR semantic view for Power BI |
| `rpt_dpr_narrative_brief` | Deterministic narrative brief — pre-computed DPR facts for the AI_COMPLETE prompt |
| `rpt_dpr_narrative` | **`enabled=false` (gated)** — AI-generated DPR narrative via Snowflake Cortex; deployed by `scripts/setup_dpr_narrative.sql`, kept out of the routine dbt build |
| `rpt_memorial_museum_tracker_ytd` | Memorial Museum Daily Tracker — YTD |

### Retail family

| Model | Description |
|-------|-------------|
| `rpt_retail_performance` | Retail Performance Report |
| `rpt_retail_report_long` | Long/unpivoted Retail Performance serving shape (actual + budget per line item) |
| `rpt_retail_category_long` | Long category-grain serving shape for the Retail Performance Report (page 2) |
| `rpt_retail_budget_daily` | Budget-vs-actual daily serving — day x facility retail budget (goal) |
| `rpt_retail_carts_analysis` | Retail Carts Analysis Report |
| `rpt_monthly_retail_kpi` | Monthly Retail KPI |
| `rpt_retail_powerbi` | Thin `SEMANTIC_VIEW()` projection of the RETAIL semantic view for Power BI |
| `rpt_retail_narrative_brief` | Deterministic narrative brief — pre-computed retail facts for the AI_COMPLETE prompt |
| `rpt_retail_narrative` | **`enabled=false` (gated)** — AI-generated retail narrative via Snowflake Cortex; deployed by `scripts/setup_retail_narrative.sql`, kept out of the routine dbt build |

### Attendance / scan family

| Model | Description |
|-------|-------------|
| `rpt_attendance` | Attendance Report (Sensource areas via `stg_sensource__*` + DPR fact) |
| `rpt_daily_attendance` | Daily Attendance Report (hourly passes via `stg_gateway__passes_by_hour`) |
| `rpt_daily_scan` | Daily Scan Report (segment mapping still to validate) |
| `rpt_daily_scan_powerbi` | Thin `SEMANTIC_VIEW()` projection of the ATTENDANCE semantic view for Power BI (Daily Scan) |
| `rpt_today_sales_powerbi` | Thin `SEMANTIC_VIEW()` projection of the ATTENDANCE semantic view for Power BI (Today's Sales) |

### Other

| Model | Description |
|-------|-------------|
| `rpt_website_commerce` | Website Commerce Report (recurring donations/memberships via `stg_ecommerce__website_recurring`) |
| `rpt_wifi_email_export` | Blue State WiFi Email Export (via `stg_wifi__audience`). **RESTRICTED/PII** — see [DATA_CLASSIFICATION.md](../../../docs/architecture/DATA_CLASSIFICATION.md); grants opt-out (`grants: {select: []}`), not POWERBI_ROLE/ML_ROLE. |

## Disabled Models (`enabled=false`) — in `disabled/` subfolder (9)

> **Name collision, on purpose:** `disabled/rpt_retail_performance.sql` is the *old*
> POC retail report (built on `fct_retail_line_items`/Shopify, all disabled) and is
> unrelated to the **active** `rpt_retail_performance` above, which is the migrated
> Pentaho Retail Performance Report. Only the active one builds; do not re-enable the
> disabled file under the same name.

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `rpt_campaign_performance` | fct_campaign_performance | SFMC pipeline connected |
| `rpt_customer_ltv` | fct_ticket_sales, fct_retail_line_items, fct_fundraising, dim_customer rewiring | Upstream enabled |
| `rpt_daily_operations` | legacy POC daily-ops shape | Superseded surface; revisit if needed |
| `rpt_digital_marketing` | fct_digital_ad_performance, fct_website_traffic | Ad + GA4 connected |
| `rpt_member_360` | fct_ticket_sales, fct_retail_line_items, int_sf_marketing_cloud | SF + mart rewiring |
| `rpt_retail_performance` (POC) | fct_retail_line_items, dim_payment_method | See name-collision note above |
| `rpt_revenue_bridge` | fct_daily_operations POC shape | Upstream enabled |
| `rpt_ticket_sales` | fct_ticket_sales, dim_payment_method | Upstream enabled |
| `rpt_visitor_traffic` | fct_visitor_traffic, fct_ticket_sales | Upstream enabled |
