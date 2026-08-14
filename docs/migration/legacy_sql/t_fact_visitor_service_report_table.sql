-- TRANSFORMATION: t_fact_visitor_service_report_table
-- DESC: 

-- WRITES: 911DW:.fact_vs_revenue_report (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select monthname(date_value), dayname(date_value), date_value, sum(mus_attendance) as mus_attend, sum(audio_rental) as audio_guide_rental
, sum(budget_audio_rental) as budget_audio_rental , (sum(audio_rental) - sum(budget_audio_rental) )as audio_rental_variance
, sum(audio_rev) as audio_guide_rev ,  sum(budget_audio_rev) as budget_audio_rev, (sum(audio_rev)- sum(budget_audio_rev)) as audio_rev_variance,
(sum(audio_rental)/sum(mus_attendance)) as audio_capture_rate, sum(budget_ag_capture_rate) as budget_ag_capture_rate, 
(sum(audio_rental)/sum(mus_attendance) - sum(budget_ag_capture_rate) ) as ag_cr_variance, 
 sum(headset_rental) as headphone_sales, sum(budget_headset_rental) as budget_headset_rental, 
(sum(headset_rental) - sum(budget_headset_rental)) as headset_rental_variance,sum(headset_rev) as headphone_rev, 
sum(budget_headset_rev) as budget_headset_rev, (sum(headset_rev) - sum(budget_headset_rev))  as headset_rev_variance, 
 (sum(headset_rental)/sum(mus_attendance)) as headset_capture_rate, sum(budget_headphone_cr), 
(sum(headset_rental)/sum(mus_attendance) - sum(budget_headphone_cr)) as headphone_variance_cr,
sum(coatcheck_donations) as coatcheck_donations,
sum(budget_coatcheck_donations), (sum(coatcheck_donations) - sum(budget_coatcheck_donations)) as coatcheck_variance,
sum(kiosk_donations) as kiosk_donations, sum(infodesk_tours) as infodesk_tours
from
(SELECT key_date as date_value, SUM(v.passes_scanned) as mus_attendance, 0 as audio_rental, 0 as budget_audio_rental,0 as audio_rev,
0 as budget_audio_rev, 0 as budget_ag_capture_rate,0 as headset_rental, 0 as budget_headset_rental, 0 as headset_rev, 0 as budget_headset_rev, 
 0 as budget_headphone_cr, 
0 as coatcheck_donations, 0 as budget_coatcheck_donations,  0 as kiosk_donations, 0 as infodesk_tours
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in ( 1006,3000)
AND d.date_value >= '20150101'
group by key_date

union
select key_date as date_value, 0 as mus_attendance, sum(quantity) as audio_rental, 0 as budget_audio_rental, sum(amount) as audio_rev,
0 as budget_audio_rev, 0 as budget_ag_capture_rate,0 as headset_rental,0 as budget_headset_rental, 0 as headset_rev, 0 as budget_headset_rev,
 0 as budget_headphone_cr,   
0 as coatcheck_donations, 0 as budget_coatcheck_donations, 0 as kiosk_donations, 0 as infodesk_tours
from fact_museum_audio_new f, dim_date d
where f.key_date= d.date_key
and f.key_museum_category in (1051,2204,2205,2206,2207,2208,2209)
and d.date_value >= '20150101'
group by key_date

union
select key_date as date_value, 0 as mus_attendance, 0 as audio_rental, audio_guide_rentals as budget_audio_rental, 0 as audio_rev, 
audio_guide_revenue as budget_audio_rev, audio_guide_capture_rate as budget_ag_capture_rate,0 as headset_rental,
sum(headphone_rental) as budget_headset_rental,
 0 as headset_rev, sum(headphone_revenue) as budget_headset_rev, sum(headphone_capture_rate) as budget_headphone_cr,
0 as coatcheck_donations, 
sum(coatcheck_donations) as budget_coatcheck_donations, 0 as kiosk_donations, 0 as infodesk_tours
from fact_dpr_forecasts f, dim_date d
where f.key_date= d.date_key
and d.date_value>= '20150101'
group by key_date

union
select key_date as date_value, 0 as mus_attendance, 0 as audio_rental,0 as budget_audio_rental, 0 as audio_rev, 0 as budget_audio_rev,
0 as budget_ag_capture_rate,sum(quantity) as headset_rental, 0 as budget_headset_rental,
sum(amount) as headset_rev, 0 as budget_headset_rev,  0 as budget_headphone_cr,
 0 as coatcheck_donations, 0 as budget_coatcheck_donations,  0 as kiosk_donations, 0 as infodesk_tours
from fact_museum_audio_new f, dim_date d
where f.key_date= d.date_key
and f.key_museum_category = 1068
and d.date_value >= '20150101'
group by key_date
union
select key_date as date_value, 0 as mus_attendance, 0 as audio_rental,0 as budget_audio_rental, 0 as audio_rev, 0 as budget_audio_rev,
0 as budget_ag_capture_rate,0 as headset_rental, 0 as budget_headset_rental, 0 as headset_rev, 0 as budget_headset_rev, 0 as budget_headphone_cr,
sum(f.amount) as coatcheck_donations, 0 as budget_coatcheck_donations, 0 as kiosk_donations, 0 as infodesk_tours
from fact_all_gateway_donations f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%DON-OPS-MUS%'
and d.date_value >= '20150101'
group by key_date
union
select key_date as date_value, 0 as mus_attendance, 0 as audio_rental,0 as budget_audio_rental, 0 as audio_rev, 0 as budget_audio_rev,
0 as budget_ag_capture_rate,0 as headset_rental,0 as budget_headset_rental, 0 as headset_rev, 0 as budget_headset_rev, 0 as budget_headphone_cr,
0 as coatcheck_donations, 0 as budget_coatcheck_donations,  sum(f.amount) as kiosk_donations, 0 as infodesk_tours
 from fact_all_gateway_donations f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%DON-OPS-MEM%'
and d.date_value >='20150101'
group by key_date
union
select key_date as date_value,0 as mus_attendance, 0 as audio_rental,0 as budget_audio_rental, 0 as audio_rev, 0 as budget_audio_rev,
0 as budget_ag_capture_rate,0 as headset_rental, 0 as budget_headset_rental, 0 as headset_rev, 0 as budget_headset_rev, 0 as budget_headphone_cr,
0 as coatcheck_donations, 0 as budget_coatcheck_donations,  0 as kiosk_donations, sum(f.quantity) as infodesk_tours 
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu in ('MUSGTOAOI001','MUSGTOAOI002')
and f.ga_flag=0
and d.date_value>='20150101'
group by key_date ) as A
where date_value < ?

group by date_value