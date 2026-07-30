# Mart Models — Facts

Fact tables and bridge tables for the NS11MM data warehouse.

## Enabled Models (11)

| Model | Description |
|-------|-------------|
| `fct_daily_performance` | Daily performance by DPR line item (admissions, retail, tours, donations, fees) |
| `fct_daily_operations` | Daily operational metrics: visitors admitted, ticket sales, revenue |
| `fct_ticket_availability` | Ticket capacity and utilization by date/type (feeds ML forecasting) |
| `fct_ticket_demand_forecast` | Ticket demand aggregated for forecasting with presale curves |

### Report-estate facts (added in the report buildout, 1.6.0)

Facts backing the migrated Pentaho report estate.

| Model | Status | Description |
|-------|--------|-------------|
| `fct_retail_performance` | **Live** | Retail sales/profit/units/donations, tidy grain: one row per day x facility x product category. Replaces legacy `fact_retail`. |
| `fct_retail_daily` | **Live** | Retail facility-grain fact: transactions, visitor counts, and facility rollups. Grain for the retail ratios. Replaces legacy `fact_num_tickets` + facility rollup. |
| `fct_daily_scan` | **Live*** | Gate passes scanned + tickets sold by market segment per day. Replaces legacy `fact_dailyscan_data`. (*Totals live; segment split pending channel-mapping validation.) |
| `fct_today_sales_hourly` | **Live** | Same-day hourly retail sales by facility. Rebuilt on the real same-day CounterPoint feed (`stg_counterpoint__todays_retail`); no longer a stub. |

### Budget facts

Budget/forecast facts behind the budget-vs-actual reports, sourced from the
Excel→CSV budget seeds via `int_budget__*`.

| Model | Description |
|-------|-------------|
| `fct_budget_dpr_forecasts` | DPR budget/forecast (one row per day) |
| `fct_budget_admissions_forecasts` | Admissions/attendance budget by facility (one row per day x facility) |
| `fct_budget_retail_forecasts` | Retail budget/forecast by facility (one row per day x facility) |

## Disabled Models (`enabled=false`) — in `disabled/` subfolder (20)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `bridge_session_customer` | int_google_analytics | GA4 pipeline connected |
| `fct_ad_campaign_daily` | int_google_ads, int_meta_ads | Ad platforms connected |
| `fct_campaign_attribution` | fct_ad_campaign_daily, bridge_session_customer, fct_ticket_sales | Upstream enabled |
| `fct_campaign_performance` | int_sf_marketing_cloud | SFMC pipeline connected |
| `fct_digital_ad_performance` | int_google_ads, int_meta_ads | Ad platforms connected |
| `fct_donor_cohort_survival` | fct_donor_retention | SF pipeline connected |
| `fct_donor_retention` | int_sf_crm | SF pipeline connected |
| `fct_fundraising` | int_classy | Classy pipeline connected |
| `fct_gl_transactions` | int_blackbaud | Blackbaud pipeline connected |
| `fct_marketing_channel_summary` | int_google_ads, int_meta_ads, int_sf_marketing_cloud | Ad + SFMC connected |
| `fct_marketing_sales_daily` | fct_marketing_channel_summary, fct_ticket_sales | Upstream enabled |
| `fct_monthly_operations` | fct_daily_operations | Shopify data available |
| `fct_monthly_retail` | fct_retail_line_items | Upstream enabled |
| `fct_retail_line_items` | int_shopify | Shopify pipeline connected |
| `fct_ticket_demand_benchmarks` | fct_ticket_availability | Historical benchmark data loaded |
| `fct_ticket_sales` | int_pos_tickets | Mart rewired to new intermediate |
| `fct_ticket_utilization` | int_pos_tickets, int_ticket_scans | Mart rewired |
| `fct_visitor_traffic` | int_ticket_scans | Mart rewired |
| `fct_website_funnel` | int_google_analytics | GA4 pipeline connected |
| `fct_website_traffic` | int_google_analytics | GA4 pipeline connected |