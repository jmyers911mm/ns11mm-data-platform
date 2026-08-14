-- TRANSFORMATION: t_fact_dpr_totals
-- DESC: 

-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date, sum(total_estimated_rev) from
(select key_date, sum(total_revenue) as total_estimated_rev
from earned_revenue_report_values e, dim_date d
where e.key_date= d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date, sum(profit) as total_estimated_rev
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20140521'
and f.key_facility in (1007, 1001, 1020,1234)
group by key_date
union
select key_date, (ifnull(sum(total_mem_tours_revenue),0) + ifnull(sum(total_mus_gt_rev),0) + ifnull(sum(early_access_mus_tour_rev),0)) as total_estimated_rev
from earned_revenue_report_values e, dim_date d
where e.key_date= d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date, sum(total_other_vis_rev) as total_estimated_rev
from earned_revenue_report_values e, dim_date d
where e.key_date= d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date, (sum(revenue)*0.05) as total_estimated_rev
 from cafe_performance c , dim_date d
where c.key_date=d.date_key
and d.date_value >= '20140521'
group by key_date
 ) as B
where key_date < ?
group by key_date
order by key_date

-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select key_date, sum(total_estimated_rev) from
(
select key_date,sum(revenue + citypass_revenue+ service_fees) as total_estimated_rev
 from fact_forecasted_value_for_date f, dim_date d
where f.key_date= d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date,sum(licensing_fees + early_access_tour_rev) as total_estimated_rev
from fact_dpr_forecasts f, dim_date d
where f.key_date= d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date,(sum(retail_1)+ sum(retail_2)) as total_estimated_rev
from
(select key_date,sum(profit_from_retail) as retail_1, 0 as retail_2
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20140521'
and f.key_facility in (1001, 1020,1003)
group by key_date
union
select key_date,0 as retail_1,sum(profit_from_ecom) as retail_2
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20140521'
group by key_date) as A
group by key_date
union
select key_date,(ifnull(sum(guided_tours_revenue),0) + ifnull(sum(mem_guided_tours_revenue),0)) as total_estimated_rev
from fact_forecasted_value_for_date f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date,(ifnull(sum(other_vis_1),0) + ifnull(sum(other_vis_2),0)) as total_estimated_rev
 from 
(select key_date,sum(audio_tour_headsets + donations_ticketing + coatcheck_donations + museum_exit_donations) as other_vis_1, 0 as other_vis_2
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as other_vis_1, sum(donations)  as other_vis_2 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility in (1003, 1001,1020)
and d.date_value >= '20140521'
group by key_date ) as B
group by key_date) as C
where key_date < ?
group by key_date