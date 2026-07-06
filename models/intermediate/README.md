# Intermediate (Silver) Models

Business logic transformations that clean, enrich, and combine staging data into analytical building blocks.

## Enabled Models

| Model | Sources | Description |
|-------|---------|-------------|
| `silver_counterpoint__retail_lines` | `stg_counterpoint__pstkthistlin`, `stg_counterpoint__pstkthist`, seeds | CounterPoint retail line items with facility assignment |
| `silver_gateway__item_journal_lines` | `stg_gateway__jnldetails`, `stg_gateway__jnlitems`, `stg_gateway__jnlheaders` | Gateway item-level journal lines (non-ticket revenue) |
| `silver_gateway__ticket_journal_lines` | `stg_gateway__jnltickets`, `stg_gateway__jnlheaders`, `stg_gateway__items` | Gateway ticket journal lines with product classification |
| `silver_dpr__admissions` | `silver_gateway__ticket_journal_lines` | DPR admissions revenue |
| `silver_dpr__donations` | `silver_gateway__item_journal_lines` | DPR donation revenue |
| `silver_dpr__fees_and_services` | `silver_gateway__item_journal_lines` | DPR fees and services revenue |
| `silver_dpr__retail` | `silver_counterpoint__retail_lines` | DPR retail revenue |
| `silver_dpr__tour_revenue` | `silver_gateway__ticket_journal_lines` | DPR tour revenue |

## Disabled Models (`enabled=false`)

These models are preserved but disabled — their upstream sources are not yet connected.

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `silver_sf_crm` | Salesforce NPS | SF pipeline connected |
| `silver_sf_marketing_cloud` | Salesforce Marketing Cloud | SFMC pipeline connected |
| `silver_shopify` | Shopify | Shopify pipeline connected |
| `silver_classy` | GoFundMe Pro / Classy | Classy pipeline connected |
| `silver_blackbaud` | Blackbaud Financial Edge NXT | Blackbaud pipeline connected |
| `silver_google_analytics` | Google Analytics 4 | GA4 pipeline connected |
| `silver_google_ads` | Google Ads | Google Ads pipeline connected |
| `silver_meta_ads` | Meta Ads | Meta Ads pipeline connected |
