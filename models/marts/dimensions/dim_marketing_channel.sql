/*
  dim_marketing_channel — Marketing channel reference dimension.
  Source: seeds/ref_marketing_channels.csv
  No RAW dependency; safe to build immediately.
*/

{{ config(materialized='table') }}

select
    channel_id,
    channel_name,
    channel_type,
    is_paid,
    platform,
    case
        when channel_type = 'Digital' and is_paid then 'Paid Digital'
        when channel_type = 'Digital' and not is_paid then 'Owned/Earned Digital'
        else 'Other'
    end as channel_category
from {{ ref('ref_marketing_channels') }}
