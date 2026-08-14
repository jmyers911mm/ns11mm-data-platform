-- Test (business_rule): a buyout PLU is never counted at line grain AND added back
-- Severity: error — the legacy pattern is "exclude the buyout categories from the
-- tour line grain, then add fact_museum_guided_tour_buyout back". If a PLU is in
-- seed_tour_buyout_plu and ALSO in seed_tour_plu, the exclusion and the add-back
-- both fire on a cohort that expects only one of them, and the revenue is counted
-- twice on whichever line seed_tour_plu points at.

select
    b.plu,
    b.buyout_line_item,
    t.dpr_line_item                     as also_labelled_in_seed_tour_plu
from {{ ref('seed_tour_buyout_plu') }} b
inner join {{ ref('seed_tour_plu') }} t on b.plu = t.plu
