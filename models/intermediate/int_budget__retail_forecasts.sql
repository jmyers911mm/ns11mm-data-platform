-- Silver intermediate: cleanse and type-cast retail forecast seed
-- ---------------------------------------------------------------------------
-- Domain: budget
-- Grain: one row per date_key x key_facility
--
-- Converts key_date (NUMBER 20260101) to DATE, casts mixed TEXT columns to
-- numeric, and coalesces NULLs to zero for additive measures.

{{ config(materialized='view') }}

with source as (
    select * from {{ source('budget_seeds', 'SEED_RETAIL_FORECASTS') }}
),

cleaned as (
    select
        to_date(key_date::varchar, 'YYYYMMDD')            as date_key,
        key_facility,

        -- Visitors & conversion
        coalesce(visitors, 0)                              as visitors,
        coalesce(customers, 0)                             as customers,
        capture_rate,
        conversion_rate,
        coalesce(average_sale, 0)                          as average_sale,

        -- Financials
        coalesce(profit_from_retail, 0)                    as profit_from_retail,
        coalesce(revenue, 0)                               as revenue,
        coalesce(donations, 0)                             as donations,

        -- Attendance (contextual)
        coalesce(museum_attendance, 0)                     as museum_attendance,

        -- Derived (memorial-only visitor donation avg — often null)
        try_to_double(avg_don_mem_only_vis)                as avg_don_mem_only_vis

    from source
)

select * from cleaned
