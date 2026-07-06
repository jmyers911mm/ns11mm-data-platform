-- Mart fact: ticket demand aggregated for forecasting and presale analysis
-- Co-authored with CoCo

{{ config(
    materialized='table',
    cluster_by=['entry_date']
) }}

with features as (
    select * from {{ ref('int_gateway__ticket_demand_features') }}
),

-- Daily demand by ticket type and presale bucket
daily_demand as (
    select
        entry_date,
        entry_dow,
        entry_day_name,
        entry_doy,
        entry_week,
        entry_month,
        entry_quarter,
        entry_year,
        is_weekend,
        plu,
        ticket_type_name,
        ticket_kind,
        presale_bucket,
        purchase_channel,

        -- Volume metrics
        count(*)                                                as ticket_count,
        sum(quantity)                                           as total_quantity,
        sum(revenue)                                            as total_revenue,
        avg(price)                                              as avg_price,

        -- Presale timing
        avg(presale_lead_days)                                  as avg_presale_lead_days,
        median(presale_lead_days)                               as median_presale_lead_days,
        min(presale_lead_days)                                  as min_presale_lead_days,
        max(presale_lead_days)                                  as max_presale_lead_days,

        -- Usage / no-show
        sum(case when was_used then 1 else 0 end)              as tickets_used,
        sum(case when not was_used and is_active then 1 else 0 end) as tickets_unused,
        round(sum(case when was_used then 1 else 0 end)::float
            / nullif(count(*), 0), 4)                           as utilization_rate

    from features
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14
),

-- Entry hour distribution (separate grain for time-of-day analysis)
hourly_demand as (
    select
        entry_date,
        entry_hour,
        plu,
        ticket_type_name,
        presale_bucket,
        count(*)                                                as ticket_count,
        sum(quantity)                                           as total_quantity
    from features
    where entry_hour is not null
    group by 1,2,3,4,5
),

-- Presale curve: how tickets accumulate before entry date
presale_curve as (
    select
        entry_date,
        plu,
        ticket_type_name,

        -- Cumulative presale buckets
        sum(case when presale_lead_days > 90 then quantity else 0 end)  as qty_sold_90plus_days_out,
        sum(case when presale_lead_days > 30 then quantity else 0 end)  as qty_sold_30plus_days_out,
        sum(case when presale_lead_days > 14 then quantity else 0 end)  as qty_sold_14plus_days_out,
        sum(case when presale_lead_days > 7 then quantity else 0 end)   as qty_sold_7plus_days_out,
        sum(case when presale_lead_days > 1 then quantity else 0 end)   as qty_sold_1plus_days_out,
        sum(case when presale_lead_days = 0 then quantity else 0 end)   as qty_sold_same_day,
        sum(quantity)                                                    as qty_sold_total,

        -- Presale percentage
        round(sum(case when presale_lead_days > 0 then quantity else 0 end)::float
            / nullif(sum(quantity), 0), 4)                              as presale_pct

    from features
    group by 1,2,3
)

select
    d.*,

    -- Presale curve columns
    p.qty_sold_90plus_days_out,
    p.qty_sold_30plus_days_out,
    p.qty_sold_14plus_days_out,
    p.qty_sold_7plus_days_out,
    p.qty_sold_1plus_days_out,
    p.qty_sold_same_day,
    p.presale_pct

from daily_demand d
left join presale_curve p
    on d.entry_date = p.entry_date
    and d.plu = p.plu

