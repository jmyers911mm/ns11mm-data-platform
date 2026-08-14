-- TRANSFORMATION: t_fact_kpi_percaps_daily
-- DESC: 

-- WRITES: 911DW:.fact_kpi_percaps (InsertUpdate)


-- ===== STEP: Items [TableInput] conn=911DW =====
SELECT  
	 key_date																		AS key_date	        
    ,'Museum Audio Guides'															AS per_caps
	,1.0*dpr_audio_tour_headset/NULLIF(dpr_mus_attendance,0) 						AS day
	,1.0*dpr_audio_tour_headset_mtd/NULLIF(dpr_mus_attendance_mtd,0) 				AS mtd
	,1.0*dpr_audio_tour_headset_last_month/NULLIF(dpr_mus_attendance_last_month,0)  AS prev_month
	,1 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION 
	SELECT 
	 key_date																		AS key_date	         
    ,'Avg. Ticket Revenue/Attendance'												AS per_caps
	,1.0*(dpr_ticket_revenue+dpr_pass_revenue)/NULLIF(dpr_mus_attendance,0) 						AS day
	,1.0*(dpr_ticket_revenue_mtd+dpr_pass_revenue_mtd)/NULLIF(dpr_mus_attendance_mtd,0) 				AS mtd
	,1.0*(dpr_ticket_revenue_last_month+dpr_pass_revenue_last_month)/NULLIF(dpr_mus_attendance_last_month,0)  AS prev_month
    ,2 AS 'order_by'
    FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																		AS key_date	               
    ,'Museum Donations'																AS per_caps
	,1.0*total_museum_donation/NULLIF(dpr_mus_attendance,0) 						AS day
	,1.0*total_museum_donation_mtd/NULLIF(dpr_mus_attendance_mtd,0) 				AS mtd
	,1.0*total_museum_donation_last_month/NULLIF(dpr_mus_attendance_last_month,0)   AS prev_month
	,3 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																		AS key_date	      	        
    ,'Memorial Donations'															AS per_caps
	,1.0*total_mem_donation/NULLIF(dpr_mem_attendance,0) 							AS day
	,1.0*total_mem_donation_mtd/NULLIF(dpr_mem_attendance_mtd,0) 					AS mtd
	,1.0*total_mem_donation_last_month/NULLIF(dpr_mem_attendance_last_month,0)  	AS prev_month 
	,4 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																		AS key_date	     	        
    ,'Museum Retail'																AS per_caps
	,1.0*(dpr_mus_store_gross_profit+dpr_ecom_gross_profit)/NULLIF(dpr_mus_attendance,0) 						AS day
	,1.0*(dpr_mus_store_gross_profit_mtd+dpr_ecom_gross_profit_mtd)/NULLIF(dpr_mus_attendance_mtd,0) 				AS mtd
	,1.0*(dpr_mus_store_gross_profit_last_month+dpr_ecom_gross_profit_last_month)/NULLIF(dpr_mus_attendance_last_month,0)  AS prev_month 
	,5 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																		AS key_date	     	 	        
    ,'Memorial Retail'																AS per_caps
	,1.0*dpr_retail_carts_gross_profit/NULLIF(dpr_mem_attendance,0)  						AS day
	,1.0*dpr_retail_carts_gross_profit_mtd/NULLIF(dpr_mem_attendance_mtd,0) 				AS mtd
	,1.0*dpr_retail_carts_gross_profit_last_month/NULLIF(dpr_mem_attendance_last_month,0)  AS prev_month   
	,6 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																		AS key_date	     	 	        
    ,'Cafe'																			AS per_caps
	,1.0*ra_cafe1_profit_all/NULLIF(dpr_mus_attendance,0)  						AS day
	,1.0*ra_cafe_profit_mtd/NULLIF(dpr_mus_attendance_mtd,0) 				AS mtd
	,1.0*ra_cafe_profit_last_month/NULLIF(dpr_mus_attendance_last_month,0)  AS prev_month   
	,7 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																		AS key_date	     	 	        
    ,'Tours'																		AS per_caps
	,1.0*total_tour_revenue/NULLIF(dpr_mus_attendance,0)  						AS day
	,1.0*total_tour_revenue_mtd/NULLIF(dpr_mus_attendance_mtd,0)				AS mtd 
	,1.0*total_tour_revenue_last_month/NULLIF(dpr_mus_attendance_last_month,0)  AS prev_month   
	,8 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
    UNION
	SELECT 
	 key_date																			AS key_date	 	        
    ,'Aggregate Museum'																	AS per_caps
	, sum(
			(1.0*dpr_audio_tour_headset/NULLIF(dpr_mus_attendance,0))+
            (1.0*avg_ticket_price/NULLIF(dpr_mus_attendance,0))+
            (1.0*total_museum_donation/NULLIF(dpr_mus_attendance,0))+
            (1.0*dpr_mus_store_gross_profit/NULLIF(dpr_mus_attendance,0))+
            (1.0*ra_cafe1_profit_all /NULLIF(dpr_mus_attendance,0))+
            (1.0*total_tour_revenue/NULLIF(dpr_mus_attendance,0))+1.0*(dpr_ticket_revenue+dpr_pass_revenue)/NULLIF(dpr_mus_attendance,0) 
		  )  AS day
	, sum(
			(1.0*dpr_audio_tour_headset_mtd/NULLIF(dpr_mus_attendance_mtd,0))+
            (1.0*avg_ticket_price_mtd/NULLIF(dpr_mus_attendance_mtd,0))+
            (1.0*total_museum_donation_mtd/NULLIF(dpr_mus_attendance_mtd,0))+
            (1.0*dpr_mus_store_gross_profit_mtd/NULLIF(dpr_mus_attendance_mtd,0))+
            (1.0*ra_cafe_profit_mtd/NULLIF(dpr_mus_attendance_mtd,0))+
            (1.0*total_tour_revenue_mtd/NULLIF(dpr_mus_attendance_mtd,0))+1.0*(dpr_ticket_revenue_mtd+dpr_pass_revenue_mtd)/NULLIF(dpr_mus_attendance_mtd,0) 
		 )	AS mtd 
	, sum(
			(1.0*dpr_audio_tour_headset_last_month/NULLIF(dpr_mus_attendance_last_month,0))+
            (1.0*avg_ticket_price_last_month/NULLIF(dpr_mus_attendance_last_month,0))+
            (1.0*total_museum_donation_last_month/NULLIF(dpr_mus_attendance_last_month,0))+
            (1.0*dpr_mus_store_gross_profit_last_month/NULLIF(dpr_mus_attendance_last_month,0))+
            (1.0*ra_cafe_profit_last_month/NULLIF(dpr_mus_attendance_last_month,0))+
            (1.0*total_tour_revenue_last_month/NULLIF(dpr_mus_attendance_last_month,0))+1.0*(dpr_ticket_revenue_last_month+dpr_pass_revenue_last_month)/NULLIF(dpr_mus_attendance_last_month,0) 
		  )	AS prev_month 
	,10 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 key_date																			AS key_date	 	        
    ,'Aggregate Memorial'																AS per_caps
	, sum(
			(1.0*total_mem_donation/NULLIF(dpr_mem_attendance,0))+
            (1.0*dpr_retail_carts_gross_profit/NULLIF(dpr_mem_attendance,0))
		  )  AS day
	, sum(
			(1.0*total_mem_donation_mtd/NULLIF(dpr_mem_attendance_mtd,0))+
            (1.0*dpr_retail_carts_gross_profit_mtd/NULLIF(dpr_mem_attendance_mtd,0))
		 )	AS mtd 
	, sum(
			(1.0*total_mem_donation_last_month/NULLIF(dpr_mem_attendance_last_month,0))+
            (1.0*dpr_retail_carts_gross_profit_last_month/NULLIF(dpr_mem_attendance_last_month,0))
		  )	AS prev_month 
	,11 AS 'order_by'
	FROM vw_kpi_daily_data
	WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
	UNION
	SELECT 
	 DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')		AS key_date	      	        
    ,' '		AS per_caps
    ,''	 	AS day
    ,''	 	AS mtd
    ,''	  	AS prev_month 
	,9		AS 'order_by'