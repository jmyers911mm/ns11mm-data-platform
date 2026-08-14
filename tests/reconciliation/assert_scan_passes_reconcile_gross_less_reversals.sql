-- Test (reconciliation): fct_daily_scan passes = gross entries minus reversals
-- Severity: error — passes_scanned is the certified attendance measure and is
-- carried alongside its two components so the redefinition stays auditable. If
-- this identity breaks, the sign logic in int_ticket_scans and the aggregation
-- in fct_daily_scan have drifted apart and the published attendance is wrong.

select
    date_key,
    segment_key,
    passes_scanned,
    gross_passes_scanned,
    reversed_passes_scanned
from {{ ref('fct_daily_scan') }}
where abs(
        coalesce(passes_scanned, 0)
        - (coalesce(gross_passes_scanned, 0) - coalesce(reversed_passes_scanned, 0))
      ) > 0.0001
