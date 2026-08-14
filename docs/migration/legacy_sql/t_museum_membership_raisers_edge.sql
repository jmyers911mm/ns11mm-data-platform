-- TRANSFORMATION: t_museum_membership_raisers_edge
-- DESC: 

-- WRITES: 911DW:.fact_membership_re (InsertUpdate)
-- WRITES: 911DW:.fact_membership_re (InsertUpdate)
-- WRITES: 911DW:.fact_museum_membership_re (TableOutput)


-- ===== STEP: Raisers Edge - DMP Museum Membership [TableInput] conn=RaisersEdge =====
select 
distinct m.ID as 'Membership ID', 
        convert(varchar(12),m.Date_Joined,112) as key_date,
		convert(varchar(12),mt.ActivityDate,112) as transaction_date,
		convert(varchar(12),g.DTE,112) as gift_date,
		g.CONSTIT_ID,
        r.FIRST_NAME + ' ' + r.LAST_NAME as 'Primary Member Name', 
        mc.MembershipCategoryID, 
        mt.Dues as 'Dues\Amount',  
        m.Added_By, 
        u.NAME,
        te.LONGDESCRIPTION as 'Gift Code' 
from MEMBER m 
left join RECORDS r on r.ID = m.ConstitID 
left join MembershipTransaction mt on m.ID = mt.MembershipID
left join TransactionGift tg on mt.ID = tg.TransactionID
left join GIFT g on tg.GiftID = g.ID 
left join TABLEENTRIES te on te.TABLEENTRIESID = g.GIFT_CODE  
inner join MembershipCategory mc on mc.MembershipCategoryID = mt.Category 
inner join USERS u on u.USER_ID = m.ADDED_BY 
where 
te.LONGDESCRIPTION like '%DMP - Membership%'
--and m.Added_By in ('24','49')
order by m.ID, gift_date,key_date

-- ===== STEP: Raisers Edge - In House membership [TableInput] conn=RaisersEdge =====
select

distinct m.ID as 'Membership ID',

        convert(varchar(12),m.Date_Joined,112) as key_date,

            convert(varchar(12),mt.ActivityDate,112) as transaction_date,

            convert(varchar(12),g.DTE,112) as gift_date,

            g.CONSTIT_ID,

        r.FIRST_NAME + ' ' + r.LAST_NAME as 'Primary Member Name',

        mc.MembershipCategoryID,

        mt.Dues as 'Dues\Amount', 

        m.Added_By,

        u.NAME,

        te.LONGDESCRIPTION as 'Gift Code'

from MEMBER m

left join RECORDS r on r.ID = m.ConstitID

left join MembershipTransaction mt on m.ID = mt.MembershipID

left join TransactionGift tg on mt.ID = tg.TransactionID

left join GIFT g on tg.GiftID = g.ID

left join TABLEENTRIES te on te.TABLEENTRIESID = g.GIFT_CODE 

inner join MembershipCategory mc on mc.MembershipCategoryID = mt.Category

inner join USERS u on u.USER_ID = m.ADDED_BY

where

te.LONGDESCRIPTION like '%In house charge - membership%'

--and m.Added_By in ('24','49')

order by m.ID,key_date, gift_date

-- ===== STEP: Raisers Edge - Office Mail membership [TableInput] conn=RaisersEdge =====
select

distinct m.ID as 'Membership ID',

        convert(varchar(12),m.Date_Joined,112) as key_date,

            convert(varchar(12),mt.ActivityDate,112) as transaction_date,

            convert(varchar(12),g.DTE,112) as gift_date,

            g.CONSTIT_ID,

        r.FIRST_NAME + ' ' + r.LAST_NAME as 'Primary Member Name',

        mc.MembershipCategoryID,

        mt.Dues as 'Dues\Amount', 

        m.Added_By,

        u.NAME,

        te.LONGDESCRIPTION as 'Gift Code'

from MEMBER m

left join RECORDS r on r.ID = m.ConstitID

left join MembershipTransaction mt on m.ID = mt.MembershipID

left join TransactionGift tg on mt.ID = tg.TransactionID

left join GIFT g on tg.GiftID = g.ID

left join TABLEENTRIES te on te.TABLEENTRIESID = g.GIFT_CODE 

inner join MembershipCategory mc on mc.MembershipCategoryID = mt.Category

inner join USERS u on u.USER_ID = m.ADDED_BY

where

te.LONGDESCRIPTION like '%Office Mail - Membership%'

--and m.Added_By in ('24','49')

order by m.ID,key_date, gift_date