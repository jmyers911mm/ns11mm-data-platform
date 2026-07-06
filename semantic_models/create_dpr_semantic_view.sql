-- DDL to create/replace the DPR semantic view (environment-portable via USE DATABASE)
-- Co-authored with CoCo

-- Set the target database before running. Change this single line for prod:
--   DEV:  USE DATABASE NS11MM_DW_DEV_JMYERS;
--   PROD: USE DATABASE NS11MM_DW_PROD;
USE DATABASE NS11MM_DW_DEV_JMYERS;
USE SCHEMA MARTS;

CREATE OR REPLACE SEMANTIC VIEW MARTS.DPR
TABLES (
    dp AS MARTS.FCT_DAILY_PERFORMANCE
        PRIMARY KEY (date_id)
        WITH SYNONYMS = ('daily performance', 'DPR fact', 'daily numbers')
        COMMENT = 'One row per calendar day of Daily Performance Report additive measures.',
    dt AS MARTS.DIM_DATE
        PRIMARY KEY (date_id)
        WITH SYNONYMS = ('calendar', 'date dimension')
        COMMENT = 'Calendar date dimension with the September 11 commemoration flag.'
)
RELATIONSHIPS (
    dpr_to_date AS dp (date_id) REFERENCES dt (date_id)
)
DIMENSIONS (
    dt.report_date AS date_day
        WITH SYNONYMS = ('date', 'day', 'business date')
        COMMENT = 'Calendar date the numbers are recognized on.',
    dt.calendar_year AS year_number
        WITH SYNONYMS = ('year', 'fiscal year')
        COMMENT = 'Calendar year.',
    dt.calendar_quarter AS quarter_of_year
        WITH SYNONYMS = ('quarter', 'qtr')
        COMMENT = 'Calendar quarter (1-4).',
    dt.calendar_month AS month_of_year
        WITH SYNONYMS = ('month number')
        COMMENT = 'Calendar month number (1-12).',
    dt.month_name AS month_name
        WITH SYNONYMS = ('month')
        COMMENT = 'Abbreviated month name.',
    dt.day_name AS day_of_week_name
        WITH SYNONYMS = ('weekday', 'day of week')
        COMMENT = 'Abbreviated day-of-week name.',
    dt.is_weekend AS is_weekend
        WITH SYNONYMS = ('weekend flag')
        COMMENT = 'TRUE on Saturday and Sunday.',
    dt.is_commemoration_day AS is_commemoration_day
        WITH SYNONYMS = ('commemoration', 'anniversary window', '9/11 period')
        COMMENT = 'TRUE for September 11, the commemoration day treated as a known structural exception.'
)
METRICS (
    -- Admissions (additive)
    dp.total_tickets_sold AS SUM(tickets_sold)
        WITH SYNONYMS = ('tickets sold', 'admissions sold', 'ticket count')
        COMMENT = 'General-admission tickets sold.',
    dp.total_ticket_revenue AS SUM(ticket_revenue)
        WITH SYNONYMS = ('ticket revenue', 'admission revenue')
        COMMENT = 'General-admission ticket revenue.',
    dp.total_pass_revenue AS SUM(pass_revenue)
        WITH SYNONYMS = ('pass revenue', 'CityPASS revenue', 'C3 revenue')
        COMMENT = 'CityPASS / C3 pass revenue.',
    dp.total_admission_revenue AS SUM(ticket_revenue) + SUM(pass_revenue)
        WITH SYNONYMS = ('total admission revenue')
        COMMENT = 'Ticket revenue plus pass revenue.',
    dp.total_museum_attendance AS SUM(mus_attendance)
        WITH SYNONYMS = ('attendance', 'museum attendance', 'visitors')
        COMMENT = 'Museum attendance (scanned general-admission component).',

    -- Tours & fees (additive)
    dp.total_mus_guided_tour_revenue AS SUM(mus_guided_tour_revenue)
        WITH SYNONYMS = ('museum guided tour revenue', 'guided tour revenue')
        COMMENT = 'Museum guided tour revenue.',
    dp.total_mem_mus_tour_revenue AS SUM(mem_mus_tour_revenue)
        WITH SYNONYMS = ('memorial and museum tour revenue', 'combined tour revenue')
        COMMENT = 'Memorial + Museum combined tour revenue.',
    dp.total_virtual_tour_revenue AS SUM(virtual_mem_tour_revenue) + SUM(virtual_mus_tour_revenue) + SUM(virtual_yf_mem_tour_revenue)
        WITH SYNONYMS = ('virtual tour revenue', 'online tour revenue')
        COMMENT = 'All virtual tour revenue (memorial, museum, youth and family).',
    dp.total_field_trip_revenue AS SUM(mem_field_trip_revenue) + SUM(mus_field_trip_revenue)
        WITH SYNONYMS = ('field trip revenue', 'school trip revenue')
        COMMENT = 'Memorial + Museum field trip revenue.',
    dp.total_service_fees AS SUM(service_fees)
        WITH SYNONYMS = ('service fees', 'fees')
        COMMENT = 'Museum + Memorial service fees.',
    dp.total_audio_revenue AS SUM(audio_tour_headset) + SUM(mem_audio_guide_revenue)
        WITH SYNONYMS = ('audio guide revenue', 'headset revenue')
        COMMENT = 'Museum audio/headset plus memorial audio guide revenue.',

    -- Retail (additive)
    dp.total_mus_store_gross_profit AS SUM(mus_store_gross_profit)
        WITH SYNONYMS = ('museum store profit', 'store gross profit')
        COMMENT = 'Museum Store gross profit (sales minus cost).',
    dp.total_retail_carts_gross_profit AS SUM(retail_carts_gross_profit)
        WITH SYNONYMS = ('memorial cart profit', 'cart gross profit')
        COMMENT = 'Memorial Carts gross profit.',
    dp.total_cafe_profit AS SUM(cafe1_all_profit)
        WITH SYNONYMS = ('cafe profit')
        COMMENT = 'Cafe gross profit.',
    dp.total_retail_gross_profit AS SUM(mus_store_gross_profit) + SUM(retail_carts_gross_profit) + SUM(cafe1_all_profit)
        WITH SYNONYMS = ('total retail profit', 'retail gross profit')
        COMMENT = 'Museum Store + Memorial Carts + Cafe gross profit.',

    -- Donations (additive)
    dp.total_ticketing_donations AS SUM(ticketing_donations)
        WITH SYNONYMS = ('ticketing donations')
        COMMENT = 'Gateway ticketing donations (excludes box/exit categories).',
    dp.total_donations AS SUM(ticketing_donations) + SUM(box_office_mem_don) + SUM(box_office_mus_exit_don) + SUM(coatcheck_don) + SUM(mask_donations) + SUM(donation_box) + SUM(mus_store_donations) + SUM(mus_exit_donations) + SUM(cart_donation_ask) + SUM(ecom_donation_ask) + SUM(cafe1_donations)
        WITH SYNONYMS = ('total donations', 'all donations', 'donation revenue')
        COMMENT = 'Sum of every DPR donation line.',

    -- Non-additive ratios (ratio-of-sums)
    dp.avg_ticket_price AS (SUM(ticket_revenue) + SUM(pass_revenue)) / NULLIF(SUM(tickets_sold), 0)
        WITH SYNONYMS = ('average ticket price', 'avg admission price')
        COMMENT = 'Non-additive: total admission revenue divided by tickets sold, recomputed at the query grain.',
    dp.mus_store_rev_per_visitor AS SUM(mus_store_gross_profit) / NULLIF(SUM(mus_attendance), 0)
        WITH SYNONYMS = ('museum store revenue per visitor', 'store per cap', 'per capita store profit')
        COMMENT = 'Non-additive: Museum Store gross profit per museum visitor, recomputed at the query grain.'
)
COMMENT = 'Daily Performance Report semantic view over FCT_DAILY_PERFORMANCE and DIM_DATE. Additive KPIs as SUM metrics; ratios as ratio-of-sums.'
AI_SQL_GENERATION 'Round all currency metrics to 2 decimal points and attendance/ticket counts to whole numbers. When a question does not specify a period, default to the most recent complete day available. Treat the September 6-16 commemoration window as a known structural exception: when comparing periods, note if either period overlaps the commemoration window.'
AI_QUESTION_CATEGORIZATION 'If a question asks for budget, forecast, or variance figures, respond that budget/variance is not yet in this model (pending the budget-source staging) and suggest asking about actuals. If a question asks for membership, ecommerce gross profit, or full Sensource attendance, note those sources are out of current scope.';
