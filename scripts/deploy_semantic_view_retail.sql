-- GENERATED FILE -- do not edit by hand.
-- Source of truth: cortex_project/RETAIL.sv.yaml
-- Regenerate: python3 scripts/generate_semantic_view_ddl.py
-- Run as the MARTS owner role. Equivalent to redeploying the .sv.yaml via the
-- Cortex project; use whichever path you have. Custom instructions and verified
-- queries in the YAML deploy via the Cortex project path, not this DDL.
CREATE OR REPLACE SEMANTIC VIEW NS11MM_DW_DEV.MARTS.RETAIL
  TABLES (
    FCT_RETAIL_PERFORMANCE AS NS11MM_DW_DEV.MARTS.FCT_RETAIL_PERFORMANCE COMMENT = 'Category-grain retail fact (one row per date x facility x category). Additive sales/profit/units/donations.',
    FCT_RETAIL_DAILY AS NS11MM_DW_DEV.MARTS.FCT_RETAIL_DAILY COMMENT = 'Facility-grain retail fact (one row per date x facility). Transaction and visitor counts plus facility rollups of sales/profit/units/donations. This is the single-fact projection the Retail Performance Power BI wrapper (RPT_RETAIL_POWERBI) reads.',
    DIM_DATE AS NS11MM_DW_DEV.MARTS.DIM_DATE PRIMARY KEY (DATE_KEY) COMMENT = 'Calendar date spine spanning 2000-2035 with commemoration day flag (no fiscal columns yet; fiscal calendar pending Data & AI Committee definition)',
    SEED_FACILITY_AREA AS NS11MM_DW_DEV.SEEDS.SEED_FACILITY_AREA PRIMARY KEY (KEY_FACILITY) COMMENT = 'Retail selling-area facility reference'
  )
  RELATIONSHIPS (
    RETAIL_PERF_TO_DATE AS FCT_RETAIL_PERFORMANCE (DATE_KEY) REFERENCES DIM_DATE (DATE_KEY),
    RETAIL_PERF_TO_FACILITY AS FCT_RETAIL_PERFORMANCE (KEY_FACILITY) REFERENCES SEED_FACILITY_AREA (KEY_FACILITY),
    RETAIL_DAILY_TO_DATE AS FCT_RETAIL_DAILY (DATE_KEY) REFERENCES DIM_DATE (DATE_KEY),
    RETAIL_DAILY_TO_FACILITY AS FCT_RETAIL_DAILY (KEY_FACILITY) REFERENCES SEED_FACILITY_AREA (KEY_FACILITY)
  )
  FACTS (
    FCT_RETAIL_PERFORMANCE.NET_SALES AS NET_SALES COMMENT = 'Sale minus return amount, non-donation lines',
    FCT_RETAIL_PERFORMANCE.NET_PROFIT AS NET_PROFIT,
    FCT_RETAIL_PERFORMANCE.NET_UNITS AS NET_UNITS,
    FCT_RETAIL_PERFORMANCE.COST_OF_GOODS AS COST_OF_GOODS,
    FCT_RETAIL_PERFORMANCE.DONATIONS AS DONATIONS,
    FCT_RETAIL_PERFORMANCE.NET_SALES_BUDGET AS NET_SALES_BUDGET,
    FCT_RETAIL_PERFORMANCE.NET_PROFIT_BUDGET AS NET_PROFIT_BUDGET,
    FCT_RETAIL_DAILY.NET_SALES AS NET_SALES,
    FCT_RETAIL_DAILY.NET_PROFIT AS NET_PROFIT,
    FCT_RETAIL_DAILY.NET_UNITS AS NET_UNITS,
    FCT_RETAIL_DAILY.DONATIONS AS DONATIONS,
    FCT_RETAIL_DAILY.TRANSACTIONS AS TRANSACTIONS,
    FCT_RETAIL_DAILY.VISITOR_COUNT AS VISITOR_COUNT,
    FCT_RETAIL_DAILY.ECOM_ORDERS AS ECOM_ORDERS
  )
  DIMENSIONS (
    FCT_RETAIL_PERFORMANCE.KEY_FACILITY AS KEY_FACILITY COMMENT = 'Selling-area facility key (see seed_facility_area)',
    FCT_RETAIL_PERFORMANCE.AREA_NAME AS AREA_NAME,
    FCT_RETAIL_PERFORMANCE.AREA_GROUP AS AREA_GROUP,
    FCT_RETAIL_PERFORMANCE.CATEGORY_CODE AS CATEGORY_CODE COMMENT = 'CounterPoint product category (Donations folded to ''Donations'')',
    FCT_RETAIL_PERFORMANCE.IS_COMMEMORATION_DAY AS IS_COMMEMORATION_DAY,
    FCT_RETAIL_PERFORMANCE.DATE_KEY AS DATE_KEY,
    FCT_RETAIL_PERFORMANCE.DATE_VALUE AS DATE_VALUE,
    FCT_RETAIL_DAILY.KEY_FACILITY AS KEY_FACILITY,
    FCT_RETAIL_DAILY.AREA_NAME AS AREA_NAME,
    FCT_RETAIL_DAILY.AREA_GROUP AS AREA_GROUP,
    FCT_RETAIL_DAILY.IS_COMMEMORATION_DAY AS IS_COMMEMORATION_DAY,
    FCT_RETAIL_DAILY.DATE_KEY AS DATE_KEY,
    FCT_RETAIL_DAILY.DATE_VALUE AS DATE_VALUE,
    DIM_DATE.REPORT_DATE AS DATE_KEY COMMENT = 'Regular (non-time) date dimension so a flat SEMANTIC_VIEW() projection can select the date. Added 1.6.0.',
    DIM_DATE.DAY_OF_WEEK_NAME AS DAY_OF_WEEK_NAME,
    DIM_DATE.MONTH_NAME AS MONTH_NAME,
    DIM_DATE.QUARTER_OF_YEAR AS QUARTER_OF_YEAR,
    DIM_DATE.YEAR_NUMBER AS YEAR_NUMBER,
    DIM_DATE.IS_WEEKEND AS IS_WEEKEND,
    DIM_DATE.IS_COMMEMORATION_DAY AS IS_COMMEMORATION_DAY COMMENT = 'True for September 11 (anniversary). Flags structural anomalies across all metrics.',
    DIM_DATE.DATE_KEY AS DATE_KEY,
    DIM_DATE.DATE_DAY AS DATE_DAY,
    SEED_FACILITY_AREA.KEY_FACILITY AS KEY_FACILITY,
    SEED_FACILITY_AREA.AREA_NAME AS AREA_NAME,
    SEED_FACILITY_AREA.AREA_GROUP AS AREA_GROUP,
    SEED_FACILITY_AREA.IS_SELLING AS IS_SELLING
  )
  METRICS (
    FCT_RETAIL_PERFORMANCE.TOTAL_NET_SALES AS SUM(NET_SALES) COMMENT = 'Total net sales across all facilities and categories',
    FCT_RETAIL_PERFORMANCE.TOTAL_NET_PROFIT AS SUM(NET_PROFIT) COMMENT = 'Total net profit',
    FCT_RETAIL_PERFORMANCE.TOTAL_NET_UNITS AS SUM(NET_UNITS) COMMENT = 'Total units sold (category grain). Added 1.6.0 for the Retail Performance Report category page.',
    FCT_RETAIL_PERFORMANCE.TOTAL_COST_OF_GOODS AS SUM(COST_OF_GOODS) COMMENT = 'Total COGS. Added 1.6.0.',
    FCT_RETAIL_PERFORMANCE.TOTAL_RETAIL_DONATIONS AS SUM(DONATIONS) WITH SYNONYMS = ('retail donations', 'register donations', 'round-up donations') COMMENT = 'Total retail donations collected at the register (category grain). Distinct from the DPR view''s TOTAL_DONATIONS (all donation lines).',
    FCT_RETAIL_PERFORMANCE.GROSS_MARGIN_PCT AS SUM(NET_PROFIT) / NULLIF(SUM(NET_SALES), 0) COMMENT = 'Gross margin percentage (profit / sales)',
    FCT_RETAIL_DAILY.TOTAL_RETAIL_NET_SALES AS SUM(NET_SALES) COMMENT = 'Facility-grain net sales rollup',
    FCT_RETAIL_DAILY.TOTAL_RETAIL_NET_PROFIT AS SUM(NET_PROFIT) COMMENT = 'Facility-grain net profit (gross margin profit) rollup',
    FCT_RETAIL_DAILY.TOTAL_RETAIL_NET_UNITS AS SUM(NET_UNITS) COMMENT = 'Facility-grain units rollup',
    FCT_RETAIL_DAILY.TOTAL_RETAIL_DONATIONS AS SUM(DONATIONS) COMMENT = 'Facility-grain donation-ask rollup',
    FCT_RETAIL_DAILY.TOTAL_TRANSACTIONS AS SUM(TRANSACTIONS) COMMENT = 'Total transaction count (customers)',
    FCT_RETAIL_DAILY.TOTAL_VISITORS AS SUM(VISITOR_COUNT) COMMENT = 'Total visitor count to retail areas (Sensource stub until fed)',
    FCT_RETAIL_DAILY.TOTAL_ECOM_ORDERS AS SUM(ECOM_ORDERS) COMMENT = 'Total ecommerce orders (Shopify stub until fed)',
    FCT_RETAIL_DAILY.REVENUE_PER_VISITOR AS SUM(NET_SALES) / NULLIF(SUM(VISITOR_COUNT), 0) COMMENT = 'Net sales per visitor'
  )
  COMMENT = 'Retail analytics model for museum store operations. Covers category-grain sales performance (net sales, profit, units, donations) and facility-grain daily aggregates (transactions, visitors, ecommerce orders, plus facility rollups of sales/profit/units/donations). Supports per-store and per-category profitability analysis, and is the natural-language / Cortex Analyst surface for the Retail Performance Report cluster.';
