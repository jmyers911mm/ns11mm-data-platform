-- Marts report: DPR MTD/YTD day-grain metric long shape (one row per date x metric)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per report_date x metric_code
--
-- Every metric the DPR MTD and YTD workbooks print, unpivoted to day grain so
-- rpt_dpr_mtd_ytd_print can sum it inside any period window. Additive metrics
-- carry `amount`; the four non-additive ratios carry `numerator` /
-- `denominator` so a ratio is a ratio-of-SUMS at MTD and YTD alike (never an
-- average of daily ratios).
--
-- Sources: rpt_dpr_powerbi (DPR semantic-view metrics) and
-- rpt_dpr_retail_conform (the retail sub-metrics the DPR fact does not carry).
--
-- COMPOSITES VERIFIED AGAINST THE 2025-12-31 WORKBOOKS (both MTD and YTD tie
-- to the cent), authored here ONCE because the DPR semantic view has no metric
-- for them:
--   TOTAL_GUIDED_TOUR_REVENUE   = mus_guided + mem_guided + revealed
--                                 + virtual_yf_tour + mem_mus
--        MTD 187,432 + 0 + 64,708.80 + 0 + 289,305 = 541,445.80  ✓
--   TOTAL_OTHER_VISITOR_REVENUE = audio_tour_headset + mem_audio_guide
--                                 + ticketing + coatcheck + mus_exit
--                                 + mus_store_don + cart_donation_ask
--                                 + cafe_don + ecom_donation_ask + mask
--        MTD ... = 591,654.68  ✓   (uses MUS_EXIT_DON, *not*
--        BOX_OFFICE_MUS_EXIT_DON, and excludes BOX_OFFICE_MEM_DON and
--        DONATION_BOX — settles which donation columns the report means)
--   TOTAL_ESTIMATED_REVENUE     = admission + guided total + virtual total
--                                 + retail GP total + cafe profit
--                                 + other visitor total
--        MTD 7,264,074.50 + 541,445.80 + 395 + 662,250.08 + 110,553.73
--            + 591,654.68 = 9,170,373.79  ✓
--        RE-VERIFY AFTER 8.1.0: the "retail GP total" term above was read from
--        the cafe-inclusive metric. With the cafe double count removed that
--        term becomes store + carts only, so the arithmetic above must be
--        re-run against the workbook before this line is treated as current.
--        If 662,250.08 already contained the 110,553.73 cafe figure, the
--        corrected MTD total is 9,059,820.06.
--
-- RATIO DEFINITIONS ALSO VERIFIED against the workbook: capture rate =
-- store visitors / museum attendance (106,299 / 266,115 = 39.94% ✓);
-- conversion = store customers / store visitors (18,376 / 106,299 = 17.29% ✓);
-- average sale = store NET SALES / customers (not profit — 40.4787 x 18,376
-- reconciles to sales, not the 533,225 gross profit).
--
-- 8.1.0 DOUBLE-COUNT FIX (Museum Cafe counted twice in TOTAL_ESTIMATED_REVENUE
-- and TOTAL_RETAIL_GROSS_PROFIT overstated):
--   TOTAL_RETAIL_GROSS_PROFIT was mapped to the DPR semantic-view metric
--   dp.total_retail_gross_profit, which is defined as
--   SUM(MUS_STORE_GROSS_PROFIT) + SUM(RETAIL_CARTS_GROSS_PROFIT)
--   + SUM(CAFE1_ALL_PROFIT). That metric's own comment says: "the legacy DPR
--   report line 'Total Retail Gross Profit' EXCLUDES cafe (its own line) ...
--   do not treat this metric as that line." This model treated it as that
--   line, then added CAFE_PROFIT again inside TOTAL_ESTIMATED_REVENUE, so
--   CAFE1_ALL_PROFIT was summed twice. The print catalog confirms the intent:
--   dpr_mtd_ytd_print_lines puts EC_TOTAL_RETAIL_GP (store/carts/e-commerce
--   section 70) and CAFE_TOTAL_PROFIT (Museum Cafe section 80) on separate
--   lines. Both now read the new governed metric
--   dp.total_retail_gross_profit_ex_cafe (store + carts), projected on the
--   wrapper as total_retail_gross_profit_ex_cafe.
--
-- 8.6.0 (ADR-005 GATED — see DECISION_MEMO.md):
--   * ECOM_GROSS_PROFIT is emitted as a metric for the first time (print line
--     EC_GROSS_PROFIT, previously Stub), and it is now a component of
--     TOTAL_RETAIL_GROSS_PROFIT_EX_CAFE, which is where the print catalog puts
--     it: section 70 runs Museum Store GP, Retail Carts GP, E-Commerce GP,
--     Total Retail GP.
--   * ADMISSION_REVENUE gains service fees (governed on the fact), so
--     TOTAL_ESTIMATED_REVENUE gains them too. SERVICE_FEES continues to print
--     as its own line (MUS_SERVICE_FEES, print order 2050) exactly as the
--     legacy workbook prints it above Total Admission Revenue -- the line and
--     the total are both correct, the fee is a component of the total, not an
--     addition to it. TOTAL_ESTIMATED_REVENUE does NOT add SERVICE_FEES
--     separately, so there is no double count.
--
-- TOTAL_ESTIMATED_REVENUE duplication: rpt_dpr_report_long authors the same
-- composite inline (its own union branch). The two component sets are NOT
-- identical -- this one carries virtual_yf_tour, mem_audio_guide and
-- mask_donations; report_long carries box_office_mem_don,
-- box_office_mus_exit_don and donation_box -- so collapsing them to one
-- authoring is a metric decision, not a refactor, and is on the ADR-005
-- agenda for release 8.6.0 rather than done here.
--
-- OPEN (recorded 8.1.0, NOT changed): VIRTUAL_YF_TOUR_REVENUE is a component
-- of BOTH total_guided_tour_revenue (below) and the semantic-view metric
-- VIRTUAL_TOUR_REVENUE (= virtual_mem + virtual_mus + virtual_yf_mem), and
-- TOTAL_ESTIMATED_REVENUE adds both, so youth-and-family virtual tour revenue
-- is counted twice whenever it is non-zero. It was zero in the 2025-12-31
-- workbook used for the verification above, which is why the check passed.
-- The MTD/YTD print catalog also prints that measure in two sections
-- (GT_YF_TOUR_REV and VT_YF_MEM_TOUR_REV), so whether the workbook intends
-- the total to count it once or twice is a question for the report owner --
-- ADR-005 gate, carried into the 8.6.0 decision memo.
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- Additive metrics available directly on the DPR wrapper: code -> column -#}
{% set dpr_additive = [
    ('MEMORIAL_ATTENDANCE', 'memorial_attendance'),
    ('MUSEUM_ATTENDANCE', 'museum_attendance'),
    ('TICKETS_SOLD', 'tickets_sold'),
    ('TICKET_REVENUE', 'ticket_revenue'),
    ('PASS_REVENUE', 'pass_revenue'),
    ('SERVICE_FEES', 'service_fees'),
    ('ADMISSION_REVENUE', 'admission_revenue'),
    ('MUSEUM_GUIDED_TOURS', 'museum_guided_tours'),
    ('MUS_GUIDED_TOUR_REVENUE', 'mus_guided_tour_revenue'),
    ('MEMORIAL_GUIDED_TOURS', 'memorial_guided_tours'),
    ('MEM_GUIDED_TOUR_REVENUE', 'mem_guided_tour_revenue'),
    ('REVEALED_TOUR_REVENUE', 'revealed_tour_revenue'),
    ('VIRTUAL_YF_TOUR_REVENUE', 'virtual_yf_tour_revenue'),
    ('MEM_MUS_TOURS', 'mem_mus_tours'),
    ('MEM_MUS_TOUR_REVENUE', 'mem_mus_tour_revenue'),
    ('VIRTUAL_MEM_TOURS', 'virtual_mem_tours'),
    ('VIRTUAL_MEM_TOUR_REVENUE', 'virtual_mem_tour_revenue'),
    ('VIRTUAL_YF_MEM_TOURS', 'virtual_yf_mem_tours'),
    ('VIRTUAL_MUS_TOURS', 'virtual_mus_tours'),
    ('VIRTUAL_MUS_TOUR_REVENUE', 'virtual_mus_tour_revenue'),
    ('MEMORIAL_FIELD_TRIPS', 'memorial_field_trips'),
    ('MEM_FIELD_TRIP_REVENUE', 'mem_field_trip_revenue'),
    ('MUSEUM_FIELD_TRIPS', 'museum_field_trips'),
    ('MUS_FIELD_TRIP_REVENUE', 'mus_field_trip_revenue'),
    ('ASK_EDUCATOR_REVENUE', 'ask_educator_revenue'),
    ('VIRTUAL_TOUR_REVENUE', 'virtual_tour_revenue'),
    ('MUS_STORE_GROSS_PROFIT', 'mus_store_gross_profit'),
    ('RETAIL_CARTS_GROSS_PROFIT', 'retail_carts_gross_profit'),
    ('ECOM_GROSS_PROFIT', 'ecom_gross_profit'),
    ('TOTAL_RETAIL_GROSS_PROFIT', 'total_retail_gross_profit_ex_cafe'),
    ('CAFE_PROFIT', 'cafe_profit'),
    ('AUDIO_TOUR_HEADSET', 'audio_tour_headset'),
    ('MEM_AUDIO_GUIDE_REVENUE', 'mem_audio_guide_revenue'),
    ('TICKETING_DONATIONS', 'ticketing_donations'),
    ('COATCHECK_DON', 'coatcheck_don'),
    ('MUS_EXIT_DON', 'mus_exit_don'),
    ('MUS_STORE_DON', 'mus_store_don'),
    ('CART_DONATION_ASK', 'cart_donation_ask'),
    ('CAFE_DON', 'cafe_don'),
    ('ECOM_DONATION_ASK', 'ecom_donation_ask'),
    ('MASK_DONATIONS', 'mask_donations')
] %}

{#- Additive metrics from the retail conform: code -> column -#}
{% set retail_additive = [
    ('MUS_STORE_VISITORS', 'mus_store_visitors'),
    ('MUS_STORE_CUSTOMERS', 'mus_store_customers'),
    ('CARTS_CUSTOMERS', 'carts_customers'),
    ('ECOM_ORDERS', 'ecom_orders'),
    ('CAFE_TRANSACTIONS', 'cafe_transactions')
] %}

with d as (
    select * from {{ ref('rpt_dpr_powerbi') }}
),

rc as (
    select * from {{ ref('rpt_dpr_retail_conform') }}
),

joined as (
    select
        d.*,
        rc.mus_store_visitors,
        rc.mus_store_customers,
        rc.mus_store_net_sales,
        rc.carts_customers,
        rc.carts_net_sales,
        rc.ecom_orders,
        rc.cafe_transactions
    from d
    left join rc on d.report_date = rc.report_date
),

-- Composites authored once (see header for the workbook verification)
composites as (
    select
        report_date,
        coalesce(mus_guided_tour_revenue, 0) + coalesce(mem_guided_tour_revenue, 0)
          + coalesce(revealed_tour_revenue, 0) + coalesce(virtual_yf_tour_revenue, 0)
          + coalesce(mem_mus_tour_revenue, 0)                       as total_guided_tour_revenue,
        coalesce(audio_tour_headset, 0) + coalesce(mem_audio_guide_revenue, 0)
          + coalesce(ticketing_donations, 0) + coalesce(coatcheck_don, 0)
          + coalesce(mus_exit_don, 0) + coalesce(mus_store_don, 0)
          + coalesce(cart_donation_ask, 0) + coalesce(cafe_don, 0)
          + coalesce(ecom_donation_ask, 0) + coalesce(mask_donations, 0)
                                                                    as total_other_visitor_revenue
    from joined
)

{% for code, col in dpr_additive %}
{% if not loop.first %}union all{% endif %}
select
    report_date,
    '{{ code }}' as metric_code,
    cast({{ col }} as number(38,4)) as amount,
    cast(null as number(38,4)) as numerator,
    cast(null as number(38,4)) as denominator
from joined
{% endfor %}

{% for code, col in retail_additive %}
union all
select
    report_date,
    '{{ code }}' as metric_code,
    cast({{ col }} as number(38,4)) as amount,
    cast(null as number(38,4)) as numerator,
    cast(null as number(38,4)) as denominator
from joined
{% endfor %}

-- composites
union all
select report_date, 'TOTAL_GUIDED_TOUR_REVENUE',
       cast(total_guided_tour_revenue as number(38,4)), null, null
from composites
union all
select report_date, 'TOTAL_OTHER_VISITOR_REVENUE',
       cast(total_other_visitor_revenue as number(38,4)), null, null
from composites
union all
select
    j.report_date, 'TOTAL_ESTIMATED_REVENUE',
    cast(
        coalesce(j.admission_revenue, 0)
      + coalesce(c.total_guided_tour_revenue, 0)
      + coalesce(j.virtual_tour_revenue, 0)
      -- store + carts only; cafe is the next term and must not be inside this one
      + coalesce(j.total_retail_gross_profit_ex_cafe, 0)
      + coalesce(j.cafe_profit, 0)
      + coalesce(c.total_other_visitor_revenue, 0) as number(38,4)),
    null, null
from joined j
inner join composites c on j.report_date = c.report_date

-- ratio metrics: numerator / denominator carried, never pre-divided
union all
select report_date, 'MUS_STORE_CAPTURE_RATE', null,
       cast(mus_store_visitors as number(38,4)),
       cast(museum_attendance as number(38,4))
from joined
union all
select report_date, 'MUS_STORE_CONVERSION_RATE', null,
       cast(mus_store_customers as number(38,4)),
       cast(mus_store_visitors as number(38,4))
from joined
union all
select report_date, 'MUS_STORE_AVG_SALE', null,
       cast(mus_store_net_sales as number(38,4)),
       cast(mus_store_customers as number(38,4))
from joined
union all
select report_date, 'CARTS_AVG_SALE', null,
       cast(carts_net_sales as number(38,4)),
       cast(carts_customers as number(38,4))
from joined
