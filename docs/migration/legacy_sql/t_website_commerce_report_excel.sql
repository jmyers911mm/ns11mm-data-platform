-- TRANSFORMATION: t_website_commerce_report_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report tmpl=template.xls
-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report tmpl=template.xls
-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report tmpl=template.xls
-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report tmpl=template.xls


-- ===== STEP: ti: Website Commerce Report - By month [TableInput] conn=911DW =====
SELECT 
    Month,
    SUM(don_2020) AS 'Donation Revenue - 2020',
    SUM(mem_2020) AS 'Membership Revenue - 2020',
    SUM(don_2021) AS 'Donation Revenue - 2021',
    SUM(mem_2021) AS 'Membership Revenue - 2021',
    SUM(don_2022) AS 'Donation Revenue - 2022',
    SUM(mem_2022) AS 'Membership Revenue - 2022',
	SUM(don_2023) AS 'Donation Revenue - 2023',
    SUM(mem_2023) AS 'Membership Revenue - 2023',
	SUM(don_2024) AS 'Donation Revenue - 2024',
    SUM(mem_2024) AS 'Membership Revenue - 2024',
    SUM(don_2025) AS 'Donation Revenue - 2025',
    SUM(mem_2025) AS 'Membership Revenue - 2025'
FROM
(SELECT 
            MONTHNAME(date_created) AS Month,
            MONTH(date_created) AS month_number,
            SUM(CASE
                WHEN
                    sku LIKE '%donat%'
                        AND YEAR(date_created) = 2020
                THEN
                    revenue
                ELSE 0
            END) AS don_2020,
            SUM(CASE
                WHEN
                    sku LIKE '%membership%'
                        AND YEAR(date_created) = 2020
                THEN
                    revenue
                ELSE 0
            END) AS mem_2020,
            0 AS don_2021,
            0 AS mem_2021,
            0 AS don_2022,
            0 AS mem_2022,
            0 AS don_2023,
            0 AS mem_2023,
            0 AS don_2024,
            0 AS mem_2024,
            0 AS don_2025,
            0 AS mem_2025
    FROM
        fact_website_data_d8
    WHERE
        YEAR(date_created) >= '2020'
            AND MONTH(date_created) <= MONTH(?)
            AND date_created <= CONCAT('2020', DATE_FORMAT(?, '%m'), DATE_FORMAT(?, '%d'))
    GROUP BY MONTH(date_created) 
    UNION 
    SELECT 
			MONTHNAME(date_created) AS Month,
            MONTH(date_created) AS month_number,
            0 AS don_2020,
            0 AS mem_2020,
            SUM(CASE
                WHEN
                    sku LIKE '%donat%'
                        AND YEAR(date_created) = 2021
                THEN
                    revenue
                ELSE 0
            END) AS don_2021,
            SUM(CASE
                WHEN
                    sku LIKE '%membership%'
                        AND YEAR(date_created) = 2021
                THEN
                    revenue
                ELSE 0
            END) AS mem_2021,
            0 AS don_2022,
            0 AS mem_2022,
            0 AS don_2023,
            0 AS mem_2023,
            0 AS don_2024,
            0 AS mem_2024,
            0 AS don_2025,
            0 AS mem_2025
    FROM
        fact_website_data_d8
    WHERE
        YEAR(date_created) >= '2021'
            AND MONTH(date_created) <= MONTH(?)
            AND date_created <= CONCAT('2021', DATE_FORMAT(?, '%m'), DATE_FORMAT(?, '%d'))
    GROUP BY MONTH(date_created) 
    UNION 
    SELECT 
			MONTHNAME(date_created) AS Month,
            MONTH(date_created) AS month_number,
            0 AS don_2020,
            0 AS mem_2020,
            0 AS don_2021,
            0 AS mem_2021,
            SUM(CASE
                WHEN
                    sku LIKE '%donat%'
                        AND YEAR(date_created) = 2022
                THEN
                    revenue
                ELSE 0
            END) AS don_2022,
            SUM(CASE
                WHEN
                    sku LIKE '%membership%'
                        AND YEAR(date_created) = 2022
                THEN
                    revenue
                ELSE 0
            END) AS mem_2022,
            0 AS don_2023,
            0 AS mem_2023,
            0 AS don_2024,
            0 AS mem_2024,
            0 AS don_2025,
            0 AS mem_2025
    FROM
        fact_website_data_d8
    WHERE
        YEAR(date_created) = '2022'
        AND date_created <= CONCAT('2022', DATE_FORMAT(?, '%m'), DATE_FORMAT(?, '%d'))
    GROUP BY month_number
	UNION -- 2023
    SELECT 
			MONTHNAME(date_created) AS Month,
            MONTH(date_created) AS month_number,
            0 AS don_2020,
            0 AS mem_2020,
            0 AS don_2021,
            0 AS mem_2021,
			0 AS don_2022,
            0 AS mem_2022,
            SUM(CASE
                WHEN
                    sku LIKE '%donat%'
                        AND YEAR(date_created) = 2023
                THEN
                    revenue
                ELSE 0
            END) AS don_2023,
            SUM(CASE
                WHEN
                    sku LIKE '%membership%'
                        AND YEAR(date_created) = 2023
                THEN
                    revenue
                ELSE 0
            END) AS mem_2023,
            0 AS don_2024,
            0 AS mem_2024,
            0 AS don_2025,
            0 AS mem_2025
    FROM
        fact_website_data_d8
    WHERE
        YEAR(date_created) = '2023'
        AND date_created <= CONCAT('2023', DATE_FORMAT(?, '%m'), DATE_FORMAT(?, '%d'))
    GROUP BY month_number
UNION -- 2024
    SELECT 
			MONTHNAME(date_created) AS Month,
            MONTH(date_created) AS month_number,
            0 AS don_2020,
            0 AS mem_2020,
            0 AS don_2021,
            0 AS mem_2021,
			0 AS don_2022,
            0 AS mem_2022,
            0 AS don_2023,
            0 AS mem_2023,
            SUM(CASE
                WHEN
                    sku LIKE '%donat%'
                        AND YEAR(date_created) = 2024
                THEN
                    revenue
                ELSE 0
            END) AS don_2024,
            SUM(CASE
                WHEN
                    sku LIKE '%membership%'
                        AND YEAR(date_created) = 2024
                THEN
                    revenue
                ELSE 0
            END) AS mem_2024,
            0 AS don_2025,
            0 AS mem_2025
    FROM
        fact_website_data_d8
    WHERE
        YEAR(date_created) = '2024'
        AND date_created <= CONCAT('2024', DATE_FORMAT(?, '%m'), DATE_FORMAT(?, '%d'))
    GROUP BY month_number
    UNION -- 2024
    SELECT 
			MONTHNAME(date_created) AS Month,
            MONTH(date_created) AS month_number,
            0 AS don_2020,
            0 AS mem_2020,
            0 AS don_2021,
            0 AS mem_2021,
			0 AS don_2022,
            0 AS mem_2022,
            0 AS don_2023,
            0 AS mem_2023,
            0 AS don_2024,
            0 AS mem_2024,
            SUM(CASE
                WHEN
                    sku LIKE '%donat%'
                        AND YEAR(date_created) = 2025
                THEN
                    revenue
                ELSE 0
            END) AS don_2025,
            SUM(CASE
                WHEN
                    sku LIKE '%membership%'
                        AND YEAR(date_created) = 2025
                THEN
                    revenue
                ELSE 0
            END) AS mem_2025
    FROM
        fact_website_data_d8
    WHERE
        YEAR(date_created) = '2025'
		AND MONTH(date_created) <= MONTH(?)
    GROUP BY month_number
) AS A
GROUP BY month_number

-- ===== STEP: ti: Website Commerce Report - By Date [TableInput] conn=911DW =====
select DATE_FORMAT(date_key,'%Y-%m-%d') as Date, 
case when null then 0 else (sum(case when sku like '%donat%' then revenue else 0 end)) end as 'Donation Revenue',
case when null then 0 else (sum(case when sku like '%membership%' then revenue else 0 end)) end as 'Membership Revenue'
from fact_website_data_d8 f right join dim_date d
on f.date_created = d.date_key
where year(d.date_key) = year(?)
and month(d.date_key) = month(?)
and d.date_key <= ?
group by d.date_key

-- ===== STEP: ti: Website Commerce Report - Donation By Date [TableInput] conn=911DW =====
select DATE_FORMAT(date_created,'%Y-%m-%d') as Date,
title,
sum(quantity),
sum(revenue)
from fact_website_data_d8
where sku like '%donat%' 
and date_created = ?
group by order_id

-- ===== STEP: ti: Website Commerce Report - Recurring by month [TableInput] conn=911DW =====
select Month, 
sum(don_2019) as 'Donation Revenue - 2019',
sum(mem_2019) as 'Membership Revenue - 2019', 
sum(don_2020) as 'Donation Revenue - 2020',
sum(mem_2020) as 'Membership Revenue - 2020'
from
(select 
monthname(date_completed) as Month, month(date_completed) as month_number,
sum(case when sku like '%donat%' and year(date_completed)=2019 then revenue else 0 end) as don_2019,
sum( case when sku like '%renewal-%' and year(date_completed)=2019 then revenue else 0 end) as mem_2019,
0 as don_2020,
0 as mem_2020 
 from fact_website_recurring_data_d8
where year(date_completed) >=year(?)-1
and month(date_completed) <= month(?)
and date_completed <= CONCAT(year(?)-1,DATE_FORMAT(?,'%m'),DATE_FORMAT(?,'%d'))
group by month(date_completed)
UNION
select monthname(date_completed) as Month, month(date_completed) as month_number,
0 as don_2019,
0 as mem_2019, 
sum(case when sku like '%donat%' and year(date_completed)=2020 then revenue else 0 end) as don_2020,
sum( case when sku like '%renewal-%' and year(date_completed)=2020 then revenue else 0 end) as  mem_2020
from fact_website_recurring_data_d8
where year(date_completed) = year(?)
and month(date_completed) <= month(?)
group by month_number) as A
group by month_number