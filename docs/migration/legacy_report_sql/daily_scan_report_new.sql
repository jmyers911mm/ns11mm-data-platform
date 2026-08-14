-- REPORT: Daily Scan Report (daily_scan_report_new)

-- ===== [datasources/sql-ds.xml] query: Passes_by_hour =====
SELECT if (f.perhour < 12, 
    concat(cast(f.perhour as char) , 'AM - ', cast(f.perhour+1 as char), if(f.perhour+1 >11,'PM', 'AM')),
    concat(cast(if(f.perhour-12<1, 12, f.perhour - 12) as char), 'PM - ' , cast(f.perhour-11 as char), if(f.perhour+1 >23,'AM', 'PM'))) as byhour
           , passes as total_passes
FROM fact_passes_by_hour f inner join dim_date d on f.key_date=d.date_key 
where d.date_value = ${today}     
order by f.perhour

-- ===== [datasources/sql-ds.xml] query: Summary By Distribution Channel =====
SELECT

(select (sum(advance)+ifnull(sum(mobile),0)) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as advance_passes_budget
,
(select sum(walk_up) from fact_dsr_forecasts f
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as walk_up_passes_budget
,
(select sum(self_organized_groups) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as self_organized_groups_passes_budget
,
(select partners from fact_dsr_forecasts f
 inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as resellers_passes_issued_budget
,
(select tour_travel from fact_dsr_forecasts f
 inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as tour_travel_passes_issued_budget
,
(select sum(citypass) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as citypass_passes_budget
,
(select sum(c3_citypass) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as c3_passes_budget
,
(select sum(sightseeing_pass) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as sightseeing_passes_budget
,
(select sum(new_york_pass) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as newyork_passes_budget
,
(select sum(explorer_pass) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as explorer_passes_budget
,
(select sum(school_groups) from fact_dsr_forecasts f
 inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as groups_schools_passes_budget
,
(select sum(membership) from fact_dsr_forecasts f 
inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as members_passes_budget
,
(select sum(comps) from fact_dsr_forecasts f
 inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as comps_passes_budget
,
(select sum(gocity) from fact_dsr_forecasts f
 inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as gocity_budget
,
(select sum(total_tickets) from fact_dsr_forecasts f
 inner join  dim_date d on f.key_date=d.date_key
where d.date_value = ${today}) as total_tickets_budget
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f 
inner join  dim_date d on f.key_date=d.date_key
where f.category = 'Groups'
and d.date_value = ${today}) as self_organized_groups_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'School Groups'
and d.date_value = ${today}) as school_groups_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'New York Pass'
and d.date_value = ${today}) as nyp_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'Explorer Pass'
and d.date_value = ${today}) as explorer_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category= 'Sightseeing Pass'
and d.date_value = ${today}) as sightseeing_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category  in ('Complimentary / Free Admission Programs', 'Stakeholders')
and d.date_value = ${today}) as comps_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'CityPASS'
and d.date_value = ${today}) as citypass_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'C3'
and d.date_value = ${today}) as c3_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category in ( 'Tour Operators', 'Concierge')
and d.date_value = ${today}) as tour_travel_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category in ( 'Resellers')
and d.date_value = ${today}) as reseller_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category  in ('Membership','Institutional Advancement')
and d.date_value = ${today}) as membership_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'offSite'
and d.date_value = ${today}) as offsite_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'onSite'
and d.date_value = ${today}) as onsite_tickets_sold
,
(select ifnull(sum(qty),0) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'GoCity'
and d.date_value = ${today}) as gocity_tickets_sold

,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'Groups'
and d.date_value = ${today}) as self_organized_groups_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category =  'School Groups'
and d.date_value = ${today}) as school_groups_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category =  'New York Pass'
and d.date_value = ${today}) as nyp_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category =  'Explorer Pass'
and d.date_value = ${today}) as explorer_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category =  'Sightseeing Pass'
and d.date_value = ${today}) as sightseeing_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category  in ( 'Complimentary / Free Admission Programs', 'Stakeholders')
and d.date_value = ${today}) as comps_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category =  'CityPASS'
and d.date_value = ${today}) as citypass_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category =  'C3'
and d.date_value = ${today}) as c3_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category in ('Tour Operators', 'Concierge')
and d.date_value = ${today}) as tour_travel_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category in ('Resellers')
and d.date_value = ${today}) as reseller_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category in ('Membership', 'Institutional Advancement')
and d.date_value = ${today}) as membership_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'offSite'
and d.date_value = ${today}) as offsite_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'onSite'
and d.date_value = ${today}) as onsite_passes_scanned
,
(select sum(scannedQty) from fact_dailyscan_data f
 inner join  dim_date d on f.key_date=d.date_key
where f.category = 'GoCity'
and d.date_value = ${today}) as gocity_passes_scanned