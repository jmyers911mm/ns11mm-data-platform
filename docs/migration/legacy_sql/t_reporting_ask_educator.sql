-- TRANSFORMATION: t_reporting_ask_educator
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Ask an Educator [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as ask_educator , sum(f.amount) as ask_educator_revenue
from fact_memorial_tours_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%VTS%')
and f.ga_flag=0
and g.plu = 'VTEDUMUSGTOADR010'
and d.date_value >= '20210301'
group by f.key_date