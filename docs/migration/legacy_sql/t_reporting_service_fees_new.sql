-- TRANSFORMATION: t_reporting_service_fees_new
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Memorial Service Fees [TableInput] conn=911DW =====
select key_date, sum(amount) as service_fees
from fact_service_fees_new f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join dim_date d on f.key_date = d.date_key
where  (g.account_idno like '%MEF%' and g.account_idno like '%FEE%')
group by key_date

-- ===== STEP: ti: Museum Service Fees [TableInput] conn=911DW =====
select key_date, sum(amount) as service_fees
from fact_service_fees_new f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join  dim_date d on f.key_date = d.date_key
where  
(g.account_idno like '%MUF%' and g.account_idno like '%FEE%')
and d.date_value >='20140521'
group by key_date