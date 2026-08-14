-- Test (business_rule): every resolved Retail Analysis exclusion / water SKU exists in the CounterPoint item master
-- Severity: error — a resolved seed row whose item_no is unknown to the item
-- master excludes nothing and resolves to no description, so the legacy filter
-- silently stops being applied and Museum Store / Memorial Carts / Vesey sales
-- silently gain membership revenue. That is a wrong number on a live workbook
-- with no symptom, which is exactly what this seed exists to prevent.
--
-- Only rows flagged is_resolved are checked. An unresolved row is the seed
-- doing its job (recording a legacy key that has not been mapped yet) and is
-- reported separately by assert_retail_analysis_carve_out_keys_unresolved.

with item_master as (
    select cast(item_no as varchar) as item_no, description
    from {{ ref('stg_counterpoint__imitem') }}
),

seeded as (
    select
        'seed_retail_analysis_excluded_item'    as seed_name,
        exclusion_group                         as seed_group,
        cast(item_no as varchar)                as item_no
    from {{ ref('seed_retail_analysis_excluded_item') }}
    where is_resolved

    union all

    select
        'seed_retail_water_item'                as seed_name,
        water_group                             as seed_group,
        cast(item_no as varchar)                as item_no
    from {{ ref('seed_retail_water_item') }}
    where is_resolved
),

-- 1. Resolved rows must name an item the item master knows.
unknown_item as (
    select
        'item_no_not_in_item_master'            as failure,
        s.seed_name,
        s.seed_group,
        s.item_no
    from seeded s
    left join item_master im on s.item_no = im.item_no
    where im.item_no is null

    union all

    -- 2. A resolved row with a blank item_no cannot match anything.
    select
        'resolved_row_has_no_item_no'           as failure,
        s.seed_name,
        s.seed_group,
        s.item_no
    from seeded s
    where nullif(trim(coalesce(s.item_no, '')), '') is null

    union all

    -- 3. The description is the legacy natural key (dim_item_descr is keyed on
    --    DESCR, not item_no). A resolved item with no description resolves to
    --    no description key and only its own item_no would be excluded.
    select
        'item_has_no_description'               as failure,
        s.seed_name,
        s.seed_group,
        s.item_no
    from seeded s
    inner join item_master im on s.item_no = im.item_no
    where nullif(trim(coalesce(im.description, '')), '') is null
)

select * from unknown_item
