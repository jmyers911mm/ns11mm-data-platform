# ADR-011: Orchestration: Azure DevOps Scheduling, dbt Run Order, and Failure Handling

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Operations
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana, Kalea Ramsey (Data & AI Team — the diagnose-when-the-engineer-is-out audience)
**Related:** ADR-001 (Stack Selection), ADR-003 (Ingestion Strategy), ADR-015 (Monitoring), ADR-016 (SLAs)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-011); decision box empty, recommended option drafted pending the session. **The review doc's proposed revisit threshold ("more than 15 active dbt models") is already exceeded — the repo currently carries ~111 active models — so that clause is stale as written and is recalibrated below to source-pipeline terms; confirm the recalibration at the session.** Document the production dbt selectors and schedule cadences in the appendix before ratification [confirm].

## Context

Pipeline orchestration uses Azure DevOps scheduled pipelines for triggering and dbt's DAG for run order. The pattern, selector logic, failure handling, and monitoring approach are not documented. This is workable at low pipeline volume but becomes critical at Q4 volume, when five or more sources run on different cadences. If the engineer is out and a pipeline fails, Diana or Kalea needs a document to diagnose it from.

A dedicated orchestrator (Dagster, Prefect, Airflow) would handle cross-pipeline dependencies and retries natively, but adds a new tool to the stack during the busiest build phase before the December 2026 go-live and the January 5, 2027 Pentaho lapse.

## Decision

**Azure DevOps + the dbt DAG is the production orchestration pattern through the December 2026 go-live.**

- Run order within a build is owned by the dbt DAG; scheduling and triggering are owned by Azure DevOps pipelines.
- The production dbt selectors, per-source schedule cadences, and failure-alert routing are documented in this ADR's appendix and kept current as sources onboard. [confirm current selector list]
- Failure handling: a failed pipeline run alerts per the ADR-015 routing; reruns are manual and idempotent (safe because RAW is append-only per ADR-007 and models rebuild deterministically).
- During the September 6–16 commemoration freeze, non-essential pipelines are paused per ADR-006.

## Options considered

### Option A: Azure DevOps + dbt DAG with a defined revisit trigger (recommended)

Wins because it is the pattern already running, requires no new tool during the highest-risk build phase, and converts "when do we need a real orchestrator?" from a recurring debate into a measurable trigger (below).

### Option B: Adopt Dagster or Prefect now (set aside)

Its genuine advantage: native dependency management, retries, backfills, and observability before Q4 volume arrives — adopting under calm conditions rather than under load. Set aside because it adds engineering overhead and a new operational surface during the busiest build phase, when the team's capacity is the binding constraint and the current pattern is not yet failing.

### Option C: Document the current pattern with no revisit trigger (set aside)

Lowest effort. Set aside because it defers the orchestrator decision indefinitely — the review doc's own criterion for a bad revisit clause — and guarantees the decision gets made reactively, mid-incident.

## Consequences

**Positive**
- Diana or Kalea can diagnose a failed run from the documented selectors, cadences, and alert routing without the engineer.
- No new tool competes for team capacity before go-live.
- The orchestrator question has a measurable answer instead of a standing argument.

**Negative**
- Azure DevOps has no native concept of cross-pipeline data dependencies; anything spanning two pipeline runs is stitched manually and is fragile by construction.
- Retries, backfills, and run observability remain manual work that a dedicated orchestrator would absorb.

**Accepted risks**
- If Q4 source volume arrives faster than planned, the migration to a dedicated orchestrator would happen under exactly the load this decision tried to avoid.

## Revisit trigger

Reopen when any of the following occurs: **more than 5 source pipelines on different cadences; any pipeline dependency that spans two DevOps pipeline runs; or the first orchestration-caused SLA miss (ADR-016)** — whichever comes first, and in any case at the December 2026 go-live review. (The review doc's ">15 active dbt models" clause is dropped as already-exceeded and not the binding constraint; the dbt DAG handles intra-build ordering at current model counts without issue. [confirm at session])
