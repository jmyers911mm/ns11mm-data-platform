# DPR / Reporting Estate — Table & Column Crosswalk

> **Purpose:** for every active legacy report, the table this maps to which new
> dbt models, and how the old (legacy Galaxy / CounterPoint / 911dw) columns map
> to the new staging/mart columns.
> **Scope:** the active Pentaho report estate (13 registered exposures in
> `models/exposures.yml`; the DPR New/MTD/YTD/Excel variants collapse into two
> rows below).
> **Source of truth:** built from the current repo (`ns11mm/ns11mm-data-platform`)
> staging renames + the reconstructed report definitions. **Last updated:** 2026-07-29.

Legend for status: **Live** = runs on the current seed/stage loads ·
**Live\*** = totals live, one sub-split pending validation.

---

## 1. Report → model → base-table matrix

| Report (legacy) | Status | New report model | Feeder models | Base tables (RAW seeds) |
|---|---|---|---|---|
| Daily Performance Report (New/MTD/YTD) | Live | `rpt_daily_performance_report` | `fct_daily_performance` ← `int_dpr__*` | jnldetails, jnltickets, jnlitems, jnlheaders, items, vattribute, coa, disbursementdetails, rmevents, ps_tkt_hist_lin, im_item |
| Retail Performance Report | Live | `rpt_retail_performance` | `fct_retail_daily`, `fct_retail_performance` ← `int_retail__*` | ps_tkt_hist_lin, im_item (+ seed_sensource_visitors → `stg_sensource__visitors`, seed_fact_shopify_orders → `stg_shopify__orders`) |
| Retail Carts Analysis Report | Live | `rpt_retail_carts_analysis` | `fct_retail_daily` | ps_tkt_hist_lin, im_item (+ seed_sensource_visitors) |
| Monthly Retail KPI | Live | `rpt_monthly_retail_kpi` | `fct_retail_daily` | ps_tkt_hist_lin, im_item (+ seed_sensource_visitors) |
| Memorial Museum Daily Tracker YTD | Live | `rpt_memorial_museum_tracker_ytd` | `fct_daily_performance` | (DPR base tables above) |
| Daily Scan Report | Live\* | `rpt_daily_scan` | `fct_daily_scan` ← `int_gateway__scan_lines` | usage, jnltickets, vattribute |
| Attendance Report | Live | `rpt_attendance` | `fct_daily_performance` + `stg_sensource__attendance` | (DPR tables) + seed_sensource_attendance |
| Daily Attendance Report | Live | `rpt_daily_attendance` | `fct_daily_performance` + `stg_gateway__passes_by_hour` | (DPR tables) + seed_fact_passes_by_hour |
| Today's Sales (hourly_retail) | Live | `fct_today_sales_hourly` / `rpt_today_sales_powerbi` | `stg_counterpoint__todays_retail(_product)` | seed_fact_todays_retail_data (same-day CP) |
| Website Commerce Report | Live | `rpt_website_commerce` | `stg_ecommerce__website_recurring` | seed_fact_website_recurring_data (Drupal commerce) |
| Blue State WiFi Email Export | Live | `rpt_wifi_email_export` (PII) | `stg_wifi__audience` | seed_stage_acceptance_uap_daily |
| DPR Excel Data | Live | (DPR data feed) | `fct_daily_performance` | (DPR tables) |

---

## 2. Base-table column crosswalk (old → new)

These renames happen once in the staging layer and are shared by every report
that uses the table. Only the report-relevant columns are listed; the staging
models carry the full set.

### Gateway `JnlDetails` → `stg_gateway__jnldetails`
| Legacy column | New column | Used for |
|---|---|---|
| `Qty` | `quantity` | tickets_sold, units |
| `Amount` | `amount` | ticket_revenue, all Gateway $ measures |
| `JnlcodeID` | `jnl_code_id` | journal split (101 tickets / 102-104 items) |
| `AuxTableID` | `aux_table_id` | bridge to JnlTickets / JnlItems |
| `AccountID` | `account_id` | COA join |
| `OrderLineID` | `order_line_id` | unissued link (**zeroed in extract**) |

### Gateway `JnlTickets` → `stg_gateway__jnltickets`
| Legacy column | New column | Used for |
|---|---|---|
| `PLU` | `plu` | product / tour PLU classification |
| `visualID` | `visual_id` | **scan ↔ ticket join** (Daily Scan) |
| `Qty` | `quantity` | ticket quantity |
| `eventNo` | `event_no` | RMEvents join (recognize date) |
| `orderNo` | `order_no` | order link |
| `disbursementID` | `disbursement_id` | ga_flag (**zeroed in extract**) |
| `ticketDate` | `ticket_date` | recognize date (**~95% unparseable**) |
| `dateSold` | `sold_at` | recognize basis 349 |
| `endOfLifeDate` | `end_of_life_date` | recognize-date fallback (visit date) |
| `salesChannelID` | `sales_channel_id` | market segment (Daily Scan) |
| `salesProgramID` | `sales_program_id` | market segment alt key |
| `attributeValueGroupID` | `attribute_value_group_id` | vAttribute join |

### Gateway `Items` → `stg_gateway__items`
| Legacy column | New column | Used for |
|---|---|---|
| `PLU` (join key) | `plu` (`trim(plu)`) | join to JnlTickets; **trimmed for CHAR(20) padding** |
| `descr` | `description` | item description |
| `attributeValueGroupID` | `attribute_value_group_id` | vAttribute join |

### Gateway `report.vAttribute` → `stg_gateway__vattribute`
| Legacy column | New column | Used for |
|---|---|---|
| `avgID` | `avg_id` | join key from Items |
| `rItmMatrixCode` | `itm_matrix_code` | matrix classification (GAD/TOU/MGT/CPA/...) |
| `rItmRecognizeBasisID` | `itm_recognize_basis_id` | recognize-date basis (182/185/349) |
| `rAcsDynamicChannel` | `acs_dynamic_channel` | sales channel (Daily Scan segment candidate) |

### Gateway `Usage` → `stg_gateway__usage`
| Legacy column | New column | Used for |
|---|---|---|
| `usageID` | `usage_id` | scan event id |
| `visualID` | `visual_id` | ticket join |
| `acp` | `acp_id` | gate id |
| `facilityID` | `facility_id` | attendance area |
| `Qty` | `quantity` | scanned quantity (scannedQty) |
| `status` | `status_code` | valid-scan flag |
| `useTime` | `use_time` | scan date |

### Gateway `JnlItems` → `stg_gateway__jnlitems`
| Legacy column | New column | Used for |
|---|---|---|
| `PLU` | `plu` (`trim(plu)`) | item-journal product (fees, audio, donations) |
| `Amount` | `amount` | item-journal $ |
| `kind` | `kind` | item kind (audio = 8) |
| `costAmt` | `cost_amt` | COGS |

### CounterPoint `ps_tkt_hist_lin` → `stg_counterpoint__pstkthistlin`
| Legacy column | New column | Used for |
|---|---|---|
| `bus_dat` | `business_date` | retail date |
| `str_id` | `store_id` | store → facility mapping |
| `item_no` | `item_no` | item + donation keys (7-999, 101375, 101165) |
| `categ_cod` | `category_code` | product category (tshirts/hats/food/...) |
| `qty_sold` | `quantity_sold` | units sold |
| `qty_ret` | `quantity_returned` | units returned |
| `ext_prc` | `ext_price` | sale/return amount |
| `ext_cost` | `ext_cost` | COGS |
| `lin_typ` | `line_type` | S = sale, R = return |
| `doc_id` | `doc_id` | transaction count (distinct) |

### CounterPoint `im_item` → `stg_counterpoint__imitem`
| Legacy column | New column | Used for |
|---|---|---|
| `item_no` | `item_no` | join to lines |
| `descr` | `description` | item description |
| `categ_cod` | `category_code` | category enrichment |

---

## 3. Per-report measure crosswalk (legacy field → new mart column)

The base-table renames above feed these. Below is the report-facing measure
mapping: the legacy report field on the left, the new mart column it now comes
from on the right.

### Daily Performance Report — `fct_daily_performance` / `rpt_daily_performance_report`
| Legacy field | New column | Notes |
|---|---|---|
| `tickets_sold` | `tickets_sold` | issued-GA slice (unissued/CityPASS pending, ADR-005) |
| `ticket_revenue` | `ticket_revenue` | |
| `pass_revenue` | `pass_revenue` | CPA/CPB |
| `mus_attendance` | `mus_attendance` | GA-ticket proxy (Sensource pending) |
| `mem_attendance` | `mem_attendance` | scan-based |
| `mus_guided_tour_revenue` | `mus_guided_tour_revenue` | early-access/youth-fam excluded via seed |
| `mem_mus_tour_revenue` | `mem_mus_tour_revenue` | PLU list (product 178) |
| `service_fees` | `service_fees` | `FEE-*-MUF/MEF` matrix (source gap on code 33) |
| `audio_tour_headset` | `audio_tour_headset` | Galaxy + CP fac-1060 |
| `mem_audio_guide_revenue` | `mem_audio_guide_revenue` | Galaxy %MAG% + CP fac-1040 |
| `mus_store_gross_profit` | `mus_store_gross_profit` | fac 1003 |
| `retail_carts_gross_profit` | `retail_carts_gross_profit` | fac 1020 |
| `cafe1_all_profit` | `cafe1_all_profit` | fac 4007 (store 1) |
| `box_office_mem_don` | `box_office_mem_don` | PLU DONOPSMEM003 |
| `box_office_mus_exit_don` | `box_office_mus_exit_don` | PLU DONOPSMUS003 |
| `coatcheck_don` | `coatcheck_don` | %DON-OPS-MUS% excl DONOPSMUS003 |
| `mask_donations` | `mask_donations` | CP item 200704 (dormant) |
| `donation_box` | `donation_box` | CP item 101165 |
| `mus_exit_donations` | `mus_exit_donations` | CP item 101375 (was surrogate 886) |
| `cart_donation_ask` | `cart_donation_ask` | CP item 7-999 (was surrogate 483) |
| `ticketing_donations` | `ticketing_donations` | excl member-desk DONMBRMUS001 |

### Retail Performance Report — `fct_retail_performance` / `fct_retail_daily` / `rpt_retail_performance`
| Legacy field | New column | Source facility / logic |
|---|---|---|
| `net_profit_mus_store` | `net_profit` (fac 1003) | Museum Store |
| `net_profit_mem_cart` | `net_profit` (fac 1020) | Memorial Carts |
| `cafe1_all_profit` | `net_profit` (fac 4007) | Cafe |
| `sales_all_cat_mus_store` | `net_sales` (fac 1003) | |
| `customers_mus_store` / `customers_mem_cart` | `transactions` | `count(distinct doc_id)` |
| `cafe1_transactions` | `transactions` (fac 4007) | |
| `total_<category>_units` / `_profit` | `net_units` / `net_profit` by `category_code` | tidy long grain (one row/category) |
| `AvgSale` / `AvgSaleMemCart` | `avg_sale` | `net_sales / transactions` (query grain) |
| `ConversionRate` | `conversion_rate` | `transactions / visitor_count` (Sensource, staged) |
| `RevPerVis` / `MemCartsRevPerVis` | `rev_per_visitor` | `net_sales / visitor_count` (Sensource, staged) |
| `visitor_counted_mus_store` | `visitor_count` | `stg_sensource__visitors` (staged) |
| `ecom_total_orders` | `ecom_orders` | `stg_shopify__orders` (staged) |
| `*_budget` | `net_sales_budget` / `net_profit_budget` | budget seeds via `stg_budget__retail` / `int_budget__retail_forecasts` |

### Retail Carts Analysis — `rpt_retail_carts_analysis`
| Legacy field | New column | Logic |
|---|---|---|
| `Sales from Memorial Carts` | `sales_mem_cart` | fac 1020 net sales |
| `Gross Profit from Memorial Carts` | `profit_mem_cart` | fac 1020 net profit |
| `Memorial Cart Customers` | `mem_cart_customers` | transactions |
| `Memorial Visitors less 25%` … | `adj_visitors` | `(mem_vis − 0.25·mem_vis) − mus_vis` (Sensource visitors, staged) |
| `Memorial Carts Capture Rate` | `capture_rate` | `customers / adj_visitors` |
| `Profit Per Cap` / `Sales Per Cap` | `profit_per_cap` / `sales_per_cap` | ÷ adj_visitors |

### Daily Scan Report — `fct_daily_scan` / `rpt_daily_scan`
| Legacy field | New column | Logic |
|---|---|---|
| `<segment>_passes_scanned` | `passes_scanned` (per `segment_key`) | `usage.quantity` on valid scans |
| `<segment>_tickets_sold` | `tickets_sold` (per `segment_key`) | ticket quantity |
| `%market_<segment>` | `pct_of_scanned` / `pct_of_sold` | share of day total (window) |
| `<segment>_passes_budget` | `passes_budget` | `stg_budget__daily_scan` (DSR budget, staged) |
| category → segment | `seed_scan_market_segment` | **mapping via `acs_dynamic_channel` — validate** |

### Attendance / Daily Attendance / Today's Sales / Website Commerce / WiFi
| Report | Legacy field → new column | Source |
|---|---|---|
| Attendance | `mem_attendance`/`mus_attendance` → same; `memorial_only`/`mus_store`/`mus_store_vesey` → `memorial_only`/`museum_store`/`museum_store_vesey` | DPR live; area counts via `stg_sensource__attendance` (staged) |
| Daily Attendance | `mus_attendance` → `museum_attendance` | `stg_gateway__passes_by_hour` (staged; scan fallback) |
| Today's Sales | hourly `sales`/`transactions`/`units` → same by `hour_of_day`×facility | `stg_counterpoint__todays_retail` (same-day CP, staged) |
| Website Commerce | `Donation Revenue`/`Membership Revenue` by year → `amount` by `revenue_type`×`revenue_year` | `stg_ecommerce__website_recurring` (Drupal commerce, staged) |
| WiFi Email Export | `EMAIL_ADDRESS`→`email_address`, `FIRST_NAME`→`first_name`, `LAST_NAME`→`last_name` | `stg_wifi__audience` (staged) — **RESTRICTED/PII** |

---

## 4. Feed status (formerly "still to source")

Every feed that was stub-wired in earlier revisions has now **landed as a
`report_estate_seed` stage load with a real staging model** — no report logic
changed, as designed:

| RAW table (source group) | Staging model | Feeds reports | Replaces legacy |
|---|---|---|---|
| `seed_sensource_visitors` / `seed_sensource_attendance` | `stg_sensource__visitors` / `stg_sensource__attendance` | Attendance, Daily Attendance, retail ratios | `fact_visitors` / hourly sensordata |
| `seed_fact_passes_by_hour` | `stg_gateway__passes_by_hour` | Daily Attendance | `fact_passes_by_hour` |
| `seed_fact_todays_retail_data` (+ `_product_data`) | `stg_counterpoint__todays_retail(_product)` | Today's Sales | `fact_todays_retail_data` |
| `seed_fact_website_recurring_data`, `seed_fact_shopify_*` | `stg_ecommerce__website_recurring`, `stg_shopify__*` | Website Commerce, DPR ecom | `fact_shopify_orders` / recurring |
| `seed_stage_acceptance_uap_daily` | `stg_wifi__audience` | WiFi export (PII) | Blue State audience table |
| Budget workbooks (Excel→CSV seed loads: `budget_seeds` + `seed_retail_budget` / `seed_dsr_budget`) | `int_budget__*`, `stg_budget__*` | all `_budget`/variance columns | `fact_*_forecasts`, `fact_dpr_report_data` budgets |

Still genuinely open: **automating the loads** (today these are manual stage/seed
refreshes; production ingestion is the Azure Function estate, currently parked in
`disabled/`), and the **Classy fundraising feed** (`int_classy` remains disabled;
Website Commerce runs on the Drupal-commerce recurring table alone).