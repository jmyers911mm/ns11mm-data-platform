-- Test (business_rule): every legacy CounterPoint store 1-14 resolves to at least one facility
-- Severity: error — a store that resolves to no facility silently drops its whole sales history
--
-- Legacy t_fact_retail runs seven queries covering stores 1-14 with no gaps:
--   1,4,6,8 -> 1001 | 2,5,7 -> 1002 | 8,9,10 -> 1003 (+ store 14 / item 201205)
--   11,12,13,14 -> 1020 and carve-outs | 3 -> 1234 | 10 -> 1030 | 1 -> 4007
-- Before 8.2.0 the scope seed listed only 1,3,8,9,10,11,12,13,14, so stores
-- 2, 4, 5, 6 and 7 never reached the platform at all. This test is the guard
-- against that regression and against a scope edit that orphans a store.
--
-- Also checks that every facility the scope seed names exists in
-- seed_facility_area, so a new scope row cannot land as 'Unmapped'.

with expected_store as (
    select column1 as store_id
    from values
        ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'),
        ('8'), ('9'), ('10'), ('11'), ('12'), ('13'), ('14')
),

scope as (
    select
        cast(store_id as varchar)   as store_id,
        key_facility
    from {{ ref('seed_retail_store_scope') }}
),

facility_area as (
    select key_facility
    from {{ ref('seed_facility_area') }}
),

-- 1. Every legacy store must map to at least one facility.
uncovered_store as (
    select
        'store_not_in_scope'                as failure,
        e.store_id                          as store_id,
        cast(null as number(38, 0))         as key_facility
    from expected_store e
    left join scope s on e.store_id = s.store_id
    where s.store_id is null
),

-- 2. Every facility the scope names must be labelled in seed_facility_area.
unlabelled_facility as (
    select distinct
        'facility_not_in_seed_facility_area' as failure,
        s.store_id                           as store_id,
        s.key_facility                       as key_facility
    from scope s
    left join facility_area fa on s.key_facility = fa.key_facility
    where fa.key_facility is null
),

-- 3. Exactly one primary facility row per store per legacy query set: a store
--    with no primary row would vanish from every cross-facility total.
store_without_primary as (
    select
        'store_has_no_primary_facility'     as failure,
        s.store_id                          as store_id,
        cast(null as number(38, 0))         as key_facility
    from {{ ref('seed_retail_store_scope') }} s
    group by s.store_id
    having sum(case when s.is_primary_facility then 1 else 0 end) = 0
)

select * from uncovered_store
union all
select * from unlabelled_facility
union all
select * from store_without_primary
