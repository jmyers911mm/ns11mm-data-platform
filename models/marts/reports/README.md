# Mart Models — Reports

Pre-aggregated report tables optimized for Power BI and Cortex Analyst consumption.

## Enabled Models

| Model | Description |
|-------|-------------|
| `rpt_daily_performance_report` | Daily performance report joining fct_daily_performance + dim_date |

### Migrated Pentaho report estate (added 1.6.0)

The active Pentaho analytical reports, rebuilt on the marts. **Live** reports
run on current seeds; **Stub** reports are wired to placeholder seeds and
populate when their source feed lands. This is the full active set (the ~90
SSRS reports are Galaxy operational/box-office admin reports, out of scope).

| Model | Status | Legacy report | Source dependency |
|-------|--------|---------------|-------------------|
| `rpt_retail_performance` | **Live** | Retail Performance Report | none (CP seeds) |
| `rpt_retail_carts_analysis` | **Live** | Retail Carts Analysis | Sensource visitors (stub) for per-cap ratios |
| `rpt_monthly_retail_kpi` | **Live** | Monthly Retail KPI | none (CP seeds) |
| `rpt_memorial_museum_tracker_ytd` | **Live** | Memorial Museum Daily Tracker YTD | none (DPR fact) |
| `rpt_daily_scan` | **Live*** | Daily Scan Report | none; segment mapping to validate |
| `rpt_attendance` | **Stub** | Attendance Report | `sensordata` (Sensource) |
| `rpt_daily_attendance` | **Stub** | Daily Attendance Report | hourly passes feed |
| `rpt_website_commerce` | **Stub** | Website Commerce Report | Classy/Shopify recurring (ADR-008) |
| `rpt_wifi_email_export` | **Stub** | Blue State WiFi Email Export | WiFi audience feed. **RESTRICTED/PII** — see [DATA_CLASSIFICATION.md](../../../docs/architecture/DATA_CLASSIFICATION.md); least-privilege grant only, not POWERBI_ROLE/ML_ROLE. |

New RAW tables that feed the stubs (each a seed/staging swap, no report rework):
`sensordata`, `fact_passes_by_hour`, `fact_todays_retail_data`, Classy/Shopify
recurring, WiFi audience, and a budget/forecast source. See
[REPORT_TABLE_COLUMN_CROSSWALK.md](../../../docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md)
for the full report → table → column mapping.

## Disabled Models (`enabled=false`)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `rpt_campaign_performance` | fct_campaign_performance | SFMC pipeline connected |
| `rpt_customer_ltv` | fct_ticket_sales, fct_retail_line_items, fct_fundraising, dim_customer | Upstream enabled |
| `rpt_daily_operations` | fct_daily_operations | Upstream enabled |
| `rpt_digital_marketing` | fct_digital_ad_performance, fct_website_traffic | Ad + GA4 connected |
| `rpt_member_360` | fct_ticket_sales, fct_retail_line_items, int_sf_marketing_cloud, dim_customer | SF + mart rewiring |
| `rpt_retail_performance` | fct_retail_line_items, dim_product, dim_payment_method, dim_customer | Upstream enabled |
| `rpt_revenue_bridge` | fct_daily_operations | Upstream enabled |
| `rpt_ticket_sales` | fct_ticket_sales, dim_ticket_type, dim_payment_method, dim_gate, dim_customer | Upstream enabled |
| `rpt_visitor_traffic` | fct_visitor_traffic, dim_gate, fct_ticket_sales | Upstream enabled |