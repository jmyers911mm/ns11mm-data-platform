# ML Feature Models

Feature tables for Snowflake ML models (forecasting, classification, propensity scoring).

## Enabled Models

| Model | Sources | Description |
|-------|---------|-------------|
| `ml_ticket_demand_features` | `fct_ticket_availability`, `dim_date` | Daily ticket demand with lag features, rolling averages, and capacity utilization for Snowflake ML FORECAST |
| `ml_visitor_forecast_training` | `fct_daily_operations`, `dim_date` | Daily visitor count training dataset for visitor forecasting |

### Forecast Model

The ticket demand forecast uses Snowflake ML FORECAST (`ns11mm_ticket_demand_model`):
- **Training table:** `ML_TICKET_DEMAND_FEATURES` (filtered to series with 10+ observations)
- **Series column:** `TICKET_TYPE` (PLU-based)
- **Target:** `DAILY_VISITORS` (reserved ticket count per day)
- **Forecast horizon:** 90 days with 95% prediction interval
- **Run via:** `MANUAL_ML_RUN.sql` or `dbt run-operation create_ticket_demand_forecast`

## Disabled Models (`enabled=false`) — in `disabled/` subfolder

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `ml_ad_budget_optimization_features` | fct_digital_ad_performance | Ad platforms connected |
| `ml_ad_creative_features` | int_google_ads, int_meta_ads | Ad platforms connected |
| `ml_campaign_response_features` | int_sf_marketing_cloud, fct_website_traffic | SFMC + GA4 connected |
| `ml_daily_visitor_features` | fct_digital_ad_performance, fct_website_traffic, fct_daily_operations, fct_visitor_traffic | Multiple upstreams |
| `ml_donor_churn_features` | int_sf_crm | SF pipeline connected |
| `ml_donor_upgrade_propensity_features` | dim_customer, int_sf_marketing_cloud | SF + SFMC connected |
| `ml_dynamic_pricing_features` | fct_ticket_availability, fct_ticket_demand_benchmarks | Capacity source confirmed |
| `ml_email_send_time_features` | int_sf_marketing_cloud | SFMC connected |
| `ml_marketing_attribution_features` | int_google_analytics | GA4 connected |
| `ml_member_churn_features` | rpt_member_360 | Upstream enabled |
| `ml_retail_cross_sell_features` | fct_retail_line_items | Mart rewired |
| `ml_ticket_no_show_features` | fct_ticket_sales | Mart rewired |
