-- Marts fact: daily performance (additive measures, one row per day)
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain: one row per date_key
--
-- Consolidates every additive DPR "today" measure into a single day-grain
-- fact by full-outer-joining the DPR silver models on key_date, then joining
-- dim_date for the conformed date key and commemoration flag.
--
-- Replaces legacy 911dw.fact_dpr_report_data (which the DPR .prpt read
-- directly). ADR-004: this is the single place additive DPR logic lands;
-- Power BI reads from rpt_daily_performance_report on top of this and does
-- no aggregation of its own. ADR (additive/non-additive): only additive
-- measures live here. Ratios (avg ticket price, conversion, per-cap) are
-- computed at query time in the rpt_ layer, never re-aggregated from here.
--
-- Grain integrity is enforced by the unique/not_null test on date_key in
-- the accompanying schema.yml.

{{ config(
    materialized='table',
    cluster_by=['date_key']
) }}

with tours as (
    select * from {{ ref('int_dpr__tour_revenue') }}
),

fees as (
    select * from {{ ref('int_dpr__fees_and_services') }}
),

retail as (
    select * from {{ ref('int_dpr__retail') }}
),

donations as (
    select * from {{ ref('int_dpr__donations') }}
),

admissions as (
    select * from {{ ref('int_dpr__admissions') }}
),

attendance as (
    select * from {{ ref('int_dpr__attendance') }}
),

-- Union all contributing dates to form the day spine.
-- date_key is normalized to DATE at every source to guarantee the
-- downstream inner join to dim_date is 1:1 (grain-integrity guard for the
-- unique/not_null test on date_key).
date_spine as (
    select cast(date_key as date) as date_key from tours where date_key is not null
    union select cast(date_key as date) from fees where date_key is not null
    union select cast(date_key as date) from retail where date_key is not null
    union select cast(date_key as date) from donations where date_key is not null
    union select cast(date_key as date) from admissions where date_key is not null
    union select cast(date_key as date) from attendance where date_key is not null
),

combined as (
    select
        s.date_key,

        -- Admissions
        coalesce(a.tickets_sold, 0)                                        as tickets_sold,
        coalesce(a.ticket_revenue, 0)                                      as ticket_revenue,
        coalesce(a.pass_revenue, 0)                                        as pass_revenue,
        -- Governed numerator for admission-yield rates. Additive, defined ONCE here;
        -- every avg_ticket_price everywhere references this column.
        coalesce(a.ticket_revenue, 0)
          + coalesce(a.pass_revenue, 0)                                    as total_admission_revenue,
        coalesce(a.mus_attendance, 0)                                      as mus_attendance,
        -- Memorial attendance: valid scans at memorial facilities (Gateway).
        -- See int_dpr__attendance scope note (facility-name classification).
        coalesce(att.mem_attendance, 0)                                    as mem_attendance,

        -- Tours (quantities)
        coalesce(t.mus_guided_tours, 0)                                    as mus_guided_tours,
        coalesce(t.mem_guided_tours, 0)                                    as mem_guided_tours,
        coalesce(t.mem_field_trips, 0)                                     as mem_field_trips,
        coalesce(t.mus_field_trips, 0)                                     as mus_field_trips,
        coalesce(t.virtual_mem_tours, 0)                                   as virtual_mem_tours,
        coalesce(t.virtual_mus_tours, 0)                                   as virtual_mus_tours,
        coalesce(t.virtual_yf_mem_tours, 0)                                as virtual_yf_mem_tours,
        coalesce(f.mem_mus_tours, 0)                                       as mem_mus_tours,

        -- Tours (revenue)
        coalesce(t.mus_guided_tour_revenue, 0)                             as mus_guided_tour_revenue,
        coalesce(t.mem_guided_tour_revenue, 0)                             as mem_guided_tour_revenue,
        coalesce(t.mem_field_trip_revenue, 0)                              as mem_field_trip_revenue,
        coalesce(t.mus_field_trip_revenue, 0)                              as mus_field_trip_revenue,
        coalesce(t.revealed_tour_revenue, 0)                               as revealed_tour_revenue,
        coalesce(t.ask_educator_revenue, 0)                                as ask_educator_revenue,
        coalesce(t.virtual_mem_tour_revenue, 0)                            as virtual_mem_tour_revenue,
        coalesce(t.virtual_mus_tour_revenue, 0)                            as virtual_mus_tour_revenue,
        coalesce(t.virtual_yf_mem_tour_revenue, 0)                         as virtual_yf_mem_tour_revenue,
        coalesce(f.mem_mus_tour_revenue, 0)                                as mem_mus_tour_revenue,

        -- Fees & audio
        coalesce(f.service_fees, 0)                                        as service_fees,
        coalesce(f.mem_audio_guide_revenue, 0)
          + coalesce(r.mag_cp_revenue, 0)                                  as mem_audio_guide_revenue,
        -- Audio tour & headset: Galaxy guide/headset + CounterPoint MUS AG (2024-01-16+)
        coalesce(f.mus_audio_guide_revenue, 0)
          + coalesce(r.musag_profit, 0)                                    as audio_tour_headset,
        coalesce(f.mus_audio_guide_units, 0)
          + coalesce(r.musag_units, 0)                                     as audio_tour_headset_units,

        -- Retail profit
        coalesce(r.mus_store_gross_profit, 0)                              as mus_store_gross_profit,
        coalesce(r.retail_carts_gross_profit, 0)                           as retail_carts_gross_profit,
        coalesce(r.cafe1_all_profit, 0)                                    as cafe1_all_profit,

        -- Donations
        coalesce(d.ticketing_donations, 0)                                 as ticketing_donations,
        coalesce(d.box_office_mem_don, 0)                                  as box_office_mem_don,
        coalesce(d.box_office_mus_exit_don, 0)                             as box_office_mus_exit_don,
        coalesce(d.coatcheck_don, 0)                                       as coatcheck_don,
        coalesce(r.mask_donations, 0)                                      as mask_donations,
        coalesce(r.donation_box, 0)                                        as donation_box,
        coalesce(r.mus_store_donations, 0)                                 as mus_store_donations,
        coalesce(r.mus_exit_donations, 0)                                  as mus_exit_donations,
        coalesce(r.cart_donation_ask, 0)                                   as cart_donation_ask,
        coalesce(r.ecom_donation_ask, 0)                                   as ecom_donation_ask,
        coalesce(r.cafe1_donations, 0)                                     as cafe1_donations

    from date_spine s
    left join tours       t   on s.date_key = cast(t.date_key as date)
    left join fees        f   on s.date_key = cast(f.date_key as date)
    left join retail      r   on s.date_key = cast(r.date_key as date)
    left join donations   d   on s.date_key = cast(d.date_key as date)
    left join admissions  a   on s.date_key = cast(a.date_key as date)
    left join attendance  att on s.date_key = cast(att.date_key as date)
)

select
    dd.date_key,
    c.date_key                                                             as date_value,
    dd.is_commemoration_day,
    c.* exclude (date_key)
from combined c
inner join {{ ref('dim_date') }} dd
    on c.date_key = dd.date_key