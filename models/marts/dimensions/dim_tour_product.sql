/*
  dim_tour_product
  Source: seed_tour_plu (dbt seed)
  Grain: one row per PLU code

  Maps tour-related PLU codes to their DPR line item classification (tour type)
  for reporting segmentation.
*/

{{ config(materialized='table', tags=['daily', 'critical']) }}

select
    plu                                 as tour_product_key,
    plu,
    dpr_line_item                       as tour_type,
    notes                               as tour_description,
    current_timestamp()                 as _loaded_at
from {{ ref('seed_tour_plu') }}
