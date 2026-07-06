/*
  fct_fundraising
  Source: int_classy + stg_classy__campaigns
  STATUS: Awaiting RAW data. New model — no POC equivalent.
*/

{{ config(enabled=false,materialized='table', cluster_by=['transaction_date']) }}

select
    t.transaction_id,
    t.transaction_date,
    t.campaign_id,
    c.campaign_name,
    c.campaign_type                                         as campaign_type,
    t.donor_member_id,
    t.gross_amount,
    t.net_amount,
    t.processing_fee,
    t.donor_covered_fee,
    t.currency_code,
    t.donation_frequency,
    t.is_recurring,
    t.is_anonymous,
    t.payment_type,
    current_timestamp()                                     as _loaded_at
from {{ ref('int_classy') }} t
left join {{ ref('stg_classy__campaigns') }} c on t.campaign_id = c.campaign_id
