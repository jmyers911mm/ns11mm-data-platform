# Intermediate (Silver) Models

Business logic transformations that clean, enrich, and combine staging data into analytical building blocks.
Materialized as views by default; four heavily-read models (`int_gateway__ticket_journal_lines`,
`int_gateway__item_journal_lines`, `int_gateway__ticket_demand_features`,
`int_counterpoint__retail_lines`) are tables.

## Enabled Models (21)

### Gateway (ticketing)

| Model | Description |
|-------|-------------|
| `int_gateway__item_attributes` | Conformed Gateway item/ticket attributes (vattribute), one row per attribute value group |
| `int_gateway__item_journal_lines` | Enriched Gateway (Galaxy) item journal lines (audio guides, service fees, ticketing donations) |
| `int_gateway__scan_lines` | Gate scan lines with ticket market segment |
| `int_gateway__ticket_demand_features` | Ticket demand features (presale lead time + temporal patterns) |
| `int_gateway__ticket_journal_lines` | Enriched Gateway (Galaxy) ticket journal lines (jnl_code_id = 101) |

### CounterPoint / retail

| Model | Description |
|-------|-------------|
| `int_counterpoint__retail_lines` | CounterPoint (NCR) retail transaction lines with seed-driven store scope + facility assignment |
| `int_retail__customers` | Retail customer / transaction counts (business_date × facility) |
| `int_retail__performance` | Retail performance, tidy category grain (business_date × facility × category) |
| `int_retail__visitors` | Retail visitor counts + ecommerce orders (reads `stg_sensource__visitors` + `stg_shopify__orders`) |

### DPR metric definitions

| Model | Description |
|-------|-------------|
| `int_dpr__admissions` | General-admission tickets sold, ticket revenue, attendance |
| `int_dpr__attendance` | Scan-based museum and memorial attendance |
| `int_dpr__donations` | Gateway ticketing donations (issued) and box/exit donations |
| `int_dpr__fees_and_services` | Service fees, audio guide/headset, memorial+museum tour |
| `int_dpr__retail` | Retail gross profit, MUS AG, and retail-sourced donations |
| `int_dpr__tour_revenue` | Guided-tour, virtual-tour, field-trip, and program revenue |

### Budget

| Model | Description |
|-------|-------------|
| `int_budget__admissions_forecasts` | Cleanse and type-cast admissions/attendance forecast seed (date × facility) |
| `int_budget__dpr_forecasts` | Cleanse and type-cast DPR budget/forecast seed (one row per day) |
| `int_budget__retail_forecasts` | Cleanse and type-cast retail forecast seed (date × facility) |

### Tickets (legacy-named)

| Model | Description |
|-------|-------------|
| `int_pos_tickets` | Daily POS ticket transactions from Gateway tickets |
| `int_ticket_inventory` | Derived daily ticket inventory (reservations vs rolling-90d-max capacity) |
| `int_ticket_scans` | Ticket scan / usage events for gate admission counts |

## Disabled Models (`enabled=false`) — in `disabled/` subfolder (8)

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

## Naming note

`int_pos_tickets`, `int_ticket_inventory`, and `int_ticket_scans` predate the
`int_<domain>__<entity>` naming convention and are kept as-is to avoid churning
downstream refs. New intermediate models must use the `int_<domain>__<entity>`
form.
