-- GENERATED FILE. Do not edit by hand.
-- Source: semantic_models/dpr.yaml
-- Regenerate: python scripts/generate_dpr_semantic_view.py
--
-- Environment-portable via USE DATABASE. Change the target with
--   python scripts/generate_dpr_semantic_view.py --database NS11MM_DW_PROD
USE DATABASE NS11MM_DW_DEV_JMYERS;
USE SCHEMA MARTS;

CREATE OR REPLACE SEMANTIC VIEW MARTS.DPR
TABLES (
    dp AS MARTS.FCT_DAILY_PERFORMANCE
        PRIMARY KEY (date_id)
        WITH SYNONYMS = ('daily performance', 'DPR fact', 'daily numbers')
        COMMENT = 'One row per calendar day of DPR additive measures.',
    dt AS MARTS.DIM_DATE
        PRIMARY KEY (date_id)
        WITH SYNONYMS = ('calendar', 'date dimension')
        COMMENT = 'Calendar date dimension with fiscal calendar (FY starts October) and the September 11 commemoration flag.'
)
RELATIONSHIPS (
    dpr_to_date AS dp (date_id) REFERENCES dt (date_id)
)
DIMENSIONS (
    dp.is_commemoration_day AS IS_COMMEMORATION_DAY
        WITH SYNONYMS = ('commemoration', 'anniversary window', '9/11 period')
        COMMENT = 'TRUE for September 11, the commemoration day treated as a known structural exception.',
    dt.report_date AS DATE_DAY
        WITH SYNONYMS = ('date', 'day', 'business date')
        COMMENT = 'Calendar date the numbers are recognized on.',
    dt.fiscal_year AS FISCAL_YEAR
        WITH SYNONYMS = ('fiscal year', 'FY')
        COMMENT = 'Fiscal year (starts in October; Oct-Dec roll into the next FY number).',
    dt.fiscal_month AS FISCAL_MONTH
        WITH SYNONYMS = ('fiscal month', 'fiscal period')
        COMMENT = 'Fiscal month number (October = 1 ... September = 12).',
    dt.calendar_year AS YEAR_NUMBER
        WITH SYNONYMS = ('year', 'calendar year')
        COMMENT = 'Calendar year (January-December). For the October-based fiscal year use fiscal_year.',
    dt.calendar_quarter AS QUARTER_OF_YEAR
        WITH SYNONYMS = ('quarter', 'qtr', 'calendar quarter')
        COMMENT = 'Calendar quarter (1-4).',
    dt.calendar_month AS MONTH_OF_YEAR
        WITH SYNONYMS = ('month number', 'calendar month')
        COMMENT = 'Calendar month number (1-12).',
    dt.month_name AS MONTH_NAME
        WITH SYNONYMS = ('month')
        COMMENT = 'Abbreviated month name.',
    dt.day_name AS DAY_OF_WEEK_NAME
        WITH SYNONYMS = ('weekday', 'day of week')
        COMMENT = 'Abbreviated day-of-week name.',
    dt.day_of_month AS DAY_OF_MONTH
        WITH SYNONYMS = ('day of month', 'date of month')
        COMMENT = 'Day of the month (1-31).',
    dt.day_of_year AS DAY_OF_YEAR
        WITH SYNONYMS = ('day of year', 'ordinal day')
        COMMENT = 'Day of the year (1-366).',
    dt.week_of_year AS WEEK_OF_YEAR
        WITH SYNONYMS = ('week', 'week number')
        COMMENT = 'Week of the year.',
    dt.is_weekend AS IS_WEEKEND
        WITH SYNONYMS = ('weekend flag', 'weekend')
        COMMENT = 'TRUE on Saturday and Sunday.',
    dt.is_weekday AS IS_WEEKDAY
        WITH SYNONYMS = ('weekday flag')
        COMMENT = 'TRUE Monday through Friday.',
    dt.is_first_of_month AS IS_FIRST_OF_MONTH
        WITH SYNONYMS = ('first of month')
        COMMENT = 'TRUE on the first calendar day of the month.',
    dt.is_last_of_month AS IS_LAST_OF_MONTH
        WITH SYNONYMS = ('last of month', 'month end')
        COMMENT = 'TRUE on the last calendar day of the month.'
)
METRICS (
    dp.total_tickets_sold AS SUM(TICKETS_SOLD)
        WITH SYNONYMS = ('tickets sold', 'admissions sold', 'ticket count')
        COMMENT = 'General-admission tickets sold.',
    dp.total_ticket_revenue AS SUM(TICKET_REVENUE)
        WITH SYNONYMS = ('ticket revenue', 'admission revenue')
        COMMENT = 'General-admission ticket revenue.',
    dp.total_pass_revenue AS SUM(PASS_REVENUE)
        WITH SYNONYMS = ('pass revenue', 'CityPASS revenue', 'C3 revenue')
        COMMENT = 'CityPASS / C3 pass revenue.',
    dp.total_admission_revenue AS SUM(TICKET_REVENUE) + SUM(PASS_REVENUE) 
        WITH SYNONYMS = ('total admission revenue')
        COMMENT = 'Ticket revenue plus pass revenue.',
    dp.total_museum_attendance AS SUM(MUS_ATTENDANCE)
        WITH SYNONYMS = ('museum attendance', 'museum visitors')
        COMMENT = 'Museum attendance (scanned general-admission component; see notes for Sensource blend).',
    dp.total_memorial_attendance AS SUM(MEM_ATTENDANCE)
        WITH SYNONYMS = ('memorial attendance', 'plaza attendance', 'memorial visitors')
        COMMENT = 'Memorial attendance (valid Gateway scans at memorial-classified facilities). Scan component only; full Sensource turnstile blend not yet staged.',
    dp.total_mus_guided_tour_revenue AS SUM(MUS_GUIDED_TOUR_REVENUE)
        WITH SYNONYMS = ('museum guided tour revenue', 'guided tour revenue')
        COMMENT = 'Museum guided tour revenue (TOU matrix cohort).',
    dp.total_mem_guided_tour_revenue AS SUM(MEM_GUIDED_TOUR_REVENUE)
        WITH SYNONYMS = ('memorial guided tour revenue')
        COMMENT = 'Memorial guided tour revenue (MGT matrix cohort).',
    dp.total_mem_mus_tour_revenue AS SUM(MEM_MUS_TOUR_REVENUE)
        WITH SYNONYMS = ('memorial and museum tour revenue', 'combined tour revenue')
        COMMENT = 'Memorial + Museum combined tour revenue (MTG matrix cohort).',
    dp.total_revealed_tour_revenue AS SUM(REVEALED_TOUR_REVENUE)
        WITH SYNONYMS = ('revealed tour revenue')
        COMMENT = 'Revealed tour revenue.',
    dp.total_ask_educator_revenue AS SUM(ASK_EDUCATOR_REVENUE)
        WITH SYNONYMS = ('ask an educator revenue', 'ask educator revenue')
        COMMENT = 'Ask An Educator program revenue.',
    dp.total_mem_field_trip_revenue AS SUM(MEM_FIELD_TRIP_REVENUE)
        WITH SYNONYMS = ('memorial field trip revenue')
        COMMENT = 'Memorial field trip revenue.',
    dp.total_mus_field_trip_revenue AS SUM(MUS_FIELD_TRIP_REVENUE)
        WITH SYNONYMS = ('museum field trip revenue')
        COMMENT = 'Museum field trip revenue.',
    dp.total_field_trip_revenue AS SUM(MEM_FIELD_TRIP_REVENUE) + SUM(MUS_FIELD_TRIP_REVENUE)
        WITH SYNONYMS = ('field trip revenue', 'school trip revenue')
        COMMENT = 'Memorial + Museum field trip revenue.',
    dp.total_virtual_mem_tour_revenue AS SUM(VIRTUAL_MEM_TOUR_REVENUE)
        WITH SYNONYMS = ('virtual memorial tour revenue')
        COMMENT = 'Virtual Memorial tour revenue.',
    dp.total_virtual_mus_tour_revenue AS SUM(VIRTUAL_MUS_TOUR_REVENUE)
        WITH SYNONYMS = ('virtual museum tour revenue')
        COMMENT = 'Virtual Museum tour revenue.',
    dp.total_virtual_yf_mem_tour_revenue AS SUM(VIRTUAL_YF_MEM_TOUR_REVENUE)
        WITH SYNONYMS = ('virtual youth and family tour revenue', 'youth family virtual tour revenue')
        COMMENT = 'Virtual Youth & Family Memorial tour revenue.',
    dp.total_virtual_tour_revenue AS SUM(VIRTUAL_MEM_TOUR_REVENUE) + SUM(VIRTUAL_MUS_TOUR_REVENUE) + SUM(VIRTUAL_YF_MEM_TOUR_REVENUE)
        WITH SYNONYMS = ('virtual tour revenue', 'online tour revenue')
        COMMENT = 'All virtual tour revenue (memorial, museum, youth & family).',
    dp.total_museum_guided_tours AS SUM(MUS_GUIDED_TOURS)
        WITH SYNONYMS = ('museum guided tour count', 'number of museum guided tours')
        COMMENT = 'Museum guided tour ticket count.',
    dp.total_memorial_guided_tours AS SUM(MEM_GUIDED_TOURS)
        WITH SYNONYMS = ('memorial guided tour count', 'number of memorial guided tours')
        COMMENT = 'Memorial guided tour ticket count.',
    dp.total_mem_mus_tours AS SUM(MEM_MUS_TOURS)
        WITH SYNONYMS = ('combined tour count', 'memorial and museum tour count')
        COMMENT = 'Memorial + Museum combined tour ticket count.',
    dp.total_memorial_field_trips AS SUM(MEM_FIELD_TRIPS)
        WITH SYNONYMS = ('memorial field trip count')
        COMMENT = 'Memorial field trip ticket count.',
    dp.total_museum_field_trips AS SUM(MUS_FIELD_TRIPS)
        WITH SYNONYMS = ('museum field trip count')
        COMMENT = 'Museum field trip ticket count.',
    dp.total_virtual_mem_tours AS SUM(VIRTUAL_MEM_TOURS)
        WITH SYNONYMS = ('virtual memorial tour count')
        COMMENT = 'Virtual Memorial tour count.',
    dp.total_virtual_mus_tours AS SUM(VIRTUAL_MUS_TOURS)
        WITH SYNONYMS = ('virtual museum tour count')
        COMMENT = 'Virtual Museum tour count.',
    dp.total_virtual_yf_mem_tours AS SUM(VIRTUAL_YF_MEM_TOURS)
        WITH SYNONYMS = ('virtual youth and family tour count')
        COMMENT = 'Virtual Youth & Family Memorial tour count.',
    dp.total_service_fees AS SUM(SERVICE_FEES)
        WITH SYNONYMS = ('service fees', 'fees')
        COMMENT = 'Museum + Memorial service fees.',
    dp.total_mem_audio_guide_revenue AS SUM(MEM_AUDIO_GUIDE_REVENUE)
        WITH SYNONYMS = ('memorial audio guide revenue')
        COMMENT = 'Memorial audio guide revenue (Galaxy MAG component).',
    dp.total_audio_tour_headset AS SUM(AUDIO_TOUR_HEADSET)
        WITH SYNONYMS = ('museum audio revenue', 'headset revenue', 'audio tour and headset')
        COMMENT = 'Museum audio/headset revenue (Galaxy guide + CounterPoint MUS AG).',
    dp.total_audio_tour_headset_units AS SUM(AUDIO_TOUR_HEADSET_UNITS)
        WITH SYNONYMS = ('audio units sold', 'headset units', 'audio guide units')
        COMMENT = 'Museum audio/headset units sold.',
    dp.total_audio_revenue AS SUM(AUDIO_TOUR_HEADSET) + SUM(MEM_AUDIO_GUIDE_REVENUE)
        WITH SYNONYMS = ('audio guide revenue', 'all audio revenue')
        COMMENT = 'Museum audio/headset plus memorial audio guide revenue.',
    dp.total_mus_store_gross_profit AS SUM(MUS_STORE_GROSS_PROFIT)
        WITH SYNONYMS = ('museum store profit', 'store gross profit')
        COMMENT = 'Museum Store gross profit (sales minus cost).',
    dp.total_retail_carts_gross_profit AS SUM(RETAIL_CARTS_GROSS_PROFIT)
        WITH SYNONYMS = ('memorial cart profit', 'cart gross profit')
        COMMENT = 'Memorial Carts gross profit.',
    dp.total_cafe_profit AS SUM(CAFE1_ALL_PROFIT)
        WITH SYNONYMS = ('cafe profit')
        COMMENT = 'Cafe gross profit.',
    dp.total_retail_gross_profit AS SUM(MUS_STORE_GROSS_PROFIT) + SUM(RETAIL_CARTS_GROSS_PROFIT) + SUM(CAFE1_ALL_PROFIT)
        WITH SYNONYMS = ('total retail profit', 'retail gross profit')
        COMMENT = 'Museum Store + Memorial Carts + Cafe gross profit.',
    dp.total_ticketing_donations AS SUM(TICKETING_DONATIONS)
        WITH SYNONYMS = ('ticketing donations')
        COMMENT = 'Gateway ticketing donations (excludes box/exit categories).',
    dp.total_box_office_mem_donations AS SUM(BOX_OFFICE_MEM_DON)
        WITH SYNONYMS = ('box office memorial donations', 'plaza box donations')
        COMMENT = 'Box office memorial (plaza) box donations.',
    dp.total_box_office_mus_exit_donations AS SUM(BOX_OFFICE_MUS_EXIT_DON)
        WITH SYNONYMS = ('box office museum exit donations', 'museum exit box donations')
        COMMENT = 'Box office museum exit box donations.',
    dp.total_coatcheck_donations AS SUM(COATCHECK_DON)
        WITH SYNONYMS = ('coat check donations')
        COMMENT = 'Coat check donations.',
    dp.total_mask_donations AS SUM(MASK_DONATIONS)
        WITH SYNONYMS = ('mask donations')
        COMMENT = 'Mask donations.',
    dp.total_donation_box AS SUM(DONATION_BOX)
        WITH SYNONYMS = ('donation box')
        COMMENT = 'General donation box collections.',
    dp.total_mus_store_donations AS SUM(MUS_STORE_DONATIONS)
        WITH SYNONYMS = ('museum store donations')
        COMMENT = 'Museum Store donations.',
    dp.total_mus_exit_donations AS SUM(MUS_EXIT_DONATIONS)
        WITH SYNONYMS = ('museum exit donations')
        COMMENT = 'Museum exit donations (CounterPoint).',
    dp.total_cart_donation_ask AS SUM(CART_DONATION_ASK)
        WITH SYNONYMS = ('cart donation ask', 'memorial cart donations')
        COMMENT = 'Memorial cart donation-ask collections.',
    dp.total_ecom_donation_ask AS SUM(ECOM_DONATION_ASK)
        WITH SYNONYMS = ('ecommerce donation ask', 'online donation ask')
        COMMENT = 'Ecommerce donation-ask collections (CounterPoint ecom store).',
    dp.total_cafe_donations AS SUM(CAFE1_DONATIONS)
        WITH SYNONYMS = ('cafe donations')
        COMMENT = 'Cafe donations.',
    dp.total_donations AS SUM(TICKETING_DONATIONS) + SUM(BOX_OFFICE_MEM_DON) + SUM(BOX_OFFICE_MUS_EXIT_DON) + SUM(COATCHECK_DON) + SUM(MASK_DONATIONS) + SUM(DONATION_BOX) + SUM(MUS_STORE_DONATIONS) + SUM(MUS_EXIT_DONATIONS) + SUM(CART_DONATION_ASK) + SUM(ECOM_DONATION_ASK) + SUM(CAFE1_DONATIONS)
        WITH SYNONYMS = ('total donations', 'all donations', 'donation revenue')
        COMMENT = 'Sum of every DPR donation line.',
    dp.avg_ticket_price AS TOTAL_ADMISSION_REVENUE / NULLIF(SUM(TICKETS_SOLD), 0)
        WITH SYNONYMS = ('average ticket price', 'avg admission price')
        COMMENT = 'Non-additive: total admission revenue divided by tickets sold, recomputed at the query grain (never averaged across days).',
    dp.mus_store_rev_per_visitor AS SUM(MUS_STORE_GROSS_PROFIT) / NULLIF(SUM(MUS_ATTENDANCE), 0)
        WITH SYNONYMS = ('museum store revenue per visitor', 'store per cap', 'per capita store profit')
        COMMENT = 'Non-additive: Museum Store gross profit per museum visitor, recomputed at the query grain.'
)
COMMENT = 'Daily Performance Report semantic model over the DPR marts. Additive KPIs are SUM metrics so Cortex Analyst can roll up to any period; the two ratios are ratio-of-sums metrics (non-additive, recomputed at the query grain). Built on FCT_DAILY_PERFORMANCE (additive day-grain fact) joined to DIM_DATE. Budget/variance, full Sensource attendance blend, ecommerce gross profit, and membership are out of current scope (see custom instructions).'
AI_SQL_GENERATION 'Round all currency metrics to 2 decimal points and attendance, ticket, tour, and audio-unit counts to whole numbers. When a question does not specify a period, default to the most recent complete day available. When comparing two periods, note if either overlaps the September 6-16 commemoration window, since that window is a known structural exception. If a question mentions "fiscal" year/month/quarter, use the fiscal_year / fiscal_month dimensions (fiscal year starts in October); otherwise use the calendar dimensions.'
AI_QUESTION_CATEGORIZATION 'If a question asks for budget, forecast, or variance figures, treat it as out of scope: explain that budget/variance is not yet in this model (pending budget-source staging) and offer the actuals instead. Memorial attendance is available as the scan-based component (total_memorial_attendance); if a question needs the full Sensource turnstile-blended attendance, note that blend is not yet staged. If a question asks for membership revenue or ecommerce gross profit, note those sources are out of current scope. If a revenue question is ambiguous about which revenue stream, ask the user to specify (tickets, tours, retail, donations, fees, or audio).';
