-- TRANSFORMATION: t_dim_category_museum_membership_re
-- DESC: 

-- WRITES: 911DW:.dim_category_membership_re (InsertUpdate)


-- ===== STEP: Category Description - Museum Membership [TableInput] conn=RaisersEdge =====
select  distinct mt.Category, te.LONGDESCRIPTION as 'Category Name' from MembershipTransaction mt
inner join MembershipCategory mc on mc.MembershipCategoryID = mt.Category 
inner join TABLEENTRIES te on te.TABLEENTRIESID = mc.CategoryID