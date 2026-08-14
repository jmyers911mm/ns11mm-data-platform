-- TRANSFORMATION: t_run_donations_ticketing
-- DESC: 

-- WRITES: 911DW:.fact_all_donations (InsertUpdate)


-- ===== STEP: ti: Issued Ticketing Donations(includes FAT, Box office donations) [TableInput] conn=911DW =====
select key_date, sum(amount) as donations
from fact_museum_ticketing_donations_issued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909,3220,3221)
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Unissued Ticketing Donations [TableInput] conn=911DW =====
select key_date, sum(amount) as donations
from fact_museum_ticketing_donations_unissued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20140521'
group by key_date