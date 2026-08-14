-- TRANSFORMATION: t_dpr_write_to_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/DPR Excel Data tmpl=template.xls


-- ===== STEP: ti:Get data from table [TableInput] conn=911DW =====
SELECT
  date_format(key_date, '%m/%d/%Y') as key_date
, mem_attendance
, mem_attendance_budget
, mus_attendance
, mus_attendance_budget
, tickets_sold
, tickets_sold_budget
, ticket_revenue
, ticket_revenue_budget
, mus_store_rev
, mus_store_rev_budget
, mem_cart_rev
, mem_cart_rev_budget
, ecom_rev
, ecom_rev_budget
, mus_guided_tour_revenue
, mem_virtual_tour_rev
, mus_virtual_tour_rev
, mem_field_trip_revenue
, mus_field_trip_revenue
, mus_don
, mem_don
, ask_educator_revenue
, revealed_tour_revenue
, mus_audio_tour_revenue
, mus_audio_tour_budget
, cafe1_profit
, (ifnull(sum(ticket_revenue),0)+ ifnull(sum(mus_guided_tour_revenue),0) + ifnull(sum(mus_store_rev),0) +ifnull(sum(mus_virtual_tour_rev),0) + ifnull(sum(mus_field_trip_revenue),0)+ ifnull(sum(ask_educator_revenue),0)+ ifnull(sum(mus_don),0)+ ifnull(sum(revealed_tour_revenue),0) + ifnull(sum(mus_audio_tour_revenue),0) + ifnull(sum(cafe1_profit),0)) as total_mus_rev
, (ifnull(sum(mem_cart_rev),0)+ ifnull(sum(mem_virtual_tour_rev),0) + ifnull(sum(mem_field_trip_revenue),0) + ifnull(sum(ecom_rev),0)+ ifnull(sum(mem_don),0)) as total_mem_rev
FROM fact_dpr_excel_data
WHERE key_date > '20221231' AND key_date < ?
GROUP BY key_date