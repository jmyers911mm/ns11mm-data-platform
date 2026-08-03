# ADR-019: All environments read source data from a single shared database (NS11MM_DW_DEV)

**Status:** Proposed (interim decision; committee ratification tracked with the ADR-005 open items)
**Date:** July 31, 2026
**Deciders:** Jeremy Myers (Data & AI Team lead)
**Consulted:** —

## Context

Ingestion is currently **seed-based**: Gateway, CounterPoint, budget, and report-estate
extracts are landed as tables in `NS11MM_DW_DEV.RAW` and `NS11MM_DW_DEV.SEEDS` by manual
loads and the interim pipelines. The Azure Function pipelines that would land data
per-environment are parked in `disabled/` (they cannot run until packaging and source
queries are confirmed — see the 7.2.0 notes), and Snowflake cannot initiate connections
to the on-prem sources (Gateway Ticketing, NCR CounterPoint), so re-landing the same
extracts into every environment would mean duplicating a manual process that exists only
once today.

The dbt project builds into multiple databases: personal sandboxes
(`NS11MM_DW_DEV_<USER>`), shared dev (`NS11MM_DW_DEV`), CI (`NS11MM_DW_DEV_CI`), and
production (`NS11MM_DW_PROD`). Before this ADR, `models/raw/sources.yml` resolved the
source database through an undocumented `seed_database` var hardcoded to
`NS11MM_DW_DEV` — which meant the production build silently read dev-hosted data with no
recorded decision behind it, and `gdpr_anonymize` performed erasure in
`{{ target.database }}.RAW`, a schema the models were not reading when the target was not
`NS11MM_DW_DEV`. The erasure and the read path could miss each other.

What is not yet known: when the function pipelines will be production-ready, and whether
the end-state landing zone will be `NS11MM_DW_PROD` or a dedicated raw/landing database.

## Decision

All dbt environments — sandboxes, shared dev, CI, and production — read RAW and SEEDS
source data from the single shared database `NS11MM_DW_DEV`, resolved through the
`source_database` project var. Erasure (`gdpr_anonymize`) operates on the same var, so
right-to-erasure always hits the data every environment actually reads.

## Options considered

### Option A: NS11MM_DW_DEV as the single source of record (selected)

The data is already there; the pipelines, `LOADER_ROLE` grants, and
`SNOWFLAKE_SETTINGS.md` all already designate shared dev as the RAW ingestion host; and
no data migration or grant restructuring is needed. Prod builds add one cross-database
read grant. This matches how the platform actually operates today and makes it explicit.

### Option B: NS11MM_DW_PROD as the single source of record (set aside)

Its genuine advantage: the source of record would live in the most-governed, least-churned
database, and prod would have no dependency on a dev-tier database's retention and
rebuild policies. Set aside because it requires migrating the landed extracts, repointing
the load process and `LOADER_ROLE` grants to prod, and giving every developer and CI a
cross-database read on prod — meaningful ops work purchasing little safety while RAW in
shared dev is already append-only (ADR-001) and written only by `LOADER_ROLE`. It remains
the natural end-state candidate once ingestion is automated.

### Option C: Land sources per-environment (set aside)

The textbook isolation answer: each environment fully self-contained. Set aside because
the load process is manual and single-instance today; per-environment landing would mean
divergent copies of source data and no single truth to reconcile against.

## Consequences

**Positive**
- One copy of source data; every environment reconciles against the same numbers.
- The prod→dev read dependency is now a recorded, greppable decision (`source_database`)
  instead of a silent var.
- GDPR erasure and the read path can no longer miss each other.

**Negative**
- Production depends on a dev-tier database being available and intact. A mistaken drop
  or reload of `NS11MM_DW_DEV.RAW` changes prod numbers on the next build.
- Time Travel / retention on shared dev (7 days) now effectively governs prod source
  recoverability.

**Accepted risks**
- `NS11MM_DW_DEV.RAW` is append-only and written only by `LOADER_ROLE` (ADR-001), which
  bounds the blast radius of the dev-tier dependency; the weekly prod clone task provides
  a fallback for the built layer.

## Revisit trigger

Reopen this decision when the first Azure Function pipeline is production-enabled (moves
out of `disabled/` with working packaging), or if `NS11MM_DW_PROD` gains its own landing
process, or at the 2026-12 production go-live review — whichever comes first. At that
point choose the end-state landing zone (prod or a dedicated raw database) and flip
`source_database` in one place.
