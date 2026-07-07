# Intermediate (Silver) Models

Business logic transformations that clean, enrich, and combine staging data into analytical building blocks.

## Enabled Models

| Model | Sources | Description |
|-------|---------|-------------|
| `int_counterpoint__retail_lines` | `stg_counterpoint__pstkthistlin`, `stg_counterpoint__pstkthist`, seeds | CounterPoint retail line items with facility assignment |
| `int_gateway__item_journal_lines` | `stg_gateway__jnldetails`, `stg_gateway__jnlitems`, `stg_gateway__jnlheaders` | Gateway item-level journal lines (non-ticket revenue) |
| `int_gateway__ticket_journal_lines` | `stg_gateway__jnltickets`, `stg_gateway__jnlheaders`, `stg_gateway__items` | Gateway ticket journal lines with product classification |
| `int_gateway__ticket_demand_features` | `stg_gateway__tickets`, `stg_gateway__items` | Ticket demand features with presale lead time and temporal patterns |
| `int_pos_tickets` | `stg_gateway__tickets` | Daily POS ticket transactions for revenue reporting |
| `int_ticket_scans` | `stg_gateway__usage` | Gate scan events for visitor admission counts |
| `int_ticket_inventory` | `int_gateway__ticket_demand_features` | Derived daily ticket inventory (reservations vs rolling-90d-max capacity) |
| `int_dpr__admissions` | `int_gateway__ticket_journal_lines` | DPR admissions revenue |
| `int_dpr__donations` | `int_gateway__item_journal_lines` | DPR donation revenue |
| `int_dpr__fees_and_services` | `int_gateway__item_journal_lines` | DPR fees and services revenue |
| `int_dpr__retail` | `int_counterpoint__retail_lines` | DPR retail revenue |
| `int_dpr__tour_revenue` | `int_gateway__ticket_journal_lines` | DPR tour revenue |

## Disabled Models (`enabled=false`) — in `disabled/` subfolder

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `int_sf_crm` | Salesforce NPS | SF pipeline connected |
| `int_sf_marketing_cloud` | Salesforce Marketing Cloud | SFMC pipeline connected |
| `int_shopify` | Shopify | Shopify pipeline connected |
| `int_classy` | GoFundMe Pro / Classy | Classy pipeline connected |
| `int_blackbaud` | Blackbaud Financial Edge NXT | Blackbaud pipeline connected |
| `int_google_analytics` | Google Analytics 4 | GA4 pipeline connected |
| `int_google_ads` | Google Ads | Google Ads pipeline connected |
| `int_meta_ads` | Meta Ads | Meta Ads pipeline connected |
