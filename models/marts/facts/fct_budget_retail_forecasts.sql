-- Marts fact: retail budget/forecast by facility (one row per day x facility)
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: budget
-- Grain: one row per date_key x key_facility
--
-- Budget/forecast counterpart to fct_retail_daily. Visitors, conversion,
-- profit, donations, and revenue by facility per day. Joined to dim_date
-- for the conformed date key.

{{ config(
    materialized='table',
    cluster_by=['date_key']
) }}

with budget as (
    select * from {{ ref('int_budget__retail_forecasts') }}
),

final as (
    select
        dd.date_key,
        b.date_key                  as date_value,
        b.key_facility,

        -- Visitors & conversion
        b.visitors,
        b.customers,
        b.capture_rate,
        b.conversion_rate,
        b.average_sale,

        -- Financials
        b.profit_from_retail,
        b.revenue,
        b.donations,

        -- Context
        b.museum_attendance,
        b.avg_don_mem_only_vis

    from budget b
    inner join {{ ref('dim_date') }} dd
        on b.date_key = dd.date_key
)

select * from final
