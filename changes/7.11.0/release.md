# 7.11.0: Hygiene & Docs Sweep

- **Date:** 2026-07-31
- **Version:** 7.11.0

Closes the remaining medium/low findings from the post-build review.

## Fixed

- **Narrative task prompts re-synced with their dbt source models.** The deployed-task
  copies in `scripts/setup_dpr_narrative.sql` / `setup_retail_narrative.sql` had drifted
  from `rpt_dpr_narrative.sql` / `rpt_retail_narrative.sql`: missing the YoY
  contextualization rule, missing "significant YoY divergence" in the watch-items rule,
  and framing "the day's" instead of "the previous day's" performance. Prompts are now
  verbatim-identical; both rpt_ models carry a SYNC GUARD note (there is no automated
  drift check for this pair yet — candidate for a future generator).
- **PII coverage extended to the Gateway staging name columns**:
  `STG_GATEWAY__TICKETS` and `STG_GATEWAY__JNLTICKETS` `first_name`/`last_name` added to
  `apply_masking_policies` and `apply_governance_tags` (they feed the already-masked
  `dim_customer.customer_name`, but staging-schema readers saw them unmasked); both
  models and `stg_ecommerce__website_recurring` now carry the `pii`/`restricted` config
  tags their WiFi sibling had.
- **`rpt_dpr_budget_daily.report_date` unique test** demoted error → warn: the dpr CTE
  passes `fct_budget_dpr_forecasts` rows through un-aggregated, so the grain is
  partially inherited (severity rule).
- **`rpt_daily_scan` header** no longer claims the DSR forecast seed is unpopulated
  (fct_daily_scan joins the real budget; variance is NULL only where the forecast has
  no row).
- **`fct_daily_operations.ticket_revenue`** now documents in-model that it is the
  POS-derived measure and NOT `fct_daily_performance.ticket_revenue` (GA journal) —
  the shared name is historical; renaming was deliberately skipped (two tests and the
  ML training set bind to it) and can be revisited with the ML model retrain.
- `rpt_wifi_email_export` schema docs now list all four columns incl. `capture_date`.
- Committed `__pycache__/` artifacts removed from both dpr-dashboard copies (already
  gitignored; if still tracked in your clone: `git rm -r --cached dpr-dashboard/__pycache__ dpr-dashboard/deployed/__pycache__`).

## Deferred (documented, deliberately unchanged)

- `TOTAL_RETAIL_GROSS_PROFIT` component realignment/rename — ADR-005 committee item
  (see 7.8.0).
- The Streamlit dashboard re-derives donation/audio composites in Python (a third
  authored surface); migrating it to read `rpt_dpr_powerbi` is a candidate follow-up.
- Generic-test macro library adoption; function-pipeline packaging; ADR 007–017
  register reconciliation — unchanged standing items.

---
