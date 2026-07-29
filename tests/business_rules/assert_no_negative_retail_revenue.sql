-- Test (business_rule): no negative net_sales or net_profit in retail facts
-- Co-authored with CoCo
-- Severity: error — negative values indicate sign / aggregation defect in retail pipeline

select 'fct_retail_performance' as source_table, date_key, key_facility, category_code as detail,
       net_sales, null as net_profit_value
from {{ ref('fct_retail_performance') }}
where net_sales < 0

union all

select 'fct_retail_daily' as source_table, date_key, key_facility, null as detail,
       net_sales, net_profit as net_profit_value
from {{ ref('fct_retail_daily') }}
where net_sales < 0 or net_profit < -net_sales
