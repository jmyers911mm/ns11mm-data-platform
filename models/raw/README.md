# Raw / Staging Models

Staging views that clean and rename columns from source tables in `{{ target.database }}.RAW`
(plus the budget seeds in `SEEDS`). 34 staging models, all enabled.

## Sources

Declared in `sources.yml` (three groups) and `_budget_sources.yml`:

| Source | Schema | Status | Freshness |
|--------|--------|--------|-----------|
| `gateway_seed` (Gateway Ticketing Galaxy) | RAW | Active | warn 7d / error 14d |
| `counterpoint_seed` (NCR CounterPoint POS) | RAW | Active | warn 7d / error 14d |
| `report_estate_seed` (911dw report-estate tables: attendance, today's sales, ecommerce, WiFi, budgets) | RAW | Active | warn 2d / error 4d |
| `budget_seeds` (Excel budget workbooks loaded as CSV seeds; read by `int_budget__*` directly — documented exception to the `stg_` pattern) | SEEDS | Active | — |

All source databases resolve via `{{ target.database }}` so the same definitions work in
every personal dev database, CI, and prod.

## Key Design Notes

- All staging models deduplicate using `QUALIFY ROW_NUMBER() OVER (PARTITION BY <pk> ORDER BY _loaded_at DESC) = 1`
- Date columns use `try_to_timestamp()` for safe parsing
- `stg_gateway__tickets.ticket_date` is sourced from `endoflifedate` (not `ticketdate` which is empty in Galaxy)

## Enabled Models (34)

### Gateway Ticketing Galaxy — 17 `stg_gateway__*`

| Model | Source Table | Primary Key |
|-------|-------------|-------------|
| `stg_gateway__acps` | SEED_GATE_ACPS | acp_id |
| `stg_gateway__coa` | SEED_GATE_COA | — |
| `stg_gateway__disbursementdetails` | SEED_GATE_DISBURSEMENTDETAILS | — |
| `stg_gateway__facility` | SEED_GATE_FACILITY | facility_id |
| `stg_gateway__items` | SEED_GATE_ITEMS | plu |
| `stg_gateway__jnldetails` | SEED_GATE_JNLDETAILS | — |
| `stg_gateway__jnlheaders` | SEED_GATE_JNLHEADERS | journal_header_id |
| `stg_gateway__jnlitems` | SEED_GATE_JNLITEMS | — |
| `stg_gateway__jnltickets` | SEED_GATE_JNLTICKETS | — |
| `stg_gateway__orderlines` | SEED_GATE_ORDERLINES | order_line_id |
| `stg_gateway__orders` | SEED_GATE_ORDERS | order_id |
| `stg_gateway__passes_by_hour` | SEED_FACT_PASSES_BY_HOUR (report_estate_seed) | date × hour |
| `stg_gateway__rmevents` | SEED_GATE_RMEVENTS | event_id |
| `stg_gateway__tickets` | SEED_GATE_TICKETS | ticket_id |
| `stg_gateway__usage` | SEED_GATE_USAGE | usage_id |
| `stg_gateway__vattribute` | SEED_GATE_VATTRIBUTE | — |
| `stg_gateway__vusage` | SEED_GATE_VUSAGE | — |

### NCR CounterPoint POS — 7 `stg_counterpoint__*`

| Model | Source Table | Primary Key |
|-------|-------------|-------------|
| `stg_counterpoint__imitem` | SEED_CP_IMITEM | item_no |
| `stg_counterpoint__pstkthist` | SEED_CP_PSTKTHIST | doc_id |
| `stg_counterpoint__pstkthistlin` | SEED_CP_PSTKTHISTLIN | doc_id + line_seq_no |
| `stg_counterpoint__todays_retail` | SEED_FACT_TODAYS_RETAIL_DATA (report_estate_seed) | date × hour × store |
| `stg_counterpoint__todays_retail_product` | SEED_FACT_TODAYS_RETAIL_PRODUCT_DATA (report_estate_seed) | date × store × item |
| `stg_counterpoint__vitkthist` | SEED_CP_VITKTHIST | doc_id |
| `stg_counterpoint__vitkthistlin` | SEED_CP_VITKTHISTLIN | doc_id + line_seq_no + seq_no |

### Report estate, budgets, and other feeds — 10 models

| Model | Source Table | Domain |
|-------|-------------|--------|
| `stg_budget__daily_scan` | SEED_DSR_BUDGET (report_estate_seed) | Daily-scan budget by market segment |
| `stg_budget__retail` | SEED_RETAIL_BUDGET (report_estate_seed) | Retail budget/forecast by facility/day |
| `stg_dpr__daily_metrics_wide` | SEED_WIFI_AUDIENCE (report_estate_seed; misnamed wide-metrics table — see the source description) | Legacy DPR wide daily metrics |
| `stg_ecommerce__website_recurring` | SEED_FACT_WEBSITE_RECURRING_DATA (report_estate_seed) | Recurring online donations/memberships (Website Commerce) |
| `stg_sensource__attendance` | SEED_SENSOURCE_ATTENDANCE (report_estate_seed) | Daily attendance by area |
| `stg_sensource__visitors` | SEED_SENSOURCE_VISITORS (report_estate_seed) | Entries/exits/passes by facility |
| `stg_shopify__cost_values` | SEED_FACT_SHOPIFY_COST_VALUES (report_estate_seed) | Shopify COGS |
| `stg_shopify__discounts` | SEED_FACT_SHOPIFY_DISCOUNTS (report_estate_seed) | Shopify discounts |
| `stg_shopify__orders` | SEED_FACT_SHOPIFY_ORDERS (report_estate_seed) | Shopify orders (ecom, ADR-008) |
| `stg_wifi__audience` | SEED_STAGE_ACCEPTANCE_UAP_DAILY (report_estate_seed) | **RESTRICTED/PII** WiFi captive-portal audience |
