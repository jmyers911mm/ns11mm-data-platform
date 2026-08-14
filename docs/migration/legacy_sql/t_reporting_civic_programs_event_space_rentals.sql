-- TRANSFORMATION: t_reporting_civic_programs_event_space_rentals
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Civic Programs & Event Space Rentals [TableInput] conn=911DW =====
select key_date, sum(civic_programs) as civic_programs, sum(space_rentals) as event_space_rentals
from fact_additional_revenue f inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20180101'
group by key_date