-- Test (business_rule): every unissued line has a positive unissued quantity
-- Severity: error — the whole model exists to capture orderlines.issued_quantity <
-- orderlines.quantity. A zero or negative qty_unissued means the filter drifted
-- and issued revenue is about to be double counted (it is already in the ticket
-- journal). A null amt_unissued means the DisbursementDetails.Basis CASE fell
-- through, which would silently drop revenue.

select
    cohort,
    leg,
    date_key,
    order_line_id,
    plu,
    matrix_code,
    qty_unissued,
    amt_unissued
from {{ ref('int_gateway__unissued_order_lines') }}
where qty_unissued <= 0
   or amt_unissued is null
