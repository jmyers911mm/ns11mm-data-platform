/*
  ml_retail_cross_sell_features
  Source: fct_retail_line_items + dim_product
  STATUS: Awaiting RAW data. Logic migrated from POC — no changes needed.
  Identifies product pair co-purchase lift for cross-sell recommendations.
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

with item_pairs as (
    select
        a.customer_id,
        a.item_sku                                         as product_a,
        b.item_sku                                         as product_b,
        a.transaction_id
    from {{ ref('fct_retail_line_items') }} a
    inner join {{ ref('fct_retail_line_items') }} b
        on  a.transaction_id = b.transaction_id
        and a.item_sku < b.item_sku
    where a.customer_id is not null
      and a.item_sku is not null
      and b.item_sku is not null
),

co_occurrence as (
    select
        product_a, product_b,
        count(distinct transaction_id)                     as co_purchase_count,
        count(distinct customer_id)                        as unique_customers
    from item_pairs
    group by product_a, product_b
),

product_totals as (
    select item_sku as product_id, count(distinct transaction_id) as total_transactions
    from {{ ref('fct_retail_line_items') }}
    where item_sku is not null
    group by item_sku
)

select
    c.product_a, pa.product_name as product_a_name, pa.category as product_a_category,
    c.product_b, pb.product_name as product_b_name, pb.category as product_b_category,
    c.co_purchase_count, c.unique_customers,
    div0(c.co_purchase_count, pt_a.total_transactions)     as lift_from_a,
    div0(c.co_purchase_count, pt_b.total_transactions)     as lift_from_b,
    div0(c.co_purchase_count, least(pt_a.total_transactions, pt_b.total_transactions)) as jaccard_similarity,
    current_timestamp()                                    as _feature_computed_at
from co_occurrence c
left join {{ ref('dim_product') }} pa   on c.product_a = pa.product_id
left join {{ ref('dim_product') }} pb   on c.product_b = pb.product_id
left join product_totals pt_a           on c.product_a = pt_a.product_id
left join product_totals pt_b           on c.product_b = pt_b.product_id
where c.co_purchase_count >= 2
