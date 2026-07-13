# ADR-006: Change Management: Seven-Stage Process

- **Status:** Accepted (current). No revision required; forward reference to ADR-014 to be added once written.
- **Category:** Governance / Change Management
- **Date:** Original [confirm].
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Related:** ADR-010 (Power BI Authorization Model, proposed), ADR-014 (Change Validation and Non-Regression, proposed), ADR-015 (Data Monitoring, proposed)

> **Source note.** The review doc marks this ADR active with one forward-reference to add. This file reconstructs the current decision from platform context; the enumerated stages are described only at the level reliably known. Confirm the exact seven stage names and gate definitions against the canonical ADR-006 before publishing.

## Context

All changes to the data platform, and to IT systems generally, flow through a defined multi-stage change process. This provides a consistent intake, review, and release path and an auditable record of what changed and why. The process predates the Snowflake migration and remains current; it is stack-agnostic.

## Decision

Platform changes follow a **seven-stage change management process** [confirm exact stage list from source ADR-006]. The governing rules that are established and in force:

- **Single intake point.** All IT changes are submitted through Ginabell as the sole intake. Change IDs follow the `ITCHG-NNNN` format. Data platform Change IDs are assigned by Diana.
- **Access governance gate.** Gate 4 covers access governance; the Power BI authorization model (ADR-010, proposed) is enforced at this gate.
- **PR-gated CI with human review.** Code changes, including AI-generated code, require pull-request review before merge. Jeremy is the exclusive merger to dev and main; Kalea Ramsey is a CODEOWNERS co-owner.
- **Freeze protocols.** Commemoration and major-event freeze windows apply. During the September 6 to 16 commemoration freeze, non-essential pipelines are paused, the `is_commemoration_day` flag is set in the date dimension, and alerts are muted.

## Consequences

- Every change is traceable to a Change ID and a reviewer.
- Freeze windows are honored operationally, not just documented.
- The process is the backbone that the proposed validation and monitoring ADRs plug into.

## Revisions applied in this version

- None to the decision itself.
- To be added once ADR-014 (Change Validation and Non-Regression) is written: a forward reference tying the seven-stage process to the non-regression validation step. [confirm after ADR-014 is ratified]