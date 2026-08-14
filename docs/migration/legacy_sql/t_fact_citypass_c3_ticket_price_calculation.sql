-- TRANSFORMATION: t_fact_citypass_c3_ticket_price_calculation
-- DESC: 



-- ===== STEP: Execute SQL script [ExecSQL] conn=911DW =====
update dim_citypass_revenue
set revenue = ?
where year(key_date) = ?
and month(key_date) = ?
and coupon_category in ('Adult','Youth')

-- ===== STEP: Execute SQL script 2 [ExecSQL] conn=911DW =====
update dim_citypass_revenue
set revenue = ?
where year(key_date) = ?
and month(key_date) = ?
and coupon_category in ('C3 Adult','C3 Youth')

-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT  key_museum_category, sum(amount), year(key_date), month(key_date) 
FROM fact_additional_revenue_new
WHERE key_museum_category in (1653, 2012)
and key_date >= Date_format(DATE_ADD(?,interval -270 day), '%Y%m%d')
group by year(key_date), month(key_date), key_museum_category

-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select ? as key_museum_category, ? as total_amount,sum(quantity), year(key_date), month(key_date)
from fact_museum_citypass_scanchange 
where key_coupon_category in ('Adult','Youth')
and year(key_date)= ?
and month(key_date)= ?

-- ===== STEP: Table input 3 [TableInput] conn=911DW =====
select ? as key_museum_category, ? as total_amount,sum(quantity), year(key_date), month(key_date)
from fact_museum_citypass_scanchange 
where key_coupon_category in ('C3 Adult','C3 Youth')
and year(key_date)= ?
and month(key_date)= ?