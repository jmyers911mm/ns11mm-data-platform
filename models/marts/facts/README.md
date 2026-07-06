# Mart Models — Facts

Fact tables and bridge tables for the NS11MM data warehouse.

## Enabled Models

| Model | Description |
|-------|-------------|
| `fct_daily_performance` | Daily performance by DPR line item (admissions, retail, tours, donations, fees) |

## Disabled Models (`enabled=false`)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `bridge_session_customer` | int_google_analytics | GA4 pipeline connected |
| `fct_ad_campaign_daily` | int_google_ads, int_meta_ads | Ad platforms connected |
| `fct_campaign_attribution` | fct_ad_campaign_daily, bridge_session_customer, fct_ticket_sales | Upstream enabled |
| `fct_campaign_performance` | int_sf_marketing_cloud | SFMC pipeline connected |
| `fct_daily_operations` | int_pos_tickets, int_ticket_scans, int_shopify | Mart rewiring + Shopify |
| `fct_digital_ad_performance` | int_google_ads, int_meta_ads | Ad platforms connected |
| `fct_donor_cohort_survival` | fct_donor_retention | SF pipeline connected |
| `fct_donor_retention` | int_sf_crm | SF pipeline connected |
| `fct_fundraising` | int_classy | Classy pipeline connected |
| `fct_gl_transactions` | int_blackbaud | Blackbaud pipeline connected |
| `fct_marketing_channel_summary` | int_google_ads, int_meta_ads, int_sf_marketing_cloud | Ad + SFMC connected |
| `fct_marketing_sales_daily` | fct_marketing_channel_summary, fct_ticket_sales | Upstream enabled |
| `fct_monthly_operations` | fct_daily_operations | Upstream enabled |
| `fct_monthly_retail` | fct_retail_line_items | Upstream enabled |
| `fct_retail_line_items` | int_pos_retail (deleted) | Mart rewired to int_counterpoint__retail_lines |
| `fct_ticket_availability` | int_ticket_inventory (deleted) | Capacity source confirmed |
| `fct_ticket_demand_benchmarks` | fct_ticket_availability | Capacity source confirmed |
| `fct_ticket_sales` | int_pos_tickets (deleted) | Mart rewired to int_gateway__ticket_journal_lines |
| `fct_ticket_utilization` | int_pos_tickets, int_ticket_scans | Mart rewired |
| `fct_visitor_traffic` | int_ticket_scans (deleted) | Mart rewired to int_gateway usage |
| `fct_website_funnel` | int_google_analytics | GA4 pipeline connected |
| `fct_website_traffic` | int_google_analytics | GA4 pipeline connected |
