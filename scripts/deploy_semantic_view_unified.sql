-- GENERATED FILE -- do not edit by hand.
-- Source of truth: cortex_project/UNIFIED.sv.yaml
-- Regenerate: python3 scripts/generate_semantic_view_ddl.py
-- Run as the MARTS owner role. Equivalent to redeploying the .sv.yaml via the
-- Cortex project; use whichever path you have. Custom instructions and verified
-- queries in the YAML deploy via the Cortex project path, not this DDL.
CREATE OR REPLACE SEMANTIC VIEW MARTS.UNIFIED
  TABLES (
    date AS MARTS.DIM_DATE PRIMARY KEY (DATE_KEY) COMMENT = 'Conformed calendar/date dimension. The single shared axis every live fact reconciles against.',
    dpr AS MARTS.FCT_DAILY_PERFORMANCE PRIMARY KEY (DATE_KEY) COMMENT = 'Ticketing / DPR additive day-grain fact. One row per calendar day.',
    retail_daily AS MARTS.FCT_RETAIL_DAILY PRIMARY KEY (DATE_KEY, KEY_FACILITY) COMMENT = 'Retail facility-grain fact. One row per day per selling area. Base for retail ratios.',
    retail_category AS MARTS.FCT_RETAIL_PERFORMANCE PRIMARY KEY (DATE_KEY, KEY_FACILITY, CATEGORY_CODE) COMMENT = 'Retail category-grain fact. One row per day per selling area per product category.',
    daily_scan AS MARTS.FCT_DAILY_SCAN PRIMARY KEY (DATE_KEY, SEGMENT_KEY) COMMENT = 'Gate-scan fact. One row per day per market segment. Scan component only.'
  )
  RELATIONSHIPS (
    dpr_to_date AS dpr (DATE_KEY) REFERENCES date (DATE_KEY),
    retail_daily_to_date AS retail_daily (DATE_KEY) REFERENCES date (DATE_KEY),
    retail_category_to_date AS retail_category (DATE_KEY) REFERENCES date (DATE_KEY),
    daily_scan_to_date AS daily_scan (DATE_KEY) REFERENCES date (DATE_KEY)
  )
  DIMENSIONS (
    date.report_date AS DATE_DAY WITH SYNONYMS = ('date', 'day', 'business date') COMMENT = 'Calendar date the numbers are recognized on.',
    date.year AS YEAR_NUMBER WITH SYNONYMS = ('year', 'calendar year') COMMENT = 'Calendar year (from dim_date year_number). No fiscal calendar yet — pending Data & AI Committee definition.',
    date.month AS MONTH_OF_YEAR WITH SYNONYMS = ('month', 'month number') COMMENT = 'Month of year (1-12).',
    date.calendar_year AS YEAR_NUMBER WITH SYNONYMS = ('year', 'calendar year'),
    date.calendar_quarter AS QUARTER_OF_YEAR WITH SYNONYMS = ('quarter', 'qtr', 'calendar quarter'),
    date.calendar_month AS MONTH_OF_YEAR WITH SYNONYMS = ('month number', 'calendar month'),
    date.month_name AS MONTH_NAME WITH SYNONYMS = ('month'),
    date.day_name AS DAY_OF_WEEK_NAME WITH SYNONYMS = ('weekday', 'day of week'),
    date.day_of_month AS DAY_OF_MONTH WITH SYNONYMS = ('day of month'),
    date.week_of_year AS WEEK_OF_YEAR WITH SYNONYMS = ('week', 'week number'),
    date.is_weekend AS IS_WEEKEND WITH SYNONYMS = ('weekend flag', 'weekend'),
    date.is_weekday AS IS_WEEKDAY WITH SYNONYMS = ('weekday flag'),
    date.is_commemoration_day AS IS_COMMEMORATION_DAY WITH SYNONYMS = ('commemoration', 'anniversary window', '9/11 period') COMMENT = 'TRUE for September 11, a known structural exception.',
    retail_daily.area_name AS AREA_NAME WITH SYNONYMS = ('store', 'selling area', 'location', 'shop') COMMENT = 'Selling area (Museum Store, Memorial Carts, Cafe, Ecommerce, Atrium). Constrains rd.* metrics only.',
    retail_daily.area_group AS AREA_GROUP WITH SYNONYMS = ('area type', 'retail channel') COMMENT = 'Retail area grouping. Constrains rd.* metrics only.',
    retail_daily.total_net_sales AS SUM(NET_SALES) WITH SYNONYMS = ('retail sales', 'net sales', 'store sales') COMMENT = 'Net retail sales (gross less returns and discounts) from CounterPoint POS, by selling area.',
    retail_daily.total_net_profit AS SUM(NET_PROFIT) WITH SYNONYMS = ('retail profit', 'net profit', 'store net profit'),
    retail_daily.total_units AS SUM(NET_UNITS) WITH SYNONYMS = ('units', 'items sold', 'quantity sold'),
    retail_daily.total_retail_donations AS SUM(DONATIONS) WITH SYNONYMS = ('retail donations', 'store donations at register'),
    retail_daily.total_transactions AS SUM(TRANSACTIONS) WITH SYNONYMS = ('transactions', 'carts', 'orders count'),
    retail_daily.total_visitors AS SUM(VISITOR_COUNT) WITH SYNONYMS = ('retail visitors', 'store visitors', 'door count', 'store entries', 'foot traffic') COMMENT = 'Sensource door count at the selling area (entries at the Museum Store, exits at Vesey). Numerator of capture_rate, denominator of conversion_rate. Live since 8.4.0.',
    retail_daily.total_ecom_orders AS SUM(ECOM_ORDERS) WITH SYNONYMS = ('ecommerce orders', 'online orders') COMMENT = 'Ecommerce order count. STUB until Shopify lands.',
    retail_daily.profit_margin AS SUM(NET_PROFIT) / NULLIF(SUM(NET_SALES), 0) WITH SYNONYMS = ('margin', 'retail margin', 'profit margin') COMMENT = 'Non-additive: net profit / net sales, recomputed at the query grain.',
    retail_daily.avg_sale AS SUM(NET_SALES) / NULLIF(SUM(TRANSACTIONS), 0) WITH SYNONYMS = ('average sale', 'average transaction value', 'basket size') COMMENT = 'Non-additive: net sales / transactions, recomputed at the query grain.',
    retail_daily.conversion_rate AS SUM(TRANSACTIONS) / NULLIF(SUM(VISITOR_COUNT), 0) WITH SYNONYMS = ('conversion', 'conversion rate', 'purchase rate', 'buy rate', 'share of store visitors who bought') COMMENT = 'Non-additive: transactions / store door count, recomputed at the query grain. The share of the people who came INTO the store who bought something. This is NOT the capture rate -- use capture_rate for that. Legacy definition of record: t_fact_mus_store_analysis.sql:19.',
    retail_daily.capture_rate AS SUM(VISITOR_COUNT) / NULLIF(SUM(MUSEUM_ATTENDANCE), 0) WITH SYNONYMS = ('capture', 'capture rate', 'store capture', 'draw rate', 'share of museum visitors who entered the store') COMMENT = 'Non-additive: store door count / museum attendance (Sensource passes scanned), recomputed at the query grain. The share of museum visitors who came INTO the store. Distinct from conversion_rate, which divides by the door count rather than into it. Legacy definition of record: t_fact_mus_store_analysis.sql:17.',
    retail_daily.rev_per_visitor AS SUM(NET_SALES) / NULLIF(SUM(VISITOR_COUNT), 0) WITH SYNONYMS = ('revenue per store visitor', 'sales per store visitor') COMMENT = 'Non-additive: net sales / store door count, recomputed at the query grain. Per-STORE-visitor. For per-museum-visitor use sales_per_cap.',
    retail_daily.sales_per_cap AS SUM(NET_SALES) / NULLIF(SUM(MUSEUM_ATTENDANCE), 0) WITH SYNONYMS = ('sales per cap', 'sales per capita', 'retail spend per museum visitor', 'per cap sales') COMMENT = 'Non-additive: net sales / museum attendance, recomputed at the query grain. Legacy per-cap basis.',
    retail_daily.profit_per_cap AS SUM(NET_PROFIT) / NULLIF(SUM(MUSEUM_ATTENDANCE), 0) WITH SYNONYMS = ('profit per cap', 'profit per capita', 'retail profit per museum visitor') COMMENT = 'Non-additive: net profit / museum attendance, recomputed at the query grain. Legacy per-cap basis.',
    retail_category.category_net_sales AS SUM(NET_SALES) WITH SYNONYMS = ('category sales', 'product category sales'),
    retail_category.category_net_profit AS SUM(NET_PROFIT) WITH SYNONYMS = ('category profit', 'product category profit'),
    retail_category.category_units AS SUM(NET_UNITS) WITH SYNONYMS = ('category units', 'items by category'),
    retail_category.category_cost_of_goods AS SUM(COST_OF_GOODS) WITH SYNONYMS = ('category cost of goods', 'category COGS'),
    daily_scan.scan_passes_scanned AS SUM(PASSES_SCANNED) WITH SYNONYMS = ('passes scanned', 'scans', 'admissions scanned', 'entries') COMMENT = 'Valid Gateway passes scanned at entry (excludes staff and re-entry). Scan component only.',
    daily_scan.scan_tickets_sold AS SUM(TICKETS_SOLD) WITH SYNONYMS = ('scan-side tickets sold', 'segment tickets sold') COMMENT = 'GA tickets sold from the scan-side daily fact (by segment). Reconcile against dpr.total_tickets_sold.',
    daily_scan.scan_utilization AS SUM(PASSES_SCANNED) / NULLIF(SUM(TICKETS_SOLD), 0) WITH SYNONYMS = ('scan utilization', 'utilization', 'redemption rate', 'scan rate') COMMENT = 'Non-additive: passes scanned / tickets sold, recomputed at the query grain.'
  )
  COMMENT = 'Cross-domain reconciliation surface for the Museum Data Warehouse. Ticketing and admissions (DPR), retail by selling area and product category, and gate scanning by market segment -- all reconciled against one conformed calendar so a user can combine any live metric with any shared date dimension in a single question. Facility/category retail detail, ticketing KPIs, donations, tours, audio, and scan/redemption all in one place. Budget/variance, full Sensource attendance, membership, ecommerce gross profit, monthly online revenue and same-day hourly sales are out of scope (see the domain models).';
