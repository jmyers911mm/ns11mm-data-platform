# 8.7.0: Scan Validity & Attendance

- **Date:** 2026-08-12
- **Version:** 8.7.0

**ADR-005 gated. This release must not ship before sign-off from Chris Wogas**, the metric
owner, per `DECISION_MEMO.md`. Four measures printed by the Daily Performance Report, the
Attendance Report, the Daily Attendance Report and the Daily Scan Report were computed from
rules the legacy 911dw estate does not use. Museum attendance in particular was a **ticket
count, not a gate count** — and because it is the denominator of every per-capita ratio on the
DPR and the Tracker, the error propagates well beyond the attendance line. Every decision here
is reversible by editing a seed, not a model. Cumulative on 8.4.0 and 8.6.0; four files are
delivered rebased onto the latest prior version so the stack applies in order.

## Added

- **`int_dpr__attendance`** — museum and memorial attendance authored once, with seed-driven
  facility classification and the closed-day zeroing rule.
- **`seed_gateway_facility_map`** (Gateway `Facility.FacilityID` → `key_facility`: 7 → 1006,
  12 → 5000, plus the facility-13 exclusion), **`seed_attendance_facility_group`** (museum /
  memorial / none / unmapped, with the disputed `1000` row carried but not counted), and
  **`seed_attendance_zeroing_rule`** (the closed-Tuesday rule and the 2022-06-15 exception,
  sharing a 300-pass threshold). Property file `_seeds_attendance.yml` is a sidecar so
  `seeds/_seeds.yml` is untouched.
- **`gross_passes_scanned` / `reversed_passes_scanned`** on `fct_daily_scan`,
  **`reversing_scans`** on `fct_daily_operations`, and the matching facts and metrics in
  `ATTENDANCE.sv.yaml` with `PASSES_SCANNED` redefined as the net measure.
- **Three tests**: `assert_scan_validity_rule`, `assert_museum_closed_day_zeroing`,
  `assert_scan_passes_reconcile_gross_less_reversals`.
- **`dbt_project.yml` version 8.6.0 → 8.7.0.**

## Changed

- **`int_ticket_scans` — the legacy validity rule, exactly.** Legacy counts only
  `Status = 0 and Code = 0` positively, **subtracts** `Code = 11`, drops every other usage
  code entirely, and excludes Gateway facility 13 from both legs. The platform was
  `status_code in ('0','1')`: no code predicate, no reversal leg, no facility exclusion, and
  status 1 wrongly admitted. Implemented as a signed `scan_sign` (+1 / −1 / 0) and a
  `net_visitor_count`; every attendance measure now sums that one column. No staging change
  was required — `stg_gateway__usage` already exposes both `code` and `status_code`, so
  ADR-001 is untouched.
- **`int_ticket_scans` — the full ACP hop.** Legacy resolves
  `Usage.ACP → ACPs.AcpId → ACPs.FacilityID → Facility.IDNo` and then reads the map off
  `Facility.FacilityID` — two different columns. The platform used
  `stg_gateway__usage.facility_id` directly, skipping the hop. Both hops are deduplicated so
  the scan grain cannot fan out.
- **`dim_gate`** — join corrected to `acps.facility_id = facility.id_no`. It was joining
  `ACPs.FacilityID` to `Facility.FacilityID`, which is the wrong pair. It now carries the
  resolved `key_facility`.
- **`int_gateway__scan_lines`**, **`fct_daily_scan`**, **`fct_daily_operations`**
  (`total_visitors` is now net; `gates_active` counts counted scans),
  **`fct_daily_performance`** (`mus_attendance` from `int_dpr__attendance`; `mem_attendance`
  no longer coalesced to 0), **`rpt_attendance`**, **`rpt_daily_attendance`**,
  **`rpt_daily_scan`**.
- **`int_dpr__admissions`** — `mus_attendance` removed. The old GA-ticket figure is retained
  as `mus_attendance_ga_proxy`, wired to nothing, for reconciliation.
- **Four report-layout seeds** — every memorial-attendance row → `availability = Stub`. The
  `not_null` tests on `mem_attendance` are removed in both schema files.

## Numbers that move

- **Passes scanned falls**, on four compounding populations: `status_code = 1` rows removed,
  `status_code = 0` with a code outside (0, 11) removed, code 11 swinging from `+q` to `−q`,
  and Gateway facility 13 removed. The direction is unambiguous; the magnitude is entirely a
  function of the code-11 and status-1 volumes in Galaxy.
- **Museum attendance changes definition and value.** Two independent shifts compound: the
  source moves from GA tickets issued to gate scans (which differ by no-shows, advance sales
  recognised on a different date, and multi-entry passes — expect the scan figure materially
  lower on advance-heavy days and materially different in *timing* on every day), and every
  Tuesday under 300 passes plus 2022-06-15 moves to exactly 0.
- **Every per-capita ratio moves with it**, including `REV_PER_CAP_MUSEUM` on the Tracker.
  Because numerator and denominator stay separate through the serving layer, no stored
  quotient needs restating — but every displayed per-cap changes.
- **Memorial attendance goes from a populated number to blank** on the DPR, the Attendance
  Report, the Daily Attendance Report and the Tracker, and `REV_PER_CAP_MEMORIAL` loses its
  denominator. That is a visible regression on four reports. The number it replaces was
  produced by pattern-matching `facility_name like '%MEMORIAL%'` on the Gateway facility
  catalogue, which is not the legacy measure and was self-flagged as unconfirmed in the model
  header. We would rather print nothing than print a number nobody can trace.
- **Any scan whose `Usage.FacilityID` differed from the ACP-derived value moves between
  attendance lines**; where the two agreed the change is a no-op.

## Findings recorded in the caveats tables (no code change this release)

- **`911dw.memorial_attendance` has no writer.** No transformation in the migrated Pentaho set
  populates it, no staged source corresponds to it, and no Gateway ACP resolves to
  `key_facility` 2000 because the facility map only produces 1006 and 5000. Memorial
  attendance therefore cannot be reproduced and is a typed NULL, cause *no data feed*. **The
  largest gap in the attendance domain.**
- **`key_facility` 3000 is unreachable.** The legacy museum filter is `IN (1006, 3000)` but
  `t_fact_museum_passes_scanned` only ever writes 1006, 5000 and 0. The seed carries 3000 so
  the definition is complete; it contributes nothing today.
- **Gateway facility 5000 is orphaned.** Facility 12 resolves to it and it belongs to neither
  attendance definition, so those scans are counted nowhere.
  `int_dpr__attendance.uncounted_passes_scanned` exposes the volume.
- **The legacy `else '0'` bucket means any gate that is neither 7 nor 12 counts toward no
  attendance line at all.** If a gate has been added since the Pentaho job was written, its
  scans are invisible today and stay invisible until a seed row is added.
- **`report.fe_dailyScan_ss` is a stored procedure whose body is not in the migrated SQL**, so
  the Daily Scan Report's market-category derivation still rests on the `acs_dynamic_channel`
  proxy rather than on proven legacy logic. Unchanged here, but it bounds how far that report
  can be reconciled.
- **`fct_daily_operations.retail_revenue_per_visitor` is a stored quotient**, which the ratio
  rule forbids. Pre-existing and out of scope — but its denominator changes in this release,
  so it is worth retiring rather than leaving a divided ratio whose meaning has shifted.
- **The `1000` memorial key is left uncounted**, carried in the seed with
  `is_primary_definition = FALSE`. The legacy estate contradicts itself: two objects use
  `(2000)` and two use `(1000, 2000)`. Flipping the cell changes the definition with no model
  edit.
