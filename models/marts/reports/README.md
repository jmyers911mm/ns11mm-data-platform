# Mart Models — Reports

Pre-aggregated report tables optimized for Power BI and Cortex Analyst consumption.

## Enabled Models

| Model | Description |
|-------|-------------|
| `rpt_daily_performance_report` | Daily performance report joining fct_daily_performance + dim_date |

## Disabled Models (`enabled=false`)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `rpt_campaign_performance` | fct_campaign_performance | SFMC pipeline connected |
| `rpt_customer_ltv` | fct_ticket_sales, fct_retail_line_items, fct_fundraising, dim_customer | Upstream enabled |
| `rpt_daily_operations` | fct_daily_operations | Upstream enabled |
| `rpt_digital_marketing` | fct_digital_ad_performance, fct_website_traffic | Ad + GA4 connected |
| `rpt_member_360` | fct_ticket_sales, fct_retail_line_items, silver_sf_marketing_cloud, dim_customer | SF + mart rewiring |
| `rpt_retail_performance` | fct_retail_line_items, dim_product, dim_payment_method, dim_customer | Upstream enabled |
| `rpt_revenue_bridge` | fct_daily_operations | Upstream enabled |
| `rpt_ticket_sales` | fct_ticket_sales, dim_ticket_type, dim_payment_method, dim_gate, dim_customer | Upstream enabled |
| `rpt_visitor_traffic` | fct_visitor_traffic, dim_gate, fct_ticket_sales | Upstream enabled |
