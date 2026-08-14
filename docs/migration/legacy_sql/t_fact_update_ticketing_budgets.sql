-- TRANSFORMATION: t_fact_update_ticketing_budgets
-- DESC: 

-- WRITES: 911DW:.fact_all_budgets (InsertUpdate)


-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
SELECT
  key_date
, tickets_sold_for_date
, ticket_revenue
, pass_revenue
, donations_ticketing
, audio_guide_rentals
, audio_guide_capture_rate
, headphone_rental
, headphone_capture_rate
, audio_guide_revenue
, headphone_revenue
, audio_tour_headsets
, coatcheck_donations
, museum_exit_donations
, ecom_orders
, profit_from_ecom
, cafe_transactions
, licensing_fees
, total_sales_ecom
, avg_sale_ecom
, early_access_tours
, early_access_tour_rev
, youth_fam_tours
, youth_fam_tour_rev
FROM fact_dpr_forecasts