-- Marts dimension: dim_tour_product — tour PLU -> DPR line-item classification
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: admissions / tours
-- Grain: one row per PLU code
--
-- Maps tour-related PLU codes to their DPR line item classification (tour type)
-- for reporting segmentation.
--
-- Source: seed_tour_plu (dbt seed)

{{ config(materialized='table', tags=['daily', 'critical']) }}

select
    plu                                 as tour_product_key,
    plu,
    dpr_line_item                       as tour_type,
    notes                               as tour_description,
    current_timestamp()                 as _loaded_at
from {{ ref('seed_tour_plu') }}
