-- Test (reconciliation): retail gross profit nets return cost, not just return revenue
-- Severity: error — an un-netted cost silently overstates profit on every day with a return
--
-- Legacy t_fact_cogs sums LINE.EXT_COST over ALL surviving lines (sale AND
-- return); before 8.3.0 the platform took cost for line_type 'S' only. A return
-- therefore gave the customer their money back (net_amount nets) while the item
-- kept its cost on the books (sale_cost did not), so gross profit was
-- overstated by the return's cost every time.
--
-- This test pins the fix in three places at once:
--   1. int_counterpoint__retail_lines.net_cost must equal sale_cost + return_cost
--      (the ONE netting convention -- addition, because CounterPoint 'R' lines
--      land negative).
--   2. int_retail__performance.net_profit must equal net_sales - net_cost
--      recomputed from the line model, i.e. it must not have gone back to
--      sale_cost.
--   3. Days that actually contain returns must show net_profit BELOW the
--      un-netted figure. If they are equal on a day with return cost, cost is
--      not being netted anywhere in the chain.
--
-- Scoped to the last 400 days so the test runs on the live window rather than
-- the full history; tolerance is 1 cent absolute, since these are the same
-- rows summed two ways and should agree exactly.

with lines as (
    select
        cast(business_date as date)         as date_key,
        key_facility,
        sum(case when not is_donation then net_amount  else 0 end)  as net_sales,
        sum(case when not is_donation then net_cost    else 0 end)  as net_cost,
        sum(case when not is_donation then sale_cost   else 0 end)  as sale_cost,
        sum(case when not is_donation then return_cost else 0 end)  as return_cost
    from {{ ref('int_counterpoint__retail_lines') }}
    where cast(business_date as date) >= dateadd(day, -400, current_date)
    group by 1, 2
),

perf as (
    select
        date_key,
        key_facility,
        sum(net_sales)      as net_sales,
        sum(net_profit)     as net_profit,
        sum(cost_of_goods)  as cost_of_goods
    from {{ ref('int_retail__performance') }}
    where date_key >= dateadd(day, -400, current_date)
    group by 1, 2
),

joined as (
    select
        l.date_key,
        l.key_facility,
        l.net_sales,
        l.net_cost,
        l.sale_cost,
        l.return_cost,
        p.net_profit,
        p.cost_of_goods
    from lines l
    inner join perf p
        on l.date_key = p.date_key
       and l.key_facility = p.key_facility
),

failures as (
    -- 1. net_cost is the sum of its components (netting convention holds)
    select
        'net_cost_not_sale_plus_return'                             as failure,
        date_key,
        key_facility,
        net_cost                                                    as observed,
        sale_cost + return_cost                                     as expected
    from joined
    where abs(net_cost - (sale_cost + return_cost)) > 0.01

    union all

    -- 2. the performance model's cost measure is the netted one
    select
        'cost_of_goods_not_netted'                                  as failure,
        date_key,
        key_facility,
        cost_of_goods                                               as observed,
        net_cost                                                    as expected
    from joined
    where abs(cost_of_goods - net_cost) > 0.01

    union all

    -- 3. profit is sales minus NETTED cost
    select
        'net_profit_not_sales_minus_net_cost'                       as failure,
        date_key,
        key_facility,
        net_profit                                                  as observed,
        net_sales - net_cost                                        as expected
    from joined
    where abs(net_profit - (net_sales - net_cost)) > 0.01

    union all

    -- 4. regression guard: on a day with real return cost, netted profit must
    --    differ from the old sale-cost-only figure. Equality here means the
    --    chain silently reverted to un-netted cost.
    select
        'profit_unchanged_despite_return_cost'                      as failure,
        date_key,
        key_facility,
        net_profit                                                  as observed,
        net_sales - sale_cost                                       as expected
    from joined
    where abs(return_cost) > 0.01
      and abs(net_profit - (net_sales - sale_cost)) <= 0.01
)

select *
from failures
