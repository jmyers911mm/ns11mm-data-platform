# 1.6.1: Report-Estate Ingestion: Stub Seeds → Real Sources

- **Date:** 2026-07-15
- **Version:** 1.6.1

Loaded the first batch of report-estate source tables from stage into RAW,
added their staging models, and repointed the consuming models off the interim
stub seeds onto real data. Four of the nine report-estate stubs are now live;
five remain stubbed pending their feeds (Sensource, WiFi, budget). Follows the
seed-swap-with-no-report-rework pattern established in 1.6.0.
 
## Added
 
### RAW sources (`models/raw/sources.yml`)
 
- **`report_estate_seed`** source group — seven 911dw tables loaded from stage
  into `RAW` (naming `SEED_FACT_*`, matching the existing seed convention):
  `seed_fact_passes_by_hour`, `seed_fact_todays_retail_data`,
  `seed_fact_todays_retail_product_data`, `seed_fact_website_recurring_data_db`,
  `seed_fact_shopify_orders`, `seed_fact_shopify_discounts`,
  `seed_fact_shopify_cost_values`. Freshness set to 2-day warn / 4-day error
  (more time-sensitive than the 7-day Gateway/CounterPoint seeds).
### Staging models (`models/raw/`)
 
Rename/recast only, faithful to source (ADR-001):
 
- **`stg_gateway__passes_by_hour`** — hourly gate passes (`key_date/perhour/
  passes` → `business_date/hour_of_day/passes`).
- **`stg_counterpoint__todays_retail`** — same-day hourly CP retail (8 cols).
- **`stg_counterpoint__todays_retail_product`** — same-day product detail.
- **`stg_ecommerce__website_recurring`** — recurring online donations/memberships
  (12 cols). `email` flagged as PII in-model; mark restricted in schema.yml if
  surfaced downstream.
- **`stg_shopify__orders`** — Shopify order lines (16 cols). `key_date` parsed
  from `YYYYMMDD`; large id columns kept as varchar (no precision loss); literal
  `'NULL'` strings in refund columns nullified via `try_to_decimal`.
- **`stg_shopify__cost_values`** — order-level gross/net/profit (10 cols).
- **`stg_shopify__discounts`** — discount codes/totals (5 cols); blank codes → null.
### Loader
 
- **`load_raw_from_stage.sql`** runbook — `INFER_SCHEMA` → `CREATE TABLE USING
  TEMPLATE` → `COPY INTO` per table (Parquet + CSV paths), transient RAW,
  `_loaded_at` default, verification queries.
## Changed — stub → real source
 
Consuming models repointed off `tmp_seed_*` stubs onto the new staging models.
The swaps were not pure `ref()` substitutions: the stub seeds used idealized
column names, so the real staging columns required adapting the consumers'
logic.
 
- **`rpt_daily_attendance`** — `tmp_seed_gateway__passes_by_hour` →
  `stg_gateway__passes_by_hour` (clean swap; same shape).
- **`fct_today_sales_hourly`** — rebuilt on `stg_counterpoint__todays_retail`.
  Real feed carries `store_id` (not `key_facility`), `doc_id`, and
  `quantity_sold`; now maps store → facility via `seed_retail_store_facility`,
  derives `transactions = count(distinct doc_id)`, `units = quantity_sold`, and
  adds real `cost` / `profit`.
- **`rpt_website_commerce`** — rebuilt on `stg_ecommerce__website_recurring`.
  `revenue_type` derived from `order_type` / `title` (Donation vs Membership),
  `revenue_year` / month from `created_at`, `amount` from `revenue`.
- **`int_retail__visitors`** — Shopify CTE now reads `stg_shopify__orders`;
  `ecom_orders = count(distinct order_id)` (real feed is one row per order line).
## Still stubbed (no data yet)
 
`tmp_seed_sensource__visitors`, `tmp_seed_sensource__attendance`,
`tmp_seed_wifi__audience`, `tmp_seed_retail__budget`, `tmp_seed_dsr__budget` —
consumed by `int_retail__visitors` (visitor half), `rpt_attendance`,
`rpt_wifi_email_export`, `fct_retail_performance`, `fct_daily_scan`. Unchanged.
 
## Deploy
 
```
dbt build --select source:report_estate_seed+ --target dev
```
 
Builds the new sources → 7 staging models → 4 updated consumers → their reports
in dependency order.
 
## Known Issues / Verify after deploy
 
- **Today's Sales store mapping** — CP today-feed uses stores 1,8-14; confirm
  `seed_retail_store_facility` covers all; unmapped stores fall to
  `key_facility = -1` (`select key_facility, count(*) from fct_today_sales_hourly
  group by 1`).
- **Website Commerce revenue_type** — the Donation/Membership split is a
  keyword match on `order_type`/`title`; validate against
  `select distinct order_type, title from stg_ecommerce__website_recurring` and
  adjust the CASE if the real values differ.
- **Shopify data age** — sample data is 2016-2018; if that is the actual range,
  ecom figures are historical, not current.
- **`email` PII** in `stg_ecommerce__website_recurring` — classify in schema.yml
  (restricted) before surfacing downstream.
- **Naming** — confirm `fact_website_recurring_data_db` vs workbook `..._d8`.
