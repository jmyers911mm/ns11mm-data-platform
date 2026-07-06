# Mart Models — Facts

Fact tables and bridge tables for the NS11MM data warehouse.

## Enabled Models

| Model | Description |
|-------|-------------|
| `fct_daily_performance` | Daily performance by DPR line item (admissions, retail, tours, donations, fees) |

## Disabled Models (`enabled=false`)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `bridge_session_customer` | silver_google_analytics | GA4 pipeline connected |
| `fct_ad_campaign_daily` | silver_google_ads, silver_meta_ads | Ad platforms connected |
| `fct_campaign_attribution` | fct_ad_campaign_daily, bridge_session_customer, fct_ticket_sales | Upstream enabled |
| `fct_campaign_performance` | silver_sf_marketing_cloud | SFMC pipeline connected |
| `fct_daily_operations` | silver_pos_tickets, silver_ticket_scans, silver_shopify | Mart rewiring + Shopify |
| `fct_digital_ad_performance` | silver_google_ads, silver_meta_ads | Ad platforms connected |
| `fct_donor_cohort_survival` | fct_donor_retention | SF pipeline connected |
| `fct_donor_retention` | silver_sf_crm | SF pipeline connected |
| `fct_fundraising` | silver_classy | Classy pipeline connected |
| `fct_gl_transactions` | silver_blackbaud | Blackbaud pipeline connected |
| `fct_marketing_channel_summary` | silver_google_ads, silver_meta_ads, silver_sf_marketing_cloud | Ad + SFMC connected |
| `fct_marketing_sales_daily` | fct_marketing_channel_summary, fct_ticket_sales | Upstream enabled |
| `fct_monthly_operations` | fct_daily_operations | Upstream enabled |
| `fct_monthly_retail` | fct_retail_line_items | Upstream enabled |
| `fct_retail_line_items` | silver_pos_retail (deleted) | Mart rewired to silver_counterpoint__retail_lines |
| `fct_ticket_availability` | silver_ticket_inventory (deleted) | Capacity source confirmed |
| `fct_ticket_demand_benchmarks` | fct_ticket_availability | Capacity source confirmed |
| `fct_ticket_sales` | silver_pos_tickets (deleted) | Mart rewired to silver_gateway__ticket_journal_lines |
| `fct_ticket_utilization` | silver_pos_tickets, silver_ticket_scans | Mart rewired |
| `fct_visitor_traffic` | silver_ticket_scans (deleted) | Mart rewired to silver_gateway usage |
| `fct_website_funnel` | silver_google_analytics | GA4 pipeline connected |
| `fct_website_traffic` | silver_google_analytics | GA4 pipeline connected |
