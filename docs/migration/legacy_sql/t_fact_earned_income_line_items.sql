-- TRANSFORMATION: t_fact_earned_income_line_items
-- DESC: 

-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)
-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date, (sum(issued_tickets) + sum(citypass_scanchange_ga)) as tickets_issued, sum(unissued_tickets) as tickets_unissued, sum(mem_mus_issued_tickets) as tickets_mem_mus_issued, sum(mem_mus_unissued_tickets) as tickets_mem_mus_unissued,
sum(citypass_tickets +citypass_scanchange) as citypass_tic, sum(bulk_tickets), sum(c3_tickets),
sum(issued_tickets + unissued_tickets + mem_mus_issued_tickets + mem_mus_unissued_tickets + citypass_tickets + bulk_tickets + c3_tickets + citypass_scanchange + citypass_scanchange_ga - child_evg_tickets) as total_tickets
from
(select key_date,sum(f.quantity) as issued_tickets, 0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets , 0 as citypass_tickets,  
0 as bulk_tickets, 0 as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.account_idno not like '%XGA%'
and f.ga_flag=1
and g.plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011','CPBOOKAD010','MUSGADEXW001')
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_tickets, 0 as unissued_tickets, sum(f.quantity) as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  
0 as bulk_tickets, 0 as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_tickets, sum(f.quantity) as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  
0 as bulk_tickets, 0 as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.account_idno not like '%XGA%'
and f.ga_flag=1
and g.plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011','CPBOOKAD010','MUSGADEXW001')
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_tickets, 0 as unissued_tickets,0 as mem_mus_issued_tickets, sum(f.quantity) as mem_mus_unissued_tickets, 0 as citypass_tickets,  
0 as bulk_tickets, 0 as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_tickets, 0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, sum(quantity) as citypass_tickets, 
0 as bulk_tickets, 0 as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by key_date
union

select key_date,  0 as issued_tickets,  0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  sum(quantity) as bulk_tickets, 0 as c3_tickets
, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_bulk_tickets_test f, dim_date d
where f.key_date = d.date_key and d.date_value >= '20140521'
group by key_date
UNION
select key_date, 0 as issued_tickets, 0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  0 as bulk_tickets,
sum(quantity) as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and key_date >= '20160501'
group by key_date
union
select key_date, 0 as issued_tickets, 0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  0 as bulk_tickets,
0 as c3_tickets, sum(quantity) as citypass_scanchange, 0 as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and f.key_coupon_category in ('Adult', 'Youth')
and d.date_value >= '20160601'
group by key_date
union
select key_date, 0 as issued_tickets, 0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  0 as bulk_tickets,
0 as c3_tickets, 0 as citypass_scanchange, sum(quantity) as citypass_scanchange_ga, 0 as child_evg_tickets
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and f.key_coupon_category in ('C3 Adult', 'C3 Youth')
and d.date_value >= '20160601'
group by key_date
union
select key_date, 0 as issued_tickets, 0 as unissued_tickets, 0 as mem_mus_issued_tickets, 0 as mem_mus_unissued_tickets, 0 as citypass_tickets,  0 as bulk_tickets,
0 as c3_tickets, 0 as citypass_scanchange, 0 as citypass_scanchange_ga, sum(quantity) as child_evg_tickets
from fact_museum_bulk_tickets_test f, dim_date d
where f.key_date =  d.date_key 
and (f.pricePointID = 84)
and d.date_value >= '20140521'
group by key_date
) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select key_date, (sum(gad_issued_rev)+sum(citypass_scanchange_rev_ga)) as gad_issued, sum(tou_issued_rev) as tou_issued, sum(unissued_rev) as unissued_revenue,
sum(mem_mus_tour_rev) as mem_mus_tour_revenue, sum(citypass_rev_adult_youth + citypass_rev_none + citypass_scanchange_rev +citypass_booklet_rev) as citypass_revenue,sum(mus_service_fees) as mus_fees, sum(mem_service_fees) as mem_fees,
sum(c3_revenue) as c3_revenue, sum(nyp_add_rev) as nyp_add_rev,  sum(bulk_ticket_rev) as bulk_ticket_rev,sum(bulk_scan_revenue) as bulk_scan_revenue,
sum(gad_issued_rev + tou_issued_rev + unissued_rev + mem_mus_tour_rev + citypass_rev_adult_youth + citypass_rev_none +citypass_booklet_rev +  mus_service_fees + mem_service_fees+ c3_revenue + citypass_scanchange_rev + citypass_scanchange_rev_ga + nyp_add_rev +  bulk_ticket_rev + bulk_scan_revenue) as total_revenue
from
(select key_date, sum(f.amount) as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none,0 as mus_service_fees, 0 as mem_service_fees, 
0 as c3_revenue , 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as gad_issued_rev, sum(f.amount) as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees,0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev, 0 as citypass_scanchange_rev_ga,0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, sum(f.amount)  as unissued_rev, 0 as mem_mus_tour_rev , 0 as citypass_rev_adult_youth, 0 as citypass_rev_none,0 as mus_service_fees, 0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_tickets_unissued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, sum(f.amount) as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees,0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, sum(quantity * amount) as citypass_rev_adult_youth,0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees, 
0 as c3_revenue , 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev, 0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('Adult','Youth')
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, sum(amount) as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and (f.key_coupon_category ='None')
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, sum(amount) as mus_service_fees , 0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_service_fees_new f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and g.account_idno like '%MUF%' and g.account_idno like '%FEE%'
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, sum(amount) as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev, 0 as citypass_scanchange_rev_ga,0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_service_fees_new f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and g.account_idno like '%MEF%' and g.account_idno like '%FEE%'
and d.date_value  >= '20140521'
group by key_date

union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees,  
sum(quantity*amount) as c3_revenue, 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and d.date_value >= '20160501'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees,  
0 as c3_revenue, 0 as citypass_scanchange_rev, sum(quantity * amount) as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and f.key_coupon_category in ('C3 Adult', 'C3 Youth')
and d.date_value >='20160601'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees,  
0 as c3_revenue, sum(quantity * amount) as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, 0  as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and f.key_coupon_category in ('Adult', 'Youth')
and d.date_value >='20160601'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees,  
0 as c3_revenue, 0 as citypass_scanchange_rev, 0 as citypass_scanchange_rev_ga,0  as nyp_add_rev,  sum(amount) as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_citypass_booklets f, dim_galaxy_items g, dim_date d
where f.key_date=d.date_key
and f.key_museum_category =g.key_category
and g.plu in ('MUSGADADCP005', 'MUSGADYSCP005')
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees,  
0 as c3_revenue, 0 as citypass_scanchange_rev,0 as citypass_scanchange_rev_ga, sum(amount) as nyp_add_rev,  0 as citypass_booklet_rev, 0 as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_museum_nyp_add f, dim_date d
where f.key_date = d.date_key
and d.date_value >='20160601'
group by key_date
UNION
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev, 0 as citypass_scanchange_rev_ga,0 as nyp_add_rev,  0 as citypass_booklet_rev, sum(amount) as bulk_ticket_rev, 0 as bulk_scan_revenue
from fact_bulk_tickets_add f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20170401'
group by key_date
union
select key_date, 0 as gad_issued_rev, 0 as tou_issued_rev, 0 as unissued_rev, 0 as mem_mus_tour_rev, 0 as citypass_rev_adult_youth, 0 as citypass_rev_none, 0 as mus_service_fees, 0 as mem_service_fees, 
0 as c3_revenue, 0 as citypass_scanchange_rev, 0 as citypass_scanchange_rev_ga, 0 as nyp_add_rev, 0 as citypass_booklet_rev, 0 as bulk_ticket_rev, sum(amount) as bulk_scan_revenue
from fact_museum_bulk_tickets_test f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20140521'
group by key_date
) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 3 [TableInput] conn=911DW =====
select key_date, sum(tou_issued) as issued_mus_tours, sum(tou_unissued) as unissued_mus_tours, (sum(tou_issued) + sum(tou_unissued) + sum(buyout_qty)) as total_mus_tours,
(sum(ea_tou_issued) + sum(ea_tou_unissued)+sum(early_buyout_qty)) as early_access_tours, sum(buyout_qty) as tour_buyout_qty, (sum(youth_fam_issued) + sum(youth_fam_unissued)) as youth_fam_tours, sum(mem_mus_tours) as mem_mus_tours,
sum(mem_mus_tour_revenue) as mem_mus_tour_rev
from
(select key_date,sum(f.quantity) as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, 0 as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001','MUSARCADW001', 'MUSGTOFTAC001','MUSGTOFTYC001','MUSGTOADW011')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as tou_issued, sum(f.quantity) as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, 0 as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001','MUSARCADW001', 'MUSGTOFTAC001','MUSGTOFTYC001','MUSGTOADW011')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as tou_issued, 0 as tou_unissued,sum(f.quantity) as ea_tou_issued, 0 as ea_tou_unissued , 0 as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005', 'MUSGTOADW005','MUSGTOADW011')
and f.ga_flag=0
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, sum(f.quantity) as ea_tou_unissued, 0 as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005', 'MUSGTOADW005','MUSGTOADW011')
and f.ga_flag=0
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, sum(f.quantity) as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
from fact_museum_guided_tour_buyout f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
and f.key_museum_category in (1077,1430,1922,2226)
group by key_date
UNION
select key_date, 0 as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, 0 as buyout_qty, sum(f.quantity) as early_buyout_qty, 0 as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue 
from fact_museum_guided_tour_buyout f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
and f.key_museum_category in (2112,2228)
group by key_date
union
select key_date,0 as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, 0 as buyout_qty, 0 as early_buyout_qty, sum(f.quantity) as youth_fam_issued, 0 as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001', 'MUSGTOFTAC001','MUSGTOFTYC001',
 'MUSGTOFTAW001',  'MUSGTOFTAW002',  'MUSGTOFTMW001',  'MUSGTOFTSW001',  'MUSGTOFTTW001', 'MUSGTOFTVW001')
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, 0 as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued,sum(f.quantity) as youth_fam_unissued, 0 as mem_mus_tours, 0 as mem_mus_tour_revenue
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001', 'MUSGTOFTAC001','MUSGTOFTYC001',
 'MUSGTOFTAW001',  'MUSGTOFTAW002',  'MUSGTOFTMW001',  'MUSGTOFTSW001',  'MUSGTOFTTW001', 'MUSGTOFTVW001')
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as tou_issued, 0 as tou_unissued, 0 as ea_tou_issued, 0 as ea_tou_unissued, 0 as buyout_qty, 0 as early_buyout_qty, 0 as youth_fam_issued,0 as youth_fam_unissued,
sum(quantity) as mem_mus_tours, sum(amount) as mem_mus_tour_revenue
from fact_memorial_museum_tour f inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20160701'
group by key_date) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 4 [TableInput] conn=911DW =====
select key_date, sum(issued_gt_rev) as mus_gt_issued_rev, sum(unissued_gt_rev) as mus_gt_unissued_rev, sum(gt_buyout_rev) as mus_gt_buyout_rev
, sum(issued_gt_rev + unissued_gt_rev + gt_buyout_rev) as total_mus_gt_rev, (sum(issued_ea_rev) + sum(unissued_ea_rev)  + sum(early_buyout_rev))as early_access_tour_rev, (sum(youth_fam_issued_rev) + sum(youth_fam_unissued_rev)) as youth_fam_tour_rev
from
(select key_date,  sum(f.amount) as issued_gt_rev, 0 as unissued_gt_rev,0 as issued_ea_rev, 0 as unissued_ea_rev, 0 as gt_buyout_rev, 0 as early_buyout_rev, 0 as youth_fam_issued_rev, 0 as youth_fam_unissued_rev
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001','MUSARCADW001', 'MUSGTOFTAC001','MUSGTOFTYC001','MUSGTOADW011')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_gt_rev, sum(f.amount) as unissued_gt_rev,0 as issued_ea_rev, 0 as unissued_ea_rev, 0 as gt_buyout_rev , 0 as early_buyout_rev, 0 as youth_fam_issued_rev, 0 as youth_fam_unissued_rev
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001','MUSARCADW001', 'MUSGTOFTAC001','MUSGTOFTYC001','MUSGTOADW011')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_gt_rev, 0 as unissued_gt_rev,0 as issued_ea_rev, 0 as unissued_ea_rev, sum(f.amount)  as gt_buyout_rev, 0 as early_buyout_rev, 0 as youth_fam_issued_rev, 0 as youth_fam_unissued_rev
from fact_museum_guided_tour_buyout f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
and f.key_museum_category in (1077,1430,1922,2226)
group by key_date
UNION
select key_date, 0 as issued_gt_rev, 0 as unissued_gt_rev,0 as issued_ea_rev, 0 as unissued_ea_rev, 0 as gt_buyout_rev, sum(f.amount)  as early_buyout_rev, 0 as youth_fam_issued_rev, 0 as youth_fam_unissued_rev
from fact_museum_guided_tour_buyout f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
and f.key_museum_category in (2112,2228)
group by key_date
union
select key_date,  0 as issued_gt_rev,  0 as unissued_gt_rev, sum(f.amount) as issued_ea_rev, 0 as unissued_ea_rev, 0 as gt_buyout_rev, 0 as early_buyout_rev, 0 as youth_fam_issued_rev, 0 as youth_fam_unissued_rev
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005', 'MUSGTOADW005','MUSGTOADW011')
and f.ga_flag in (0,1)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_gt_rev, 0 as unissued_gt_rev, 0 as issued_ea_rev, sum(f.amount) as unissued_ea_rev, 0 as gt_buyout_rev , 0 as early_buyout_rev, 0 as youth_fam_issued_rev, 0 as youth_fam_unissued_rev
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and g.plu in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005', 'MUSGTOADW005','MUSGTOADW011')
and f.ga_flag in (0,1)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_gt_rev, 0 as unissued_gt_rev, 0 as issued_ea_rev, 0 as unissued_ea_rev, 0 as gt_buyout_rev , 0 as early_buyout_rev, sum(f.amount) as youth_fam_issued_rev, 0 as youth_fam_unissued_rev 
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and f.ga_flag = 0 
and g.plu in ('MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001', 'MUSGTOFTAC001','MUSGTOFTYC001',
 'MUSGTOFTAW001',  'MUSGTOFTAW002',  'MUSGTOFTMW001',  'MUSGTOFTSW001',  'MUSGTOFTTW001', 'MUSGTOFTVW001')
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as issued_gt_rev, 0 as unissued_gt_rev, 0 as issued_ea_rev, 0 as unissued_ea_rev, 0 as gt_buyout_rev , 0 as early_buyout_rev, 0 as youth_fam_issued_rev,sum(f.amount) as youth_fam_unissued_rev
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%TOU%'
and f.ga_flag = 0
and g.plu in ('MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001', 'MUSGTOFTAC001','MUSGTOFTYC001',
 'MUSGTOFTAW001',  'MUSGTOFTAW002',  'MUSGTOFTMW001',  'MUSGTOFTSW001',  'MUSGTOFTTW001', 'MUSGTOFTVW001')
and d.date_value >= '20140521'
group by key_date) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 5 [TableInput] conn=911DW =====
select key_date, sum(mem_tours_issued) as mem_tours_issued, sum(mem_tours_unissued) as mem_tours_unissued, sum(mem_tours_dis_issued) as mem_tours_dis_issued, sum(mem_tours_dis_unissued) as mem_tours_dis_unissued,
(sum(mem_tours_issued) + sum(mem_tours_unissued) + sum(mem_tours_dis_issued) + sum(mem_tours_dis_unissued)+ sum(mem_buyout_qty)) as total_mem_tours
from  
(select key_date, sum(f.quantity) as mem_tours_issued, 0 as mem_tours_unissued, 0 as mem_tours_dis_issued, 0 as mem_tours_dis_unissued, 0 as mem_buyout_qty
from fact_memorial_tours_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XGA%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as mem_tours_issued, sum(f.quantity) as mem_tours_unissued , 0 as mem_tours_dis_issued , 0 as mem_tours_dis_unissued, 0 as mem_buyout_qty
from fact_memorial_tours_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XGA%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as mem_tours_issued, 0 as mem_tours_unissued, sum(f.quantity) as mem_tours_dis_issued, 0 as mem_tours_dis_unissued, 0 as mem_buyout_qty
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=0
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as mem_tours_issued, 0 as mem_tours_unissued, 0 as mem_tours_dis_issued, sum(f.quantity) as mem_tours_dis_unissued, 0 as mem_buyout_qty
 from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=0 
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as mem_tours_issued,  0 as mem_tours_unissued, 0 as mem_tours_dis_issued, 0 as mem_tours_dis_unissued, sum(f.quantity) as mem_buyout_qty
from fact_museum_guided_tour_buyout f, dim_date d
where f.key_date = d.date_key
and f.key_museum_category in (2219,2220)
group by key_date ) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 6 [TableInput] conn=911DW =====
select key_date, sum(mem_tours_issued_rev) as mem_tours_issued_revenue, sum(mem_tours_unissued_rev) as mem_tours_unissued_revenue, sum(mem_tours_dis_issued_rev) as mem_tours_dis_issued_revenue, 
sum(mem_tours_dis_unissued_rev) as mem_tours_dis_unissued_revenue,
(sum(mem_tours_issued_rev) + sum(mem_tours_unissued_rev) + sum(mem_tours_dis_issued_rev) + sum(mem_tours_dis_unissued_rev) + sum(mem_buyout_rev)) as total_mem_tours_revenue
from  
(select key_date, sum(f.amount) as mem_tours_issued_rev, 0 as mem_tours_unissued_rev, 0 as mem_tours_dis_issued_rev, 0 as mem_tours_dis_unissued_rev, 0 as mem_buyout_rev
from fact_memorial_tours_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XGA%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as mem_tours_issued_rev, sum(f.amount) as mem_tours_unissued_rev , 0 as mem_tours_dis_issued_rev , 0 as mem_tours_dis_unissued_rev, 0 as mem_buyout_rev
from fact_memorial_tours_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XGA%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as mem_tours_issued_rev, 0 as mem_tours_unissued_rev, sum(f.amount) as mem_tours_dis_issued_rev, 0 as mem_tours_dis_unissued_rev, 0 as mem_buyout_rev
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=0
and d.date_value >= '20140521'
group by key_date
union
select key_date,0 as mem_tours_issued_rev, 0 as mem_tours_unissued_rev, 0 as mem_tours_dis_issued_rev, sum(f.amount) as mem_tours_dis_unissued_rev, 0 as mem_buyout_rev
 from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=0 
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as mem_tours_issued,  0 as mem_tours_unissued, 0 as mem_tours_dis_issued, 0 as mem_tours_dis_unissued, sum(f.amount) as mem_buyout_rev
from fact_museum_guided_tour_buyout f, dim_date d
where f.key_date = d.date_key
and f.key_museum_category in (2219,2220)
group by key_date  ) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 7 [TableInput] conn=911DW =====
select key_date, sum(audio_headset), sum(ticketing_don_1 + ticketing_don_2) as ticketing_don, sum(coatcheck_don) , sum(mus_exit_don),
sum(ms_don), sum(msv_don), sum(retail_cart_don + retail_cart_don_2), 
sum(audio_headset + ticketing_don_1 + ticketing_don_2 + coatcheck_don + mus_exit_don + ms_don + msv_don + retail_cart_don + retail_cart_don_2) as total_other_vis_rev
from
(select key_date, sum(f.amount) as audio_headset, 0 as ticketing_don_1, 0 as ticketing_don_2, 0 as coatcheck_don, 0 as mus_exit_don, 
0 as ms_don, 0 as msv_don,0 as retail_cart_don, 0 as retail_cart_don_2
from fact_museum_audio f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as audio_headset, sum(f.amount) as ticketing_don_1,  0 as ticketing_don_2, 0 as coatcheck_don, 0 as mus_exit_don, 
0 as ms_don, 0 as msv_don,0 as retail_cart_don, 0 as retail_cart_don_2
from fact_museum_ticketing_donations_issued f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20140521'
group by key_date
UNION
select key_date, 0 as audio_headset, 0 as ticketing_don_1, sum(f.amount) as ticketing_don_2,  0 as coatcheck_don, 0 as mus_exit_don, 
0 as ms_don, 0 as msv_don,0 as retail_cart_don, 0 as retail_cart_don_2
from fact_museum_ticketing_donations_unissued f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as audio_headset, 0 as ticketing_don_1, 0 as ticketing_don_2, sum(f.amount) as coatcheck_don,0 as mus_exit_don, 
 0 as ms_don, 0 as msv_don,0 as retail_cart_don, 0 as retail_cart_don_2
 from fact_museum_coatcheck_donations f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%DON-OPS-MUS%'
and d.date_value>= '20140521'
group by key_date
union
select key_date, 0 as audio_headset, 0 as ticketing_don_1,0 as ticketing_don_2,  0 as coatcheck_donations, 
sum(r.Amount+r.Return_Amount) as mus_exit_don,  0 as ms_don, 0 as msv_don,0 as retail_cart_don , 0 as retail_cart_don_2
from fact_retail r, dim_date d
 where r.key_item_descr in ('886') 
and r.key_date=d.date_key 
and d.date_value >='20150129'
group by key_date
union
SELECT key_date, 0 as audio_headset, 0 as ticketing_don_1,0 as ticketing_don_2,  0 as coatcheck_donations, 0 as mus_exit_don,
 (sum(r.Amount)+sum(r.Return_Amount)) as ms_don, 0 as msv_don, 0 as retail_cart_don, 0 as retail_cart_don_2
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
AND d.date_value >= '20140521'
group by key_date
union
SELECT key_date, 0 as audio_headset, 0 as ticketing_don_1, 0 as ticketing_don_2,  0 as coatcheck_donations, 0 as mus_exit_don,
0 as ms_don, (sum(r.Amount)+sum(r.Return_Amount)) as msv_don, 0 as retail_cart_don, 0 as retail_cart_don_2
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr not in (583,598,886,931,2168,2169,2170,2171,2172,2173)
AND r.key_facility = 1001
AND r.key_summary_category = 6
AND d.date_value >= '20140521'
group by key_date
union
SELECT key_date, 0 as audio_headset, 0 as ticketing_don_1, 0 as ticketing_don_2,  0 as coatcheck_donations, 0 as mus_exit_don,
0 as ms_don, 0 as msv_don, (sum(r.Amount)+sum(r.Return_Amount)) as retail_cart_don_1, 0 as retail_cart_don_2
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3373,3375)
AND f.key_facility = 1020
AND r.key_summary_category = 6
AND d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as audio_headset, 0 as ticketing_don_1, 0 as ticketing_don_2,  0 as coatcheck_donations, 0 as mus_exit_don,
0 as ms_don, 0 as msv_don, 0 as retail_cart_don_1, sum(f.amount) as retail_cart_don_2 
from fact_memorial_kiosk_donations f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%DON-OPS-MEM%'
and d.date_value  >= '20140521'
group by key_date) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 8 [TableInput] conn=911DW =====
select the_date, (sum(issued_rev) + sum(unissued_rev) + sum(mem_mus_tkts) + sum(evg_rev) + sum(bulk_rev)) as ticket_revenue
from
(select f.key_date as the_date, sum(f.amount) as issued_rev, 0 as unissued_rev, 0 as mem_mus_tkts, 0 as evg_rev, 0 as bulk_rev
from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.customer_id not in ('20056','17522','23110','22361')
and f.ga_flag=1
and d.date_value >= '20140521'
group by f.key_date
union
select f.key_date as the_date,  0 as issued_rev, sum(f.amount) as unissued_rev, 0 as mem_mus_tkts, 0 as evg_rev, 0 as bulk_rev
from fact_museum_tickets_unissued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.ga_flag=1
and d.date_value >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date, 0 as issued_rev, 0 as unissued_rev, sum(f.amount) as mem_mus_tkts, 0 as evg_rev, 0 as bulk_rev
from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date, 0 as issued_rev, 0 as unissued_rev, 0 as mem_mus_tkts, sum(amount_sold) as evg_rev, 0 as bulk_rev
from fact_museum_evergreen f, dim_date d, dim_galaxy_items g
where f.key_date = d.date_key 
and f.key_museum_category = g.key_category and 
g.plu in ('MUSGADADW011','MUSGADSNW011','MUSGADVTW011','MUSGADSTW011','MUSGADYSW011')
and d.date_value >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date, 0 as issued_rev, 0 as unissued_rev, 0 as mem_mus_tkts, 0 as evg_rev, sum(amount) as bulk_rev
from fact_bulk_tickets_add f, dim_date d
where f.key_date = d.date_key and
d.date_value >= '20140521'
group by f.key_date)as A
where the_date < ?
group by the_date

-- ===== STEP: Table input 9 [TableInput] conn=911DW =====
select the_date, (sum(citypass_none) + sum(citypass_adult_youth)+sum(citypass_scanchange) +sum(citypass_booklets)+sum(c3_revenue)+sum(c3_scanchange)+sum(nyp_add_rev)+sum(other_pass_rev)) as pass_revenue
from
(select f.key_date as the_date, sum(amount) as citypass_none, 0 as citypass_adult_youth, 0 as citypass_scanchange, 0 as citypass_booklets, 
0 as c3_revenue, 0 as c3_scanchange, 0 as nyp_add_rev,0 as other_pass_rev
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and (f.key_coupon_category ='None')
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by f.key_date
union
select f.key_date as the_date, 0 as citypass_none, sum(quantity*amount) as citypass_adult_youth, 0 as citypass_scanchange, 0 as citypass_booklets, 
0 as c3_revenue, 0 as c3_scanchange,0 as nyp_add_rev, 0 as other_pass_rev
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('Adult','Youth')
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date,0 as citypass_none, 0 as citypass_adult_youth, sum(quantity*amount) as citypass_scanchange, 0 as citypass_booklets, 
0 as c3_revenue, 0 as c3_scanchange,0 as nyp_add_rev, 0 as other_pass_rev
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and f.key_coupon_category in ('Adult', 'Youth')
and d.date_value>= '20140521'
group by f.key_date
union
select f.key_date as the_date,0 as citypass_none, 0 as citypass_adult_youth, 0 as citypass_scanchange, sum(amount) as citypass_booklets, 
0 as c3_revenue, 0 as c3_scanchange, 0 as nyp_add_rev,0 as other_pass_rev
from fact_museum_citypass_booklets f, dim_galaxy_items g, dim_date d
where f.key_date=d.date_key
and f.key_museum_category =g.key_category
and g.plu in ('MUSGADADCP005', 'MUSGADYSCP005')
and d.date_value >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date,0 as citypass_none, 0 as citypass_adult_youth, 0 as citypass_scanchange, 0 as citypass_booklets,
sum(quantity*amount) as c3_revenue, 0 as c3_scanchange,0 as nyp_add_rev, 0 as other_pass_rev
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and d.date_value  >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date, 0 as citypass_none, 0 as citypass_adult_youth, 0 as citypass_scanchange, 0 as citypass_booklets,
0 as c3_revenue, sum(quantity*amount) as c3_scanchange,0 as nyp_add_rev, 0 as other_pass_rev
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and f.key_coupon_category in ('C3 Adult', 'C3 Youth')
and d.date_value >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date, 0 as citypass_none, 0 as citypass_adult_youth, 0 as citypass_scanchange, 0 as citypass_booklets,
0 as c3_revenue, 0 as c3_scanchange, 0 as other_pass_rev,sum(amount) as nyp_add_rev
from fact_museum_nyp_add f, dim_date d
where f.key_date = d.date_key
and d.date_value  >= '20140521'
group by f.key_date
UNION
select f.key_date as the_date, 0 as citypass_none, 0 as citypass_adult_youth, 0 as citypass_scanchange, 0 as citypass_booklets,
0 as c3_revenue, 0 as c3_scanchange, 0 as nyp_add_rev, sum(f.amount) as other_pass_rev
from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.customer_id in ('20056','17522','23110','22361')
and f.ga_flag=1
and d.date_value  >= '20140521'
group by f.key_date) as A
where the_date <?
group by the_date