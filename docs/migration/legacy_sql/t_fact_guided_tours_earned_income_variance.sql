-- TRANSFORMATION: t_fact_guided_tours_earned_income_variance
-- DESC: 

-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)


-- ===== STEP: Table input 3 [TableInput] conn=911DW =====
select key_date, sum(guided_tours), sum(mus_guided_tour_rev), 
sum(mem_guided_tours), sum(mem_guided_tour_revenue), 
sum(early_access_tours),sum(early_access_rev),
 sum(forecasted_mem_tours), sum(forecasted_mem_tour_rev),
sum(forecasted_gt), sum(forecasted_gt_rev),
 sum(forecasted_early_access_tours), sum(forecasted_early_access_rev),
(sum(guided_tours)- sum(forecasted_gt)) as guided_tour_diff, 
(sum(mus_guided_tour_rev)-sum(forecasted_gt_rev)) as guided_tour_rev_diff,
(sum(mem_guided_tours)-sum(forecasted_mem_tours)) as mem_guided_tours_diff,
(sum(mem_guided_tour_revenue)-sum(forecasted_mem_tour_rev)) as mem_guided_tour_rev_diff, 
(sum(early_access_tours)-sum(forecasted_early_access_tours)) as early_access_tours_variance,
(sum(early_access_rev) - sum(forecasted_early_access_rev)) as early_access_tour_rev_diff, 
sum(youth_fam_tours), 
sum(youth_fam_tour_rev), 
sum(forecasted_youth_fam_tours), 
sum(forecasted_youth_fam_tour_rev), 
(sum(youth_fam_tours) - sum(forecasted_youth_fam_tours)) as youth_fam_tour_diff,
(sum(youth_fam_tour_rev) - sum(forecasted_youth_fam_tour_rev)) as youth_fam_tour_rev_diff, 
sum(mem_mus_tours), 
sum(mem_mus_tour_rev), 
sum(forecasted_mem_mus_tours), 
sum(forecasted_mem_mus_tour_rev),
(sum(mem_mus_tours) - sum(forecasted_mem_mus_tours)) as mem_mus_tour_diff, 
(sum(mem_mus_tour_rev) - sum(forecasted_mem_mus_tour_rev)) as mem_mus_tour_rev_diff
from
(select key_date, sum( total_mus_tours + mus_gt_buyout_qty) as guided_tours,sum(total_mus_gt_rev) as mus_guided_tour_rev , sum(total_mem_tours) as mem_guided_tours, sum(total_mem_tours_revenue) as mem_guided_tour_revenue, 
sum(early_access_mus_tours) as early_access_tours, sum(early_access_mus_tour_rev) as early_access_rev, sum(youth_fam_tours) as youth_fam_tours, sum(youth_fam_tour_rev) as youth_fam_tour_rev, sum(mem_mus_tours) as mem_mus_tours, sum(mem_mus_tour_rev) as mem_mus_tour_rev,
 0 as forecasted_mem_tours, 0 as forecasted_mem_tour_rev, 
0 as forecasted_gt, 0 as forecasted_gt_rev, 0 as forecasted_early_access_tours, 0 as forecasted_early_access_rev, 0 as forecasted_youth_fam_tours, 0 as forecasted_youth_fam_tour_rev,
0 as forecasted_mem_mus_tours, 0 as forecasted_mem_mus_tour_rev
from earned_revenue_report_values e, dim_date d
where e.key_date = d.date_key
and d.date_value >='20140521'
group by key_date
union
select key_date, 0 as guided_tours, 0 as mus_guided_tour_rev, 0 as mem_guided_tours, 0 as mem_guided_tour_revenue, 0 as early_access_tours, 0 as early_access_rev, 0 as youth_fam_tours, 0 as youth_fam_tour_rev,
0 as mem_mus_tours, 0 as mem_mus_tour_rev,
sum(f.mem_guided_tours) as forecasted_mem_tours, sum(f.mem_guided_tours_revenue) as forecasted_mem_tour_rev, sum(f.guided_tours)  as forcasted_gt,
 sum(f.guided_tours_revenue) as forecasted_gt_rev, 0 as forecasted_early_access_tours, 0 as forecastd_early_access_rev, 0 as forecasted_youth_fam_tours, 0 as forecasted_youth_fam_tour_rev
, sum(mem_mus_tours) as forecasted_mem_mus_tours, sum(mem_mus_tour_revenue) as forecasted_mem_mus_tour_rev 
from
fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
group by f.key_date
UNION
select key_date, 0 as guided_tours, 0 as mus_guided_tour_rev, 0 as mem_guided_tours, 0 as mem_guided_tour_revenue, 0 as early_access_tours, 0 as early_access_rev, 0 as youth_fam_tours, 0 as youth_fam_tour_rev,
0 as mem_mus_tours, 0 as mem_mus_tour_rev,
0 as forecasted_mem_tours, 0 as forecasted_mem_tour_rev, 0 as forecasted_gt, 0 as forecasted_gt_rev,
 sum(early_access_tours) as forecasted_early_access_tours, sum(f.early_access_tour_rev) as forecasted_early_access_rev, sum(youth_fam_tours) as forecasted_youth_fam_tours, sum(youth_fam_tour_rev) as forecasted_youth_fam_tour_rev,
0 as forecasted_mem_mus_tours, 0 as forecasted_mem_mus_tour_rev
from fact_dpr_forecasts f, dim_date d
where f.key_date= d.date_key
and d.date_value >= '20160101'
group by key_date
) as A
where key_date < ?
group by key_date