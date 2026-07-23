-- Silver intermediate: conformed Gateway item/ticket attributes (vattribute)
-- ---------------------------------------------------------------------------
-- Domain: shared gateway reference
-- Grain:  one row per avg_id (attribute value group)
--
-- Single lookup for avg_id -> matrix code / recognize basis / default customer /
-- dynamic channel. Previously each of int_gateway__item_journal_lines,
-- int_gateway__ticket_journal_lines, and int_gateway__scan_lines re-selected
-- stg_gateway__vattribute directly. This is a RAW passthrough (no coalesce or
-- derivation) so each consumer keeps its own existing matrix_code coalesce /
-- visit_type logic and output is unchanged; it just gives the avg_id lookup one
-- home (and a place to add shared derivations later).

{{ config(materialized='view') }}

with vattribute as (
    select * from {{ ref('stg_gateway__vattribute') }}
)

select
    avg_id,
    itm_matrix_code,
    itm_recognize_basis_id,
    itm_default_customer_id,
    acs_dynamic_channel
from vattribute
