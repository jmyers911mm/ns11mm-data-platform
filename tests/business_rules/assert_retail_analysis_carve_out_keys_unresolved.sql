-- Test (business_rule): the legacy dim_item_descr keys the Retail Analysis carve-outs depend on are still unresolved
-- Severity: warn — this is a standing reminder, not a regression. Each row is a
-- legacy surrogate key (911dw.dim_item_descr.key_item_desc) that could not be
-- mapped to a CounterPoint item_no from any staged source, so the measure it
-- drives is published as a typed NULL and its layout line is marked Stub.
-- PROMOTE TO ERROR: never. This test goes SILENT when the seeds are filled in —
-- delete it at that point rather than promoting it.
--
-- It is here because the resolution can only be performed against the legacy
-- 911dw MySQL warehouse, which is scheduled for decommission. Once that server
-- is gone the mapping is unrecoverable and the water carve-out is permanently
-- dead. The exact query is in the 8.10.0 NOTES; owner: Jeremy Myers.

{{ config(severity='warn') }}

select
    'seed_retail_water_item'                    as seed_name,
    w.legacy_key_item_descr                     as legacy_key,
    w.water_group                               as seed_group,
    w.resolution_basis,
    'water measures publish as typed NULL; 2 layout lines are Stub' as consequence
from {{ ref('seed_retail_water_item') }} w
where not w.is_resolved

union all

select
    'seed_retail_analysis_excluded_item'        as seed_name,
    e.legacy_key_item_descr_set                 as legacy_key,
    e.exclusion_group                           as seed_group,
    e.resolution_basis,
    'sales/units exclusion not applied for this group'              as consequence
from {{ ref('seed_retail_analysis_excluded_item') }} e
where not e.is_resolved
