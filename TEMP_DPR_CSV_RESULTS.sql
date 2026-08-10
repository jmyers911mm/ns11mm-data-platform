-- DPR MTD
select
    as_of_date                as reporting_date,
    section,
    line_item,
    actual,
    prior_year,
    variance_amount,
    variance_pct,
    availability
from marts.rpt_dpr_mtd_ytd_print
where period_group = 'MTD'
order by print_order;

-- DPR YTD
select
    as_of_date                as reporting_date,
    section,
    line_item,
    actual,
    prior_year,
    variance_amount,
    variance_pct,
    availability
from marts.rpt_dpr_mtd_ytd_print
where period_group = 'YTD'
order by print_order;

-- DPR Excel Data
select * from marts.rpt_dpr_excel_export order by "Date";