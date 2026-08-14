-- GENERATED FILE -- do not edit by hand.
-- 8.5.0 (ADR-005 GATED): capture_rate split out from conversion_rate.
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
    retail_category.area_name AS AREA_NAME WITH SYNONYMS = ('store', 'selling area for category') COMMENT = 'Selling area on the category fact. Constrains rc.* metrics only.',
    retail_category.category AS CATEGORY_CODE WITH SYNONYMS = ('product category', 'category', 'merch category') COMMENT = 'CounterPoint product category (Donations folded to Donations). Constrains rc.* metrics only.',
    daily_scan.market_segment AS SEGMENT_NAME WITH SYNONYMS = ('segment', 'market segment', 'channel', 'reseller', 'market') COMMENT = 'Market segment (CityPASS, C3, School Groups, Walk-up, ...). Constrains sc.* metrics only; split provisional pending channel-mapping validation.'
  )
  METRICS (
    dpr.total_tickets_sold AS SUM(TICKETS_SOLD) WITH SYNONYMS = ('tickets sold', 'admissions sold', 'ticket count') COMMENT = 'General-admission tickets sold (Gateway DPR).',
    dpr.total_ticket_revenue AS SUM(TICKET_REVENUE) WITH SYNONYMS = ('ticket revenue', 'admission revenue'),
    dpr.total_pass_revenue AS SUM(PASS_REVENUE) WITH SYNONYMS = ('pass revenue', 'CityPASS revenue', 'C3 revenue'),
    dpr.total_admission_revenue AS SUM(TICKET_REVENUE) + SUM(PASS_REVENUE) WITH SYNONYMS = ('total admission revenue') COMMENT = 'Governed admission-revenue numerator (ticket + pass revenue). Definition of record is the fct column TOTAL_ADMISSION_REVENUE; components restated here because the metric name shadows the same-named column (engine limitation) — guarded by assert_sv_admission_revenue_matches_fct on the DPR twin.',
    dpr.total_museum_attendance AS SUM(MUS_ATTENDANCE) WITH SYNONYMS = ('museum attendance', 'museum visitors') COMMENT = 'Museum attendance (scanned GA component; full Sensource blend not yet staged).',
    dpr.total_memorial_attendance AS SUM(MEM_ATTENDANCE) WITH SYNONYMS = ('memorial attendance', 'plaza attendance', 'memorial visitors') COMMENT = 'Memorial attendance (valid Gateway scans at memorial facilities). Scan component only.',
    dpr.total_mus_guided_tour_revenue AS SUM(MUS_GUIDED_TOUR_REVENUE) WITH SYNONYMS = ('museum guided tour revenue', 'guided tour revenue'),
    dpr.total_mem_guided_tour_revenue AS SUM(MEM_GUIDED_TOUR_REVENUE) WITH SYNONYMS = ('memorial guided tour revenue'),
    dpr.total_mem_mus_tour_revenue AS SUM(MEM_MUS_TOUR_REVENUE) WITH SYNONYMS = ('memorial and museum tour revenue', 'combined tour revenue'),
    dpr.total_revealed_tour_revenue AS SUM(REVEALED_TOUR_REVENUE) WITH SYNONYMS = ('revealed tour revenue'),
    dpr.total_ask_educator_revenue AS SUM(ASK_EDUCATOR_REVENUE) WITH SYNONYMS = ('ask an educator revenue', 'ask educator revenue'),
    dpr.total_field_trip_revenue AS SUM(MEM_FIELD_TRIP_REVENUE) + SUM(MUS_FIELD_TRIP_REVENUE) WITH SYNONYMS = ('field trip revenue', 'school trip revenue') COMMENT = 'Memorial + Museum field trip revenue.',
    dpr.total_virtual_tour_revenue AS SUM(VIRTUAL_MEM_TOUR_REVENUE) + SUM(VIRTUAL_MUS_TOUR_REVENUE) + SUM(VIRTUAL_YF_MEM_TOUR_REVENUE) WITH SYNONYMS = ('virtual tour revenue', 'online tour revenue') COMMENT = 'All virtual tour revenue (memorial, museum, youth & family).',
    dpr.total_service_fees AS SUM(SERVICE_FEES) WITH SYNONYMS = ('service fees', 'fees'),
    dpr.total_audio_revenue AS SUM(AUDIO_TOUR_HEADSET) + SUM(MEM_AUDIO_GUIDE_REVENUE) WITH SYNONYMS = ('audio guide revenue', 'all audio revenue') COMMENT = 'Museum audio/headset plus memorial audio guide revenue.',
    dpr.total_audio_tour_headset_units AS SUM(AUDIO_TOUR_HEADSET_UNITS) WITH SYNONYMS = ('audio units sold', 'headset units', 'audio guide units'),
    dpr.total_retail_gross_profit AS SUM(MUS_STORE_GROSS_PROFIT) + SUM(RETAIL_CARTS_GROSS_PROFIT) + SUM(CAFE1_ALL_PROFIT) WITH SYNONYMS = ('total retail profit', 'retail gross profit (DPR rollup)') COMMENT = 'Museum Store + Memorial Carts + Cafe gross profit (DPR rollup). For selling-area/category detail use rd.*/rc.*.',
    dpr.total_mus_store_gross_profit AS SUM(MUS_STORE_GROSS_PROFIT) WITH SYNONYMS = ('museum store profit', 'store gross profit'),
    dpr.total_ticketing_donations AS SUM(TICKETING_DONATIONS) WITH SYNONYMS = ('ticketing donations'),
    dpr.total_donations AS SUM(TICKETING_DONATIONS) + SUM(BOX_OFFICE_MEM_DON) + SUM(BOX_OFFICE_MUS_EXIT_DON) + SUM(COATCHECK_DON) + SUM(MASK_DONATIONS) + SUM(DONATION_BOX) + SUM(MUS_STORE_DONATIONS) + SUM(MUS_EXIT_DONATIONS) + SUM(CART_DONATION_ASK) + SUM(ECOM_DONATION_ASK) + SUM(CAFE1_DONATIONS) WITH SYNONYMS = ('total donations', 'all donations', 'donation revenue') COMMENT = 'Sum of every DPR donation line.',
    dpr.mus_store_profit_per_visitor AS SUM(MUS_STORE_GROSS_PROFIT) / NULLIF(SUM(MUS_ATTENDANCE), 0) WITH SYNONYMS = ('store profit per visitor', 'per-cap store profit', 'store per cap') COMMENT = 'Non-additive: Museum Store GROSS PROFIT (not sales revenue) / museum visitors, recomputed at the query grain.',
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
  COMMENT = 'Cross-domain reconciliation surface for the Museum Data Warehouse. Ticketing and admissions (DPR), retail by selling area and product category, and gate scanning by market segment -- all reconciled against one conformed calendar so a user can combine any live metric with any shared date dimension in a single question. Facility/category retail detail, ticketing KPIs, donations, tours, audio, and scan/redemption all in one place. Retail capture rate and conversion rate are DISTINCT metrics with different denominators -- capture divides by museum attendance, conversion divides by the store door count; never answer one with the other. Budget/variance, membership, ecommerce gross profit, monthly online revenue and same-day hourly sales are out of scope (see the domain models).';
