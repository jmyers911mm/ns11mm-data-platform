-- GENERATED FILE -- do not edit by hand.
-- Source of truth: cortex_project/DPR.sv.yaml
-- Regenerate: python3 scripts/generate_semantic_view_ddl.py
-- Run as the MARTS owner role. Equivalent to redeploying the .sv.yaml via the
-- Cortex project; use whichever path you have. Custom instructions and verified
-- queries in the YAML deploy via the Cortex project path, not this DDL.
CREATE OR REPLACE SEMANTIC VIEW MARTS.DPR
  TABLES (
    DP AS MARTS.FCT_DAILY_PERFORMANCE WITH SYNONYMS = ('daily performance', 'DPR fact', 'daily numbers') COMMENT = 'One row per calendar day of DPR additive measures.',
    DT AS MARTS.DIM_DATE PRIMARY KEY (DATE_KEY) WITH SYNONYMS = ('calendar', 'date dimension') COMMENT = 'Calendar date spine with the September 11 commemoration flag. Calendar attributes only — no fiscal columns yet; the fiscal calendar is pending Data & AI Committee definition.'
  )
  RELATIONSHIPS (
    DPR_TO_DATE AS DP (DATE_KEY) REFERENCES DT (DATE_KEY)
  )
  DIMENSIONS (
    DP.IS_COMMEMORATION_DAY AS IS_COMMEMORATION_DAY WITH SYNONYMS = ('commemoration', 'anniversary window', '9/11 period') COMMENT = 'TRUE for September 11, the commemoration day treated as a known structural exception.',
    DT.CALENDAR_MONTH AS MONTH_OF_YEAR WITH SYNONYMS = ('month number', 'calendar month') COMMENT = 'Calendar month number (1-12).',
    DT.CALENDAR_QUARTER AS QUARTER_OF_YEAR WITH SYNONYMS = ('quarter', 'qtr', 'calendar quarter') COMMENT = 'Calendar quarter (1-4).',
    DT.CALENDAR_YEAR AS YEAR_NUMBER WITH SYNONYMS = ('year', 'calendar year') COMMENT = 'Calendar year (January-December).',
    DT.DAY_NAME AS DAY_OF_WEEK_NAME WITH SYNONYMS = ('weekday', 'day of week') COMMENT = 'Abbreviated day-of-week name.',
    DT.DAY_OF_MONTH AS DAY_OF_MONTH WITH SYNONYMS = ('day of month', 'date of month') COMMENT = 'Day of the month (1-31).',
    DT.DAY_OF_YEAR AS DAY_OF_YEAR WITH SYNONYMS = ('day of year', 'ordinal day') COMMENT = 'Day of the year (1-366).',
    DT.IS_FIRST_OF_MONTH AS IS_FIRST_OF_MONTH WITH SYNONYMS = ('first of month') COMMENT = 'TRUE on the first calendar day of the month.',
    DT.IS_LAST_OF_MONTH AS IS_LAST_OF_MONTH WITH SYNONYMS = ('last of month', 'month end') COMMENT = 'TRUE on the last calendar day of the month.',
    DT.IS_WEEKDAY AS IS_WEEKDAY WITH SYNONYMS = ('weekday flag') COMMENT = 'TRUE Monday through Friday.',
    DT.IS_WEEKEND AS IS_WEEKEND WITH SYNONYMS = ('weekend flag', 'weekend') COMMENT = 'TRUE on Saturday and Sunday.',
    DT.MONTH_NAME AS MONTH_NAME WITH SYNONYMS = ('month') COMMENT = 'Abbreviated month name.',
    DT.REPORT_DATE AS DATE_DAY WITH SYNONYMS = ('date', 'day', 'business date') COMMENT = 'Calendar date the numbers are recognized on.',
    DT.WEEK_OF_YEAR AS WEEK_OF_YEAR WITH SYNONYMS = ('week', 'week number') COMMENT = 'Week of the year.'
  )
  METRICS (
    DP.TOTAL_ADMISSION_REVENUE AS SUM(TICKET_REVENUE) + SUM(PASS_REVENUE) WITH SYNONYMS = ('total admission revenue') COMMENT = 'Ticket revenue plus pass revenue.',
    DP.TOTAL_ASK_EDUCATOR_REVENUE AS SUM(ASK_EDUCATOR_REVENUE) WITH SYNONYMS = ('ask an educator revenue', 'ask educator revenue') COMMENT = 'Ask An Educator program revenue.',
    DP.TOTAL_AUDIO_REVENUE AS SUM(AUDIO_TOUR_HEADSET) + SUM(MEM_AUDIO_GUIDE_REVENUE) WITH SYNONYMS = ('audio guide revenue', 'all audio revenue') COMMENT = 'Museum audio/headset plus memorial audio guide revenue.',
    DP.TOTAL_AUDIO_TOUR_HEADSET AS SUM(AUDIO_TOUR_HEADSET) WITH SYNONYMS = ('museum audio revenue', 'headset revenue', 'audio tour and headset') COMMENT = 'Museum audio/headset revenue (Galaxy guide + CounterPoint MUS AG).',
    DP.TOTAL_AUDIO_TOUR_HEADSET_UNITS AS SUM(AUDIO_TOUR_HEADSET_UNITS) WITH SYNONYMS = ('audio units sold', 'headset units', 'audio guide units') COMMENT = 'Museum audio/headset units sold.',
    DP.TOTAL_BOX_OFFICE_MEM_DONATIONS AS SUM(BOX_OFFICE_MEM_DON) WITH SYNONYMS = ('box office memorial donations', 'plaza box donations') COMMENT = 'Box office memorial (plaza) box donations.',
    DP.TOTAL_BOX_OFFICE_MUS_EXIT_DONATIONS AS SUM(BOX_OFFICE_MUS_EXIT_DON) WITH SYNONYMS = ('box office museum exit donations', 'museum exit box donations') COMMENT = 'Box office museum exit box donations.',
    DP.TOTAL_CAFE_DONATIONS AS SUM(CAFE1_DONATIONS) WITH SYNONYMS = ('cafe donations') COMMENT = 'Cafe donations.',
    DP.TOTAL_CAFE_PROFIT AS SUM(CAFE1_ALL_PROFIT) WITH SYNONYMS = ('cafe profit') COMMENT = 'Cafe gross profit.',
    DP.TOTAL_CART_DONATION_ASK AS SUM(CART_DONATION_ASK) WITH SYNONYMS = ('cart donation ask', 'memorial cart donations') COMMENT = 'Memorial cart donation-ask collections.',
    DP.TOTAL_COATCHECK_DONATIONS AS SUM(COATCHECK_DON) WITH SYNONYMS = ('coat check donations') COMMENT = 'Coat check donations.',
    DP.TOTAL_DONATIONS AS SUM(TICKETING_DONATIONS) + SUM(BOX_OFFICE_MEM_DON) + SUM(BOX_OFFICE_MUS_EXIT_DON) + SUM(COATCHECK_DON) + SUM(MASK_DONATIONS) + SUM(DONATION_BOX) + SUM(MUS_STORE_DONATIONS) + SUM(MUS_EXIT_DONATIONS) + SUM(CART_DONATION_ASK) + SUM(ECOM_DONATION_ASK) + SUM(CAFE1_DONATIONS) WITH SYNONYMS = ('total donations', 'all donations', 'donation revenue') COMMENT = 'Sum of every DPR donation line.',
    DP.TOTAL_DONATION_BOX AS SUM(DONATION_BOX) WITH SYNONYMS = ('donation box') COMMENT = 'General donation box collections.',
    DP.TOTAL_ECOM_DONATION_ASK AS SUM(ECOM_DONATION_ASK) WITH SYNONYMS = ('ecommerce donation ask', 'online donation ask') COMMENT = 'Ecommerce donation-ask collections (CounterPoint ecom store).',
    DP.TOTAL_FIELD_TRIP_REVENUE AS SUM(MEM_FIELD_TRIP_REVENUE) + SUM(MUS_FIELD_TRIP_REVENUE) WITH SYNONYMS = ('field trip revenue', 'school trip revenue') COMMENT = 'Memorial + Museum field trip revenue.',
    DP.TOTAL_MASK_DONATIONS AS SUM(MASK_DONATIONS) WITH SYNONYMS = ('mask donations') COMMENT = 'Mask donations.',
    DP.TOTAL_MEMORIAL_ATTENDANCE AS SUM(MEM_ATTENDANCE) WITH SYNONYMS = ('memorial attendance', 'plaza attendance', 'memorial visitors') COMMENT = 'Memorial attendance (valid Gateway scans at memorial-classified facilities). Scan component only; full Sensource turnstile blend not yet staged.',
    DP.TOTAL_MEMORIAL_FIELD_TRIPS AS SUM(MEM_FIELD_TRIPS) WITH SYNONYMS = ('memorial field trip count') COMMENT = 'Memorial field trip ticket count.',
    DP.TOTAL_MEMORIAL_GUIDED_TOURS AS SUM(MEM_GUIDED_TOURS) WITH SYNONYMS = ('memorial guided tour count', 'number of memorial guided tours') COMMENT = 'Memorial guided tour ticket count.',
    DP.TOTAL_MEM_AUDIO_GUIDE_REVENUE AS SUM(MEM_AUDIO_GUIDE_REVENUE) WITH SYNONYMS = ('memorial audio guide revenue') COMMENT = 'Memorial audio guide revenue (Galaxy MAG component).',
    DP.TOTAL_MEM_FIELD_TRIP_REVENUE AS SUM(MEM_FIELD_TRIP_REVENUE) WITH SYNONYMS = ('memorial field trip revenue') COMMENT = 'Memorial field trip revenue.',
    DP.TOTAL_MEM_GUIDED_TOUR_REVENUE AS SUM(MEM_GUIDED_TOUR_REVENUE) WITH SYNONYMS = ('memorial guided tour revenue') COMMENT = 'Memorial guided tour revenue (MGT matrix cohort).',
    DP.TOTAL_MEM_MUS_TOURS AS SUM(MEM_MUS_TOURS) WITH SYNONYMS = ('combined tour count', 'memorial and museum tour count') COMMENT = 'Memorial + Museum combined tour ticket count.',
    DP.TOTAL_MEM_MUS_TOUR_REVENUE AS SUM(MEM_MUS_TOUR_REVENUE) WITH SYNONYMS = ('memorial and museum tour revenue', 'combined tour revenue') COMMENT = 'Memorial + Museum combined tour revenue (MTG matrix cohort).',
    DP.TOTAL_MUSEUM_ATTENDANCE AS SUM(MUS_ATTENDANCE) WITH SYNONYMS = ('museum attendance', 'museum visitors') COMMENT = 'Museum attendance (scanned general-admission component; see notes for Sensource blend).',
    DP.TOTAL_MUSEUM_FIELD_TRIPS AS SUM(MUS_FIELD_TRIPS) WITH SYNONYMS = ('museum field trip count') COMMENT = 'Museum field trip ticket count.',
    DP.TOTAL_MUSEUM_GUIDED_TOURS AS SUM(MUS_GUIDED_TOURS) WITH SYNONYMS = ('museum guided tour count', 'number of museum guided tours') COMMENT = 'Museum guided tour ticket count.',
    DP.TOTAL_MUS_EXIT_DONATIONS AS SUM(MUS_EXIT_DONATIONS) WITH SYNONYMS = ('museum exit donations') COMMENT = 'Museum exit donations (CounterPoint).',
    DP.TOTAL_MUS_FIELD_TRIP_REVENUE AS SUM(MUS_FIELD_TRIP_REVENUE) WITH SYNONYMS = ('museum field trip revenue') COMMENT = 'Museum field trip revenue.',
    DP.TOTAL_MUS_GUIDED_TOUR_REVENUE AS SUM(MUS_GUIDED_TOUR_REVENUE) WITH SYNONYMS = ('museum guided tour revenue', 'guided tour revenue') COMMENT = 'Museum guided tour revenue (TOU matrix cohort).',
    DP.TOTAL_MUS_STORE_DONATIONS AS SUM(MUS_STORE_DONATIONS) WITH SYNONYMS = ('museum store donations') COMMENT = 'Museum Store donations.',
    DP.TOTAL_MUS_STORE_GROSS_PROFIT AS SUM(MUS_STORE_GROSS_PROFIT) WITH SYNONYMS = ('museum store profit', 'store gross profit') COMMENT = 'Museum Store gross profit (sales minus cost).',
    DP.TOTAL_PASS_REVENUE AS SUM(PASS_REVENUE) WITH SYNONYMS = ('pass revenue', 'CityPASS revenue', 'C3 revenue') COMMENT = 'CityPASS / C3 pass revenue.',
    DP.TOTAL_RETAIL_CARTS_GROSS_PROFIT AS SUM(RETAIL_CARTS_GROSS_PROFIT) WITH SYNONYMS = ('memorial cart profit', 'cart gross profit') COMMENT = 'Memorial Carts gross profit.',
    DP.TOTAL_RETAIL_GROSS_PROFIT AS SUM(MUS_STORE_GROSS_PROFIT) + SUM(RETAIL_CARTS_GROSS_PROFIT) + SUM(CAFE1_ALL_PROFIT) WITH SYNONYMS = ('total retail profit', 'retail gross profit') COMMENT = 'Museum Store + Memorial Carts + Cafe gross profit.',
    DP.TOTAL_REVEALED_TOUR_REVENUE AS SUM(REVEALED_TOUR_REVENUE) WITH SYNONYMS = ('revealed tour revenue') COMMENT = 'Revealed tour revenue.',
    DP.TOTAL_SERVICE_FEES AS SUM(SERVICE_FEES) WITH SYNONYMS = ('service fees', 'fees') COMMENT = 'Museum + Memorial service fees.',
    DP.TOTAL_TICKETING_DONATIONS AS SUM(TICKETING_DONATIONS) WITH SYNONYMS = ('ticketing donations') COMMENT = 'Gateway ticketing donations (excludes box/exit categories).',
    DP.TOTAL_TICKETS_SOLD AS SUM(TICKETS_SOLD) WITH SYNONYMS = ('tickets sold', 'admissions sold', 'ticket count') COMMENT = 'General-admission tickets sold.',
    DP.TOTAL_TICKET_REVENUE AS SUM(TICKET_REVENUE) WITH SYNONYMS = ('ticket revenue', 'admission revenue') COMMENT = 'General-admission ticket revenue.',
    DP.TOTAL_VIRTUAL_MEM_TOURS AS SUM(VIRTUAL_MEM_TOURS) WITH SYNONYMS = ('virtual memorial tour count') COMMENT = 'Virtual Memorial tour count.',
    DP.TOTAL_VIRTUAL_MEM_TOUR_REVENUE AS SUM(VIRTUAL_MEM_TOUR_REVENUE) WITH SYNONYMS = ('virtual memorial tour revenue') COMMENT = 'Virtual Memorial tour revenue.',
    DP.TOTAL_VIRTUAL_MUS_TOURS AS SUM(VIRTUAL_MUS_TOURS) WITH SYNONYMS = ('virtual museum tour count') COMMENT = 'Virtual Museum tour count.',
    DP.TOTAL_VIRTUAL_MUS_TOUR_REVENUE AS SUM(VIRTUAL_MUS_TOUR_REVENUE) WITH SYNONYMS = ('virtual museum tour revenue') COMMENT = 'Virtual Museum tour revenue.',
    DP.TOTAL_VIRTUAL_TOUR_REVENUE AS SUM(VIRTUAL_MEM_TOUR_REVENUE) + SUM(VIRTUAL_MUS_TOUR_REVENUE) + SUM(VIRTUAL_YF_MEM_TOUR_REVENUE) WITH SYNONYMS = ('virtual tour revenue', 'online tour revenue') COMMENT = 'All virtual tour revenue (memorial, museum, youth & family).',
    DP.TOTAL_VIRTUAL_YF_MEM_TOURS AS SUM(VIRTUAL_YF_MEM_TOURS) WITH SYNONYMS = ('virtual youth and family tour count') COMMENT = 'Virtual Youth & Family Memorial tour count.',
    DP.TOTAL_VIRTUAL_YF_MEM_TOUR_REVENUE AS SUM(VIRTUAL_YF_MEM_TOUR_REVENUE) WITH SYNONYMS = ('virtual youth and family tour revenue', 'youth family virtual tour revenue') COMMENT = 'Virtual Youth & Family Memorial tour revenue.'
  )
  COMMENT = 'Daily Performance Report semantic model over the DPR marts. Additive KPIs are SUM metrics so Cortex Analyst can roll up to any period; the two ratios are ratio-of-sums metrics (non-additive, recomputed at the query grain). Built on FCT_DAILY_PERFORMANCE (additive day-grain fact) joined to DIM_DATE. Budget/variance, full Sensource attendance blend, ecommerce gross profit, and membership are out of current scope (see custom instructions).';
