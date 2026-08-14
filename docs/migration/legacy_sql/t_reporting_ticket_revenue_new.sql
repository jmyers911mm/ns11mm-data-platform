-- TRANSFORMATION: t_reporting_ticket_revenue_new
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Bulk Ticket Scans Revenue [TableInput] conn=911DW =====
select key_date, sum(amount) as revenue
from fact_museum_bulk_tickets_test f inner join dim_date d on f.key_date =  d.date_key 
where d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Bulk Tickets Additional Revenue [TableInput] conn=911DW =====
select cast(key_date as char(12)) as key_date, sum(amount) as revenue
from fact_additional_revenue_new f inner join dim_date d on f.key_date =  d.date_key 
inner join dim_galaxy_items g on f.key_museum_category = g.key_category
where d.date_value >= '20140521'
and g.plu = 'RESLADDREV001'
group by key_date

-- ===== STEP: ti: Issued Ticket Revenue [TableInput] conn=911DW =====
select key_date, sum(f.amount) as revenue
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on  f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
 (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.customer_id not in ('20056','17522','23110','22361','29619')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Memorial Tour Museum Admission Issued Revenue [TableInput] conn=911DW =====
select key_date, sum(f.amount) as revenue
from fact_museum_tickets_issued_fordate_new f inner join  dim_date d on f.key_date =d.date_key 
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Unissued Ticket Revenue [TableInput] conn=911DW =====
select key_date, sum(f.amount) as revenue
from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on  f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
 (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date